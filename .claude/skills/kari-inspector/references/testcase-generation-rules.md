# Testcase Generation Rules

> **Version:** 1.4 — canonical rule set shipped with the kit. `.inspector/rules.md` may only *add* to it.
> Optional project business chains: `.inspector/domain-map.md` (copy from `domain-map.example.md`).

---

## 0. Output Language (Mandatory)

Write **testcase content** — `title`, `preconditions`, every `steps[].action` / `steps[].expected`, and
`expected_result` — in the **user's working language**, not English by default.

- **Detect** from: the language the user chats in, the spec/feature file, and existing active testcases in
  `<work_dir>/testcases/**` (read one before generating). When these disagree, **ask once** with
  `AskUserQuestion`.
- **Vietnamese-first teams:** user chats Vietnamese or existing testcases are Vietnamese → all prose in
  Vietnamese.
- **Keep literal / never translate:** the `[L1]` tag (`[Main]`, `[Validation]`, `[Other]`…); field, button,
  screen and API names exactly as in the spec/UI (`name`, `expires_in_days`, **Tạo token**); status codes
  and identifiers (`404`, `login_required`, `SCR-A02`); `test_data` keys (`name=...`). Only the surrounding
  prose is translated.
- `test_case_type` and `severity` values stay canonical English (schema values, not display prose).

---

## 0.1. E2E Only (Mandatory)

**Only produce End-to-End test cases** — real user actions on the application UI, suitable for manual or
automated testing (Playwright, Selenium). Always write from the **user's** point of view.

**Do NOT create:** unit tests; code-level integration tests (direct API response checks, internal function
calls); anything about AJAX/XHR, internal HTTP status codes, source code, DOM structure, network calls,
direct DB queries, mocks/stubs/spies; or steps requiring the tester to read/run code, inspect the network
tab, or use the browser console.

| ❌ Never write | ✅ Always write |
|---|---|
| "Call POST /api/login and verify 200 OK" | "Login - Wrong password: enter wrong password → error message shown" |
| "validateEmail() returns false when input is empty" | "Email field - Required: leave empty → 'Email is required' shown" |
| "Database has one new record after form submit" | "Submit form successfully → user is redirected to the list page" |

---

## 0.2. Test Level — IT vs ST (Mandatory, decide before writing)

Every draft carries exactly **one** `test_level`: `integration_test` (IT) or `system_test` (ST), decided
**before** authoring because it changes what you write. Kari files them on separate pages
(`/it-testcase-design` vs `/st-testcase-design`) and a project may define separate generation rules per
level. Both levels are still E2E, UI-driven, user-perspective per §0.1 — the difference is **scope**.

| | `integration_test` (IT) — **default** | `system_test` (ST) |
|---|---|---|
| **Question answered** | Does this feature work correctly? | Does the whole flow work end to end? |
| **Scope** | One feature / screen / function | A business process across screens or modules |
| **Boundaries** | Within the feature and what it directly touches | Multiple modules, roles, or systems |
| **Depth vs breadth** | Deep: every field, validation, error message, branch | Broad: the path through the system; per-field detail belongs in IT |
| **Typical case** | "Email field — leave empty → 'Email is required'" | "Order a product: search → cart → checkout → payment → order in history" |
| **Steps** | 3–8 | 6–15 |
| **Data setup** | Preconditions inside the feature | Multi-step setup across modules; state carries between steps |

**Choosing:**

