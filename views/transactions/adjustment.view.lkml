include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/employee_struct.view.lkml"
include: "/views/structs/retail_calendar.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/adjustment_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# ADJUSTMENT - Inventory Adjustment View
# Each row = one inventory adjustment line
# ══════════════════════════════════════════════════════════════

view: adjustment {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct, employee_struct, retail_calendar, adjustment_custom_fields]
  sql_table_name: `@{schema_name}.external_datamart_1.Adjustment_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use adjusted_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── adjustment STRUCT: Operational Dates ──

  dimension_group: adjusted_date {
    group_label: "Adjusted Date"
    label: "Adjusted"
    description: "Timestamp the inventory adjustment was recorded"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.adjustment.MemoDateTime ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

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

  dimension: adjustment_id {
    primary_key: yes
    group_label: "Adjustment"
    description: "Unique identifier for an inventory adjustment line. Primary key of this view."
    type: string
    sql: ${TABLE}.adjustment.AdjustmentId ;;
  }

  dimension: adjustment_no {
    group_label: "Adjustment"
    label: "Adjustment Number"
    description: "Document-level adjustment number shared across all lines on the same adjustment."
    type: string
    sql: ${TABLE}.adjustment.AdjustmentNo ;;
  }

  dimension: adjustment_reason_code {
    group_label: "Adjustment"
    description: "Short code for why the adjustment was made (e.g. damage, shrink, count correction). See Adjustment Reason for the friendly label."
    type: string
    sql: ${TABLE}.adjustment.AdjustmentReasonCode ;;
  }

  dimension: adjustment_reason {
    group_label: "Adjustment"
    description: "Friendly description of the adjustment reason."
    type: string
    sql: ${TABLE}.adjustment.AdjustmentReason ;;
  }

  dimension: adjustment_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.adjustment.Qty ;;
  }

  dimension: adjustment_cost_amt {
    hidden: yes
    type: number
    sql: ${TABLE}.adjustment.CostAmt ;;
  }

  # ── Measures ──

  measure: total_adjustment_qty {
    description: "Net total of adjustment quantities. Signed — positive = inventory increased, negative = inventory decreased."
    type: sum
    sql: ${TABLE}.adjustment.Qty ;;
    value_format_name: decimal_0
  }

  measure: total_adjustment_cost {
    description: "Net cost impact of adjustments. USD."
    type: sum
    sql: ${TABLE}.adjustment.CostAmt ;;
    value_format_name: usd
  }

  measure: adjustment_count {
    description: "Distinct adjustment lines (count of AdjustmentId)."
    type: count_distinct
    sql: ${TABLE}.adjustment.AdjustmentId ;;
  }

  measure: positive_adjustments {
    description: "Sum of positive adjustment quantities (inventory increases only)."
    type: sum
    sql: ${TABLE}.adjustment.Qty ;;
    filters: [adjustment_qty: ">0"]
    value_format_name: decimal_0
  }

  measure: negative_adjustments {
    description: "Sum of negative adjustment quantities, expressed as a positive number (inventory decreases only — typically shrink or damage)."
    type: sum
    sql: ABS(${TABLE}.adjustment.Qty) ;;
    filters: [adjustment_qty: "<0"]
    value_format_name: decimal_0
  }
}