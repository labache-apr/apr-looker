include: "/views/operational/action_tracking.view.lkml"
include: "/views/transactions/drawer_memo.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"
include: "/views/master/dim_employee.view.lkml"
include: "/views/master/customer_master.view.lkml"
include: "/views/master/item_master.view.lkml"
include: "/views/master/style_master.view.lkml"
include: "/views/master/location_master.view.lkml"
include: "/views/operational/customer_metrics.view.lkml"
include: "/views/operational/dim_customer_location.view.lkml"
include: "/views/operational/customer_attributes.view.lkml"
include: "/views/operational/customer_location_lookups.view.lkml"
include: "/views/operational/forecast_vs_actuals.view.lkml"
include: "/views/operational/forecasting.view.lkml"
include: "/views/operational/inventory.view.lkml"
include: "/views/operational/location_availability.view.lkml"
include: "/views/operational/traffic_counter.view.lkml"
include: "/views/operational/item_lifecycle_dates.view.lkml"
include: "/views/custom_fields/customer_custom_fields.view.lkml"
include: "/views/transactions/transfer.view.lkml"
include: "/views/transactions/transfer_order.view.lkml"
include: "/views/transactions/adjustment.view.lkml"
include: "/views/transactions/ledger.view.lkml"
include: "/views/transactions/ship_memo.view.lkml"
include: "/views/transactions/reserve_order.view.lkml"
include: "/views/transactions/sales_order.view.lkml"
include: "/views/operational/product_flash.view.lkml"
include: "/views/transactions/purchase.view.lkml"
include: "/views/transactions/purchase_order.view.lkml"
include: "/views/transactions/sales_receipt.view.lkml"

# ══════════════════════════════════════════════════════════════
# ACTION TRACKING - System / user audit trail
# Each row = one tracked action at the POS or back office.
# ══════════════════════════════════════════════════════════════

