---
- dashboard: sales_kpi_period_comparison
  title: "Sales KPI - Period Comparison"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Compare sales KPIs across periods with location and department breakdowns."

  filters:
    - name: current_period
      title: "Current Period"
      type: date_filter
      default_value: "last 30 days"

    - name: previous_period
      title: "Previous Period"
      type: date_filter
      default_value: "60 days ago for 30 days"

    - name: location
      title: "Location"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.location_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── Current Period KPIs ──

    - title: "Net Sales (Current)"
      name: current_net_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 0
      width: 5
      height: 3

    - title: "Transactions (Current)"
      name: current_transactions
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 5
      width: 5
      height: 3

    - title: "ATV (Current)"
      name: current_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 10
      width: 4
      height: 3

    - title: "UPT (Current)"
      name: current_upt
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_units_per_transaction]
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 14
      width: 5
      height: 3

    - title: "Margin % (Current)"
      name: current_margin_pct
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 0
      col: 19
      width: 5
      height: 3

    # ── Previous Period KPIs ──

    - title: "Net Sales (Previous)"
      name: prev_net_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 0
      width: 5
      height: 3

    - title: "Transactions (Previous)"
      name: prev_transactions
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 5
      width: 5
      height: 3

    - title: "ATV (Previous)"
      name: prev_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 10
      width: 4
      height: 3

    - title: "UPT (Previous)"
      name: prev_upt
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_units_per_transaction]
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 14
      width: 5
      height: 3

    - title: "Margin % (Previous)"
      name: prev_margin_pct
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 3
      col: 19
      width: 5
      height: 3

    # ── Location Comparison ──

    - title: "Sales by Location - Current Period"
      name: location_current
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.location_name, sales_receipt.total_net_sales, sales_receipt.transaction_count,
               sales_receipt.avg_transaction_value, sales_receipt.margin_percent, sales_receipt.total_quantity]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 6
      col: 0
      width: 12
      height: 8

    - title: "Sales by Location - Previous Period"
      name: location_previous
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.location_name, sales_receipt.total_net_sales, sales_receipt.transaction_count,
               sales_receipt.avg_transaction_value, sales_receipt.margin_percent, sales_receipt.total_quantity]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 6
      col: 12
      width: 12
      height: 8

    # ── Department Comparison ──

    - title: "Sales by Department - Current Period"
      name: dept_current
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.department, sales_receipt.total_net_sales, sales_receipt.total_quantity,
               sales_receipt.margin_percent, sales_receipt.discount_rate]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      listen:
        current_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 14
      col: 0
      width: 12
      height: 8

    - title: "Sales by Department - Previous Period"
      name: dept_previous
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.department, sales_receipt.total_net_sales, sales_receipt.total_quantity,
               sales_receipt.margin_percent, sales_receipt.discount_rate]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      listen:
        previous_period: sales_receipt.date_part
        location: sales_receipt.location_name
      row: 14
      col: 12
      width: 12
      height: 8
