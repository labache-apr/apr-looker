# ══════════════════════════════════════════════════════════════
# CUSTOMER LOCATION LOOKUPS - Reusable location aliases for
# joining dim_Location_view to customer_attributes location codes
# ══════════════════════════════════════════════════════════════

view: last_receipt_location {
  sql_table_name: `@{schema_name}.bi_star.dim_Location_view` ;;

  dimension: location_id {
    group_label: "Last Receipt Location"
    label: "Location ID"
    hidden: yes
    type: string
    sql: ${TABLE}.LocationId ;;
  }

  dimension: location_code {
    group_label: "Last Receipt Location"
    label: "Location Code"
    hidden: yes  # use customer_attributes.last_receipt_location_code instead
    type: string
    sql: ${TABLE}.LocationCode ;;
  }

  dimension: location_name {
    group_label: "Last Receipt Location"
    label: "Location Name"
    description: "Friendly name of the location where the customer most recently transacted."
    type: string
    sql: ${TABLE}.LocationName ;;
  }
}

view: preferred_location {
  sql_table_name: `@{schema_name}.bi_star.dim_Location_view` ;;

  dimension: location_id {
    group_label: "Preferred Location"
    label: "Location ID"
    hidden: yes
    type: string
    sql: ${TABLE}.LocationId ;;
  }

  dimension: location_code {
    group_label: "Preferred Location"
    label: "Location Code"
    hidden: yes  # use customer_attributes.preferred_location_code instead
    type: string
    sql: ${TABLE}.LocationCode ;;
  }

  dimension: location_name {
    group_label: "Preferred Location"
    label: "Location Name"
    description: "Friendly name of the customer's preferred / home location."
    type: string
    sql: ${TABLE}.LocationName ;;
  }
}