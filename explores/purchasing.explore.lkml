include: "/views/transactions/purchase.view.lkml"
include: "/views/transactions/purchase_order.view.lkml"
include: "/views/operational/item_lifecycle_dates.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"

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
