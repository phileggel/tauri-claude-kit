# Testing Strategy

## Overview

| Tier                    | What                                   | Location                                                     | Mocks?                        |
| ----------------------- | -------------------------------------- | ------------------------------------------------------------ | ----------------------------- |
| Frontend                | Component and reactive-module behavior | colocated `*.test.ts` next to the file                       | Gateway mocked                |
| BE Tier 1 — Unit        | Service / orchestrator logic           | inline `#[cfg(test)] mod tests` in the same `.rs` file       | All deps mocked (mockall)     |
| BE Tier 2 — Repository  | SQL queries and persistence            | inline `#[cfg(test)] mod tests` in the repository `.rs` file | None — real in-memory SQLite  |
| BE Tier 3 — Integration | Spec-driven end-to-end flows           | `src-tauri/tests/` (separate binary)                         | None — real services + SQLite |
| Tier 4 — E2E            | WebDriver UI flows                     | `e2e-rules-svelte.md` (ephemeral DB, B36)                    | None                          |

Run checks before committing:

```bash
npm run test                   # Frontend (Vitest)
cargo test --manifest-path src-tauri/Cargo.toml   # Backend (Rust)
<your-check-command>           # Full check: lint + type-check + tests
```

---

## Frontend Testing (Vitest + testing-library/svelte)

### What to test

Test **behavior**, not implementation:

- State transitions triggered by user actions (auto-fill, reset after submit, type switching)
- Gateway call arguments — correct command, correct params, correct order
- Success and error handling — snackbar shown, form reset, modal closed
- Async flows — loading, race conditions, late-resolving promises

Do **not** write tests for:

- Rendering / DOM structure only
- Trivial getters or constructors

### Mocking gateway modules

Always mock at the **module level** with `vi.mock`, before importing the module under test. Use `vi.hoisted` for mocks that need to be referenced in setup callbacks.

```ts
import { waitFor } from "@testing-library/svelte";
import { flushSync } from "svelte";
import { beforeEach, describe, expect, it, vi } from "vitest";

// 1. Mock gateway modules before importing the module under test
vi.mock("../gateway", () => ({
  fetchItems: vi.fn(),
}));

vi.mock("@/ui/components/snackbar/snackbarStore.svelte", () => ({
  showSnackbar: vi.fn(),
}));

// 2. Import mocked modules for typed access
import * as gateway from "../gateway";
import { createMyState } from "./myState.svelte";
```

For mocks that are referenced inside `beforeEach` or test bodies, use `vi.hoisted`:

```ts
const mockToastShow = vi.hoisted(() => vi.fn());

vi.mock("@/ui/components/snackbar/snackbarStore.svelte", () => ({
  toastService: { show: mockToastShow, subscribe: vi.fn(() => vi.fn()) },
}));
```

### Seeding a shared store

For app-wide reactive state in a `.svelte.ts` module, expose a `reset()` (or test-only setter) and call it in `beforeEach`:

```ts
import { appStore } from "@/shell/appStore.svelte";

beforeEach(() => {
  vi.clearAllMocks();
  appStore.reset({
    items: [{ id: "item-1", name: "Example item" }],
  });
});
```

For modules that export a factory, call the factory afresh in each test instead — that's the preferred pattern since it scopes state to one test.

### Testing reactive modules

Import the `.svelte.ts` factory directly and call it. There is no `renderHook` equivalent in Svelte 5 and none is needed — runes work in `.svelte.ts` files exactly as they do inside components.

```ts
import { it, expect } from "vitest";
import { flushSync } from "svelte";
import { createMyState } from "./myState.svelte";

it("recomputes derived value when source state changes", () => {
  const state = createMyState({ count: 0 });

  state.count = 5;
  flushSync(); // force $derived to recompute synchronously

  expect(state.doubled).toBe(10);
});
```

`flushSync` is only needed when you assert on a `$derived` value synchronously after mutating its source. Async work observed via `waitFor` does not need it.

### Async patterns

Use `waitFor` to wait for async state to settle:

```ts
it("loads data on mount", async () => {
  vi.mocked(gateway.fetchItems).mockResolvedValue({
    success: true,
    data: ["item-1"],
  });

  const item = makeItem();
  const state = createMyState(item);

  await waitFor(() => expect(state.items).toEqual(["item-1"]));
});

it("resets selection when type changes", async () => {
  const state = createMyForm();

  await waitFor(() => expect(gateway.fetchItems).toHaveBeenCalled());

  state.handleTypeChange("OTHER");
  flushSync();

  expect(state.selectedItem).toBe("");
});
```

For testing race conditions (value resolves after a user action):

