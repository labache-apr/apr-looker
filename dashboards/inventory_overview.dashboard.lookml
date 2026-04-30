---
- dashboard: inventory_overview
  title: "Inventory Overview"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Executive view of inventory health, stock levels, stockout rates, and reorder needs."
  preferred_slug: inventory-overview

  filters:
    - name: location
      title: "Location"
      type: field_filter
      explore: location_availability
      field: location_availability.location_name
      default_value: ""
      allow_multiple_values: true

    - name: department
      title: "Department"
      type: field_filter
      explore: location_availability
      field: location_availability.department
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPI Row 1 ──

    - title: "Total On Hand Qty"
      name: on_hand_qty
      model: twc_aefc
      explore: location_availability
      type: single_value
      fields: [location_availability.total_on_hand]
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 0
      col: 0
      width: 6
      height: 3

    - title: "Available to Sell"
      name: ats
      model: twc_aefc
      explore: location_availability
      type: single_value
      fields: [location_availability.total_ats]
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 0
      col: 6
      width: 6
      height: 3

    - title: "SKU-Location Count"
      name: sku_locations
      model: twc_aefc
      explore: location_availability
      type: single_value
      fields: [location_availability.sku_location_count]
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 0
      col: 12
      width: 4
      height: 3

    - title: "Stockout Count"
      name: stockouts
      model: twc_aefc
      explore: location_availability
      type: single_value
      fields: [location_availability.stockout_count]
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 0
      col: 16
      width: 4
      height: 3

    - title: "Stockout Rate"
      name: stockout_rate
      model: twc_aefc
      explore: location_availability
      type: single_value
      fields: [location_availability.stockout_rate]
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 0
      col: 20
      width: 4
      height: 3

    # ── Stock by Location ──

    - title: "Stock by Location"
      name: stock_by_location
      model: twc_aefc
      explore: location_availability
      type: looker_bar
      fields: [location_availability.location_name, location_availability.total_on_hand,
               location_availability.total_ats]
      sorts: [location_availability.total_on_hand desc]
      limit: 15
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 3
      col: 0
      width: 12
      height: 7

    # ── Stock by Department ──

    - title: "Stock by Department"
      name: stock_by_dept
      model: twc_aefc
      explore: location_availability
      type: looker_bar
      fields: [location_availability.department, location_availability.total_on_hand,
               location_availability.total_ats]
      sorts: [location_availability.total_on_hand desc]
      limit: 15
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 3
      col: 12
      width: 12
      height: 7

    # ── Committed / Reserved / Damaged Breakdown ──

    - title: "Inventory Status Breakdown"
      name: status_breakdown
      model: twc_aefc
      explore: location_availability
      type: looker_grid
      fields: [location_availability.location_name, location_availability.total_on_hand,
               location_availability.total_ats, location_availability.total_committed,
               location_availability.total_reserved, location_availability.total_held,
               location_availability.total_damaged, location_availability.total_incoming]
      sorts: [location_availability.total_on_hand desc]
      limit: 25
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 10
      col: 0
      width: 24
      height: 8

    # ── Stockout Items ──

    - title: "Items Currently Out of Stock"
      name: stockout_items
      model: twc_aefc
      explore: location_availability
      type: looker_grid
      fields: [location_availability.style, location_availability.description1,
               location_availability.department, location_availability.brand,
               location_availability.location_name, location_availability.total_on_hand,
               location_availability.total_ats, location_availability.total_incoming,
               item_lifecycle_dates.last_purchase_date, item_lifecycle_dates.last_received_date,
               item_lifecycle_dates.last_order_date]
      filters:
        location_availability.total_ats: "0"
      sorts: [location_availability.department]
      limit: 50
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 18
      col: 0
      width: 24
      height: 8

    # ══════════════════════════════════════════════════
    # PERIOD-BASED MERCHANDISE KPIs (last 28 snapshot days)
    # Sourced from the daily inventory snapshot (inventory explore).
    # ══════════════════════════════════════════════════

    - title: "Period KPIs — Last 28 Days"
      name: period_kpis_text
      type: text
      body_text: "**Trailing 28-day merchandising productivity** — sourced from the daily inventory snapshot. Filter rows below by Location and Department using the dashboard filters."
      row: 26
      col: 0
      width: 24
      height: 2

    - title: "GMROI (28d)"
      name: gmroi_28d
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.gmroi]
      filters:
        inventory.date_part: "28 days"
      listen:
        location: location_master.location_name
        department: item_master.department
      row: 28
      col: 0
      width: 5
      height: 3

    - title: "Inventory Turn (28d)"
      name: turn_28d
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.inventory_turn_ratio]
      filters:
        inventory.date_part: "28 days"
      listen:
        location: location_master.location_name
        department: item_master.department
      row: 28
      col: 5
      width: 5
      height: 3

    - title: "Sell-Through (28d)"
      name: sell_through_28d
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.sell_through_rate]
      filters:
        inventory.date_part: "28 days"
      listen:
        location: location_master.location_name
        department: item_master.department
      row: 28
      col: 10
      width: 5
      height: 3

    - title: "WOS (28d)"
      name: wos_28d
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.weeks_of_supply]
      filters:
        inventory.date_part: "28 days"
      listen:
        location: location_master.location_name
        department: item_master.department
      row: 28
      col: 15
      width: 5
      height: 3

    - title: "OOS Rate (28d)"
      name: oos_28d
      model: twc_aefc
      explore: inventory
      type: single_value
      fields: [inventory.out_of_stock_rate]
      filters:
        inventory.date_part: "28 days"
      listen:
        location: location_master.location_name
        department: item_master.department
      row: 28
      col: 20
      width: 4
      height: 3
