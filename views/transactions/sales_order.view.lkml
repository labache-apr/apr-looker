include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/customer_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/customer_custom_fields.view.lkml"
include: "/views/custom_fields/sales_order_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# SALES ORDER - Order Management View
# Each row = one sales order item (line level)
# ══════════════════════════════════════════════════════════════

view: sales_order {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, customer_struct, customer_custom_fields, location_struct, sales_order_header_custom_fields, sales_order_line_custom_fields]
  sql_table_name: `@{schema_name}.external_datamart_1.SalesOrder_view` ;;

  # ── Top-Level ──

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use ordered_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── sales_order STRUCT: Operational Dates ──

  dimension_group: ordered_date {
    group_label: "Ordered Date"
    label: "Ordered"
    description: "Timestamp the sales order was placed by the customer"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.SalesOrderDateTime ;;
  }

  dimension_group: created_date {
    group_label: "Created Date"
    label: "Created"
    description: "Timestamp the sales order record was created in the system"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.CreateDateTime ;;
  }

  dimension_group: edited_date {
    group_label: "Edited Date"
    label: "Edited"
    description: "Timestamp the sales order was last edited"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.EditDateTime ;;
  }

  dimension_group: placed_date {
    group_label: "Placed Date"
    label: "Placed"
    description: "Timestamp the order was placed (typically web order checkout time)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.PlaceOrderDateTime ;;
  }

  dimension_group: promised_date {
    group_label: "Promised Date"
    label: "Promised"
    description: "Promised delivery date provided to the customer (header level)"
    type: time
    timeframes: [raw, date, day_of_week, day_of_month, week, week_of_year, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.PromiseDate ;;
  }

  # ── sales_order_item STRUCT: Operational Dates (line-level) ──

  dimension_group: assigned_date {
    group_label: "Assigned Date"
    label: "Assigned"
    description: "Timestamp the line item was assigned to a fulfillment location"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order_item.AssignedDateTime ;;
  }

  dimension_group: filled_date {
    group_label: "Filled Date"
    label: "Filled"
    description: "Timestamp the line item was fulfilled"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order_item.FilledDateTime ;;
  }

  dimension_group: abandoned_date {
    group_label: "Abandoned Date"
    label: "Abandoned"
    description: "Timestamp the line item was abandoned (NULL if not abandoned). Source field: AbondonedDateTime [sic]."
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order_item.AbondonedDateTime ;;
  }

  dimension_group: line_rejected_date {
    group_label: "Line Rejected Date"
    label: "Line Rejected"
    description: "Timestamp the line item was rejected (NULL if not rejected)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order_item.RejectedDateTime ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp the record was created in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.RecCreated ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp the record was last modified in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.sales_order.RecModified ;;
  }

  dimension_group: streaming {
    group_label: "Audit"
    label: "Streaming"
    description: "Timestamp the record was ingested into BigQuery"
    type: time
    timeframes: [raw, date, time]
    datatype: timestamp
    hidden: yes
    sql: ${TABLE}.sales_order.StreamingDate ;;
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

  # ── sales_order STRUCT: Header Identifiers ──

  dimension: sales_order_id {
    primary_key: yes
    group_label: "Order Identifiers"
    description: "Unique identifier for a sales order line. Primary key of this view."
    type: string
    sql: ${TABLE}.sales_order.SalesOrderId ;;
  }

  dimension: order_no {
    group_label: "Order Identifiers"
    label: "Order Number"
    description: "Customer-facing order number shown on confirmations and packing slips."
    type: string
    sql: ${TABLE}.sales_order.OrderNo ;;
  }

  dimension: external_id {
    group_label: "Order Identifiers"
    description: "Identifier from the external order system (e.g. e-commerce platform order id)."
    type: string
    sql: ${TABLE}.sales_order.ExternalId ;;
  }

  # ── sales_order STRUCT: Status ──

  dimension: status {
    group_label: "Order Status"
    description: "Numeric status code for the order. Use Status Label for the friendly name."
    type: number
    sql: ${TABLE}.sales_order.Status ;;
  }

  dimension: status_label {
    group_label: "Order Status"
    description: "Friendly label for order status (e.g. New, In Progress, Fulfilled, Cancelled)."
    type: string
    sql: ${TABLE}.sales_order.StatusLabel ;;
  }

  # ── sales_order STRUCT: Amounts ──

  dimension: total_amount_with_tax {
    group_label: "Order Amounts"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order.TotalAmountWithTax ;;
  }

  dimension: total_qty {
    group_label: "Order Quantities"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order.TotalQty ;;
  }

  dimension: total_qty_fulfilled {
    group_label: "Order Quantities"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order.TotalQtyFulfilled ;;
  }

  # ── sales_order STRUCT: Fulfillment Flags ──

  dimension: delivery_method {
    group_label: "Fulfillment"
    description: "How the customer chose to receive the order (e.g. ship to address, store pickup, curbside)."
    type: string
    sql: ${TABLE}.sales_order.DeliveryMethod ;;
  }

  dimension: is_store_pickup {
    group_label: "Fulfillment"
    description: "Yes when the order is being picked up at a store rather than shipped (BOPIS/click-and-collect)."
    type: yesno
    sql: ${TABLE}.sales_order.ShipToIsStorePickup ;;
  }

  dimension: is_drop_shipment {
    group_label: "Fulfillment"
    description: "Yes when the order ships directly from the vendor to the customer rather than through a store or DC."
    type: yesno
    sql: ${TABLE}.sales_order.IsDropShipment ;;
  }

  dimension: is_external_oms {
    group_label: "Fulfillment"
    label: "Is External OMS"
    description: "Yes when fulfillment is managed by an external Order Management System rather than the in-house system."
    type: yesno
    sql: ${TABLE}.sales_order.IsExternalOms ;;
  }

  # ── sales_order_item STRUCT: Line-level ──

  dimension: order_item_id {
    group_label: "Order Item"
    description: "Unique identifier for an individual order line item within a sales order."
    type: string
    sql: ${TABLE}.sales_order_item.SalesOrderItemId ;;
  }

  dimension: item_status {
    group_label: "Order Item"
    label: "Item Status"
    description: "Numeric status code for the line item. Use Item Status Label for the friendly name."
    type: number
    sql: ${TABLE}.sales_order_item.Status ;;
  }

  dimension: item_status_label {
    group_label: "Order Item"
    label: "Item Status Label"
    description: "Friendly label for line-item status (e.g. Pending, Picked, Shipped, Cancelled, Rejected)."
    type: string
    sql: ${TABLE}.sales_order_item.StatusLabel ;;
  }

  dimension: item_qty {
    group_label: "Order Item"
    label: "Item Qty"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order_item.Qty ;;
  }

  dimension: item_qty_fulfilled {
    group_label: "Order Item"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order_item.QtyFulfilled ;;
  }

  dimension: item_qty_rejected {
    group_label: "Order Item"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order_item.QtyRejected ;;
  }

  dimension: item_qty_cancelled {
    group_label: "Order Item"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order_item.QtyCancelled ;;
  }

  dimension: item_qty_due {
    group_label: "Order Item"
    hidden: yes
    type: number
    sql: ${TABLE}.sales_order_item.QtyDue ;;
  }

  # ══════════════════════════════════════════════════
  # MEASURES
  # ══════════════════════════════════════════════════

  measure: total_order_amount {
    description: "Sum of order totals including tax. Header-level value — pivot by Sales Order ID to avoid double-counting if also pivoting by line. USD."
    type: sum
    sql: ${TABLE}.sales_order.TotalAmountWithTax ;;
    value_format_name: usd
  }

  measure: total_order_qty {
    description: "Sum of order-header total quantities. Header-level — see Total Line Qty for line-level sums."
    type: sum
    sql: ${TABLE}.sales_order.TotalQty ;;
    value_format_name: decimal_0
  }

  measure: total_qty_fulfilled_measure {
    label: "Total Qty Fulfilled"
    description: "Sum of order-header fulfilled quantities (header-level)."
    type: sum
    sql: ${TABLE}.sales_order.TotalQtyFulfilled ;;
    value_format_name: decimal_0
  }

  measure: fulfillment_rate {
    description: "Order-header fulfillment rate (Total Qty Fulfilled / Total Order Qty). 100% = fully fulfilled."
    type: number
    sql: SAFE_DIVIDE(${total_qty_fulfilled_measure}, ${total_order_qty}) ;;
    value_format_name: percent_1
  }

  measure: order_count {
    description: "Distinct sales orders (count of SalesOrderId)."
    type: count_distinct
    sql: ${TABLE}.sales_order.SalesOrderId ;;
  }

  measure: avg_order_value {
    label: "AOV"
    description: "Average Order Value: total order amount per order (Total Order Amount / Order Count). USD."
    type: number
    sql: SAFE_DIVIDE(${total_order_amount}, ${order_count}) ;;
    value_format_name: usd
  }

  # ── Line-level measures ──

  measure: total_line_qty {
    description: "Total ordered units across line items. Line-level — sums one row per item per order."
    type: sum
    sql: ${TABLE}.sales_order_item.Qty ;;
    value_format_name: decimal_0
  }

  measure: total_line_qty_fulfilled {
    description: "Total units fulfilled across line items."
    type: sum
    sql: ${TABLE}.sales_order_item.QtyFulfilled ;;
    value_format_name: decimal_0
  }

  measure: total_line_qty_rejected {
    description: "Total units rejected at line level (received but not accepted, or returned during fulfillment)."
    type: sum
    sql: ${TABLE}.sales_order_item.QtyRejected ;;
    value_format_name: decimal_0
  }

  measure: total_line_qty_cancelled {
    description: "Total units cancelled at line level (order modified or cancelled before fulfillment)."
    type: sum
    sql: ${TABLE}.sales_order_item.QtyCancelled ;;
    value_format_name: decimal_0
  }

  measure: total_line_qty_due {
    description: "Total units still due to be fulfilled at line level (open backlog)."
    type: sum
    sql: ${TABLE}.sales_order_item.QtyDue ;;
    value_format_name: decimal_0
  }

  measure: line_fulfillment_rate {
    description: "Line-level fulfillment rate (Total Line Qty Fulfilled / Total Line Qty). Use this for accurate fulfillment when grouping by line attributes."
    type: number
    sql: SAFE_DIVIDE(${total_line_qty_fulfilled}, ${total_line_qty}) ;;
    value_format_name: percent_1
  }
}

# ══════════════════════════════════════════════════════════════
# ALTERNATE LOCATION CONTEXTS
# These use different STRUCT paths (salecredit_location, sellfrom_location)
# so they cannot extend location_struct. They need special handling
# and are kept as concrete views with their own sql_table_name.
# ══════════════════════════════════════════════════════════════

view: sales_order_salecredit_location {
  sql_table_name: `@{schema_name}.external_datamart_1.SalesOrder_view` ;;

  dimension: location_id   { group_label: "Sale Credit Location" description: "Internal id of the location credited with the sale (the store that 'gets' the revenue)." type: string sql: ${TABLE}.salecredit_location.LocationId ;; }
  dimension: location_code { group_label: "Sale Credit Location" description: "Short code of the sale-credit location." type: string sql: ${TABLE}.salecredit_location.LocationCode ;; }
  dimension: location_name { group_label: "Sale Credit Location" description: "Friendly name of the sale-credit location." type: string sql: ${TABLE}.salecredit_location.LocationName ;; }
  dimension: city          { group_label: "Sale Credit Location" description: "City of the sale-credit location." type: string sql: ${TABLE}.salecredit_location.City ;; }
  dimension: state         { group_label: "Sale Credit Location" description: "State or province of the sale-credit location." type: string sql: ${TABLE}.salecredit_location.State ;; }
  dimension: country       { group_label: "Sale Credit Location" description: "Country of the sale-credit location." type: string sql: ${TABLE}.salecredit_location.Country ;; }
}

view: sales_order_sellfrom_location {
  sql_table_name: `@{schema_name}.external_datamart_1.SalesOrder_view` ;;

  dimension: location_id   { group_label: "Sell From Location" description: "Internal id of the location physically fulfilling the order (the store/DC the goods ship from)." type: string sql: ${TABLE}.sellfrom_location.LocationId ;; }
  dimension: location_code { group_label: "Sell From Location" description: "Short code of the sell-from location." type: string sql: ${TABLE}.sellfrom_location.LocationCode ;; }
  dimension: location_name { group_label: "Sell From Location" description: "Friendly name of the sell-from location." type: string sql: ${TABLE}.sellfrom_location.LocationName ;; }
  dimension: city          { group_label: "Sell From Location" description: "City of the sell-from location." type: string sql: ${TABLE}.sellfrom_location.City ;; }
  dimension: state         { group_label: "Sell From Location" description: "State or province of the sell-from location." type: string sql: ${TABLE}.sellfrom_location.State ;; }
  dimension: country       { group_label: "Sell From Location" description: "Country of the sell-from location." type: string sql: ${TABLE}.sellfrom_location.Country ;; }
}