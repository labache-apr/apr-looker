# LookML Style Guide — `aefc-looker`

This guide governs how we write LookML in this project. Its goal is to make the
output usable by **dashboard and report developers** who don't read LookML, not
just by the data team.

If a rule here would make a specific situation worse, document the exception
in a comment on the offending block. Style guides are guardrails, not laws.

---

## 1. Required metadata

Every PR is checked in CI. The following are **required**:

| Element | Required fields |
|---|---|
| `view` (standalone) | header comment block (see §6), at least one `primary_key` dimension |
| `view` (extension target — `*_struct`, `*_custom_fields`) | header comment; primary key not required |
| `dimension` (non-hidden) | `description:` |
| `measure` (non-hidden) | `description:`, `value_format_name:` or `value_format:` (exempt: `type: count` / `count_distinct`) |
| `dimension_group` (non-hidden) | `description:` (one is enough; covers all timeframes) |
| `explore` | `label:`, `description:`, `group_label:` |
| `join` | `relationship:`, comment line stating cardinality assumption + fan-out risk |

Hidden fields (`hidden: yes`) are exempt — but if a field is worth describing,
it's worth showing. Prefer to write the description and unhide it.

> **Extension targets** (`structs/`, `custom_fields/`) are composed into other
> views via `extends:`. They don't need their own primary key, but their
> dimensions still need descriptions if they're non-hidden in the host view.

---

## 2. Naming

### Views
- Snake case. Match the source table name (lower-cased) when mirroring a
  TWC export — e.g., `SalesReceipt_view` → `sales_receipt`.
- **Master / dimension views** (`master/`): prefix `dim_` for `bi_star`
  dimensions (`dim_calendar`, `dim_employee`, `dim_location_franchise`).
  Use the business name (`item_master`, `customer_master`) for the
  source-of-truth mirrors.
- **Transaction views** (`transactions/`): singular business name
  (`sales_receipt`, `purchase_order`, `transfer`).
- **Operational / derived views** (`operational/`): keep the business name
  (`item_lifecycle_dates`, `product_flash`, `forecast_vs_actuals`).
- **Extension targets** (`structs/`, `custom_fields/`): suffix `_struct`
  or `_custom_fields`. These are not standalone explores.
- **Aggregates / aggregate-aware**: suffix `_daily_agg`, `_monthly_agg`.

### Dimensions
- Snake case. Match the underlying source column when mirroring; use a
  business name when deriving.
- **Money:** suffix `_amt`. USD unless the field name says otherwise.
  Use `value_format_name: usd` (or `usd_0` for whole-dollar).
- **Quantity:** suffix `_qty`. Use `value_format_name: decimal_0` for
  unit counts.
- **Percent / rate:** suffix `_pct` or `_rate`. Use
  `value_format_name: percent_2`.
- **Identifier:** suffix `_id` (internal/system) or `_no` (human-facing
  number, e.g., `receipt_no`, `universal_no`). Use `value_format_name: id`
  on numeric IDs to suppress thousands separators.
- **Foreign keys:** suffix `_id`. Hide them by default (`hidden: yes`);
  expose only when joins rely on them being visible.
- **Boolean:** prefix `is_` or `has_`. `type: yesno`.
- **Timestamps:** suffix `_at` (e.g., `posted_at`). Stored UTC unless
  suffixed `_local`.
- **Calendar dates:** suffix `_date` for `dimension_group: time` blocks.

### Measures
- Lead with the aggregation: `total_net_sales_amt`, `avg_basket_size`,
  `transaction_count`, `count_distinct_customers`.
- For ratios, end with `_pct` or `_rate`: `margin_pct`, `return_rate`.
- Avoid bare entity names (`sales`, `customers`) — these read as
  dimensions in the field picker.

### Explores
- `name`: snake_case, business-meaningful (`sales_receipt`, not `sr_explore`).
- `label`: title-cased, business-friendly (`"Sales Receipts"`).
- `group_label:` is required. Top-level groups: `"Sales"`, `"Inventory"`,
  `"Merchandising"`, `"Purchasing"`, `"Planning"`, `"CRM"`, `"Operations"`,
  `"Finance"`, `"Audits"`.

---

## 3. Writing descriptions

Descriptions are written for **a non-technical analyst building a dashboard**.