```ts
it("assigns value reactively when fetch resolves late", async () => {
  let resolve!: (v: { success: true; data: string }) => void;
  vi.mocked(gateway.fetchItems).mockReturnValue(
    new Promise((r) => {
      resolve = r;
    }),
  );

  const state = createMyForm();

  state.handleTypeChange("OTHER");
  flushSync();
  expect(state.selectedItem).toBe(""); // not yet resolved

  resolve({ success: true, data: "default-item" });
  await waitFor(() => expect(state.selectedItem).toBe("default-item"));
});
```

### Verifying gateway calls

Check that the correct command is called with the correct arguments:

```ts
expect(gateway.updateItem).toHaveBeenCalledWith("item-id-1", "2026-03-10", [
  "group-1",
]);
expect(gateway.deleteItem).not.toHaveBeenCalled();
```

---

## Backend Testing (Rust)

Three distinct tiers, each with a clear purpose and location.

---

### Tier 1 — Unit tests (mock dependencies)

**Location:** inline `#[cfg(test)] mod tests { ... }` at the bottom of service and orchestrator files.

**Purpose:** Test business logic in isolation. Every external dependency is mocked.

**Use mockall** (`#[cfg_attr(test, mockall::automock)]` on the trait):

```rust
#[tokio::test]
async fn test_create_item_success() {
    let mut repo = MockItemRepository::new();
    repo.expect_create()
        .returning(|name, value| {
            Item::new(name, value)
        });

    let service = ItemService::new(Arc::new(repo));
    let result = service.create("example".to_string(), 100).await;

    assert!(result.is_ok());
    assert_eq!(result.unwrap().value, 100);
}
```

**What to test:**

- Service logic: correct values returned, correct state transitions
- Error propagation: repository failures bubble up correctly
- Domain factory methods: validation rules enforced (`new()`, `with_id()`)
- Orchestrator flows: correct sequence of service calls, correct field values set

---

### Tier 2 — Repository tests (real SQLite)

**Location:** inline `#[cfg(test)] mod tests { ... }` at the bottom of repository files.

**Purpose:** Verify SQL queries and persistence behavior. No mocking — uses a real in-memory `SqlitePool` with migrations applied.

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};

    async fn make_pool() -> SqlitePool {
        let opts = SqliteConnectOptions::new().in_memory(true).foreign_keys(false);
        SqlitePoolOptions::new()
            .max_connections(1)
            .connect_with(opts)
            .await
            .unwrap()
            .tap_mut(|p| sqlx::migrate!("./migrations").run(p))
    }

    #[tokio::test]
    async fn test_create_and_read_item() {
        let pool = make_pool().await;
        let repo = SqliteItemRepository::new(pool);
        let item = repo.create("example", 100).await.unwrap();
        let found = repo.find_by_id(&item.id).await.unwrap().unwrap();
        assert_eq!(found.name, "example");
    }
}
```

**What to test:**

- CRUD correctness: insert → read round-trip
- Constraint enforcement: duplicate key, foreign key
- Query filters: find-by-X returns correct rows
- Soft-delete behavior: deleted rows excluded from reads

---

### Tier 3 — Integration / spec tests (full flow)

**Location:** `src-tauri/tests/` directory (separate Rust test binary — only public API visible).

**Purpose:** Validate spec-driven orchestrator flows end-to-end across multiple services and repositories. No mocking — real services backed by real in-memory SQLite.

```rust
struct Ctx {
    orchestrator: MyOrchestrator,
    item_service: Arc<ItemService>,  // held separately for post-action assertions
}

async fn build_ctx() -> Ctx {
    let pool = make_pool().await;
    let item_repo = Arc::new(SqliteItemRepository::new(pool.clone()));
    let item_service = Arc::new(ItemService::new(item_repo.clone()));
    let orchestrator = MyOrchestrator::new(item_service.clone());
    Ctx { orchestrator, item_service }
}
```

**What to test:**

- Multi-service flows: orchestrated operations across multiple BCs
- Spec business rules: invariants enforced across the full stack
- Cross-context interactions that can't be exercised by a single unit test

**Key constraint:** `tests/` can only access public API. Keep a separate `Arc<Service>` in the `Ctx` struct when you need to assert post-action state — do not access private fields.

---

### Tier 4 — E2E (WebDriver UI flows)

**Location:** `e2e/` tests driving the full app through WebDriver.

**Purpose:** Validate UI flows end-to-end against an ephemeral database (per B36).

See [`e2e-rules-svelte.md`](e2e-rules-svelte.md) for the full rule set (E1–E10) — selector discipline, controlled-input helpers, locale-formatted date pickers, deterministic test values.

---

### What not to test (all tiers)

- A constructor doesn't panic
- An empty input returns empty output (no logic traversed)
- A getter returns what was just passed in
- A test helper disguised as a test

---

### Running backend tests

```bash
cd src-tauri
cargo test                     # All tests
cargo test {filter}            # Filter by name
cargo test -- --nocapture      # Show println! output
RUST_BACKTRACE=1 cargo test    # With backtraces
```
