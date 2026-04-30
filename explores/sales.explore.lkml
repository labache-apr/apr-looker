include: "/views/transactions/sales_receipt.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"
include: "/views/master/dim_employee.view.lkml"
include: "/views/operational/item_lifecycle_dates.view.lkml"
include: "/views/operational/location_availability.view.lkml"
include: "/views/operational/inventory.view.lkml"

# ══════════════════════════════════════════════════════════════
# SALES RECEIPTS - Primary POS sales analysis
# ══════════════════════════════════════════════════════════════

explore: sales_receipt {
  label: "Sales Receipts"
  description: "POS transaction data at the receipt line level. Each row represents one item sold on a receipt."
  group_label: "Sales"

  # Hide the calendar/retail-calendar fields that the sales_receipt view
  # inherits from the retail_calendar struct, since dim_calendar (joined
  # below) is the canonical source in this explore. Set is defined in
  # retail_calendar.view.lkml. date_key remains exposed — it's the join key.
  fields: [ALL_FIELDS*, -sales_receipt.dim_calendar_duplicates*]

  persist_with: daily_refresh

  always_filter: {
    filters: [sales_receipt.date_part: "last 90 days"]
  }

  sql_always_where:
    {% if _user_attributes['dev_mode_bypass'] == 'yes' %}
      1=1
    {% else %}
      1=1
      AND
      {% if _user_attributes['location_code'] != 'any' and _user_attributes['location_code'] != '' %}
        ${dim_location_franchise.location_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["location_code"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
      AND
      {% if _user_attributes['franchise_codes'] != 'any' and _user_attributes['franchise_codes'] != '' %}
        ${dim_location_franchise.franchise_code_rls} IN UNNEST(SPLIT(LOWER('{{_user_attributes["franchise_codes"]}}'), ','))
      {% else %}
        1=1
      {% endif %}
    {% endif %}
  ;;

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Retail Calendar (bi_star - full calendar dimension) ──
  # The sales_receipt view also extends the retail_calendar struct, which
  # denormalizes the same fields onto each row. The struct duplicates are
  # excluded by the explore-level `fields:` parameter above (see set
  # `dim_calendar_duplicates` in retail_calendar.view.lkml) so the field
  # picker shows only one copy of each calendar field. dim_calendar is the
  # canonical source here — it adds retail_week_id, retail_month_week, and
  # the is_current_retail_* filters that the struct does not have.
  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.date_key} = ${dim_calendar.date_key} ;;
  }

  # ── Employee Master (bi_star - full employee dimension) ──
  join: dim_employee {
    view_label: "Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.employee_id} = ${dim_employee.employee_id} ;;
  }

  # ── Payments ARRAY (unnested - actual join needed) ──
  join: sales_receipt_payments {
    view_label: "Payments"
    type: left_outer
    relationship: one_to_many
    sql_on: ${sales_receipt.universal_no} = ${sales_receipt_payments.universal_no}
      AND ${sales_receipt.date_part} = ${sales_receipt_payments.date_part} ;;
  }

  # ── Item Lifecycle Dates (first/last sale, receipt, PO, transfer per item) ──
  join: item_lifecycle_dates {
    view_label: "Item Lifecycle Dates"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.item_id} = ${item_lifecycle_dates.item_id} ;;
  }

  # ── Inventory Snapshot (point-in-time at sale: matches the receipt's
  # date_part to the daily inventory snapshot for that item × location).
  # Use these fields when you need on-hand / turn / GMROI / sell-through
  # *as of the day each item sold*. The join condition prunes the
  # inventory partition by date for performance. `fields:` excludes the
  # inventory view's pre-aggregated sold_* measures because those overlap
  # with sales_receipt's own sales totals — use sales_receipt for sales.
  join: inventory {
    view_label: "Inventory Snapshot (At Sale)"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.date_part} = ${inventory.date_part}
      AND ${sales_receipt.item_id} = ${inventory.item_id}
      AND ${sales_receipt.location_id} = ${inventory.location_id} ;;
    fields: [
      inventory.total_on_hand_qty,
      inventory.total_on_hand_cost,
      inventory.total_on_hand_retail,
      inventory.avg_unit_cost,
      inventory.avg_inventory_qty,
      inventory.avg_inventory_cost,
      inventory.avg_inventory_retail,
      inventory.inventory_turn_ratio,
      inventory.gmroi,
      inventory.weeks_of_supply,
      inventory.days_of_supply,
      inventory.sell_through_rate,
      inventory.out_of_stock_row_count,
      inventory.out_of_stock_rate,
      inventory.sku_location_count,
      inventory.sku_count,
      inventory.location_count
    ]
  }

  # ── Stock Availability (real-time ATS / OnHand at item × location) ──
  # Symmetric aggregates dedupe via location_availability.availability_pk,
  # so inventory measures are correct even when many receipt lines match.
  # `fields:` is restricted to measures — location_availability extends
  # item_struct + location_struct, and the inherited dimensions would
  # otherwise duplicate the ones already on sales_receipt.
  join: location_availability {
    view_label: "Stock Availability"
    type: left_outer
    relationship: many_to_one
    sql_on: ${sales_receipt.item_id} = ${location_availability.item_id}
      AND ${sales_receipt.location_id} = ${location_availability.location_id} ;;
    fields: [
      location_availability.total_on_hand,
      location_availability.total_ats,
      location_availability.total_committed,
      location_availability.total_reserved,
      location_availability.total_held,
      location_availability.total_damaged,
      location_availability.total_incoming,
      location_availability.sku_location_count,
      location_availability.stockout_count,
      location_availability.stockout_rate
    ]
  }
}
