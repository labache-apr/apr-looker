---
- dashboard: mobile_top_sellers
  title: "Mobile - Top Sellers"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Mobile-optimized top sellers view: stacked, full-width charts and grids for phone screens."
  preferred_slug: mobile-top-sellers

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

    # ── Top Departments ──

    - title: "Top 10 Departments by Sales"
      name: m_top_departments
      model: twc_aefc
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
      row: 0
      col: 0
      width: 24
      height: 8

    # ── Top Brands ──

    - title: "Top 10 Brands by Sales"
      name: m_top_brands
      model: twc_aefc
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
      row: 8
      col: 0
      width: 24
      height: 8

    # ── Top Vendors ──

    - title: "Top 10 Vendors by Sales"
      name: m_top_vendors
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.primary_vendor, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      hide_legend: true
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 16
      col: 0
      width: 24
      height: 8

    # ── Top Items by Net Sales ──

    - title: "Top 25 Items by Net Sales"
      name: m_top_items_revenue
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.total_net_sales, sales_receipt.total_quantity,
               sales_receipt.margin_percent, sales_receipt.avg_selling_price]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 25
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 24
      col: 0
      width: 24
      height: 9

    # ── Top Items by Quantity ──

    - title: "Top 25 Items by Quantity Sold"
      name: m_top_items_qty
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.total_quantity, sales_receipt.total_net_sales,
               sales_receipt.avg_selling_price, sales_receipt.margin_percent]
      sorts: [sales_receipt.total_quantity desc]
      limit: 25
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 33
      col: 0
      width: 24
      height: 9
