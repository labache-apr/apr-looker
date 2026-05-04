---
- dashboard: executive_summary
  title: "Executive Summary"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "High-level retail performance overview with sales, margin, and inventory KPIs."

  filters:
    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "last 90 days"
      allow_multiple_values: true

    - name: location
      title: "Location"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.location_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPI Row ──

    - title: "Net Sales"
      name: net_sales_kpi
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      filters:
        sales_receipt.date_part: ""
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 0
      width: 5
      height: 3

    - title: "Margin"
      name: margin_kpi
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_margin]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 5
      width: 5
      height: 3

    - title: "Margin %"
      name: margin_pct_kpi
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 10
      width: 5
      height: 3

    - title: "Transactions"
      name: transactions_kpi
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 15
      width: 4
      height: 3

    - title: "ATV"
      name: atv_kpi
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 19
      width: 5
      height: 3

    # ── Sales Trend ──

    - title: "Sales Trend"
      name: sales_trend
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_line
      fields: [sales_receipt.total_net_sales, sales_receipt.total_margin]
      # fields: [sales_receipt.retail_month_desc, sales_receipt.total_net_sales, sales_receipt.total_margin]
      # sorts: [sales_receipt.retail_month_desc]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 0
      width: 24
      height: 7

    # ── Sales by Location ──

    - title: "Sales by Location"
      name: sales_by_location
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 10
      col: 0
      width: 12
      height: 7

    # ── Sales by Department ──

    - title: "Sales by Department"
      name: sales_by_department
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.total_net_sales, sales_receipt.margin_percent]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 10
      col: 12
      width: 12
      height: 7
