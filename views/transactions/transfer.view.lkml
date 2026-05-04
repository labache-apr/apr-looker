include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/employee_struct.view.lkml"
include: "/views/structs/retail_calendar.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/transfer_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# TRANSFER - Inventory Transfer View
# Each row = one transfer line item
# ══════════════════════════════════════════════════════════════

view: transfer {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, employee_struct, retail_calendar, transfer_custom_fields]
  sql_table_name: `@{schema_name}.external_datamart_1.Transfer_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use posted_out_date / posted_in_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── transfer STRUCT: Operational Dates ──

  dimension_group: posted_out_date {
    group_label: "Posted Out Date"
    label: "Posted Out"
    description: "Timestamp the transfer was posted out from the source location (shipped)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.transfer.PostOutDate ;;
  }

  dimension_group: posted_in_date {
    group_label: "Posted In Date"
    label: "Posted In"
    description: "Timestamp the transfer was posted in at the target location (received)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.transfer.PostInDate ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp the record was created in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.transfer.RecCreated ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp the record was last modified in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.transfer.RecModified ;;
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

  # ── transfer STRUCT ──

  dimension: transfer_id {
    primary_key: yes
    group_label: "Transfer"
    description: "Unique identifier for a transfer line. Primary key of this view."
    type: string
    sql: ${TABLE}.transfer.TransferId ;;
  }

  dimension: transfer_no {
    group_label: "Transfer"
    label: "Transfer Number"
    description: "Document-level transfer number shared across all lines of the same transfer document."
    type: string
    sql: ${TABLE}.transfer.TransferNo ;;
  }

  dimension: transfer_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.transfer.TransferredQty ;;
  }

  dimension: qty_in {
    hidden: yes
    type: number
    sql: ${TABLE}.transfer.QtyIn ;;
  }

  dimension: qty_out {
    hidden: yes
    type: number
    sql: ${TABLE}.transfer.QtyOut ;;
  }

  # ── Measures ──

  measure: total_transferred_qty {
    description: "Total units transferred between locations. Counts the line-level transfer quantity, regardless of whether it was confirmed at the destination."
    type: sum
    sql: ${TABLE}.transfer.TransferredQty ;;
    value_format_name: decimal_0
  }

  measure: total_qty_in {
    description: "Total units posted into the destination location (received side of the transfer)."
    type: sum
    sql: ${TABLE}.transfer.QtyIn ;;
    value_format_name: decimal_0
  }

  measure: total_qty_out {
    description: "Total units posted out of the source location (shipped side of the transfer)."
    type: sum
    sql: ${TABLE}.transfer.QtyOut ;;
    value_format_name: decimal_0
  }

  measure: transfer_count {
    description: "Distinct transfer lines (count of TransferId)."
    type: count_distinct
    sql: ${TABLE}.transfer.TransferId ;;
  }
}

# ── Source / Target Location (concrete views, not extends) ──
# These use custom STRUCT paths (SourceLocation/TargetLocation)
# and cannot extend location_struct.

view: transfer_source_location {
  sql_table_name: `@{schema_name}.external_datamart_1.Transfer_view` ;;

  dimension: location_id    { group_label: "Source Location"  description: "Internal identifier of the location shipping the transfer (the 'from' location)." type: string sql: ${TABLE}.SourceLocation.LocationId ;; }
  dimension: location_code  { group_label: "Source Location"  description: "Short code (e.g. store number) of the source location." type: string sql: ${TABLE}.SourceLocation.LocationCode ;; }
  dimension: location_name  { group_label: "Source Location"  description: "Friendly name of the source location." type: string sql: ${TABLE}.SourceLocation.LocationName ;; }
  dimension: label          { group_label: "Source Location"  description: "Display label for the source location (typically code + name)." type: string sql: ${TABLE}.SourceLocation.Label ;; }
  dimension: city           { group_label: "Source Location"  description: "City of the source location." type: string sql: ${TABLE}.SourceLocation.City ;; }
  dimension: state          { group_label: "Source Location"  description: "State or province of the source location." type: string sql: ${TABLE}.SourceLocation.State ;; }
  dimension: country        { group_label: "Source Location"  description: "Country of the source location." type: string sql: ${TABLE}.SourceLocation.Country ;; }
  dimension: postal_code    { group_label: "Source Location"  description: "Postal/ZIP code of the source location." type: string sql: ${TABLE}.SourceLocation.PostalCode ;; }
}

view: transfer_target_location {
  sql_table_name: `@{schema_name}.external_datamart_1.Transfer_view` ;;

  dimension: location_id    { group_label: "Target Location"  description: "Internal identifier of the location receiving the transfer (the 'to' location)." type: string sql: ${TABLE}.TargetLocation.LocationId ;; }
  dimension: location_code  { group_label: "Target Location"  description: "Short code (e.g. store number) of the target location." type: string sql: ${TABLE}.TargetLocation.LocationCode ;; }
  dimension: location_name  { group_label: "Target Location"  description: "Friendly name of the target location." type: string sql: ${TABLE}.TargetLocation.LocationName ;; }
  dimension: label          { group_label: "Target Location"  description: "Display label for the target location (typically code + name)." type: string sql: ${TABLE}.TargetLocation.Label ;; }
  dimension: city           { group_label: "Target Location"  description: "City of the target location." type: string sql: ${TABLE}.TargetLocation.City ;; }
  dimension: state          { group_label: "Target Location"  description: "State or province of the target location." type: string sql: ${TABLE}.TargetLocation.State ;; }
  dimension: country        { group_label: "Target Location"  description: "Country of the target location." type: string sql: ${TABLE}.TargetLocation.Country ;; }
  dimension: postal_code    { group_label: "Target Location"  description: "Postal/ZIP code of the target location." type: string sql: ${TABLE}.TargetLocation.PostalCode ;; }
}