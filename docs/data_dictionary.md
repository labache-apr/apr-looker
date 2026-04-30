# AEFC Looker — Data Dictionary

**Audience:** Dashboard and report developers, business analysts, anyone building Looks or Explores against this LookML project.
**Owner:** _<team / dl>_
**Last reviewed:** _<YYYY-MM-DD>_

This dictionary is the canonical reference for **what every certified metric and field means**. When LookML field descriptions and this document disagree, this document wins — open a PR to fix the LookML.

This is one of three companion docs:

- **[GLOSSARY.md](GLOSSARY.md)** — business concepts, grains, tenancy, money & calendar conventions. Read this first if a *term* is unfamiliar.
- **[STYLEGUIDE.md](STYLEGUIDE.md)** — how to write LookML in this project: required metadata, naming, tags, datagroups, deprecation flow.
- **data_dictionary.md** (this file) — certified-explore catalog, metric glossary, view reference. Read this when a *field or metric* is unfamiliar.

---

## How to use this dictionary

1. **Looking for a metric?** Jump to [Metric Glossary](#metric-glossary).
2. **Building a new dashboard?** Start with [Certified Explores](#certified-explores) — those are blessed for executive and customer-facing use.
3. **Field shows up unfamiliar in an Explore?** Search this file for the field name, then fall back to the relevant [View Reference](#view-reference) section.
4. **Term unfamiliar (not a field — a concept like "ATS" or "DCSS")?** See [GLOSSARY.md](GLOSSARY.md).
5. **Disagree with a definition?** File a ticket in `<tracker>` and tag the explore owner.

---

## Status legend

| Status | Meaning |
|---|---|
| ✅ Certified | Vetted by data team. Safe for exec reporting and external sharing. |
| 🧪 Beta | Functional but definitions may shift. Use with caveats. |
| ⚠️ Deprecated | Will be removed by `<date>`. Migrate to `<replacement>`. |
| 🔒 Restricted | Requires elevated access (PII, finance, HR). |

> **Naming and writing conventions** (suffixes like `_amt` / `_qty` / `_pct`, measure prefixes like `total_` / `avg_`, etc.) live in [STYLEGUIDE.md §2](STYLEGUIDE.md#2-naming). **Currency, calendar, and money rules** live in [GLOSSARY.md](GLOSSARY.md#money).

---

## Certified explores

| Explore | Status | Group | Grain | Refresh | Owner | Use when |
|---|---|---|---|---|---|---|
| [`sales_receipt`](../explores/sales.explore.lkml) | ✅ | Sales | One row per receipt line | Daily | _<owner>_ | POS sales analysis, receipt-level drill-down |
| [`inventory`](../explores/inventory.explore.lkml) | ✅ | Inventory | One row per item × location × day | 4h | _<owner>_ | On-hand snapshots, sell-through, stock value |
| [`location_availability`](../explores/inventory.explore.lkml) | ✅ | Inventory | One row per item × location (current) | 4h | _<owner>_ | Real-time ATS, allocation decisions |
| [`traffic_counter`](../explores/inventory.explore.lkml) | ✅ | Inventory | One row per location × interval | Daily | _<owner>_ | Foot traffic, conversion rate |
| [`merchandise_movement`](../explores/merchandise_movement.explore.lkml) | _<status>_ | Merchandising | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`purchasing`](../explores/purchasing.explore.lkml) | _<status>_ | Purchasing | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`forecasting`](../explores/forecasting.explore.lkml) | _<status>_ | Planning | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`forecast_vs_actuals`](../explores/forecast_vs_actuals.explore.lkml) | _<status>_ | Planning | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`customers`](../explores/customers.explore.lkml) | _<status>_ | CRM | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`product_flash`](../explores/product_flash.explore.lkml) | _<status>_ | Merchandising | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`orders`](../explores/orders.explore.lkml) | _<status>_ | Sales | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`cash_drawer`](../explores/cash_drawer.explore.lkml) | _<status>_ | Operations | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`cash_reconciliation`](../explores/cash_reconciliation.explore.lkml) | _<status>_ | Finance | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |
| [`action_tracking`](../explores/action_tracking.explore.lkml) | _<status>_ | Operations | _<grain>_ | _<cadence>_ | _<owner>_ | _<use case>_ |

