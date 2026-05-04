---
- dashboard: reorder_dead_stock
  title: "Reorder & Dead Stock Analysis"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Identify items needing reorder based on stock levels and sales velocity, plus slow-moving and dead stock for markdown or discontinuation."

  filters:
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

    - name: sales_date_range
      title: "Sales Date Range"
      type: date_filter
      default_value: "last 90 days"

  elements:

    # ── Reorder Section ──

    - title: "Items Needing Reorder (Low Stock, Active Sellers)"
      name: reorder_items
      model: "@{model_name}"
      explore: location_availability
      type: looker_grid
      fields: [location_availability.style, location_availability.description1,
               location_availability.department, location_availability.brand,
               location_availability.location_name, location_availability.total_on_hand,
               location_availability.total_ats, location_availability.total_committed,
               location_availability.total_incoming,
               item_lifecycle_dates.last_purchase_date, item_lifecycle_dates.last_received_date,
               item_lifecycle_dates.last_order_date]
      filters:
        location_availability.total_ats: "[0, 5]"
      sorts: [location_availability.total_ats asc]
      limit: 50
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 0
      col: 0
      width: 24
      height: 9

    # ── Low Stock by Department ──

    - title: "Low Stock Items by Department"
      name: low_stock_dept
      model: "@{model_name}"
      explore: location_availability
      type: looker_bar
      fields: [location_availability.department, location_availability.stockout_count]
      sorts: [location_availability.stockout_count desc]
      limit: 15
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 9
      col: 0
      width: 12
      height: 7

    - title: "Low Stock Items by Location"
      name: low_stock_loc
      model: "@{model_name}"
      explore: location_availability
      type: looker_bar
      fields: [location_availability.location_name, location_availability.stockout_count]
      sorts: [location_availability.stockout_count desc]
      limit: 15
      listen:
        location: location_availability.location_name
        department: location_availability.department
      row: 9
      col: 12
      width: 12
      height: 7

    # ── Dead Stock Section ──

    - title: "Dead Stock (On Hand, Zero Recent Sales)"
      name: dead_stock
      model: "@{model_name}"
      explore: inventory
      type: looker_grid
      fields: [item_master.style, item_master.description1, item_master.department,
               item_master.brand, location_master.location_name,
               inventory.total_on_hand_qty, inventory.total_on_hand_cost,
               inventory.total_on_hand_retail, inventory.total_sold_qty,
               item_lifecycle_dates.last_purchase_date, item_lifecycle_dates.first_purchase_date,
               item_lifecycle_dates.last_received_date]
      filters:
        inventory.total_sold_qty: "0"
      sorts: [inventory.total_on_hand_cost desc]
      limit: 50
      listen:
        location: location_master.location_name
        department: item_master.department
        sales_date_range: inventory.date_part
      row: 16
      col: 0
      width: 24
      height: 9

    # ── Slow Moving Stock ──

    - title: "Slow Moving Stock (Low Sales Velocity)"
      name: slow_movers
      model: "@{model_name}"
      explore: inventory
      type: looker_grid
      fields: [item_master.style, item_master.description1, item_master.department,
               item_master.brand, location_master.location_name,
               inventory.total_on_hand_qty, inventory.total_on_hand_cost,
               inventory.total_sold_qty, inventory.total_sold_cost,
               item_lifecycle_dates.last_purchase_date, item_lifecycle_dates.first_purchase_date,
               item_lifecycle_dates.last_received_date]
      filters:
        inventory.total_sold_qty: "[1, 3]"
      sorts: [inventory.total_on_hand_cost desc]
      limit: 50
      listen:
        location: location_master.location_name
        department: item_master.department
        sales_date_range: inventory.date_part
      row: 25
      col: 0
      width: 24
      height: 9

    # ── Stock Value at Risk ──

    - title: "Dead Stock Value by Department"
      name: dead_stock_value
      model: "@{model_name}"
      explore: inventory
      type: looker_bar
      fields: [item_master.department, inventory.total_on_hand_cost]
      filters:
        inventory.total_sold_qty: "0"
      sorts: [inventory.total_on_hand_cost desc]
      limit: 15
      listen:
        location: location_master.location_name
        department: item_master.department
        sales_date_range: inventory.date_part
      row: 34
      col: 0
      width: 12
      height: 7

    - title: "Slow Moving Value by Department"
      name: slow_value
      model: "@{model_name}"
      explore: inventory
      type: looker_bar
      fields: [item_master.department, inventory.total_on_hand_cost]
      filters:
        inventory.total_sold_qty: "[1, 3]"
      sorts: [inventory.total_on_hand_cost desc]
      limit: 15
      listen:
        location: location_master.location_name
        department: item_master.department
        sales_date_range: inventory.date_part
      row: 34
      col: 12
      width: 12
      height: 7