- **Default to IT.** Most requests are IT — if the spec covers one screen/function, don't ask.
- **Choose ST** when the requirement describes a process spanning modules ("từ lúc đặt hàng đến khi giao
  xong"), says system/E2E/luồng nghiệp vụ, or its ACs only make sense after several screens in sequence.
- **Genuinely ambiguous → ask once** with `AskUserQuestion` before authoring, never mid-draft.
- **Never mix.** One draft = one level. Needs both → IT draft first, then a separate ST draft (different
  `--draft` slug); say so rather than blending.

**Writing ST specifically:** follow **§0.2.1** (business-flow authoring). Keep steps at the level of what a
user does across screens, name the screen each step happens on, and carry state forward explicitly (the
order created in step 3 is verified in step 8). Verify **data continuity** and cross-feature effects
(create order → pay → confirmation email → status). Don't re-test field validation already covered by the
IT draft — a failing ST case should point at the *integration between* steps, not a single field. Titles
reflect the business scenario, e.g. `"Order flow - Create order to payment success"`.

### 0.2.1 Business-flow ST authoring (Mandatory for ST)

System Testcases must follow the **business process / module dependency chain**, not a laundry list of IT
functions. Extract the chain **before** writing any ST body.

**Pipeline (do in order):**

1. **Extract** an ordered module/screen chain from SRS / Jira / AC (and any project notes).
2. **Load** `.inspector/domain-map.md` when present (confirmed chains for this product). Also read
   `.inspector/rules.md` if filled. Template: kit `domain-map.example.md` — copy into the project as
   `.inspector/domain-map.md` and fill; **do not** invent another product's modules as if they were kit truth.
3. **Confirm gate:** if the chain is ambiguous, missing from the domain map, or conflicts with SRS → ask
   **once** with `AskUserQuestion`. If the map already has a confirmed chain that matches this ticket →
   reuse it and log a one-line assumption (avoid confirm fatigue).
4. **Plan coverage** as **chained short ST cases** along that flow (not one mega-TC per IT leaf). Continuity:
   later cases put prior outcomes in `preconditions`; set per-testcase `order` along the journey.
5. **Write** Kari JSON for each segment (see limits below), then self-review.

**Multi-project safety (hard):**

- Shared kit rules stay **pattern-only**. Never hardcode a concrete product module chain (e.g. a named
  Account→Setting→… path) as mandatory kit text.
- Illustrative chains in docs must use placeholders (`ModuleA → ModuleB → ModuleC`) or be explicitly labeled
  *example — project-specific*.
- Copying another project's domain map into a different product is a **contamination** defect — flag in review.

**Step limits:**

- Target **6–15** steps per ST testcase (same band as the table above).
- **Hard split** when a draft case would exceed **15** steps, or at a natural segment boundary (after a
  durable business checkpoint: create/save/approve/submit that later cases can precondition on).
- Prefer several short chained cases over one 24-step monster.

**Checkpoint expects:**

- Fill `steps[].expected` on create / save / approve / status-change / other verifiable mid outcomes.
- Navigation-only steps may omit `expected`.
- Do **not** dump every assertion only into `expected_result` while mid checkpoints stay empty.
- `expected_result` remains required (overall outcome for that case).

**Feature attachment:** keep the IT Module→Screen→Function→Item tree. An ST draft may span **multiple leaf
features**; attach each case to the **anchor leaf** for that segment (primary feature of the ticket or the
screen where the segment ends). Do not invent a parallel "Flow" feature type.

**Roles / permissions:** expand role×permission coverage only when roles or permission gates are in scope for
the ticket — not a default full matrix on every ST cluster.

**Schema note (external MD skills → Kari):** one flat "entry" with a single ExpectedResult maps to **one**
Kari testcase (`steps[]` + `expected_result`); mid-step outcomes become `steps[].expected`.

---

## 1. Scope (Mandatory)

- When many related features exist, **focus on the one most clearly targeted** by the requirement. Don't
  spread generation thinly across many features.
- Per feature: cover happy path, error handling, and boundary values before deeper edge cases.
- "Feature" = a node in the split feature tree (§1.1) — scope focus applies per *function*, not per screen.

---

## 1.1 Feature Tree & Testcase Title Convention (Mandatory)

**A feature must exist before testcases are generated for it** — resolve or create it first
(`inspector-gen-test` Step 3), never against an ad-hoc or missing `feature_id`.

**Tree — 2 to 4 levels:**

```
Module (app-level grouping — Auth, Cart, Store Management)
  └── Screen (one screen — Login Page, Product Management)
        └── [if the screen offers >1 distinct, independently-usable function] Function
              (Login SSO / Login with password / Register → 3 features, not 1)
              └── [encouraged, whenever there's >1 distinct field-group or section] Item
                    (General Info / Pricing / Media; Profile / Security / Notifications)
```

**Feature size heuristic:** aim for **under ~10 testcases per leaf feature**. Heading past ~10 is the signal
to split — first by distinct *function*, then by **Item**. Two limits: don't split a genuinely single,
undivided field-group just to hit the number (it stays one feature even if it runs a bit over), and don't
pad thin features with trivial cases to reach it.

**Distinct function vs CRUD variant** — *is this a separate thing the user chooses to do, or a variant of
the same operation on the same entity?*

- **Separate feature:** different auth methods (SSO / password / OTP), different entities reachable from
  one screen, tabs representing unrelated workflows.
- **One feature, title-prefix only:** Create/Update/Delete/Search on the *same* entity, different validation
  branches of the *same* form.

**Testcase title prefix — Test Viewpoint `[L1]` tag:** every title starts with `[<L1>] <scenario>`, taken
from the Kari Test Viewpoint template (`Matrix` sheet). Use **only Level 1** in the bracket.

| L0 (group — not in the tag) | L1 values (use in the `[...]` tag) |
|---|---|
| UI testing | Title bar, Screen Resolution, Layout, Type, Default value, Value, Placeholder, Text content/Mes content, Size, Position, Status, Format, Multi click, Hover, Scroll, Input method, Zoom in/Zoom out, Keyboard, Link |
| Function testing | Main, Validation, Other |

> The **Non-Function testing** L0 group (Performance, Usability, Compatibility, Monkey, Security) is **not**
> a `[L1]` tag — that's already carried by `test_case_type` (§8.1). Don't duplicate it in the bracket.

L2 / L3 detail goes into the scenario text, not the tag: `Main` → Create, Update, Delete, Search ·
`Validation` → Kiểu Text, Kiểu số, Date time, Radio button, Checkbox, Selectbox/Pulldown, Pop-up
message/dialog/alert · `Other` → Upload file, Export file, Real time (send mail…), Phân trang.

Examples: `[Main] Create product with valid data → record saved` · `[Validation] Email field rejects input
over max length` · `[Placeholder] Product name field shows correct placeholder text` · `[Layout] Header
stays fixed when the page is scrolled`.

No clear L1 → default to **`[Main]`** or **`[Validation]`**.

---

## 2. Output Format (Mandatory)

Author each testcase as a JSON object in the CLI schema — **snake_case**, matching
`inspector-cli/schema/testcases.schema.json` and what `inspector validate` enforces. `feature_id` is not
per-testcase; it lives once in `meta.feature_id`.

```json
{
  "title": "[Validation] Login - Wrong password",
  "order": 10,
  "test_case_type": "negative",
  "severity": "HIGH",
  "preconditions": "User is on login page. Account 'user@test.com' exists.",
  "steps": [
    { "action": "Enter email in Email field", "test_data": "email=user@test.com" },
    { "action": "Enter wrong password in Password field", "test_data": "password=wrongpass123" },
    { "action": "Click Login button" }
  ],
  "expected_result": "Error message 'Invalid email or password' is displayed. User remains on login page."
}
```

> The REST API and `kari_*` MCP tools use PascalCase (`FeatureId`, `TestCaseType`, `Precondition`…);
> `push`/`convert` map the snake_case above to it. Never hand-write the PascalCase payload.

**Hard rules:**

- **feature_id** — required for push; UUID from `inspector features`, set once in `meta.feature_id`.
- **test_case_type** — required, exactly one of `happy_path`, `alternate`, `negative`, `boundary`, `edge`,
  `security`, `non_functional` (§8.1).
- **severity** — required, one of `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` (§6).
- **title** — concise, specific, with the `[L1]` prefix (§1.1).
- **steps** — array of `{action, test_data?, expected?}`:
  - `test_data`: `"field=value; field2=value2"` with real field names, no placeholders (`value1`, `<email>`);
    **omit the key entirely** when the step enters no data.
  - **Long values:** never paste the full string. **Hard cap ~120 characters per field value** — use
    `"email=256×'a' + @test.com"`, `"name=string of 255 identical 'a' characters"`. Keep `action` concise
    and put the data hint in `test_data`.
  - `expected`: fill for steps with a verifiable mid-step outcome; **omit** for navigation/intermediate
    steps. For **ST**, checkpoint expects are mandatory per §0.2.1 (create/save/approve/state change).
- **expected_result** — overall final result; **always required, never empty**.
- **preconditions** — login state, screen location, prerequisite data.
- **order** (optional) — integer deciding display position, the single source of truth shared by the
  rendered page, `push` (server `order_index`) and `pull`. `convert` auto-fills `0,1,2…` when omitted. **To
  insert a case under case X**, give it X's `order` (duplicates allowed) and place it right after X in the
  array — don't append to the end. The CLI never shifts other cases' order.

**Inline Markdown (optional):** the UI renders `**bold**`, `*italic*`, `` `code` ``, `~~strike~~` and
newlines in `preconditions`, `steps[].*` and `expected_result` — use it to emphasise a field, button, or
the asserted message. The text must still read correctly as plain text (Excel export shows markers
literally). Full rules + gotchas: `markdown-formatting.md`.

---

## 3. Coverage Techniques

Name the technique when deciding what TCs to generate:

- **Equivalence Partitioning (EP)** — group valid/invalid input classes; ≥1 TC per class.
- **Boundary Value Analysis (BVA)** — any range/length: `min-1`, `min`, `max`, `max+1`.
- **Decision Table** — ≥2 conditions affecting the outcome: cover all meaningful combinations.
- **State Transition** — entity with a status/lifecycle: every valid and key invalid transition.
- **Error Guessing** — empty, null, zero, negative, very long string, special chars, concurrent submit.
- **Use Case Testing** — happy path + alternate + exception paths.

---

## 4. Field Type Coverage Checklist

Skip anything not applicable to the spec.

**Text / Textarea** — required (empty → error) · max length (`max` valid, `max+1` error, described not
pasted) · valid representative input · format (invalid → error, valid → success) · special chars (HTML
tags, SQL `'` `"`, `<script>` — no injection) · leading/trailing spaces (trimmed or rejected per spec).

**Number** — required/empty · range `min-1` / `min` / `max` / `max+1` · non-numeric → error · zero/negative
if disallowed.

**Date / DateTime** — required/empty · valid vs invalid format · boundary min/max date · constraints
(start ≤ end, date ≥ today) · leap year (Feb 29).

**Combobox / Select** — required (select nothing → error) · one TC per meaningful option · correct default
on load · empty/placeholder option.

**Checkbox** — check (state + dependent field changes) · uncheck (state + dependents revert).

**File Upload** — valid format + size → success · invalid format → error · size > max → error · empty file
/ zero records.

---

## 5. Function-Level Coverage

| Operation | Must-have TCs |
|-----------|--------------|
| **Create** | Success: data saved, record count +1, redirect correct. Failure: no record created, data unchanged |
| **Update** | Success: data changed, count unchanged. Failure: data unchanged |
| **Delete** | Success: record gone, count -1. Failure: data unchanged. Cascade: related data per spec |
| **Search** | No results; single condition; combined conditions; exact match; partial match |

**Screen** — all required fields/sections display on load · default values correct · submit success →
correct redirect + data persisted · submit failure (server error) → user sees error, data not lost.

---

## 6. Severity

| Severity | When to use |
|----------|-------------|
| **CRITICAL** | Happy path of the main flow; data integrity; security (auth, injection) |
| **HIGH** | Important negative cases; edge cases with high risk to data or UX |
| **MEDIUM** | Alternate paths; secondary validation; ordinary edge cases; normal non-functional |
| **LOW** | Cosmetic/UI only; very rare edge cases; compatibility (unless a hard requirement) |

---

## 7. Non-Functional Reminders

Generate these when the spec or context implies them — **always from an E2E perspective**:

- **Security** — SQL injection / XSS payloads in fields → UI doesn't break or render scripts; open a URL
  without permission → 403 page or redirect.
- **Session** — after timeout → redirect to login; after logout → revisiting a protected URL redirects.
- **Performance** — if the spec defines an SLA, the tester measures perceived UI response time (not the
  network tab).
- **Compatibility** — if the spec lists browsers/devices, add a TC matrix from the user's perspective.
- **Multibyte / i18n** — if the app supports JA/ZH/KO, enter full-width / 2-byte characters and verify
  display.

---

## 8.1 test_case_type (mandatory on every testcase)

Classifies the **scenario design** — not execution labels (smoke/regression) and not priority.

| Value | Meaning (UI / E2E perspective) |
|---|---|
| `happy_path` | Main success flow per spec |
| `alternate` | Valid secondary branch or optional path |
| `negative` | Validation failure, business rule rejection, permission denied, or user-visible server error |
| `boundary` | BVA: min/max length, min−1/max+1, numeric/date edges |
| `edge` | Rare combinations: special characters, i18n/multibyte, double-submit, unusual order |
| `security` | Injection strings in fields, unauthorized URL access (§7) |
| `non_functional` | Session timeout, logout behavior, perceived performance per spec (§7) |

Exactly **one** per testcase. Both boundary-ish and edgy → prefer **`boundary`** when the spec defines a
concrete limit, otherwise **`edge`**. Equivalence partitioning doesn't need its own type.

---

## 9. What to Avoid

- TCs for features, fields, or screens **not in the spec**.
- Empty or vague `expected_result`; combining multiple assertions into one (split into separate TCs).
- Vague actions ("Enter data", "Check result"); generic titles ("Test login").
- `test_data` placeholders (`value1`, `test`, `xxx`), or a full long literal for length tests.
- Duplicate TCs differing only trivially in data.
- **Unit/code-level TCs** and **steps requiring internal technical checks** ("open DevTools", "check
  Network tab", "verify response body", "run script") — the tester interacts only through the UI.