---

## Metric glossary

The single canonical definition for each business metric. Where a metric exists in multiple views, the **canonical reference** is the one to use; others are listed for traceability.

### Sales

#### Net sales
- **Definition:** Gross sales less discounts and returns. Excludes tax and shipping.
- **Formula:** `gross_sales_amt − discount_amt − returned_sales_amt`
- **Canonical reference:** `sales_receipt.total_net_sales`
- **Source column:** `external_datamart_1.SalesReceipt_view.sale.NetSalesAmt`
- **Unit:** USD
- **Also surfaces in:** `inventory.total_sold_net_sales` (for sell-through context — same definition, scoped to inventory grain)
- **Caveats:** Returns are stored as negative amounts; `total_net_sales` already nets them out. Don't apply `is_return = no` filter on top — that double-counts.
- **Owner:** _<team>_

#### Gross sales
- **Definition:** Sales before discount, before return netting. Excludes tax.
- **Canonical reference:** `sales_receipt.total_gross_sales`
- **Caveats:** Don't use this for "sales" on dashboards unless explicitly comparing pre/post-discount.

#### COGS (Cost of Goods Sold)
- **Definition:** Cost basis of items sold, valued using **FIFO** (First-In, First-Out). The cost recorded is the cost of the oldest on-hand units at the time of the sale.
- **Canonical reference:** `sales_receipt.total_cogs`
- **Caveats:** _<state when COGS is finalized vs. provisional>_

#### Margin (amount)
- **Definition:** Net sales minus COGS.
- **Canonical reference:** `sales_receipt.total_margin`
- **Formula:** `total_net_sales − total_cogs`

#### Margin %
- **Definition:** Margin expressed as a percentage of net sales.
- **Canonical reference:** `sales_receipt.margin_percent`
- **Formula:** `total_margin / total_net_sales`
- **Caveats:** Uses `SAFE_DIVIDE` — returns `NULL` (not 0) when denominator is 0.

#### Discount amount / discount rate
- **Definition:** Total discount value. Discount rate = discount / gross sales.
- **Canonical reference:** `sales_receipt.total_discount`, `sales_receipt.discount_rate`

#### Return rate
- **Definition:** Returned units as a proportion of total units (sold + returned).
- **Canonical reference:** `sales_receipt.return_rate`
- **Formula:** `return_quantity / (total_quantity + return_quantity)`
- **Caveats:** Note `total_quantity` already excludes returns (returns are filtered out of sold qty); the +returns in the denominator is intentional.

#### Transaction count
- **Definition:** Distinct receipts (not lines).
- **Canonical reference:** `sales_receipt.transaction_count`
- **Formula:** `count_distinct(sale.UniversalNo)`

#### ATV — Average Transaction Value
- **Definition:** Net sales per transaction.
- **Canonical reference:** `sales_receipt.avg_transaction_value`
- **Formula:** `total_net_sales / transaction_count`

#### UPT — Units per Transaction
- **Canonical reference:** `sales_receipt.avg_units_per_transaction`
- **Formula:** `total_quantity / transaction_count`

#### ASP — Average Selling Price
- **Definition:** **Net (post-discount)** realized revenue per unit. The price actually collected per unit after register-level promo discounts.
- **Canonical reference:** `sales_receipt.avg_selling_price`
- **Formula:** `total_net_sales / total_quantity`

