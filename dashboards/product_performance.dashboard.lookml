---
- dashboard: product_performance
  title: "Product Performance"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Deep dive into product, department, brand, and vendor level performance with margin analysis."
  preferred_slug: product-performance

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

    - name: brand
      title: "Brand"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.brand
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── Sales by Department ──

    - title: "Sales by Department"
      name: by_department
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
        brand: sales_receipt.brand
      row: 0
      col: 0
      width: 12
      height: 7

    # ── Margin % by Department ──

    - title: "Margin % by Department"
      name: margin_by_dept
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.margin_percent]
      sorts: [sales_receipt.margin_percent desc]
      limit: 15
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
        brand: sales_receipt.brand
      row: 0
      col: 12
      width: 12
      height: 7

    # ── Sales by Class ──

    - title: "Sales by Class"
      name: by_class
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.class, sales_receipt.total_net_sales, sales_receipt.margin_percent]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 20
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
        brand: sales_receipt.brand
      row: 7
      col: 0
      width: 12
      height: 7

    # ── Top Brands ──

    - title: "Top 15 Brands"
      name: top_brands
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
        brand: sales_receipt.brand
      row: 7
      col: 12
      width: 12
      height: 7

    # ── Top Styles Detail ──

    - title: "Top 25 Styles by Net Sales"
      name: top_styles
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.total_net_sales, sales_receipt.total_quantity,
               sales_receipt.margin_percent, sales_receipt.avg_selling_price, sales_receipt.discount_rate,
               item_lifecycle_dates.first_purchase_date, item_lifecycle_dates.last_purchase_date]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 25
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
        brand: sales_receipt.brand
      row: 14
      col: 0
      width: 24
      height: 8

    # ── Vendor Performance ──

    - title: "Vendor Performance"
      name: vendor_perf
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.primary_vendor, sales_receipt.total_net_sales, sales_receipt.total_quantity,
               sales_receipt.total_margin, sales_receipt.margin_percent, sales_receipt.discount_rate,
               sales_receipt.return_rate]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 25
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
        brand: sales_receipt.brand
      row: 22
      col: 0
      width: 24
      height: 8

    # ── Bottom Performers ──

    - title: "Bottom 20 Styles by Margin %"
      name: bottom_margin
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.margin_percent, sales_receipt.total_net_sales,
               sales_receipt.total_quantity, sales_receipt.discount_rate,
               item_lifecycle_dates.first_purchase_date, item_lifecycle_dates.last_purchase_date]
      sorts: [sales_receipt.margin_percent asc]
      limit: 20
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
        brand: sales_receipt.brand
      row: 30
      col: 0
      width: 24
      height: 8