explore: action_tracking {
  label: "Action Tracking"
  description: "Audit log of POS and back-office actions (logins, voids, drawer events, document changes)."
  group_label: "Operations"

  always_filter: {
    filters: [action_tracking.action_at_date: "last 30 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  join: dim_location_franchise {
    view_label: "Location"
    type: left_outer
    relationship: many_to_one
    sql_on: ${action_tracking.location_id} = ${dim_location_franchise.location_id} ;;
  }

  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${action_tracking.action_date_key} = ${dim_calendar.date_key} ;;
  }

  join: dim_employee {
    view_label: "Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${action_tracking.employee_id} = ${dim_employee.employee_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# CASH DRAWERS - Drawer memo sessions (operations view)
# Operational view of drawer activity: opens, closes, paid in/out,
# tender totals, status history. For variance / over-short
# analysis, see the cash_reconciliation explore.
# ══════════════════════════════════════════════════════════════

explore: cash_drawer {
  from: drawer_memo
  view_name: drawer_memo
  label: "Cash Drawers"
  description: "Drawer memo sessions — open, close, paid in/out, tender totals, lifecycle. One row per drawer session."
  group_label: "Operations"

  always_filter: {
    filters: [drawer_memo.fiscal_date: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  join: dim_location_franchise {
    view_label: "Location"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.location_id} = ${dim_location_franchise.location_id} ;;
  }

  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.fiscal_date_key} = ${dim_calendar.date_key} ;;
  }

  join: dim_employee {
    view_label: "Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.employee_id} = ${dim_employee.employee_id} ;;
  }

  # ── Per-tender drawer media (one row per drawer × payment method) ──
  join: drawer_memo_media {
    view_label: "Drawer Media"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_media.drawer_memo_id} ;;
  }

  # ── Paid in / paid out / cash drop events ──
  join: drawer_memo_paid_in_out {
    view_label: "Paid In/Out"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_paid_in_out.drawer_memo_id} ;;
  }

  # ── Drawer-attributed receipt payments ──
  join: drawer_memo_payment {
    view_label: "Drawer Payments"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_payment.drawer_memo_id} ;;
  }

  # ── Status transitions (Open → Closed → Audited → Deposited) ──
  join: drawer_memo_status_history {
    view_label: "Status History"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_status_history.drawer_memo_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# CASH RECONCILIATION - Drawer audit / over-short variance
# Drives off drawer_memo_media (one row per drawer × tender) so
# that the system Amount, counted AuditedAmount, and Over/(Short)
# variance are first-class fields. Filters default to drawers
# that have actually been audited (AuditedAmount IS NOT NULL).
# ══════════════════════════════════════════════════════════════

explore: cash_reconciliation {
  from: drawer_memo_media
  view_name: drawer_memo_media
  label: "Cash Reconciliation"
  description: "Per-drawer, per-tender reconciliation. Compares system-expected drawer balances to counted amounts and surfaces over/short variance."
  group_label: "Operations"

  always_filter: {
    filters: [
      drawer_memo_media.audited_date: "last 90 days",
      drawer_memo_media.audited_amount: "NOT NULL"
    ]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Drawer header (gives status, lifecycle, location) ──
  join: drawer_memo {
    view_label: "Drawer Memo"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo_media.drawer_memo_id} = ${drawer_memo.drawer_memo_id} ;;
  }

  join: dim_location_franchise {
    view_label: "Location"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.location_id} = ${dim_location_franchise.location_id} ;;
  }

  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.fiscal_date_key} = ${dim_calendar.date_key} ;;
  }

  # ── Audit employee (who counted the drawer) ──
  join: dim_employee {
    view_label: "Audit Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.audit_employee_id} = ${dim_employee.employee_id} ;;
  }

  # ── Paid in/out lines posted against the drawer ──
  join: drawer_memo_paid_in_out {
    view_label: "Paid In/Out"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo_media.drawer_memo_media_id} = ${drawer_memo_paid_in_out.drawer_memo_media_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# CUSTOMERS - Customer master data with contacts and addresses
# ══════════════════════════════════════════════════════════════

explore: customer_master {
  label: "Customers"
  description: "Customer master data with contacts and addresses."
  group_label: "Master Data"

  persist_with: master_refresh

  join: customer_contacts {
    view_label: "Customer Contacts"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_master.customer_id} = ${customer_contacts.customer_id} ;;
  }

  join: customer_addresses {
    view_label: "Customer Addresses"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_master.customer_id} = ${customer_addresses.customer_id} ;;
  }

  join: dim_customer_location {
    view_label: "Customer Locations"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_master.customer_id} = ${dim_customer_location.customer_id} ;;
  }

  join: customer_attributes {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: one_to_one
    sql_on: ${customer_master.customer_id} = ${customer_attributes.customer_id} ;;
  }

  join: last_receipt_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.last_receipt_location_id} = ${last_receipt_location.location_id} ;;
  }

  join: preferred_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.preferred_location_name_raw} = ${preferred_location.location_name} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# CUSTOMER PERFORMANCE - Customer metrics & performance analysis
# ══════════════════════════════════════════════════════════════

explore: customer_performance {
  from: customer_master
  view_label: "Customer Profile"
  label: "Customer Performance"
  description: "Customer master data enriched with lifetime performance metrics: spend, frequency, recency, margin, and return rates."
  group_label: "Customers"

  persist_with: daily_refresh

  # ── Customer Metrics (aggregated from sales receipts) ──
  join: customer_metrics {
    view_label: "Customer Metrics"
    type: left_outer
    relationship: one_to_one
    sql_on: ${customer_performance.customer_id} = ${customer_metrics.customer_id} ;;
  }

  # ── Contacts & Addresses ──
  join: customer_contacts {
    view_label: "Customer Contacts"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_performance.customer_id} = ${customer_contacts.customer_id} ;;
  }

  join: customer_addresses {
    view_label: "Customer Addresses"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_performance.customer_id} = ${customer_addresses.customer_id} ;;
  }

  # ── All Customer-Location Associations ──
  join: dim_customer_location {
    view_label: "Customer Locations"
    type: left_outer
    relationship: one_to_many
    sql_on: ${customer_performance.customer_id} = ${dim_customer_location.customer_id} ;;
  }

  join: customer_attributes {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: one_to_one
    sql_on: ${customer_performance.customer_id} = ${customer_attributes.customer_id} ;;
  }

  join: last_receipt_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.last_receipt_location_id} = ${last_receipt_location.location_id} ;;
  }

  join: preferred_location {
    view_label: "Customer Attributes"
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_attributes.preferred_location_name_raw} = ${preferred_location.location_name} ;;
  }
}

