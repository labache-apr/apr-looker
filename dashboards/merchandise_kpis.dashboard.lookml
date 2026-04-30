---
- dashboard: merchandise_kpis
  title: "Merchandise KPIs"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Period-based merchandising health: GMROI, inventory turn, weeks/days of supply, sell-through, out-of-stock rate, markdown %, AUR, ATV, UPT. Sourced from the daily inventory snapshot and POS receipts — apply the date range to scope the period."
  preferred_slug: merchandise-kpis

  filters:
    - name: date_range
      title: "Snapshot Date Range"
      type: field_filter
      explore: inventory
      field: inventory.date_part
      default_value: "28 days"
      allow_multiple_values: false
      required: true

    - name: sales_date_range
      title: "Receipt Date Range"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.date_part
      default_value: "28 days"
      allow_multiple_values: false
      required: true

    - name: location
      title: "Location"
      type: field_filter
      explore: inventory
      field: location_master.location_name
      default_value: ""
      allow_multiple_values: true

    - name: department
      title: "Department"
      type: field_filter
      explore: inventory
      field: item_master.department
      default_value: ""
      allow_multiple_values: true

  elements:

    # ══════════════════════════════════════════════════
    # ROW 1 — Inventory productivity KPIs
    # ══════════════════════════════════════════════════

    - title: "GMROI"
      name: gmroi_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.gmroi]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 0
      col: 0
      width: 5
      height: 3

    - title: "Inventory Turn"
      name: turn_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.inventory_turn_ratio]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 0
      col: 5
      width: 5
      height: 3

    - title: "Sell-Through Rate"
      name: sell_through_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.sell_through_rate]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 0
      col: 10
      width: 5
      height: 3

    - title: "Weeks of Supply"
      name: wos_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.weeks_of_supply]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 0
      col: 15
      width: 5
      height: 3

    - title: "Days of Supply"
      name: dos_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.days_of_supply]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 0
      col: 20
      width: 4
      height: 3

    # ══════════════════════════════════════════════════
    # ROW 2 — Availability + sales productivity
    # ══════════════════════════════════════════════════

    - title: "Out-of-Stock Rate"
      name: oos_rate_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.out_of_stock_rate]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 3
      col: 0
      width: 5
      height: 3

    - title: "Avg Inventory Cost"
      name: avg_inv_cost_kpi
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.avg_inventory_cost]
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 3
      col: 5
      width: 5
      height: 3

    - title: "AUR"
      name: aur_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_unit_retail]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 3
      col: 10
      width: 5
      height: 3

    - title: "ATV"
      name: atv_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_transaction_value]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 3
      col: 15
      width: 5
      height: 3

    - title: "UPT"
      name: upt_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.avg_units_per_transaction]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 3
      col: 20
      width: 4
      height: 3

    # ══════════════════════════════════════════════════
    # ROW 3 — Markdown KPIs
    # ══════════════════════════════════════════════════

    - title: "Markdown %"
      name: markdown_pct_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.markdown_pct]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 6
      col: 0
      width: 6
      height: 3

    - title: "Total Markdown $"
      name: markdown_dollars_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_markdown_amount]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 6
      col: 6
      width: 6
      height: 3

    - title: "Discount Rate"
      name: discount_rate_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.discount_rate]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 6
      col: 12
      width: 6
      height: 3

    - title: "Margin %"
      name: margin_pct_kpi
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 6
      col: 18
      width: 6
      height: 3

    # ══════════════════════════════════════════════════
    # KPIs by Department
    # ══════════════════════════════════════════════════

    - title: "Inventory KPIs by Department"
      name: kpis_by_dept
      model: twc_aefc
      explore: inventory
      type: looker_grid
      fields: [
        item_master.department,
        inventory.avg_inventory_qty,
        inventory.avg_inventory_cost,
        inventory.total_sold_qty,
        inventory.total_sold_margin,
        inventory.gmroi,
        inventory.inventory_turn_ratio,
        inventory.sell_through_rate,
        inventory.weeks_of_supply,
        inventory.days_of_supply,
        inventory.out_of_stock_rate
      ]
      sorts: [inventory.gmroi desc]
      limit: 50
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 9
      col: 0
      width: 24
      height: 8

    # ══════════════════════════════════════════════════
    # KPIs by Location
    # ══════════════════════════════════════════════════

    - title: "Inventory KPIs by Location"
      name: kpis_by_location
      model: twc_aefc
      explore: inventory
      type: looker_grid
      fields: [
        location_master.location_name,
        inventory.avg_inventory_qty,
        inventory.avg_inventory_cost,
        inventory.total_sold_qty,
        inventory.total_sold_margin,
        inventory.gmroi,
        inventory.inventory_turn_ratio,
        inventory.sell_through_rate,
        inventory.weeks_of_supply,
        inventory.days_of_supply,
        inventory.out_of_stock_rate
      ]
      sorts: [inventory.gmroi desc]
      limit: 50
      listen:
        date_range: inventory.date_part
        location: location_master.location_name
        department: item_master.department
      row: 17
      col: 0
      width: 24
      height: 8

    # ══════════════════════════════════════════════════
    # Sales productivity by Department
    # ══════════════════════════════════════════════════

    - title: "Sales Productivity by Department"
      name: sales_kpis_by_dept
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [
        sales_receipt.department,
        sales_receipt.transaction_count,
        sales_receipt.total_quantity,
        sales_receipt.total_net_sales,
        sales_receipt.avg_transaction_value,
        sales_receipt.avg_units_per_transaction,
        sales_receipt.avg_unit_retail,
        sales_receipt.markdown_pct,
        sales_receipt.discount_rate,
        sales_receipt.margin_percent
      ]
      sorts: [sales_receipt.total_net_sales desc]
      limit: 50
      listen:
        sales_date_range: sales_receipt.date_part
        location: dim_location_franchise.location_name
        department: sales_receipt.department
      row: 25
      col: 0
      width: 24
      height: 8
