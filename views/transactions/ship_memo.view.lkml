include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/customer_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# SHIP MEMO - Shipping & Fulfillment View
# Contains 4 shipping STRUCTs: ship_sales_order, ship_item,
# ship_carton, ship_carton_item
# ══════════════════════════════════════════════════════════════

view: ship_memo {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct, customer_struct]
  sql_table_name: `@{schema_name}.external_datamart_1.ShipMemo_view` ;;

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
    description: "Timestamp the ship memo was created"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.CreatedDate ;;
  }

  dimension_group: edited_date {
    group_label: "Edited Date"
    label: "Edited"
    description: "Timestamp the ship memo was last edited"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order.EditDate ;;
  }

  dimension_group: rejected_date {
    group_label: "Rejected Date"
    label: "Rejected"
    description: "Timestamp the ship memo was rejected (NULL if not rejected)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order.RejectedDate ;;
  }

  # ── Carton STRUCT: Operational Dates ──

  dimension_group: shipped_date {
    group_label: "Shipped Date"
    label: "Shipped"
    description: "Timestamp the carton was shipped (the actual ship event)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order_carton.ShippedDate ;;
  }

  # ── Item STRUCT: Operational Dates ──

  dimension_group: pickup_ready_date {
    group_label: "Pickup Ready Date"
    label: "Pickup Ready"
    description: "Timestamp the item was marked ready for pickup"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order_item.PickUpReadyDate ;;
  }

  dimension_group: picked_up_date {
    group_label: "Picked Up Date"
    label: "Picked Up"
    description: "Timestamp the item was picked up by the customer"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order_item.PickedUpDate ;;
  }

  dimension_group: item_rejected_date {
    group_label: "Item Rejected Date"
    label: "Item Rejected"
    description: "Timestamp the line item was rejected (NULL if not rejected)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order_item.RejectDate ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp the record was created in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order.RecCreated ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp the record was last modified in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.ship_sales_order.RecModified ;;
  }

  dimension_group: streaming {
    group_label: "Audit"
    label: "Streaming"
    description: "Timestamp the record was ingested into BigQuery"
    type: time
    timeframes: [raw, date, time]
    datatype: timestamp
    hidden: yes
    sql: ${TABLE}.ship_sales_order.StreamingDate ;;
  }

  # ── ship_sales_order STRUCT ──

  dimension: ship_memo_id {
    primary_key: yes
    group_label: "Ship Order"
    description: "Unique identifier for a ship memo line. Primary key of this view."
    type: string
    sql: ${TABLE}.ship_sales_order.ShipMemoId ;;
  }

  dimension: ship_memo_no {
    group_label: "Ship Order"
    label: "Ship Memo Number"
    description: "Document-level ship memo number shared across all lines on the same shipment."
    type: string
    sql: ${TABLE}.ship_sales_order.ShipMemoNo ;;
  }

  dimension: sales_order_id {
    group_label: "Ship Order"
    description: "Identifier of the sales order this ship memo fulfills. Join to Sales Order to compare ordered vs. shipped."
    type: string
    sql: ${TABLE}.ship_sales_order.SalesOrderId ;;
  }

  dimension: ship_status {
    group_label: "Ship Order"
    description: "Lifecycle status of the shipment (e.g. pending, in transit, delivered, picked up, rejected)."
    type: string
    sql: ${TABLE}.ship_sales_order.Status ;;
  }

  # ── ship_item STRUCT ──

  dimension: ship_item_qty {
    group_label: "Ship Item"
    label: "Shipped Qty"
    hidden: yes
    type: number
    sql: ${TABLE}.ship_item.Qty ;;
  }

  # ── ship_carton STRUCT ──

  dimension: tracking_no {
    group_label: "Shipping Carton"
    label: "Tracking Number"
    description: "Carrier tracking number for the carton. Primary handle for shipment lookup with the carrier."
    type: string
    sql: ${TABLE}.ship_carton.TrackingNo ;;
  }

  dimension: carrier {
    group_label: "Shipping Carton"
    description: "Shipping carrier (e.g. UPS, FedEx, USPS)."
    type: string
    sql: ${TABLE}.ship_carton.Carrier ;;
  }

  dimension: ship_method {
    group_label: "Shipping Carton"
    description: "Carrier service level (e.g. Ground, 2-Day, Overnight)."
    type: string
    sql: ${TABLE}.ship_carton.ShipMethod ;;
  }

  dimension: weight {
    group_label: "Shipping Carton"
    description: "Carton weight (units depend on the carrier — typically pounds)."
    type: number
    sql: ${TABLE}.ship_carton.Weight ;;
  }

  # ── Measures ──

  measure: total_shipped_qty {
    description: "Total units shipped across ship memo lines."
    type: sum
    sql: ${TABLE}.ship_item.Qty ;;
    value_format_name: decimal_0
  }

  measure: shipment_count {
    description: "Distinct ship memos (count of ShipMemoId)."
    type: count_distinct
    sql: ${TABLE}.ship_sales_order.ShipMemoId ;;
  }

  measure: carton_count {
    description: "Distinct cartons (count of distinct TrackingNo)."
    type: count_distinct
    sql: ${TABLE}.ship_carton.TrackingNo ;;
  }
}