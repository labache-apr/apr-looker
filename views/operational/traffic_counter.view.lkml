include: "/views/structs/location_struct.view.lkml"

# ══════════════════════════════════════════════════════════════
# TRAFFIC COUNTER - Foot traffic metrics
# 3 columns + traffic_counter STRUCT + location STRUCT
# ══════════════════════════════════════════════════════════════

view: traffic_counter {
  extends: [location_struct]
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.TrafficCounter_view` ;;

  dimension: date_part {
    description: "Calendar date of the traffic count. BigQuery partition column."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── traffic_counter STRUCT ──

  dimension: traffic_counter_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.traffic_counter.TrafficCounterId ;;
  }

  dimension: visitors {
    hidden: yes
    type: number
    sql: ${TABLE}.traffic_counter.Visitors ;;
  }

  dimension: walkby {
    hidden: yes
    type: number
    sql: ${TABLE}.traffic_counter.Walkby ;;
  }

  # ── Measures ──

  measure: total_visitors {
    description: "Total number of people who entered the store. Use as the denominator for conversion rate."
    type: sum
    sql: ${TABLE}.traffic_counter.Visitors ;;
    value_format_name: decimal_0
  }

  measure: total_walkby {
    description: "Total number of people who walked past the store entrance without entering."
    type: sum
    sql: ${TABLE}.traffic_counter.Walkby ;;
    value_format_name: decimal_0
  }

  measure: capture_rate {
    description: "Visitors / Walkby - what % of passersby enter the store"
    type: number
    sql: SAFE_DIVIDE(${total_visitors}, ${total_walkby}) ;;
    value_format_name: percent_1
  }

  # Note: conversion_rate requires joining to sales_receipt for transaction_count
  # measure: conversion_rate {
  #   description: "Transactions / Visitors"
  #   type: number
  #   sql: SAFE_DIVIDE(${sales_receipt.transaction_count}, ${total_visitors}) ;;
  #   value_format_name: percent_1
  # }
}
