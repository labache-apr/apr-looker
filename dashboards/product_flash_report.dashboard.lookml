---
- dashboard: product_flash_report
  title: "Product Flash Report"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Single-product deep dive showing inventory health, sales velocity, and reorder status across all locations."
  preferred_slug: product-flash-report

  filters:
    - name: plu
      title: "PLU"
      type: field_filter
      explore: product_flash
      field: product_flash.plu
      default_value: ""
      allow_multiple_values: false
      required: true

    - name: as_of_date
      title: "As Of Date"
      type: field_filter
      explore: product_flash
      field: product_flash.as_of_date
      default_value: "today"
      allow_multiple_values: false

    - name: location
      title: "Location"
      type: field_filter
      explore: product_flash
      field: product_flash.location_name
      default_value: ""
      allow_multiple_values: true

  elements:

    # ══════════════════════════════════════════════════
    # ROW 0 - PRODUCT HEADER
    # ══════════════════════════════════════════════════

    - title: "Product"
      name: product_info
      model: twc_aefc
      explore: product_flash
      type: looker_single_record
      fields: [product_flash.description1, product_flash.style,
               product_flash.primary_vendor, product_flash.brand,
               product_flash.department, product_flash.item_class,
               product_flash.status_label]
      limit: 1
      listen:
        plu: product_flash.plu
      row: 0
      col: 0
      width: 14
      height: 4

    - title: "Vendor Cost"
      name: vendor_cost
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.vendor_cost]
      limit: 1
      listen:
        plu: product_flash.plu
      row: 0
      col: 14
      width: 4
      height: 4

    - title: "Current Price"
      name: current_price
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.retail_price]
      limit: 1
      listen:
        plu: product_flash.plu
      row: 0
      col: 18
      width: 3
      height: 4

    - title: "Est. Margin"
      name: est_margin
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.est_margin_pct]
      limit: 1
      listen:
        plu: product_flash.plu
      row: 0
      col: 21
      width: 3
      height: 4

    # ══════════════════════════════════════════════════
    # ROW 1 - KPI TILES
    # ══════════════════════════════════════════════════

    - title: "Total On Hand"
      name: total_on_hand
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.total_on_hand, product_flash.total_available]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 4
      col: 0
      width: 6
      height: 4

    - title: "Weeks of Supply"
      name: weeks_of_supply
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.weeks_of_supply]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 4
      col: 6
      width: 6
      height: 4

    - title: "Sell-Through YTD"
      name: sell_through_ytd
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.sell_through_ytd, product_flash.total_ytd_sales_units]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 4
      col: 12
      width: 6
      height: 4

    - title: "YTD vs LY"
      name: ytd_vs_ly
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.ytd_vs_ly_pct, product_flash.total_ytd_sales_dollars,
               product_flash.total_ly_sales_dollars]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 4
      col: 18
      width: 6
      height: 4

    # ══════════════════════════════════════════════════
    # ROW 2 - ALERT TILES
    # ══════════════════════════════════════════════════

    - title: "Stock-Outs"
      name: stockouts
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.stockout_location_count, product_flash.below_reorder_min_count]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 8
      col: 0
      width: 8
      height: 3

    - title: "Incoming"
      name: incoming
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.total_incoming]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 8
      col: 8
      width: 8
      height: 3

    - title: "First / Last Sale"
      name: sale_dates
      model: twc_aefc
      explore: product_flash
      type: single_value
      fields: [product_flash.first_sale_date, product_flash.last_sale_date]
      limit: 1
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
      row: 8
      col: 16
      width: 8
      height: 3

    # ══════════════════════════════════════════════════
    # ROW 3 - REORDER ALERT GRID
    # ══════════════════════════════════════════════════

    - title: "Reorder Alert"
      name: reorder_alert
      model: twc_aefc
      explore: product_flash
      type: looker_grid
      fields: [product_flash.location_label, product_flash.available,
               product_flash.reorder_min, product_flash.reorder_max,
               product_flash.on_hand, product_flash.incoming,
               product_flash.stock_status]
      filters:
        product_flash.needs_reorder: "yes"
      sorts: [product_flash.available asc]
      limit: 50
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 11
      col: 0
      width: 24
      height: 5

    # ══════════════════════════════════════════════════
    # ROW 4 - LOCATION DETAIL GRID
    # ══════════════════════════════════════════════════

    - title: "Location Detail"
      name: location_detail
      model: twc_aefc
      explore: product_flash
      type: looker_grid
      fields: [product_flash.location_label, product_flash.stock_status,
               product_flash.on_hand, product_flash.committed,
               product_flash.available, product_flash.incoming,
               product_flash.reorder_min, product_flash.reorder_max,
               product_flash.l4w_sales_units, product_flash.lw_sales_units,
               product_flash.ytd_sales_units, product_flash.ly_sales_units,
               product_flash.l4w_sales_dollars, product_flash.lw_sales_dollars,
               product_flash.ytd_sales_dollars]
      sorts: [product_flash.location_label asc]
      limit: 500
      total: true
      listen:
        plu: product_flash.plu
        as_of_date: product_flash.as_of_date
        location: product_flash.location_name
      row: 16
      col: 0
      width: 24
      height: 12
