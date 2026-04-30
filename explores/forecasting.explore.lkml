include: "/views/operational/forecasting.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"

# ══════════════════════════════════════════════════════════════
# FORECASTING & BUDGET - Sales/GM/UPT/ATV forecast vs budget
# Grain: location × date × hierarchy depth
# Always filter to a single Path Level Depth to avoid double-counting.
# ══════════════════════════════════════════════════════════════

explore: forecasting {
  label: "Forecasting & Budget"
  description: "Forecast and budget figures (Sales, GM, UPT, ATV) by location and date. Filter to a single Path Level Depth — values are stored at multiple hierarchy levels and will double-count otherwise."
  group_label: "Forecasting"

  persist_with: daily_refresh

  always_filter: {
    filters: [
      forecasting.forecast_date: "this fiscal year",
      forecasting.path_level_depth: ""
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

  # ── Dim Location (bi_star - provides franchise fields + RLS) ──
  join: dim_location_franchise {
    view_label: "User Access"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecasting.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Retail Calendar (bi_star - full calendar dimension) ──
  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecasting.date_key} = ${dim_calendar.date_key} ;;
  }
}