# ══════════════════════════════════════════════════════════════

# FORECAST VS ACTUALS - Daily forecast/budget vs actual sales
# Grain: location × date
# Forecast aggregated at deepest PathLevelDepth (assumed = location).
# Actuals from external_datamart_1.SalesReceipt_view (last 3 fiscal years).
# ══════════════════════════════════════════════════════════════

explore: forecast_vs_actuals {
  label: "Forecast vs Actuals"
  description: "Daily comparison of actual sales/GM/UPT/ATV against forecast and budget at location grain. Use 'Variance' measure groups for gap and attainment metrics."
  group_label: "Forecasting"

  persist_with: daily_refresh

  always_filter: {
    filters: [forecast_vs_actuals.business_date: "this fiscal year"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecast_vs_actuals.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Retail Calendar (bi_star - full calendar dimension) ──
  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecast_vs_actuals.date_key} = ${dim_calendar.date_key} ;;
  }
}

# ══════════════════════════════════════════════════════════════

# FORECASTING & BUDGET - Sales/GM/UPT/ATV forecast vs budget
# Grain: location × date × hierarchy depth
# Always filter to a single Path Level Depth to avoid double-counting.
# ══════════════════════════════════════════════════════════════

explore: forecasting {
  label: "Forecasting & Budget"
  description: "Forecast and budget figures (Sales, GM, UPT, ATV) by location and date. Filter to a single Path Level Depth — values are stored at multiple hierarchy levels and will double-count otherwise."
  group_label: "Forecasting"

  persist_with: daily_refresh

  always_filter: {
    filters: [
      forecasting.forecast_date: "this fiscal year",
      forecasting.path_level_depth: ""
    ]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecasting.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Retail Calendar (bi_star - full calendar dimension) ──
  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecasting.date_key} = ${dim_calendar.date_key} ;;
  }
}

# ══════════════════════════════════════════════════════════════

# INVENTORY SNAPSHOT - Daily inventory by item + location
# Uses FK joins to master tables (not STRUCTs)
# location_master already sourced from bi_star.dim_Location_view
# ══════════════════════════════════════════════════════════════

