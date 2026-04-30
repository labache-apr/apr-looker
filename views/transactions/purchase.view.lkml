include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/retail_calendar.view.lkml"
include: "/views/structs/vendor_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/purchase_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# PURCHASE - Purchase Receipt View
# Each row = one received purchase line
# ══════════════════════════════════════════════════════════════

view: purchase {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct, vendor_struct, retail_calendar, purchase_custom_fields]
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.Purchase_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use transacted_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── purchase STRUCT: Operational Dates ──

  dimension_group: transacted_date {
    group_label: "Transacted Date"
    label: "Transacted"
    description: "Timestamp the purchase receipt was posted to the ledger (goods received)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.purchase.PostedDateTime ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp the record was created in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.purchase.RecCreated ;;
  }

  dimension_group: dependencies_rec_modified {
    group_label: "Audit"
    label: "Dependencies Modified"
    description: "Latest modification timestamp across joined STRUCT dependencies"
    type: time
    timeframes: [raw, date, time]
    datatype: timestamp
    hidden: yes
    sql: ${TABLE}.DependenciesRecModified ;;
  }

  # ── purchase STRUCT ──

  dimension: purchase_id {
    primary_key: yes
    group_label: "Purchase"
    description: "Unique identifier for a purchase receipt line. Primary key of this view."
    type: string
    sql: ${TABLE}.purchase.PurchaseId ;;
  }

  dimension: purchase_no {
    group_label: "Purchase"
    label: "Purchase Number"
    description: "Document-level purchase receipt number shared across all lines on the same receipt."
    type: string
    sql: ${TABLE}.purchase.PurchaseNo ;;
  }

  dimension: po_no {
    group_label: "Purchase"
    label: "PO Number"
    description: "Purchase order number this receipt was received against. Join to Purchase Order to compare ordered vs received."
    type: string
    sql: ${TABLE}.purchase.PoNo ;;
  }

  dimension: purchase_qty {
    group_label: "Purchase"
    hidden: yes
    type: number
    sql: ${TABLE}.purchase.Qty ;;
  }

  dimension: cost_amt {
    group_label: "Purchase"
    hidden: yes
    type: number
    sql: ${TABLE}.purchase.CostAmt ;;
  }

  # ── Measures ──

  measure: total_received_qty {
    description: "Total units received from vendors across purchase receipt lines."
    type: sum
    sql: ${TABLE}.purchase.Qty ;;
    value_format_name: decimal_0
  }

  measure: total_cost_amount {
    description: "Total cost of goods received from vendors. USD."
    type: sum
    sql: ${TABLE}.purchase.CostAmt ;;
    value_format_name: usd
  }

  measure: receipt_count {
    description: "Distinct purchase receipt lines (count of PurchaseId). One row per item received on a receipt."
    type: count_distinct
    sql: ${TABLE}.purchase.PurchaseId ;;
  }

  measure: avg_unit_cost {
    description: "Weighted average unit cost of received goods (Total Cost / Total Received Qty). USD."
    type: number
    sql: SAFE_DIVIDE(${total_cost_amount}, ${total_received_qty}) ;;
    value_format_name: usd
  }
}
