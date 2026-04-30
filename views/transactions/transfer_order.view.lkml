include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/employee_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/transfer_order_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# TRANSFER ORDER
# Each row = one transfer order line item
# ══════════════════════════════════════════════════════════════

view: transfer_order {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, employee_struct, transfer_order_custom_fields]
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.TransferOrder_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use ordered_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── transfer_order STRUCT: Operational Dates ──

  dimension_group: ordered_date {
    group_label: "Ordered Date"
    label: "Ordered"
    description: "Date the transfer order was placed"
    type: time
    timeframes: [raw, date, day_of_week, day_of_month, week, week_of_year, month, month_name, month_num, quarter, year]
    datatype: date
    sql: ${TABLE}.transfer_order.Date ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp the record was created in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.transfer_order.RecCreated ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp the record was last modified in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.transfer_order.RecModified ;;
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

  dimension: transfer_order_id {
    primary_key: yes
    group_label: "Transfer Order"
    description: "Unique identifier for a transfer order line. Primary key of this view."
    type: string
    sql: ${TABLE}.transfer_order.TransferOrderId ;;
  }

  dimension: transfer_order_no {
    group_label: "Transfer Order"
    label: "Transfer Order Number"
    description: "Document-level transfer order number shared across all lines on the same transfer order."
    type: string
    sql: ${TABLE}.transfer_order.TransferOrderNo ;;
  }

  dimension: status {
    group_label: "Transfer Order"
    description: "Lifecycle status of the transfer order line (e.g. open, in transit, received, cancelled)."
    type: string
    sql: ${TABLE}.transfer_order.Status ;;
  }

  # ── Measures ──

  measure: total_qty {
    description: "Total units requested across transfer order lines."
    type: sum
    sql: ${TABLE}.transfer_order.Qty ;;
    value_format_name: decimal_0
  }

  measure: total_qty_posted_in {
    description: "Total units actually received at the target location."
    type: sum
    sql: ${TABLE}.transfer_order.QtyPostedIn ;;
    value_format_name: decimal_0
  }

  measure: total_qty_posted_out {
    description: "Total units actually shipped from the source location."
    type: sum
    sql: ${TABLE}.transfer_order.QtyPostedOut ;;
    value_format_name: decimal_0
  }

  measure: total_qty_rejected {
    description: "Total units rejected at the target location (received but not accepted into stock)."
    type: sum
    sql: ${TABLE}.transfer_order.QtyRejected ;;
    value_format_name: decimal_0
  }

  measure: total_qty_available {
    description: "Total units available at the source location to fulfill the transfer order."
    type: sum
    sql: ${TABLE}.transfer_order.QtyAvailable ;;
    value_format_name: decimal_0
  }

  measure: transfer_order_count {
    description: "Distinct transfer orders (count of TransferOrderId)."
    type: count_distinct
    sql: ${TABLE}.transfer_order.TransferOrderId ;;
  }
}

# ── Source / Target Locations ──
# These use custom STRUCT paths (SourceLocation/TargetLocation)
# and cannot extend location_struct.

view: transfer_order_source_location {
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.TransferOrder_view` ;;

  dimension: location_id    { group_label: "Source Location"  description: "Internal identifier of the location shipping the transfer order (the 'from' location)." type: string sql: ${TABLE}.SourceLocation.LocationId ;; }
  dimension: location_code  { group_label: "Source Location"  description: "Short code (e.g. store number) of the source location." type: string sql: ${TABLE}.SourceLocation.LocationCode ;; }
  dimension: location_name  { group_label: "Source Location"  description: "Friendly name of the source location." type: string sql: ${TABLE}.SourceLocation.LocationName ;; }
  dimension: city           { group_label: "Source Location"  description: "City of the source location." type: string sql: ${TABLE}.SourceLocation.City ;; }
  dimension: state          { group_label: "Source Location"  description: "State or province of the source location." type: string sql: ${TABLE}.SourceLocation.State ;; }
  dimension: country        { group_label: "Source Location"  description: "Country of the source location." type: string sql: ${TABLE}.SourceLocation.Country ;; }
}

view: transfer_order_target_location {
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.TransferOrder_view` ;;

  dimension: location_id    { group_label: "Target Location"  description: "Internal identifier of the location receiving the transfer order (the 'to' location)." type: string sql: ${TABLE}.TargetLocation.LocationId ;; }
  dimension: location_code  { group_label: "Target Location"  description: "Short code (e.g. store number) of the target location." type: string sql: ${TABLE}.TargetLocation.LocationCode ;; }
  dimension: location_name  { group_label: "Target Location"  description: "Friendly name of the target location." type: string sql: ${TABLE}.TargetLocation.LocationName ;; }
  dimension: city           { group_label: "Target Location"  description: "City of the target location." type: string sql: ${TABLE}.TargetLocation.City ;; }
  dimension: state          { group_label: "Target Location"  description: "State or province of the target location." type: string sql: ${TABLE}.TargetLocation.State ;; }
  dimension: country        { group_label: "Target Location"  description: "Country of the target location." type: string sql: ${TABLE}.TargetLocation.Country ;; }
}
