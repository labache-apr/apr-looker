---
- dashboard: mobile_employee_performance
  title: "Mobile - Employee Performance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Mobile-optimized employee scorecard: KPIs and per-employee ranking."

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

    - name: employee
      title: "Employee"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.employee_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── Filtered total KPIs ──

    - title: "Net Sales"
      name: emp_net_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 0
      col: 0
      width: 12
      height: 4

    - title: "Transactions"
      name: emp_transactions
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 0
      col: 12
      width: 12
      height: 4

    - title: "ATV"
      name: emp_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 4
      col: 0
      width: 12
      height: 4

    - title: "UPT"
      name: emp_upt
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_units_per_transaction]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 4
      col: 12
      width: 12
      height: 4

    # ── Employee leaderboards ──

    - title: "Top Employees by Net Sales"
      name: emp_top_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.employee_name, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 8
      col: 0
      width: 24
      height: 9

    - title: "Top Employees by ATV"
      name: emp_top_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.employee_name, sales_receipt.avg_transaction_value]
      sorts: [sales_receipt.avg_transaction_value desc]
      limit: 20
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 17
      col: 0
      width: 24
      height: 9

    - title: "Top Employees by UPT"
      name: emp_top_upt
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.employee_name, sales_receipt.avg_units_per_transaction]
      sorts: [sales_receipt.avg_units_per_transaction desc]
      limit: 20
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 26
      col: 0
      width: 24
      height: 9

    # ── Employee scorecard table ──

    - title: "Employee Scorecard"
      name: emp_scorecard
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_grid
      fields:
        - sales_receipt.employee_name
        - sales_receipt.total_net_sales
        - sales_receipt.transaction_count
        - sales_receipt.avg_transaction_value
        - sales_receipt.avg_units_per_transaction
        - sales_receipt.margin_percent
      sorts: [sales_receipt.total_net_sales desc]
      limit: 50
      show_view_names: false
      show_row_numbers: false
      truncate_column_names: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        employee: sales_receipt.employee_name
      row: 35
      col: 0
      width: 24
      height: 10
