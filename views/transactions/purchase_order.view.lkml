include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/retail_calendar.view.lkml"
include: "/views/structs/vendor_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/purchase_order_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# PURCHASE ORDER - PO Management View
# Each row = one PO line item
# ══════════════════════════════════════════════════════════════

view: purchase_order {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct, vendor_struct, retail_calendar, purchase_order_custom_fields]
  sql_table_name: `@{schema_name}.external_datamart_1.PurchaseOrder_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use ordered_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── purchase_order STRUCT: Operational Dates ──

  dimension_group: ordered_date {
    group_label: "Ordered Date"
    label: "Ordered"
    description: "Date the purchase order was placed with the vendor"
    type: time
    timeframes: [raw, date, day_of_week, day_of_month, week, week_of_year, month, month_name, month_num, quarter, year]
    datatype: date
    sql: ${TABLE}.purchase_order.OrderDate ;;
  }

  dimension_group: ship_date {
    group_label: "Ship Date"
    label: "Expected Ship"
    description: "Expected ship date from the vendor"
    type: time
    timeframes: [raw, date, day_of_week, day_of_month, week, week_of_year, month, month_name, month_num, quarter, year]
    datatype: date
    sql: ${TABLE}.purchase_order.ShipDate ;;
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

  # ── purchase_order STRUCT ──

  dimension: purchase_order_id {
    primary_key: yes
    group_label: "PO Identifiers"
    description: "Unique identifier for a PO line. Primary key of this view."
    type: string
    sql: ${TABLE}.purchase_order.PurchaseOrderId ;;
  }

  dimension: po_no {
    group_label: "PO Identifiers"
    label: "PO Number"
    description: "Document-level purchase order number shared across all lines on the same PO. Join to Purchase to compare ordered vs. received."
    type: string
    sql: ${TABLE}.purchase_order.PoNo ;;
  }

  dimension: status {
    group_label: "PO Status"
    description: "Lifecycle status of the PO line (e.g. open, partially received, closed, cancelled)."
    type: string
    sql: ${TABLE}.purchase_order.Status ;;
  }

  dimension: qty_ordered {
    hidden: yes
    type: number
    sql: ${TABLE}.purchase_order.QtyOrdered ;;
  }

  dimension: qty_received {
    hidden: yes
    type: number
    sql: ${TABLE}.purchase_order.QtyReceived ;;
  }

  dimension: order_cost {
    hidden: yes
    type: number
    sql: ${TABLE}.purchase_order.OrderCost ;;
  }

  # ── Measures ──

  measure: total_qty_ordered {
    description: "Total units ordered from vendors across PO lines."
    type: sum
    sql: ${TABLE}.purchase_order.QtyOrdered ;;
    value_format_name: decimal_0
  }

  measure: total_qty_received {
    description: "Total units received against PO lines so far. Equals Total Qty Ordered when fully received."
    type: sum
    sql: ${TABLE}.purchase_order.QtyReceived ;;
    value_format_name: decimal_0
  }

  measure: total_order_cost {
    description: "Total ordered cost across PO lines. USD."
    type: sum
    sql: ${TABLE}.purchase_order.OrderCost ;;
    value_format_name: usd
  }

  measure: po_fill_rate {
    label: "PO Fill Rate"
    description: "Share of ordered units received (Total Qty Received / Total Qty Ordered). 100% means fully received."
    type: number
    sql: SAFE_DIVIDE(${total_qty_received}, ${total_qty_ordered}) ;;
    value_format_name: percent_1
  }

  measure: po_count {
    label: "PO Count"
    description: "Distinct purchase order lines (count of PurchaseOrderId)."
    type: count_distinct
    sql: ${TABLE}.purchase_order.PurchaseOrderId ;;
  }
}

# ── Memo Lines ARRAY (unnested) ──

view: purchase_order_memo_lines {
  derived_table: {
    sql:
      SELECT
        po.purchase_order.PurchaseOrderId AS purchase_order_id,
        po.purchase_order.PoNo            AS po_no,
        po.Date_Part                      AS date_part,
        ml.LineNo                         AS line_no,
        ml.Memo                           AS memo,
        ml.DocumentDateTime               AS document_date,
        ml.MemoDateTime                   AS memo_date
      FROM `@{schema_name}.external_datamart_1.PurchaseOrder_view` po,
           UNNEST(po.purchase_order.memo_lines) AS ml
    ;;
  }

  dimension: purchase_order_id { type: string sql: ${TABLE}.purchase_order_id ;; hidden: yes }
  dimension: line_no           { description: "Line number within the memo (1-based)." type: number sql: ${TABLE}.line_no ;; }
  dimension: memo              { description: "Free-text memo associated with the PO (notes, special instructions)." type: string sql: ${TABLE}.memo ;; }

  dimension_group: document_date {
    group_label: "Document Date"
    label: "Document"
    description: "Timestamp on the source document referenced by this memo line"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: datetime
    sql: ${TABLE}.document_date ;;
  }

  dimension_group: memo_date {
    group_label: "Memo Date"
    label: "Memo"
    description: "Timestamp the memo line was recorded"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: datetime
    sql: ${TABLE}.memo_date ;;
  }
}