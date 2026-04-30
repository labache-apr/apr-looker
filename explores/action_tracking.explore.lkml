include: "/views/operational/action_tracking.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"
include: "/views/master/dim_employee.view.lkml"

# ══════════════════════════════════════════════════════════════
# ACTION TRACKING - System / user audit trail
# Each row = one tracked action at the POS or back office.
# ══════════════════════════════════════════════════════════════

explore: action_tracking {
  label: "Action Tracking"
  description: "Audit log of POS and back-office actions (logins, voids, drawer events, document changes)."
  group_label: "Operations"

  always_filter: {
    filters: [action_tracking.action_at_date: "last 30 days"]
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
    sql_on: ${action_tracking.location_id} = ${dim_location_franchise.location_id} ;;
  }

  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${action_tracking.action_date_key} = ${dim_calendar.date_key} ;;
  }

  join: dim_employee {
    view_label: "Employee"
    type: left_outer
    relationship: many_to_one
    sql_on: ${action_tracking.employee_id} = ${dim_employee.employee_id} ;;
  }
}
