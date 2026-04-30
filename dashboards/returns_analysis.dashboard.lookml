---
- dashboard: returns_analysis
  title: "Returns Analysis"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Deep dive into return patterns, problem areas, and return rates by location, department, and product."
  preferred_slug: returns-analysis

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

    # ── KPI Row ──

    - title: "Return Amount"
      name: return_amt
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.return_amount]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 0
      width: 8
      height: 3

    - title: "Return Quantity"
      name: return_qty
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.return_quantity]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 8
      width: 8
      height: 3

    - title: "Return Rate"
      name: return_rate
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.return_rate]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 16
      width: 8
      height: 3

    # ── Return Trend ──

    - title: "Return Trend"
      name: return_trend
      model: twc_aefc
      explore: sales_receipt
      type: looker_line
      fields: [sales_receipt.date_part, sales_receipt.return_amount, sales_receipt.return_rate]
      fill_fields: [sales_receipt.date_part]
      sorts: [sales_receipt.date_part]
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 3
      col: 0
      width: 24
      height: 7

    # ── Returns by Department ──

    - title: "Returns by Department"
      name: returns_by_dept
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.return_amount, sales_receipt.return_rate]
      sorts: [sales_receipt.return_amount desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 10
      col: 0
      width: 12
      height: 7

    # ── Returns by Location ──

    - title: "Returns by Location"
      name: returns_by_location
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.location_name, sales_receipt.return_amount, sales_receipt.return_rate]
      sorts: [sales_receipt.return_amount desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 10
      col: 12
      width: 12
      height: 7

    # ── Top Returned Items ──

    - title: "Top 20 Returned Items"
      name: top_returns
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.return_amount, sales_receipt.return_quantity,
               sales_receipt.return_rate, sales_receipt.total_net_sales]
      sorts: [sales_receipt.return_amount desc]
      limit: 20
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 17
      col: 0
      width: 24
      height: 8