#### AUR — Average Unit Retail
- **Definition:** **Gross (pre-discount)** ticketed retail per unit sold. The list/ticket price at the line before register-level promo discounts.
- **Canonical reference:** `sales_receipt.avg_unit_retail`
- **Formula:** `Σ(item.RetailPrice × sale.Qty) / total_quantity`
- **Caveats:** Distinct from ASP. AUR uses ticketed retail (already net of permanent markdowns captured in `BasePrice → RetailPrice`); ASP uses realized net sales. `AUR − ASP` is per-unit discount erosion from register promos.

### Inventory

#### On-hand quantity / cost / retail
- **Definition:** Current inventory position from the daily snapshot.
- **Canonical reference:** `inventory.total_on_hand_qty`, `total_on_hand_cost`, `total_on_hand_retail`
- **Caveats:** Snapshot is taken at _<time>_; intra-day movements not reflected.

#### ATS — Available to Sell
- **Definition:** _<define: on-hand minus committed/reserved/held/damaged?>_
- **Canonical reference:** `location_availability.<measure>`
- **Caveats:** Real-time, not a daily snapshot.

#### Sell-through
- **Definition:** _<units sold / (units sold + units on hand)>_
- **Canonical reference:** _<measure or computed in Looks>_

### Traffic / conversion

#### Foot traffic
- **Canonical reference:** `traffic_counter.<measure>`

#### Conversion rate
- **Definition:** Transactions per visitor.
- **Canonical reference:** _<computed by joining traffic_counter to sales_receipt>_

### Forecast

#### Forecast vs actuals — variance, attainment %
- **Canonical reference:** `forecast_vs_actuals.<measure>`
- **Caveats:** _<grain match — sales by retail week? store? sku?>_

---

## View reference

One section per view, in alphabetical order within each domain. Fill in any rows where the LookML doesn't already have a `description:`.

### Master views

#### `dim_calendar`
- **File:** [views/master/dim_calendar.view.lkml](../views/master/dim_calendar.view.lkml)
- **Source:** `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view`
- **Grain:** One row per calendar date.
- **Refresh:** `master_refresh` (12h)
- **Use for:** Retail (4-5-4) calendar joins. Always join sales/inventory to this for retail week/month/quarter alignment instead of using calendar dates.
- **Key fields:** `date_key` (PK, `YYYYMMDD` INT64), `retail_week_id`, `retail_month_no`, `ly_date_key`, `ny_date_key`.

#### `dim_employee`
- **File:** [views/master/dim_employee.view.lkml](../views/master/dim_employee.view.lkml)
- **Source:** _<table>_
- **Grain:** _<one row per employee>_
- **Refresh:** _<cadence>_
- **PII:** _<flag if applicable>_
- **Use for:** _<purpose>_

#### `dim_location_franchise`
- **File:** [views/master/dim_location_franchise.view.lkml](../views/master/dim_location_franchise.view.lkml)
- **Source:** _<table>_
- **Grain:** One row per location.
- **Use for:** RLS gating. `location_code_rls` and `franchise_code_rls` are referenced from every explore's `sql_always_where`.

#### `customer_master`
- **File:** [views/master/customer_master.view.lkml](../views/master/customer_master.view.lkml)
- **PII:** 🔒 Contains customer name, contact info — restricted access.
- _<fill in>_

#### `item_master`
- **File:** [views/master/item_master.view.lkml](../views/master/item_master.view.lkml)
- **Grain:** One row per item.
- **Key hierarchies:** DCSS (Department / Class / Subclass1 / Subclass2). Use `surrogate_item_id` (INT64) for joins, not the string `item_id`.

#### `location_master`
- _<fill in>_

### Transaction views

