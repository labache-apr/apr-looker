include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# LOCATION AVAILABILITY - Real-time stock availability (ATS)
# 13 columns + 2 nested STRUCTs (item, location)
# Base view extends structs directly so ${TABLE} resolves to
# the explore's base table alias in generated SQL.
# ══════════════════════════════════════════════════════════════

view: location_availability {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct]
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.LocationAvailability_view` ;;

  dimension: availability_pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: CONCAT(${TABLE}.item.ItemId, '|', ${TABLE}.location.LocationId) ;;
  }

  # ── Availability Quantities ──

  dimension: on_hand {
    hidden: yes
    type: number
    sql: ${TABLE}.OnHand ;;
  }

  dimension: ats {
    label: "ATS"
    hidden: yes
    type: number
    sql: ${TABLE}.ATS ;;
  }

  dimension: committed {
    hidden: yes
    type: number
    sql: ${TABLE}.Committed ;;
  }

  dimension: reserved {
    hidden: yes
    type: number
    sql: ${TABLE}.Reserved ;;
  }

  dimension: held {
    hidden: yes
    type: number
    sql: ${TABLE}.Held ;;
  }

  dimension: damaged {
    hidden: yes
    type: number
    sql: ${TABLE}.Damaged ;;
  }

  dimension: incoming {
    hidden: yes
    type: number
    sql: ${TABLE}.Incoming ;;
  }

  # ── Measures ──

  measure: total_on_hand {
    description: "Total physical units in stock at the location, before subtracting commitments. Includes ATS plus committed, reserved, held, and damaged units."
    type: sum
    sql: ${TABLE}.OnHand ;;
    value_format_name: decimal_0
  }

  measure: total_ats {
    label: "Total ATS"
    description: "Available to Sell: units actually free to sell right now. Computed upstream as OnHand − Committed − Reserved − Held − Damaged."
    type: sum
    sql: ${TABLE}.ATS ;;
    value_format_name: decimal_0
  }

  measure: total_committed {
    description: "Units committed to open sales orders (allocated but not yet shipped)."
    type: sum
    sql: ${TABLE}.Committed ;;
    value_format_name: decimal_0
  }

  measure: total_reserved {
    description: "Units actively reserved (e.g. for online order pickup, customer holds)."
    type: sum
    sql: ${TABLE}.Reserved ;;
    value_format_name: decimal_0
  }

  measure: total_held {
    description: "Units placed on hold and not currently sellable (e.g. price-pending, awaiting QC)."
    type: sum
    sql: ${TABLE}.Held ;;
    value_format_name: decimal_0
  }

  measure: total_damaged {
    description: "Units flagged as damaged and removed from sellable inventory."
    type: sum
    sql: ${TABLE}.Damaged ;;
    value_format_name: decimal_0
  }

  measure: total_incoming {
    description: "Units in transit toward the location (e.g. open transfers in, PO receipts pending). Not yet on hand."
    type: sum
    sql: ${TABLE}.Incoming ;;
    value_format_name: decimal_0
  }

  measure: sku_location_count {
    label: "SKU-Location Count"
    description: "Count of (item × location) rows in the snapshot. Each row is one SKU stocked at one location."
    type: count
  }

  measure: stockout_count {
    description: "Number of SKU-location combinations with zero ATS (out of stock)."
    type: count
    filters: [ats: "0"]
  }

  measure: stockout_rate {
    description: "Share of SKU-locations that are out of stock (Stockout Count / SKU-Location Count)."
    type: number
    sql: SAFE_DIVIDE(${stockout_count}, ${sku_location_count}) ;;
    value_format_name: percent_1
  }
}