**Do:**
- State *what the field represents in business terms*.
- Note the unit if non-obvious (`"Net sales in USD, excluding tax"`).
- Call out caveats inline (`"NULL on non-return lines"`).
- Use examples for enums (`"e.g., 'Sale', 'Return', 'CreditMemo'"`).
- For derived/calculated fields, name the inputs in business terms — not
  the SQL.

**Don't:**
- Restate the field name (`"The receipt number."` for `receipt_no`).
- Describe the SQL (`"COALESCE of NetSalesAmt and AdjustedAmt"`).
- Reference current callers, tickets, or sprints (`"Used by Q2 dashboard"`).

**Length:** one to three sentences. Long-form context belongs in the data
dictionary entry, not the LookML.

---

## 4. Tags vocabulary

Use only these tags. Adding a new one requires a styleguide PR.

| Tag | Meaning |
|---|---|
| `certified` | Reviewed, owner-signed-off, safe to build dashboards on |
| `draft` | Functional but not yet certified — may change without notice |
| `deprecated` | Slated for removal; pair with `hidden: yes` |
| `pii` | Personally identifiable information — gated by access grants |
| `tenancy` | Field is part of the row-level-security key set |
| `twc-native` | Field comes directly from a TWC export (no transformation) |
| `bi-star` | Field comes from the `bi_star` supplemental dataset |
| `derived` | Field is calculated in LookML or a PDT, not in source |
| `client-config` | Value depends on per-client configuration (custom field, mapping) |

Tags are machine-readable. The data dictionary keys off them.

---

## 5. Hidden fields

Hide by default:
- Foreign-key IDs whose only purpose is joins
- Partition columns (`date_part`) — expose business-friendly date dimensions instead
- Raw struct/array fields whose values are exposed via parsed dimensions
- Source-system internal columns kept for debugging
- Anything tagged `deprecated`

A clean field picker beats a complete one. If a dashboard developer can't
find the field they need, the answer is to expose and document it — not to
expose everything.

---

## 6. View header comment

Every view starts with this block. Use the `═` rule (already established in
this project) — don't change to other styles in new files.

```lookml
# ══════════════════════════════════════════════════════════════
# View:    sales_receipt
# Source:  aefc-prod-us-twc-b1bc.external_datamart_1.SalesReceipt_view
# Grain:   One row per receipt line (one item sold)
# Refresh: daily_refresh
# Owner:   data-team@allpointretail.com
# Tenancy: location_code, franchise_codes (via dim_location_franchise)
# Notes:   Includes returns and credit memos. Filter on transaction_type
#          for sale-only reporting.
# ══════════════════════════════════════════════════════════════
```

Required lines: `View`, `Source`, `Grain`, `Owner`. Others are optional.

For derived/PDT views, replace `Source` with `Source: derived (see SQL)` and
add a `Built from:` line listing upstream tables.

For extension targets (`structs/`, `custom_fields/`), replace `Grain` with
`Used by:` listing the host views that extend it.

---

## 7. Tenancy & row-level security

Two user attributes drive access (defined in the model):

- `location_code` — comma-separated list of location codes the user can see.
  Lower-cased on read. Sourced from `dim_location_franchise.location_code`.
- `franchise_codes` — comma-separated list of franchise group codes.
  Lower-cased on read. Sourced from `dim_location_franchise.FranchiseGroupCode`.
- `dev_mode_bypass` — escape hatch (`'yes'` disables both filters).
  **Never set this for production users.**

A user attribute value of `'any'` or empty string bypasses that filter
(admin-only).

**Rules:**
- Every customer-facing explore must join `dim_location_franchise` and
  enforce both filters via `sql_always_where`. See
  [`sales.explore.lkml`](../explores/sales.explore.lkml) for the canonical pattern.
- The `_rls` suffix (e.g., `location_code_rls`, `franchise_code_rls`) marks
  the lower-cased columns used in `sql_always_where`. Tag them `tenancy`.
- Every customer-facing view should expose user-friendly versions of the
  tenancy fields (without `_rls`) so analysts can filter and group.
- Never hardcode a location or franchise identifier in a derived table —
  pass it via the user attribute.

---

## 8. Datagroups

Use the existing datagroups in [`models/twc_aefc.model.lkml`](../models/twc_aefc.model.lkml).
Don't invent per-view datagroups unless you have a specific freshness
requirement.

