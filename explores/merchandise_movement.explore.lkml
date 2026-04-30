include: "/views/transactions/transfer.view.lkml"
include: "/views/transactions/transfer_order.view.lkml"
include: "/views/transactions/adjustment.view.lkml"
include: "/views/transactions/ledger.view.lkml"
include: "/views/transactions/ship_memo.view.lkml"
include: "/views/transactions/reserve_order.view.lkml"
include: "/views/operational/item_lifecycle_dates.view.lkml"
include: "/views/master/item_master.view.lkml"
include: "/views/master/style_master.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"

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
