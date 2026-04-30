include: "/views/transactions/drawer_memo.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"
include: "/views/master/dim_employee.view.lkml"

# ══════════════════════════════════════════════════════════════
# CASH RECONCILIATION - Drawer audit / over-short variance
# Drives off drawer_memo_media (one row per drawer × tender) so
# that the system Amount, counted AuditedAmount, and Over/(Short)
# variance are first-class fields. Filters default to drawers
# that have actually been audited (AuditedAmount IS NOT NULL).
# ══════════════════════════════════════════════════════════════

explore: cash_reconciliation {
  from: drawer_memo_media
  view_name: drawer_memo_media
  label: "Cash Reconciliation"
  description: "Per-drawer, per-tender reconciliation. Compares system-expected drawer balances to counted amounts and surfaces over/short variance."
  group_label: "Operations"

  always_filter: {
    filters: [
      drawer_memo_media.audited_date: "last 90 days",
      drawer_memo_media.audited_amount: "NOT NULL"
    ]
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

  # ── Drawer header (gives status, lifecycle, location) ──
  join: drawer_memo {
    view_label: "Drawer Memo"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo_media.drawer_memo_id} = ${drawer_memo.drawer_memo_id} ;;
  }

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

  # ── Audit employee (who counted the drawer) ──
  join: dim_employee {
    view_label: "Audit Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${drawer_memo.audit_employee_id} = ${dim_employee.employee_id} ;;
  }

  # ── Paid in/out lines posted against the drawer ──
  join: drawer_memo_paid_in_out {
    view_label: "Paid In/Out"
    type: left_outer
    relationship: one_to_many
    sql_on: ${drawer_memo_media.drawer_memo_media_id} = ${drawer_memo_paid_in_out.drawer_memo_media_id} ;;
  }
}
