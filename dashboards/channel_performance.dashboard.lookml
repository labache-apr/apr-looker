---
- dashboard: channel_performance
  title: "Channel Performance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Analyze sales performance by channel - web vs in-store, receipt source breakdown, and channel trends."
  preferred_slug: channel-performance

  filters:
    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "last 90 days"

    - name: location
      title: "Location"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.location_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPIs by Channel ──

    - title: "In-Store Net Sales"
      name: instore_sales
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      filters:
        sales_receipt.is_web_receipt: "no"
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 0
      width: 6
      height: 3

    - title: "In-Store Transactions"
      name: instore_transactions
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      filters:
        sales_receipt.is_web_receipt: "no"
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 6
      width: 6
      height: 3

    - title: "Web Net Sales"
      name: web_sales
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      filters:
        sales_receipt.is_web_receipt: "yes"
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 12
      width: 6
      height: 3

    - title: "Web Transactions"
      name: web_transactions
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      filters:
        sales_receipt.is_web_receipt: "yes"
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 18
      width: 6
      height: 3

    # ── Channel Split ──

    - title: "Sales by Channel"
      name: channel_split
      model: twc_aefc
      explore: sales_receipt
      type: looker_pie
      fields: [sales_receipt.is_web_receipt, sales_receipt.total_net_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 0
      width: 8
      height: 7

    # ── Sales by Receipt Source ──

    - title: "Sales by Receipt Source"
      name: by_source
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.rec_source_label, sales_receipt.total_net_sales, sales_receipt.transaction_count]
      sorts: [sales_receipt.total_net_sales desc]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 8
      width: 16
      height: 7

    # ── Channel Trend ──

    - title: "Channel Sales Trend"
      name: channel_trend
      model: twc_aefc
      explore: sales_receipt
      type: looker_area
      fields: [sales_receipt.date_part, sales_receipt.is_web_receipt, sales_receipt.total_net_sales]
      pivots: [sales_receipt.is_web_receipt]
      fill_fields: [sales_receipt.date_part]
      sorts: [sales_receipt.date_part]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 10
      col: 0
      width: 24
      height: 7

    # ── KPIs by Channel Detail ──

    - title: "Channel KPI Comparison"
      name: channel_kpi_table
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.rec_source_label, sales_receipt.total_net_sales, sales_receipt.transaction_count,
               sales_receipt.avg_transaction_value, sales_receipt.avg_units_per_transaction,
               sales_receipt.margin_percent, sales_receipt.total_quantity]
      sorts: [sales_receipt.total_net_sales desc]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 17
      col: 0
      width: 24
      height: 7
