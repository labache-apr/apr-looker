include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# RESERVE ORDER - Inventory Reservation View
# ══════════════════════════════════════════════════════════════

view: reserve_order {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct]
  sql_table_name: `@{schema_name}.external_datamart_1.ReserveOrder_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use created_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── Operational Dates ──

  dimension_group: created_date {
    group_label: "Created Date"
    label: "Created"
    description: "Timestamp the reserve order was created"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.CreatedDate ;;
  }

  dimension_group: released_date {
    group_label: "Released Date"
    label: "Released"
    description: "Timestamp the reserve order was released (NULL if still active)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.reserve_order.ReleasedDate ;;
  }

  dimension_group: modified_date {
    group_label: "Modified Date"
    label: "Modified"
    description: "Timestamp the reserve order was last modified"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.reserve_order.LastModifiedDate ;;
  }

  dimension_group: archived_date {
    group_label: "Archived Date"
    label: "Archived"
    description: "Timestamp the reserve order was archived (NULL if still active)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.reserve_order.ArchiveSwitchedDate ;;
  }

  # ── reserve_order STRUCT ──

  dimension: reserve_order_id {
    primary_key: yes
    group_label: "Reserve Order"
    description: "Unique identifier for a reserve order line. Primary key of this view."
    type: string
    sql: ${TABLE}.reserve_order.ReserveOrderId ;;
  }

  dimension: reserve_order_no {
    group_label: "Reserve Order"
    label: "Reserve Order Number"
    description: "Document-level reserve order number shared across all lines on the same reserve order."
    type: string
    sql: ${TABLE}.reserve_order.ReserveOrderNo ;;
  }

  # ── reserve_order_item STRUCT ──

  dimension: order_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.reserve_order_item.OrderQty ;;
  }

  dimension: reserved_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.reserve_order_item.ReservedQty ;;
  }

  dimension: released_qty {
    hidden: yes
    type: number
    sql: ${TABLE}.reserve_order_item.ReleasedQty ;;
  }

  # ── reserve_reason (nested in reserve_order_item) ──

  dimension: reserve_reason {
    group_label: "Reserve Reason"
    description: "Reason inventory was reserved (e.g. customer hold, online order pending pickup, allocation)."
    type: string
    sql: ${TABLE}.reserve_order_item.reserve_reason.ReserveReason ;;
  }

  # ── Measures ──

  measure: total_order_qty {
    description: "Total units originally requested across reserve order lines."
    type: sum
    sql: ${TABLE}.reserve_order_item.OrderQty ;;
    value_format_name: decimal_0
  }

  measure: total_reserved_qty {
    description: "Total units actually reserved against inventory (may be less than ordered if stock was insufficient)."
    type: sum
    sql: ${TABLE}.reserve_order_item.ReservedQty ;;
    value_format_name: decimal_0
  }

  measure: total_released_qty {
    description: "Total units released back to available inventory (reservation no longer holding)."
    type: sum
    sql: ${TABLE}.reserve_order_item.ReleasedQty ;;
    value_format_name: decimal_0
  }

  measure: reserve_order_count {
    description: "Distinct reserve orders (count of ReserveOrderId)."
    type: count_distinct
    sql: ${TABLE}.reserve_order.ReserveOrderId ;;
  }
}