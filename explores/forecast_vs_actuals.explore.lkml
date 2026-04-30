include: "/views/operational/forecast_vs_actuals.view.lkml"
include: "/views/master/dim_location_franchise.view.lkml"
include: "/views/master/dim_calendar.view.lkml"

# ══════════════════════════════════════════════════════════════
# FORECAST VS ACTUALS - Daily forecast/budget vs actual sales
# Grain: location × date
# Forecast aggregated at deepest PathLevelDepth (assumed = location).
# Actuals from external_datamart_1.SalesReceipt_view (last 3 fiscal years).
# ══════════════════════════════════════════════════════════════

explore: forecast_vs_actuals {
  label: "Forecast vs Actuals"
  description: "Daily comparison of actual sales/GM/UPT/ATV against forecast and budget at location grain. Use 'Variance' measure groups for gap and attainment metrics."
  group_label: "Forecasting"

  persist_with: daily_refresh

  always_filter: {
    filters: [forecast_vs_actuals.business_date: "this fiscal year"]
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
    sql_on: ${forecast_vs_actuals.location_id} = ${dim_location_franchise.location_id} ;;
  }

  # ── Retail Calendar (bi_star - full calendar dimension) ──
  join: dim_calendar {
    view_label: "Retail Calendar"
    type: left_outer
    relationship: many_to_one
    sql_on: ${forecast_vs_actuals.date_key} = ${dim_calendar.date_key} ;;
  }
}
