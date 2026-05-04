---
- dashboard: mobile_location_performance
  title: "Mobile - Location Performance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Mobile-optimized location scorecard: KPIs and per-location ranking."

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

    # ── Filtered total KPIs ──

    - title: "Net Sales"
      name: l_net_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 0
      width: 12
      height: 4

    - title: "Margin %"
      name: l_margin_pct
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 12
      width: 12
      height: 4

    - title: "Transactions"
      name: l_transactions
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 4
      col: 0
      width: 12
      height: 4

    - title: "ATV"
      name: l_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 4
      col: 12
      width: 12
      height: 4

    # ── Location ranking bars ──

    - title: "Net Sales by Location"
      name: l_sales_by_location
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 25
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 8
      col: 0
      width: 24
      height: 9

    - title: "Margin % by Location"
      name: l_margin_by_location
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.margin_percent]
      sorts: [sales_receipt.margin_percent desc]
      limit: 25
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 17
      col: 0
      width: 24
      height: 9

    - title: "Transactions by Location"
      name: l_txn_by_location
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.transaction_count]
      sorts: [sales_receipt.transaction_count desc]
      limit: 25
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 26
      col: 0
      width: 24
      height: 9

    # ── Location scorecard table (compact columns) ──

    - title: "Location Scorecard"
      name: l_scorecard
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_grid
      fields:
        - sales_receipt.location_name
        - sales_receipt.total_net_sales
        - sales_receipt.margin_percent
        - sales_receipt.transaction_count
        - sales_receipt.avg_transaction_value
      sorts: [sales_receipt.total_net_sales desc]
      limit: 50
      show_view_names: false
      show_row_numbers: false
      truncate_column_names: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 35
      col: 0
      width: 24
      height: 10
