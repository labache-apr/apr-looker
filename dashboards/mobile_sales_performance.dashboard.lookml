---
- dashboard: mobile_sales_performance
  title: "Mobile - Sales Performance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Mobile-optimized sales view: stacked KPIs and full-width charts for phone screens."

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

    - name: department
      title: "Department"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.department
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPI Pairs (stack 1-up on phone, 2-up on tablet) ──

    - title: "Net Sales"
      name: m_net_sales
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 0
      width: 12
      height: 4

    - title: "Margin"
      name: m_margin
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_margin]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 12
      width: 12
      height: 4

    - title: "Margin %"
      name: m_margin_pct
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 4
      col: 0
      width: 12
      height: 4

    - title: "Transactions"
      name: m_transactions
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 4
      col: 12
      width: 12
      height: 4

    - title: "ATV"
      name: m_atv
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 8
      col: 0
      width: 12
      height: 4

    - title: "UPT"
      name: m_upt
      model: "@{model_name}"
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_units_per_transaction]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 8
      col: 12
      width: 12
      height: 4

    # ── Full-width chart: daily sales trend ──

    - title: "Daily Net Sales"
      name: m_daily_trend
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_line
      fields: [sales_receipt.transacted_date_date, sales_receipt.total_net_sales]
      fill_fields: [sales_receipt.transacted_date_date]
      sorts: [sales_receipt.transacted_date_date]
      x_axis_gridlines: false
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 12
      col: 0
      width: 24
      height: 7

    # ── Full-width breakdown bars ──

    - title: "Top Locations"
      name: m_top_locations
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
        department: sales_receipt.department
      row: 19
      col: 0
      width: 24
      height: 8

    - title: "Top Departments"
      name: m_top_departments
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 27
      col: 0
      width: 24
      height: 8

    - title: "Top Brands"
      name: m_top_brands
      model: "@{model_name}"
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.brand, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 35
      col: 0
      width: 24
      height: 8