explore: inventory {
  label: "Inventory Snapshot"
  description: "Daily inventory snapshot with current quantity, cost, retail, and sold metrics. Joins to Item and Location master tables."
  group_label: "Inventory"

  persist_with: inventory_refresh

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  join: item_master {
    view_label: "Item"
    type: left_outer
    relationship: many_to_one
    sql_on: ${inventory.surrogate_item_id} = ${item_master.surrogate_item_id} ;;
  }

  # ── Style Master (style-level rollup — many SKUs per style) ──
  join: style_master {
    view_label: "Style"
    type: left_outer
    relationship: many_to_one
    sql_on: ${item_master.style} = ${style_master.style} ;;
    required_joins: [item_master]
  }

  join: location_master {
    view_label: "Location"
    type: left_outer
    relationship: many_to_one
    sql_on: ${inventory.surrogate_location_id} = ${location_master.surrogate_location_id} ;;
  }

  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${location_master.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${inventory.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# STOCK AVAILABILITY - Real-time ATS by item + location
# Base view extends item_struct + location_struct directly
# ══════════════════════════════════════════════════════════════

explore: location_availability {
  label: "Stock Availability"
  description: "Real-time stock availability with ATS (Available to Sell), OnHand, Committed, Reserved, Held, Damaged, and Incoming quantities."
  group_label: "Inventory"

  persist_with: inventory_refresh

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${location_availability.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${location_availability.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# FOOT TRAFFIC
# ══════════════════════════════════════════════════════════════

explore: traffic_counter {
  label: "Foot Traffic"
  description: "Store traffic counters with visitor and walkby counts. Join to sales data for conversion rate analysis."
  group_label: "Inventory"

  persist_with: daily_refresh

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${traffic_counter.location_id} = ${dim_location_franchise.location_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════

# TRANSFERS
# ══════════════════════════════════════════════════════════════

explore: transfer {
  label: "Transfers"
  description: "Inventory transfers between locations with source/target location context."
  group_label: "Merchandise Movement"

  persist_with: daily_refresh

  always_filter: {
    filters: [transfer.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - RLS via source location) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${transfer_source_location.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Source / Target Locations (concrete views with custom STRUCT paths) ──
  join: transfer_source_location {
    view_label: "Source Location"
    relationship: one_to_one
    sql:  ;;
}

join: transfer_target_location {
  view_label: "Target Location"
  relationship: one_to_one
  sql:  ;;
}

# ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
join: item_lifecycle_dates {
  view_label: "Item Lifecycle Dates"
  type: left_outer
  relationship: many_to_one
  sql_on: ${transfer.item_id} = ${item_lifecycle_dates.item_id} ;;
}
}

# ══════════════════════════════════════════════════════════════
# TRANSFER ORDERS
# ══════════════════════════════════════════════════════════════

explore: transfer_order {
  label: "Transfer Orders"
  description: "Transfer order management with source/target locations and fulfillment tracking."
  group_label: "Merchandise Movement"

  persist_with: daily_refresh

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - RLS via source location) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${transfer_order_source_location.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Source / Target Locations (concrete views with custom STRUCT paths) ──
  join: transfer_order_source_location {
    view_label: "Source Location"
    relationship: one_to_one
    sql:  ;;
}

join: transfer_order_target_location {
  view_label: "Target Location"
  relationship: one_to_one
  sql:  ;;
}

# ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
join: item_lifecycle_dates {
  view_label: "Item Lifecycle Dates"
  type: left_outer
  relationship: many_to_one
  sql_on: ${transfer_order.item_id} = ${item_lifecycle_dates.item_id} ;;
}
}

# ══════════════════════════════════════════════════════════════
# ADJUSTMENTS
# ══════════════════════════════════════════════════════════════

explore: adjustment {
  label: "Inventory Adjustments"
  description: "Inventory adjustments by reason code with item, location, and employee details."
  group_label: "Merchandise Movement"

  persist_with: daily_refresh

  always_filter: {
    filters: [adjustment.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${adjustment.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${adjustment.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# GENERAL LEDGER
# ══════════════════════════════════════════════════════════════

explore: ledger {
  label: "General Ledger"
  description: "Unified general ledger entries across all document types."
  group_label: "Merchandise Movement"

  persist_with: daily_refresh

  always_filter: {
    filters: [ledger.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${ledger.location_id} = ${dim_location_franchise.location_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# SHIPPING
# ══════════════════════════════════════════════════════════════

explore: ship_memo {
  label: "Shipping"
  description: "Shipping and fulfillment with carton tracking, carrier data, and order linkage."
  group_label: "Merchandise Movement"

  persist_with: daily_refresh

  always_filter: {
    filters: [ship_memo.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${ship_memo.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${ship_memo.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# RESERVE ORDERS
# ══════════════════════════════════════════════════════════════

explore: reserve_order {
  label: "Reserve Orders"
  description: "Inventory reservations by reserve reason with order and reserved quantity tracking."
  group_label: "Merchandise Movement"

  persist_with: daily_refresh

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${reserve_order.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${reserve_order.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# MASTER DATA EXPLORES
# ══════════════════════════════════════════════════════════════

explore: item_master {
  label: "Items"
  description: "Item (SKU) master data with optional style-level rollup. One row per SKU."
  group_label: "Master Data"

  persist_with: master_refresh

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: one_to_one
    sql_on: ${item_master.item_id} = ${item_lifecycle_dates.item_id} ;;
  }

  # ── Style Master (style-level attributes — many SKUs per style) ──
  join: style_master {
    view_label: "Style"
    type: left_outer
    relationship: many_to_one
    sql_on: ${item_master.style} = ${style_master.style} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# STYLES (product-grain master, analogous to Shopify product)
# ══════════════════════════════════════════════════════════════

explore: style_master {
  label: "Styles"
  description: "Style master — product-grain attributes (one row per style). Drill into Variants (SKUs) for the items that make up each style."
  group_label: "Master Data"

  persist_with: master_refresh

  # ── Variants (SKUs) — one style maps to many items ──
  join: item_master {
    view_label: "Variants (SKUs)"
    type: left_outer
    relationship: one_to_many
    sql_on: ${style_master.style} = ${item_master.style} ;;
  }

  # ── Item Lifecycle Dates (joined through item_master) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: one_to_one
    sql_on: ${item_master.item_id} = ${item_lifecycle_dates.item_id} ;;
    required_joins: [item_master]
  }
}

# ══════════════════════════════════════════════════════════════

# SALES ORDERS - Order management & fulfillment
# ══════════════════════════════════════════════════════════════

explore: sales_order {
  label: "Sales Orders"
  description: "Sales orders at the line level with fulfillment tracking, three location contexts, and omnichannel flags."
  group_label: "Orders"

  persist_with: daily_refresh

  always_filter: {
    filters: [sales_order.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_order.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Sale Credit Location STRUCT (custom path - kept as separate view) ──
  join: sales_order_salecredit_location {
    view_label: "Location (Sale Credit)"
    relationship: one_to_one
    sql:  ;;
}

# ── Sell From Location STRUCT (custom path - kept as separate view) ──
join: sales_order_sellfrom_location {
  view_label: "Location (Sell From)"
  relationship: one_to_one
  sql:  ;;
}
}

# ══════════════════════════════════════════════════════════════

# PRODUCT FLASH - Single-product deep dive
# Inventory + sales by location for one style at a time
# ══════════════════════════════════════════════════════════════

explore: product_flash {
  label: "Product Flash Report"
  description: "Single-product view combining real-time inventory with time-bucketed sales data across all locations. Filter by PLU to use."
  group_label: "Inventory"

  persist_with: inventory_refresh

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${product_flash.location_id} = ${dim_location_franchise.location_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════

# PURCHASING - Purchase receipts
# ══════════════════════════════════════════════════════════════

explore: purchase {
  label: "Purchasing"
  description: "Purchase receipt data with vendor, item, and location details."
  group_label: "Purchasing"

  persist_with: daily_refresh

  always_filter: {
    filters: [purchase.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${purchase.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${purchase.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════
# PURCHASE ORDERS
# ══════════════════════════════════════════════════════════════

explore: purchase_order {
  label: "Purchase Orders"
  description: "Purchase order management with fill rate tracking, vendor analysis, and memo lines."
  group_label: "Purchasing"

  persist_with: daily_refresh

  always_filter: {
    filters: [purchase_order.date_part: "last 180 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${purchase_order.location_id} = ${dim_location_franchise.location_id} ;;
  }

  join: purchase_order_memo_lines {
    view_label: "PO Memo Lines"
    type: left_outer
    relationship: one_to_many
    sql_on: ${purchase_order.purchase_order_id} = ${purchase_order_memo_lines.purchase_order_id} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${purchase_order.item_id} = ${item_lifecycle_dates.item_id} ;;
  }
}

# ══════════════════════════════════════════════════════════════

# SALES RECEIPTS - Primary POS sales analysis
# ══════════════════════════════════════════════════════════════

explore: sales_receipt {
  label: "Sales Receipts"
  description: "POS transaction data at the receipt line level. Each row represents one item sold on a receipt."
  group_label: "Sales"

  # Hide the calendar/retail-calendar fields that the sales_receipt view
  # inherits from the retail_calendar struct, since dim_calendar (joined
  # below) is the canonical source in this explore. Set is defined in
  # retail_calendar.view.lkml. date_key remains exposed — it's the join key.
  fields: [ALL_FIELDS*, -sales_receipt.dim_calendar_duplicates*]

  persist_with: daily_refresh

  always_filter: {
    filters: [sales_receipt.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Retail Calendar (bi_star - full calendar dimension) ──
  # The sales_receipt view also extends the retail_calendar struct, which
  # denormalizes the same fields onto each row. The struct duplicates are
  # excluded by the explore-level `fields:` parameter above (see set
  # `dim_calendar_duplicates` in retail_calendar.view.lkml) so the field
  # picker shows only one copy of each calendar field. dim_calendar is the
  # canonical source here — it adds retail_week_id, retail_month_week, and
  # the is_current_retail_* filters that the struct does not have.
  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.date_key} = ${dim_calendar.date_key} ;;
  }

  # ── Employee Master (bi_star - full employee dimension) ──
  join: dim_employee {
    view_label: "Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.employee_id} = ${dim_employee.employee_id} ;;
  }

  # ── Payments ARRAY (unnested - actual join needed) ──
  join: sales_receipt_payments {
    view_label: "Payments"
    type: left_outer
    relationship: one_to_many
    sql_on: ${sales_receipt.universal_no} = ${sales_receipt_payments.universal_no}
      AND ${sales_receipt.date_part} = ${sales_receipt_payments.date_part} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.item_id} = ${item_lifecycle_dates.item_id} ;;
  }

  # ── Inventory Snapshot (point-in-time at sale: matches the receipt's
  # date_part to the daily inventory snapshot for that item × location).
  # Use these fields when you need on-hand / turn / GMROI / sell-through
  # *as of the day each item sold*. The join condition prunes the
  # inventory partition by date for performance. `fields:` excludes the
  # inventory view's pre-aggregated sold_* measures because those overlap
  # with sales_receipt's own sales totals — use sales_receipt for sales.
  join: inventory {
    view_label: "Inventory Snapshot (At Sale)"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.date_part} = ${inventory.date_part}
      AND ${sales_receipt.item_id} = ${inventory.item_id}
      AND ${sales_receipt.location_id} = ${inventory.location_id} ;;
    fields: [
      inventory.total_on_hand_qty,
      inventory.total_on_hand_cost,
      inventory.total_on_hand_retail,
      inventory.avg_unit_cost,
      inventory.avg_inventory_qty,
      inventory.avg_inventory_cost,
      inventory.avg_inventory_retail,
      inventory.inventory_turn_ratio,
      inventory.gmroi,
      inventory.weeks_of_supply,
      inventory.days_of_supply,
      inventory.sell_through_rate,
      inventory.out_of_stock_row_count,
      inventory.out_of_stock_rate,
      inventory.sku_location_count,
      inventory.sku_count,
      inventory.location_count
    ]
  }

  # ── Stock Availability (real-time ATS / OnHand at item × location) ──
  # Symmetric aggregates dedupe via location_availability.availability_pk,
  # so inventory measures are correct even when many receipt lines match.
  # `fields:` is restricted to measures — location_availability extends
  # item_struct + location_struct, and the inherited dimensions would
  # otherwise duplicate the ones already on sales_receipt.
  join: location_availability {
    view_label: "Stock Availability"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.item_id} = ${location_availability.item_id}
      AND ${sales_receipt.location_id} = ${location_availability.location_id} ;;
    fields: [
      location_availability.total_on_hand,
      location_availability.total_ats,
      location_availability.total_committed,
      location_availability.total_reserved,
      location_availability.total_held,
      location_availability.total_damaged,
      location_availability.total_incoming,
      location_availability.sku_location_count,
      location_availability.stockout_count,
      location_availability.stockout_rate
    ]
  }
}
