# Data Glossary — `aefc-looker`

Plain-English definitions for the terms used in this Looker project.
Read this before building or reviewing dashboards.

When a term here conflicts with how a stakeholder uses it, **flag the
conflict in your PR** rather than silently picking a side. Vocabulary
drift is the #1 cause of dashboard disagreements.

This glossary defines *concepts*. The
[data dictionary](data_dictionary.md) defines *fields and metrics*.
The [styleguide](STYLEGUIDE.md) defines *how the LookML is written*.

---

## Grains (one row represents…)

Knowing the grain of a view is the difference between a correct dashboard
and a fan-out disaster. Always check the view header.

### Transaction views

| View | Grain |
|---|---|
| `sales_receipt` | One line on a receipt (one item sold, returned, or credited) |
| `sales_receipt_payments` | One payment method on a receipt (unnested from `Payments` array) |
| `sales_order` | One line on a sales order |
| `reserve_order` | One line on a reserve / hold order |
| `ship_memo` | One line on a shipment memo |
| `purchase` | One line on a received purchase |
| `purchase_order` | One line on a purchase order |
| `transfer` | One line on a completed transfer |
| `transfer_order` | One line on a transfer order |
| `adjustment` | One inventory adjustment line |
| `drawer_memo` | One drawer session at a workstation (open → close) |
| `drawer_memo_tenders` | One (drawer memo × payment method) pair |
| `drawer_memo_actions` | One paid-in / paid-out / cash-drop action |
| `drawer_memo_status_history` | One status transition on a drawer memo |
| `ledger` | One general-ledger posting line |

### Master / dimension views

| View | Grain |
|---|---|
| `dim_calendar` | One calendar date (with retail-calendar attributes) |
| `dim_employee` | One employee |
| `dim_location_franchise` | One location (with franchise group attributes) |
| `customer_master` | One customer |
| `item_master` | One item (one SKU) |
| `location_master` | One location |

### Operational / derived views

| View | Grain |
|---|---|
| `inventory` | One (item × location × day) snapshot |
| `location_availability` | One (item × location) — current available-to-sell |
| `traffic_counter` | One (location × interval) foot-traffic record |
| `forecasting` | One (location × date × forecast path level) |
| `forecast_vs_actuals` | One (date × location) |
| `customer_metrics` | One customer (with lifetime spend / frequency / recency) |
| `customer_attributes` | One customer (raw attributes from `bi_star`) |
| `dim_customer_location` | One (customer × location × association type) |
| `item_lifecycle_dates` | One item (with first/last dates across sale, receipt, PO, transfer) |
| `product_flash` | One unit sold or returned (returns count as -1) |
| `action_tracking` | One tracked operator action (login, void, refund, drawer event) |

**Rule of thumb:** if you're aggregating money across joined tables, the
sum is correct only when one side is at the grain of the measure. If in
doubt, count distinct receipt numbers (`universal_no`) and sanity-check.

---

## Tenancy

Two user attributes drive row-level security on every certified Explore.

- **`location_code`** — comma-separated list of location codes the user
  can see. Lower-cased on read. Sourced from
  `dim_location_franchise.location_code` (which mirrors
  `bi_star.dim_Location.LocationCode`).
- **`franchise_codes`** — comma-separated list of franchise group codes.
  Lower-cased on read. Sourced from
  `dim_location_franchise.FranchiseGroupCode`. Plural because users can
  belong to multiple franchise groups.
- **`dev_mode_bypass`** — escape hatch. Setting this to `'yes'` disables
  both filters. **Never set this for production users.**

A user attribute value of `'any'` or empty string bypasses that specific
filter (admin-only).

`dim_location_franchise` is the canonical tenancy join. The `_rls`-suffixed
columns (`location_code_rls`, `franchise_code_rls`) are the lower-cased
versions used in `sql_always_where`. The non-suffixed versions are for
analyst-facing filters.

---

## POS and retail concepts

### Transaction lifecycle

The TWC POS produces several document types, each landing in its own view.
They are independent — do not assume one implies another.

- **Sales receipt** — the customer-facing transaction at the POS.
  Identified by `universal_no` (numeric, globally unique per receipt) and
  `receipt_no` (printed on the customer copy; not globally unique on its
  own — combine with store/date). One receipt has one or more lines, each
  a row in `sales_receipt`.
- **Sales order** — a forward-looking commitment to sell (special order,
  layaway). Becomes a `sales_receipt` when fulfilled.
- **Reserve order** — a hold placed on inventory without commitment to
  sell.
- **Ship memo** — the shipping document associated with fulfillment.
- **Purchase order (PO)** — outgoing order to a vendor.
- **Purchase** — receipt of goods against a PO (or stand-alone receipt).
- **Transfer order / Transfer** — request and execution for moving stock
  between locations.
- **Adjustment** — manual change to on-hand stock (count corrections,
  damage write-offs, etc.).
