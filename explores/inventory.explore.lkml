include: "/views/operational/inventory.view.lkml"
include: "/views/operational/location_availability.view.lkml"
include: "/views/operational/traffic_counter.view.lkml"
include: "/views/operational/item_lifecycle_dates.view.lkml"
include: "/views/master/item_master.view.lkml"
include: "/views/master/style_master.view.lkml"
include: "/views/master/location_master.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"

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