#### `sales_receipt`
- **File:** [views/transactions/sales_receipt.view.lkml](../views/transactions/sales_receipt.view.lkml)
- **Source:** `external_datamart_1.SalesReceipt_view`
- **Grain:** One row per receipt **line** (not per receipt).
- **Refresh:** `daily_refresh` (24h, BQ partition `Date_Part`).
- **Always-filter:** `date_part: "last 90 days"` — explicitly widen if reporting on longer windows.
- **Notable:** Returns stored as negative amounts on `Qty` and `NetSalesAmt`. Most measures already net them out.
- **Companion view:** `sales_receipt_payments` (unnested `Payments` array, joined on `universal_no` + `date_part`).
- **Custom fields available:** sale_receipt_custom_fields, sale_line_custom_fields, item_*, location_*, customer_*, employee_* (via `extends`).

#### `purchase`, `purchase_order`, `transfer`, `transfer_order`, `sales_order`, `reserve_order`, `ship_memo`, `drawer_memo`, `adjustment`, `ledger`
- _<one section each — same shape: source, grain, refresh, owner, gotchas>_

### Operational views

#### `inventory`
- **File:** [views/operational/inventory.view.lkml](../views/operational/inventory.view.lkml)
- **Source:** `external_datamart_1.Inventory_view`
- **Grain:** One row per item × location × day (composite PK `inventory_pk`).
- **Refresh:** `inventory_refresh` (4h).
- **Joins:** Use `surrogate_item_id` / `surrogate_location_id` for performance.

#### `location_availability`, `traffic_counter`, `forecasting`, `forecast_vs_actuals`, `product_flash`, `customer_metrics`, `customer_attributes`, `item_lifecycle_dates`, `action_tracking`
- _<one section each>_

### Struct views (extension bases)
These are not explored directly. They define reusable field sets that are mixed into transaction views via `extends:`.

| Struct | Provides | Extended by |
|---|---|---|
| `item_struct` | Item identifiers + attributes from `sale.item` STRUCT | `sales_receipt`, `purchase`, … |
| `location_struct` | Location fields | _<…>_ |
| `customer_struct` | Customer fields | _<…>_ |
| `employee_struct` | Employee fields | _<…>_ |
| `vendor_struct` | Vendor fields | _<…>_ |
| `retail_calendar` | Inline retail calendar fields | `sales_receipt`, _<…>_ |

### Custom field views
Extension bases for client-defined `udf_*` columns. **All require business definition before use** — these are the highest-ambiguity fields in the model.

| View | Extends into | UDFs defined | Status |
|---|---|---|---|
| `sale_custom_fields` | `sales_receipt` | _<list>_ | _<status>_ |
| `item_custom_fields` | `sales_receipt`, `inventory`, … | _<list>_ | _<status>_ |
| `customer_custom_fields` | `sales_receipt`, `customer_master` | _<list>_ | _<status>_ |
| _<…>_ | | | |

---

> **Row-level security** (`location_code` / `franchise_codes` / `dev_mode_bypass`) — see [GLOSSARY.md §Tenancy](GLOSSARY.md#tenancy) for the user attributes and [STYLEGUIDE.md §7](STYLEGUIDE.md#7-tenancy--row-level-security) for the rules every new explore must follow.
>
> **Refresh cadences / datagroups** — see [STYLEGUIDE.md §8](STYLEGUIDE.md#8-datagroups).

---

## Deprecation log

| Field / explore | Replaced by | Removed on | Notes |
|---|---|---|---|
| _<example: `sales_receipt.old_metric`>_ | _<`sales_receipt.new_metric`>_ | _<YYYY-MM-DD>_ | _<reason>_ |

---

## Change log

| Date | Author | Change |
|---|---|---|
| _<YYYY-MM-DD>_ | _<name>_ | Initial dictionary draft |

---

## Maintenance

- This file is maintained by _<team>_.
- Source of truth for **definitions** is this document; source of truth for **field names and SQL** is the LookML.
- When you change a metric definition in LookML, update the corresponding entry here in the same PR.
- Auto-generated stub: `lkml`-parsed field listing can be regenerated with _<script path TBD>_ — use it as a checklist, not a substitute for hand-curated definitions.