| Datagroup | Trigger | When to use |
|---|---|---|
| `daily_refresh` (default) | `MAX(Date_Part)` on `SalesReceipt_view` | Most explores; daily POS data |
| `inventory_refresh` | `MAX(Date_Part)` on `Inventory_view` | Inventory views (4h cadence) |
| `master_refresh` | `CURRENT_TIMESTAMP()` | Master / dim views (12h ceiling) |

The model declares `persist_with: daily_refresh` as the project default.
Override per-explore with `persist_with:` when the explore is driven by a
faster-refreshing source (e.g., inventory).

If a new datagroup is needed, document it inline in the model file and
update this table in the same PR.

---

## 9. Group labels

Within a view, cluster fields with `group_label:` so the field picker is
navigable. Use these as a starting set — extend per-domain when the entity
calls for it (e.g., `"Sale Identifiers"`, `"Sale Amounts"`,
`"Sale Quantities"` on `sales_receipt` rather than a single `"Money"` group).

- `"User Access"` — RLS / tenancy fields (often hidden or restricted)
- `"Identifiers"` — primary and foreign keys, business numbers
- `"Status"` — transaction type, posting status, lifecycle flags
- `"Dates"` — `dimension_group:` blocks
- `"Amounts"` — money fields (`_amt`)
- `"Quantities"` — counts and units (`_qty`)
- `"Costs"` — cost / margin fields (per FIFO costing)
- `"Address"` — address fields
- `"Marketing"` — campaign / channel fields
- `"Flags"` — `is_*` / `has_*` yesno fields
- `"Custom Fields"` — fields surfaced from `*_custom_fields` extensions

Cluster names are case-sensitive in Looker. Match an existing group exactly
when extending.

---

## 10. Certification states

Every Explore has one of three states, declared via `tags`:

| State | Meaning | Allowed in production dashboards? |
|---|---|---|
| `certified` | Owner has signed off in the last 90 days | Yes |
| `draft` | New or under revision | Internal use only |
| `deprecated` | Scheduled for removal | No — migrate off |

Quarterly review: each Explore owner re-tags or marks deprecated.

The certified set is also reflected in
[`docs/data_dictionary.md`](data_dictionary.md) — keep them in sync.

---

## 11. Deprecation flow

To remove a field or view:

1. **Quarter 1**: Add `tags: ["deprecated"]` and `hidden: yes`. Add a
   comment pointing to the replacement. Communicate in the data channel.
2. **Quarter 2**: Verify no dashboards or scheduled looks reference it
   (use Looker's content validator). Delete.

Renames follow the same flow: keep the old field as a deprecated alias for
one quarter.

---

## 12. CI enforcement

The existing `looker-ci.yml` runs Spectacles for syntax, SQL, and content
validation. A `lint-lookml-docs` job (planned) will additionally fail a PR if:

- A new or modified non-hidden dimension/measure lacks `description:`
- A new or modified non-hidden measure lacks `value_format_name:` or `value_format:`
- A new or modified explore lacks `description:`, `label:`, or `group_label:`
- A new view lacks the §6 header
- A field is tagged `deprecated` without `hidden: yes`

The check runs only on **changed lines** (via `git diff` against the base
branch), so legacy debt doesn't block your PR.

---

## 13. Quick reference: a well-documented dimension

```lookml
dimension: net_sales_amt {
  type: number
  description: "Net sales in USD, after discounts but before tax. Negative
    on returns and credit memos."
  group_label: "Sale Amounts"
  value_format_name: usd
  tags: ["twc-native", "certified"]
  sql: ${TABLE}.sale.NetSalesAmt ;;
}
```

And a measure:

```lookml
measure: total_net_sales_amt {
  type: sum
  description: "Net sales in USD, after discounts but before tax. Returns
    and credit memos are subtracted (net of returns)."
  value_format_name: usd
  group_label: "Sale Amounts"
  tags: ["derived", "certified"]
  sql: ${net_sales_amt} ;;
}
```

And a margin measure (FIFO costing — see [GLOSSARY.md](GLOSSARY.md#money)):

```lookml
measure: margin_pct {
  type: number
  description: "Gross margin percentage: (net sales − FIFO COGS) ÷ net sales.
    Returns reduce both numerator and denominator."
  value_format_name: percent_2
  group_label: "Costs"
  tags: ["derived", "certified"]
  sql: SAFE_DIVIDE(${total_net_sales_amt} - ${total_cogs_amt}, ${total_net_sales_amt}) ;;
}
```
