---
- dashboard: mobile_executive_overview
  title: "Mobile - Executive Overview"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Mobile-optimized executive view: headline KPIs and trend at a glance."

  filters:
    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "last 30 days"

    - name: location
      title: "Location"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.location_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── Headline KPI (full width on phone) ──

    - title: "Net Sales"
      name: e_net_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 0
      width: 24
      height: 4

    # ── Secondary KPIs in 2-up pairs ──

    - title: "Margin"
      name: e_margin
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_margin]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 4
      col: 0
      width: 12
      height: 4

    - title: "Margin %"
      name: e_margin_pct
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 4
      col: 12
      width: 12
      height: 4

    - title: "Transactions"
      name: e_transactions
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 8
      col: 0
      width: 12
      height: 4

    - title: "ATV"
      name: e_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 8
      col: 12
      width: 12
      height: 4

    # ── Monthly trend (full width) ──

    - title: "Monthly Sales & Margin"
      name: e_monthly_trend
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_line
      fields: [sales_receipt.total_net_sales, sales_receipt.total_margin]
      # fields: [sales_receipt.retail_month_desc, sales_receipt.total_net_sales, sales_receipt.total_margin]
      # sorts: [sales_receipt.retail_month_desc]
      x_axis_gridlines: false
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 12
      col: 0
      width: 24
      height: 7

    # ── Location and department breakdowns ──

    - title: "Sales by Location"
      name: e_by_location
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 19
      col: 0
      width: 24
      height: 8

    - title: "Sales by Department"
      name: e_by_department
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.total_net_sales, sales_receipt.margin_percent]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 27
      col: 0
      width: 24
      height: 8