- **Drawer memo** — a register session: open, transact, close. Holds
  declared cash, computed cash, and the actions taken during the session.
- **Ledger** — the GL posting record. Links revenue, COGS, tax, and
  payment activity to GL accounts.

### Receipt-line nuances

The `sales_receipt` view is at the **line** grain. Things to know:

- **Returns and credit memos are stored on the same view as sales**, with
  negative `Qty` and negative `NetSalesAmt`. Most certified measures
  already net them out — don't add `is_return = no` on top, that
  double-counts.
- **`document_line_id`** is the line-level primary key. **`universal_no`**
  is the receipt-level identifier — use it for `count_distinct` to get
  transaction count.
- **Original-receipt fields** (`original_receipt_date`, etc.) are
  populated only on return lines, pointing back to the sale being
  returned.
- **Custom fields** are mixed in via `extends:` from `*_custom_fields`
  views (sale, line, item, location, customer, employee). These vary
  per-client configuration — see [Custom fields](#custom-fields).

### Status fields

Several columns describe transaction state. They are independent.

- **`transaction_type`** — `Sale`, `Return`, `CreditMemo`, etc.
  (enumerate full set in data dictionary entry per view).
- **`is_return`** — derived boolean flag, true when the line is a return
  or credit memo.
- **`posted_date` vs `transacted_date`** — **`transacted_date`** is when
  the receipt was rung up at the POS; **`posted_date`** is when it landed
  in the GL. They differ when receipts post next-day.
- **Drawer memo status** — `Open`, `Closed`, etc.; transitions are
  captured in `drawer_memo_status_history`.

### Items, styles, and the DCSS hierarchy

- **Item** — a single SKU. The unique sellable unit. One row per item in
  `item_master`.
- **Style** — a parent grouping of related items (color/size variants of
  the same garment). Surface via `style_id` / `style_count` on
  `item_master` for "unique products" reporting.
- **DCSS hierarchy** — Department → Class → Subclass1 → Subclass2. The
  primary merchandising hierarchy. Use these for category reporting.
- **`surrogate_item_id` (INT64)** — fast-join surrogate. Use this in
  joins for performance; the string `item_id` is for display and lookup.
- **`surrogate_location_id` (INT64)** — same idea for locations.

### Locations, franchises, and master data

- **Location** — a single store, warehouse, or other operating unit.
  Identified by `location_id` (system) or `location_code` (short code).
- **Franchise group** — corporate parent that owns one or more locations.
  Drives a layer of RLS via `franchise_codes`.
- **`dim_location_franchise`** — `bi_star`-sourced view that supplies
  fields not present in the embedded `location` STRUCT (notably
  `FranchiseGroupCode` / `FranchiseGroupName`).

### Custom fields

- **Custom field (UDF)** — a client-configured field added to a Shopify
  object equivalent (sale, item, location, customer, employee). Surfaced
  via the `*_custom_fields` extension views.
- **Per-client meaning** — UDFs are configured per client and the
  business meaning **is not in the data**. Tag exposed UDFs with
  `client-config` (see [styleguide §4](STYLEGUIDE.md#4-tags-vocabulary))
  and document the meaning in the data dictionary before using them in
  certified reports.
- **Extension pattern** — custom-field views are `extends:` targets, not
  standalone explores. The host view (e.g., `sales_receipt`) inherits
  their dimensions.

### Structs vs flat columns

The TWC export delivers most domain data as nested STRUCT / ARRAY columns
(e.g., `sale.NetSalesAmt`, `Payments[]`).

- **STRUCT views** (`structs/`) — define dimensions over a STRUCT once,
  then `extends:` into the transaction view that uses it
  (`item_struct`, `location_struct`, `customer_struct`,
  `employee_struct`, `vendor_struct`, `retail_calendar`).
- **ARRAY columns** — typically unnested into a sibling view (e.g.,
  `sales_receipt_payments`) and joined on the parent's keys
  (`universal_no` + `date_part`).
- **Don't** flatten STRUCT fields ad-hoc inside a transaction view —
  add the field to the struct view so every consumer benefits.

---

## Money

- All `_amt` fields are **USD** unless suffixed otherwise. AEFC operates
  in USD; non-USD locations don't currently exist in this dataset.
- **Net** = gross less discounts and returns, **excluding** tax and
  shipping unless the field name says otherwise.
- **Gross** = before discounts and before return netting. Excludes tax.
- Returns and credit memos are stored as **negative** amounts on
  `sales_receipt`. Most certified measures already net them out.
- **Discount amount** is positive when subtracted from gross.

### COGS and margin

- **COGS (Cost of Goods Sold)** is valued using **FIFO** (First-In,
  First-Out): the cost recorded for a sale is the cost of the oldest
  on-hand units at the time of sale.
- **Margin amount** = `total_net_sales − total_cogs`.
- **Margin %** = `total_margin / total_net_sales`. Computed with
  `SAFE_DIVIDE` — returns `NULL` (not `0`) when net sales is zero, so
  filter accordingly.
- Reference FIFO in any cost or margin field description so analysts
  understand the basis.

---

## Calendar

The retail business runs on a **4-5-4 retail calendar**, not the standard
Gregorian month. Use `dim_calendar` for any period reporting that should
align with retail weeks/months/quarters.

- **`date_key`** — `YYYYMMDD` INT64. Primary key of `dim_calendar`. The
  natural join key from sales/inventory.
- **Retail week / month / quarter** — 4-5-4 periods on `dim_calendar`.
- **`ly_date_key`** / **`ny_date_key`** — last-year / next-year matching
  date keys. Use these for YoY comparisons rather than calendar offsets,
  so retail-week alignment holds.
- **`fiscal_month_offset`** in the model is `0` — fiscal year matches
  calendar year today. Adjust if AEFC's fiscal year shifts.
- **`transacted_date`** is in **store local time**; the underlying
  timestamp lives in the source. UTC vs local conversion is not currently
  performed in LookML — assume local-time semantics on POS dates.

---

## Loader and infrastructure

- **TWC** — the POS / retail platform that exports to BigQuery. The
  authoritative system of record for sales and inventory.
- **`@{schema_name}`** — the GCP project hosting the BigQuery
  datasets.
- **`external_datamart_1`** — the dataset TWC writes to. Most transaction
  and operational views read from `<TableName>_view` here. The `_view`
  suffix is a TWC convention (these are BigQuery views over the raw
  export, not authored views).
- **`bi_star`** — supplemental dataset with master/dim tables not in the
  primary export (`dim_Calendar_view`, `dim_Location_view`,
  `CHQCustomerAttributes`, etc.).
- **`Date_Part`** — partition column on every TWC view. Hidden in the
  LookML; exposed as `date_part` only for `always_filter` partition
  pruning. Don't use it for business dates — use `transacted_date`,
  `posted_date`, or `dim_calendar.date_key`.
- **PDT (Persistent Derived Table)** — a Looker-managed table built from
  a `derived_table` block, persisted in BigQuery, refreshed by a
  datagroup. See [styleguide §8](STYLEGUIDE.md#8-datagroups) for
  refresh cadences.

---

## Conventions you'll see in the LookML

- **`extends:`** — heavy use across transaction views. The host view
  (e.g., `sales_receipt`) extends a stack of struct + custom-field views
  rather than redefining their dimensions. New struct fields propagate
  automatically.
- **Lower-casing on read** — RLS columns and any string compared against
  a user attribute wrap `LOWER(...)` in `sql:`. User attributes are
  lower-cased before comparison. Don't strip the `LOWER`.
- **Surrogate IDs for joins** — when both a string and an INT64 surrogate
  are present, join on the surrogate. The string is for display.
- **`value_format_name: id`** — applied to numeric IDs to suppress
  thousands separators (`1234567` not `1,234,567`).
- **`SAFE_DIVIDE`** — used in every ratio measure. Returns `NULL` on
  divide-by-zero. Wrap denominators that can legitimately be zero.
- **Hidden partition column** — `date_part` is exposed as a hidden
  dimension solely so explore-level `always_filter` can prune partitions
  without polluting the field picker.

---

## Audit and quality views

_AEFC does not currently have dedicated `*_audit` views. When data
quality issues are surfaced through reporting, add them here and link to
the audit view in the same PR._

---

## Acronyms

| Acronym | Expansion |
|---|---|
| AEFC | American Eagle Franchise Corporation _(confirm full expansion with team)_ |
| TWC | The Wholesale Connection (POS / retail platform) |
| POS | Point of Sale |
| SKU | Stock Keeping Unit |
| DCSS | Department / Class / Subclass1 / Subclass2 |
| UDF | User-Defined Field (custom field) |
| RLS | Row-Level Security |
| GL | General Ledger |
| PO | Purchase Order |
| PDT | Persistent Derived Table (Looker) |
| COGS | Cost of Goods Sold |
| FIFO | First-In, First-Out (cost flow assumption) |
| ATV | Average Transaction Value |
| ASP | Average Selling Price (net, post-discount: net sales ÷ units) |
| AUR | Average Unit Retail (gross, pre-discount: ticketed retail ÷ units) |
| UPT | Units per Transaction |
| ATS | Available to Sell |
| STR | Sell-Through Rate |
| GMROI | Gross Margin Return on Inventory Investment |
| WTD / MTD / QTD / YTD | Week / Month / Quarter / Year to Date |
| LY / NY | Last Year / Next Year (retail-calendar matched) |
| YoY / MoM / WoW | Year / Month / Week-over-prior-period |
| 4-5-4 | Retail-calendar pattern (weeks per month: 4, 5, 4) |