---
- dashboard: sales_performance
  title: "Sales Performance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Comprehensive sales analytics with KPIs, trends, and breakdowns by location, department, brand, and employee."
  preferred_slug: sales-performance

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

    - name: department
      title: "Department"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.department
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPI Row 1: Revenue ──

    - title: "Net Sales"
      name: net_sales
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 0
      width: 5
      height: 3

    - title: "Gross Sales"
      name: gross_sales
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_gross_sales]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 5
      width: 5
      height: 3

    - title: "Margin"
      name: margin
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_margin]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 10
      width: 5
      height: 3

    - title: "Margin %"
      name: margin_pct
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 15
      width: 4
      height: 3

    - title: "Discount Rate"
      name: discount_rate
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.discount_rate]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 19
      width: 5
      height: 3

    # ── KPI Row 2: Transaction Metrics ──

    - title: "Transactions"
      name: transactions
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.transaction_count]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 3
      col: 0
      width: 6
      height: 3

    - title: "ATV"
      name: atv
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 3
      col: 6
      width: 6
      height: 3

    - title: "UPT"
      name: upt
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_units_per_transaction]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 3
      col: 12
      width: 6
      height: 3

    - title: "ASP"
      name: asp
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_selling_price]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 3
      col: 18
      width: 6
      height: 3

    # ── Daily Sales Trend ──

    - title: "Daily Sales Trend"
      name: daily_trend
      model: twc_aefc
      explore: sales_receipt
      type: looker_line
      fields: [sales_receipt.date_part, sales_receipt.total_net_sales, sales_receipt.total_margin]
      fill_fields: [sales_receipt.date_part]
      sorts: [sales_receipt.date_part]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 6
      col: 0
      width: 24
      height: 7

    # ── Sales by Location ──

    - title: "Sales by Location"
      name: by_location
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.total_net_sales, sales_receipt.transaction_count]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 13
      col: 0
      width: 12
      height: 7

    # ── Sales by Department ──

    - title: "Sales by Department"
      name: by_department
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.total_net_sales, sales_receipt.margin_percent]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 13
      col: 12
      width: 12
      height: 7

    # ── Sales by Brand ──

    - title: "Top 15 Brands"
      name: by_brand
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.brand, sales_receipt.total_net_sales, sales_receipt.total_quantity]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 20
      col: 0
      width: 12
      height: 7

    # ── Sales by Employee ──

    - title: "Sales by Employee"
      name: by_employee
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.employee_name, sales_receipt.total_net_sales, sales_receipt.transaction_count,
               sales_receipt.avg_transaction_value, sales_receipt.total_quantity, sales_receipt.margin_percent]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 20
      col: 12
      width: 12
      height: 7
