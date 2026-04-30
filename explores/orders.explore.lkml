include: "/views/transactions/sales_order.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"

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
