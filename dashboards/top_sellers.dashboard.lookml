---
- dashboard: top_sellers
  title: "Top Sellers"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Top selling products, brands, and departments by revenue and quantity."
  preferred_slug: top-sellers

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

    # ── Top Departments ──

    - title: "Top 10 Departments by Sales"
      name: top_departments
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.department, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 0
      width: 12
      height: 7

    # ── Top Brands ──

    - title: "Top 10 Brands by Sales"
      name: top_brands
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.brand, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 0
      col: 12
      width: 12
      height: 7

    # ── Top Vendors ──

    - title: "Top 10 Vendors by Sales"
      name: top_vendors
      model: twc_aefc
      explore: sales_receipt
      type: looker_bar
      fields: [sales_receipt.primary_vendor, sales_receipt.total_net_sales]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 10
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 7
      col: 0
      width: 24
      height: 7

    # ── Top Items by Revenue ──

    - title: "Top 25 Items by Net Sales"
      name: top_items_revenue
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.total_net_sales, sales_receipt.total_quantity,
               sales_receipt.margin_percent, sales_receipt.avg_selling_price,
               item_lifecycle_dates.first_purchase_date, item_lifecycle_dates.last_purchase_date]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 25
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 14
      col: 0
      width: 24
      height: 8

    # ── Top Items by Quantity ──

    - title: "Top 25 Items by Quantity Sold"
      name: top_items_qty
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [sales_receipt.style, sales_receipt.description1, sales_receipt.department,
               sales_receipt.brand, sales_receipt.total_quantity, sales_receipt.total_net_sales,
               sales_receipt.avg_selling_price, sales_receipt.margin_percent,
               item_lifecycle_dates.first_purchase_date, item_lifecycle_dates.last_purchase_date]
      sorts: [sales_receipt.total_quantity desc]
      limit: 25
      listen:
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        department: sales_receipt.department
      row: 22
      col: 0
      width: 24
      height: 8
