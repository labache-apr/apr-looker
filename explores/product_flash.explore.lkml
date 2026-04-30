include: "/views/operational/product_flash.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"

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
