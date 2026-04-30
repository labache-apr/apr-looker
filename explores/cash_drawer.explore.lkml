include: "/views/transactions/drawer_memo.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"
include: "/views/master/dim_employee.view.lkml"

# ══════════════════════════════════════════════════════════════
# CASH DRAWERS - Drawer memo sessions (operations view)
# Operational view of drawer activity: opens, closes, paid in/out,
# tender totals, status history. For variance / over-short
# analysis, see the cash_reconciliation explore.
# ══════════════════════════════════════════════════════════════

explore: cash_drawer {
  from: drawer_memo
  view_name: drawer_memo
  label: "Cash Drawers"
  description: "Drawer memo sessions — open, close, paid in/out, tender totals, lifecycle. One row per drawer session."
  group_label: "Operations"

  always_filter: {
    filters: [drawer_memo.fiscal_date: "last 90 days"]
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

  join: dim_location_franchise {
    view_label: "Location"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.location_id} = ${dim_location_franchise.location_id} ;;
  }

  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.fiscal_date_key} = ${dim_calendar.date_key} ;;
  }

  join: dim_employee {
    view_label: "Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.employee_id} = ${dim_employee.employee_id} ;;
  }

  # ── Per-tender drawer media (one row per drawer × payment method) ──
  join: drawer_memo_media {
    view_label: "Drawer Media"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_media.drawer_memo_id} ;;
  }

  # ── Paid in / paid out / cash drop events ──
  join: drawer_memo_paid_in_out {
    view_label: "Paid In/Out"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_paid_in_out.drawer_memo_id} ;;
  }

  # ── Drawer-attributed receipt payments ──
  join: drawer_memo_payment {
    view_label: "Drawer Payments"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_payment.drawer_memo_id} ;;
  }

  # ── Status transitions (Open → Closed → Audited → Deposited) ──
  join: drawer_memo_status_history {
    view_label: "Status History"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo.drawer_memo_id} = ${drawer_memo_status_history.drawer_memo_id} ;;
  }
}
