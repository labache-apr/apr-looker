# ══════════════════════════════════════════════════════════════
# FORECASTING - Sales/GM/UPT/ATV forecast and budget by location
# Source: bi_star.append_window_dbo_Forecasting_view
# Grain: LocationId × CommonDate × PathLevelDepth
# IMPORTANT: PathLevelDepth represents a hierarchy level — values
# are duplicated across levels. Filter to a single PathLevelDepth
# before summing to avoid double-counting.
# ══════════════════════════════════════════════════════════════

view: forecasting {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_Forecasting_view` ;;

  # ── Primary Key ──

  dimension: forecasting_id {
    primary_key: yes
    hidden: yes
    type: string
    sql: ${TABLE}.ForecastingId ;;
  }

  # ── Foreign Keys ──

  dimension: location_id {
    hidden: yes
    type: string
    sql: ${TABLE}.LocationId ;;
  }

  dimension: date_key {
    hidden: yes
    type: number
    sql: CAST(FORMAT_DATE('%Y%m%d', DATE(${TABLE}.CommonDate)) AS INT64) ;;
    description: "INT64 surrogate date key (YYYYMMDD) derived from CommonDate - use to join dim_calendar"
  }

  # ── Hierarchy ──

  dimension: path_level_depth {
    label: "Path Level Depth"
    type: number
    sql: ${TABLE}.PathLevelDepth ;;
    description: "Location-hierarchy depth. Forecast values are stored at multiple aggregation levels — filter to a single value before summing measures."
  }

  # ── Forecast Date ──

  dimension_group: forecast {
    label: "Forecast"
    description: "Forecast period date — the day the forecast/budget value applies to. Use weekly/monthly timeframes for retail planning."
    type: time
    timeframes: [raw, date, week, month, quarter, year, fiscal_month, fiscal_quarter, fiscal_year]
    convert_tz: no
    datatype: timestamp
    sql: ${TABLE}.CommonDate ;;
  }

  dimension: date_part {
    hidden: yes
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

  # ── Audit ──

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp the record was created in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.RecCreated ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp the record was last modified in the source system"
    type: time
    timeframes: [raw, time, date, week, month, year]
    datatype: timestamp
    sql: ${TABLE}.RecModified ;;
  }

  dimension_group: streaming {
    group_label: "Audit"
    label: "Streaming"
    description: "Timestamp the record was ingested into BigQuery"
    type: time
    timeframes: [raw, date, time]
    datatype: timestamp
    hidden: yes
    sql: ${TABLE}.StreamingDate ;;
  }

  # ══════════════════════════════════════════════════
  # FORECAST MEASURES
  # ══════════════════════════════════════════════════

  measure: forecast_sales {
    group_label: "Forecast"
    label: "Forecast Sales"
    type: sum
    sql: ${TABLE}.ForecastSales ;;
    value_format_name: usd
    description: "Forecast net sales. Filter to a single Path Level Depth before summing."
  }

  measure: forecast_gm {
    group_label: "Forecast"
    label: "Forecast GM ($)"
    type: sum
    sql: ${TABLE}.ForecastGm ;;
    value_format_name: usd
    description: "Forecast gross margin dollars. Filter to a single Path Level Depth before summing."
  }

  measure: forecast_gm_pct {
    group_label: "Forecast"
    label: "Forecast GM %"
    description: "Forecast gross margin percentage (Forecast GM / Forecast Sales)."
    type: number
    sql: SAFE_DIVIDE(${forecast_gm}, ${forecast_sales}) ;;
    value_format_name: percent_1
  }

  measure: forecast_upt {
    group_label: "Forecast"
    label: "Forecast UPT"
    type: average
    sql: ${TABLE}.ForecastUpt ;;
    value_format_name: decimal_2
    description: "Forecast units per transaction. Averaged across selected rows — UPT is a ratio, not additive."
  }

  measure: forecast_atv {
    group_label: "Forecast"
    label: "Forecast ATV"
    type: average
    sql: ${TABLE}.ForecastAtv ;;
    value_format_name: usd
    description: "Forecast average transaction value. Averaged across selected rows — ATV is a ratio, not additive."
  }

  # ══════════════════════════════════════════════════
  # BUDGET MEASURES
  # ══════════════════════════════════════════════════

  measure: budget_sales {
    group_label: "Budget"
    label: "Budget Sales"
    type: sum
    sql: ${TABLE}.BudgetSales ;;
    value_format_name: usd
    description: "Budgeted net sales. Filter to a single Path Level Depth before summing."
  }

  measure: budget_gm {
    group_label: "Budget"
    label: "Budget GM ($)"
    type: sum
    sql: ${TABLE}.BudgetGm ;;
    value_format_name: usd
    description: "Budgeted gross margin dollars. Filter to a single Path Level Depth before summing."
  }

  measure: budget_gm_pct {
    group_label: "Budget"
    label: "Budget GM %"
    description: "Budgeted gross margin percentage (Budget GM / Budget Sales)."
    type: number
    sql: SAFE_DIVIDE(${budget_gm}, ${budget_sales}) ;;
    value_format_name: percent_1
  }

  measure: budget_upt {
    group_label: "Budget"
    label: "Budget UPT"
    type: average
    sql: ${TABLE}.BudgetUpt ;;
    value_format_name: decimal_2
    description: "Budgeted units per transaction. Averaged across selected rows — UPT is a ratio, not additive."
  }

  measure: budget_atv {
    group_label: "Budget"
    label: "Budget ATV"
    type: average
    sql: ${TABLE}.BudgetAtv ;;
    value_format_name: usd
    description: "Budgeted average transaction value. Averaged across selected rows — ATV is a ratio, not additive."
  }

  # ══════════════════════════════════════════════════
  # VARIANCE MEASURES (Forecast vs Budget)
  # ══════════════════════════════════════════════════

  measure: forecast_vs_budget_sales {
    group_label: "Variance (Forecast vs Budget)"
    label: "Sales Variance ($)"
    description: "Forecast Sales minus Budget Sales. Positive = forecast is above plan. USD."
    type: number
    sql: ${forecast_sales} - ${budget_sales} ;;
    value_format_name: usd
  }

  measure: forecast_vs_budget_sales_pct {
    group_label: "Variance (Forecast vs Budget)"
    label: "Sales Variance (%)"
    description: "Sales variance as a share of budget ((Forecast − Budget) / Budget)."
    type: number
    sql: SAFE_DIVIDE(${forecast_sales} - ${budget_sales}, NULLIF(${budget_sales}, 0)) ;;
    value_format_name: percent_1
  }

  measure: forecast_vs_budget_gm {
    group_label: "Variance (Forecast vs Budget)"
    label: "GM Variance ($)"
    description: "Forecast GM minus Budget GM. Positive = forecast margin above plan. USD."
    type: number
    sql: ${forecast_gm} - ${budget_gm} ;;
    value_format_name: usd
  }

  measure: forecast_vs_budget_gm_pct {
    group_label: "Variance (Forecast vs Budget)"
    label: "GM Variance (%)"
    description: "GM variance as a share of budgeted GM ((Forecast GM − Budget GM) / Budget GM)."
    type: number
    sql: SAFE_DIVIDE(${forecast_gm} - ${budget_gm}, NULLIF(${budget_gm}, 0)) ;;
    value_format_name: percent_1
  }

  measure: row_count {
    hidden: yes
    type: count
  }
}
