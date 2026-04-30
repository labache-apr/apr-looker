# ══════════════════════════════════════════════════════════════
# FORECAST VS ACTUALS - Daily forecast/budget vs actual sales
# Grain: date × location_id (one row per day per location)
#
# Forecast/Budget: rolled up from bi_star.append_window_dbo_Forecasting_view
#   filtered to MAX(PathLevelDepth) — assumed to be the leaf/location level.
#   ⚠️ If your hierarchy uses depth=0 for leaves, swap MAX → MIN in the CTE.
#
# Actuals: aggregated from external_datamart_1.SalesReceipt_view
#   (last 3 fiscal years to limit scan cost).
#
# UPT/ATV note: actual UPT/ATV are computed correctly as SUM(units|sales)
#   / SUM(transactions). Forecast/Budget UPT/ATV are stored as ratios
#   per row, so they're averaged across the selected grain (caveat applies).
# ══════════════════════════════════════════════════════════════

view: forecast_vs_actuals {
  derived_table: {
    datagroup_trigger: daily_refresh
    sql:
      WITH forecast_agg AS (
        SELECT
          DATE(CommonDate)              AS date,
          LocationId                    AS location_id,
          SUM(ForecastSales)            AS forecast_sales,
          SUM(ForecastGm)               AS forecast_gm,
          AVG(ForecastUpt)              AS forecast_upt,
          AVG(ForecastAtv)              AS forecast_atv,
          SUM(BudgetSales)              AS budget_sales,
          SUM(BudgetGm)                 AS budget_gm,
          AVG(BudgetUpt)                AS budget_upt,
          AVG(BudgetAtv)                AS budget_atv
        FROM `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_Forecasting_view`
        WHERE PathLevelDepth = (
          SELECT MAX(PathLevelDepth)
          FROM `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_Forecasting_view`
        )
        GROUP BY 1, 2
      ),
      actuals_agg AS (
        SELECT
          sr.Date_Part                                AS date,
          sr.location.LocationId                      AS location_id,
          SUM(sr.sale.NetSalesAmt)                    AS actual_sales,
          SUM(sr.sale.GrossSalesAmt)                  AS actual_gross_sales,
          SUM(sr.sale.MarginAmt)                      AS actual_gm,
          SUM(sr.sale.COGS)                           AS actual_cogs,
          SUM(sr.sale.Qty)                            AS actual_units,
          COUNT(DISTINCT sr.sale.UniversalNo)         AS actual_transactions
        FROM `aefc-prod-us-twc-b1bc.external_datamart_1.SalesReceipt_view` sr
        WHERE sr.location.LocationId IS NOT NULL
          AND sr.location.LocationId != ''
          AND sr.Date_Part >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 YEAR)
        GROUP BY 1, 2
      )
      SELECT
        COALESCE(f.date, a.date)                    AS date,
        COALESCE(f.location_id, a.location_id)      AS location_id,
        CAST(FORMAT_DATE('%Y%m%d', COALESCE(f.date, a.date)) AS INT64) AS date_key,
        f.forecast_sales,
        f.forecast_gm,
        f.forecast_upt,
        f.forecast_atv,
        f.budget_sales,
        f.budget_gm,
        f.budget_upt,
        f.budget_atv,
        a.actual_sales,
        a.actual_gross_sales,
        a.actual_gm,
        a.actual_cogs,
        a.actual_units,
        a.actual_transactions
      FROM forecast_agg f
      FULL OUTER JOIN actuals_agg a
        ON f.date = a.date
        AND f.location_id = a.location_id
    ;;
  }

  # ── Identifiers ──

  dimension: pk {
    primary_key: yes
    hidden: yes
    type: string
    sql: CONCAT(CAST(${TABLE}.date AS STRING), '|', ${TABLE}.location_id) ;;
  }

  dimension: location_id {
    hidden: yes
    type: string
    sql: ${TABLE}.location_id ;;
  }

  dimension: date_key {
    hidden: yes
    type: number
    sql: ${TABLE}.date_key ;;
    description: "INT64 surrogate date key (YYYYMMDD) - use to join dim_calendar"
  }

  # ── Date ──

  dimension_group: business {
    label: "Business"
    description: "Business date — the day actual sales were rung up and forecast/budget rows are aligned to."
    type: time
    timeframes: [raw, date, week, month, quarter, year, fiscal_quarter, fiscal_year]
    # timeframes: [raw, date, week, month, quarter, year, fiscal_month, fiscal_quarter, fiscal_year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.date ;;
  }

  # ══════════════════════════════════════════════════
  # ACTUAL MEASURES
  # ══════════════════════════════════════════════════

  measure: actual_sales {
    group_label: "Actual"
    label: "Sales"
    description: "Actual net sales from sales receipts. Net of discounts and returns. USD."
    type: sum
    sql: ${TABLE}.actual_sales ;;
    value_format_name: usd
  }

  measure: actual_gross_sales {
    group_label: "Actual"
    label: "Gross Sales"
    description: "Actual gross sales (pre-discount, pre-return netting). USD."
    type: sum
    sql: ${TABLE}.actual_gross_sales ;;
    value_format_name: usd
  }

  measure: actual_gm {
    group_label: "Actual"
    label: "GM ($)"
    description: "Actual gross margin dollars (Net Sales − COGS). USD."
    type: sum
    sql: ${TABLE}.actual_gm ;;
    value_format_name: usd
  }

  measure: actual_gm_pct {
    group_label: "Actual"
    label: "GM %"
    description: "Actual gross margin percentage (Actual GM / Actual Sales)."
    type: number
    sql: SAFE_DIVIDE(${actual_gm}, ${actual_sales}) ;;
    value_format_name: percent_1
  }

  measure: actual_units {
    group_label: "Actual"
    label: "Units"
    description: "Total actual units sold (net of returns)."
    type: sum
    sql: ${TABLE}.actual_units ;;
    value_format_name: decimal_0
  }

  measure: actual_transactions {
    group_label: "Actual"
    label: "Transactions"
    type: sum
    sql: ${TABLE}.actual_transactions ;;
    value_format_name: decimal_0
    description: "Distinct receipts. Note: counted within each (date, location) row, then summed — small overcount possible for receipts spanning a date×location boundary, which is rare."
  }

  measure: actual_upt {
    group_label: "Actual"
    label: "UPT"
    type: number
    sql: SAFE_DIVIDE(${actual_units}, ${actual_transactions}) ;;
    value_format_name: decimal_2
    description: "Units per transaction = SUM(units) / SUM(transactions)."
  }

  measure: actual_atv {
    group_label: "Actual"
    label: "ATV"
    type: number
    sql: SAFE_DIVIDE(${actual_sales}, ${actual_transactions}) ;;
    value_format_name: usd
    description: "Average transaction value = SUM(net sales) / SUM(transactions)."
  }

  # ══════════════════════════════════════════════════
  # FORECAST MEASURES
  # ══════════════════════════════════════════════════

  measure: forecast_sales {
    group_label: "Forecast"
    label: "Sales"
    description: "Forecasted net sales for the business date and location. USD."
    type: sum
    sql: ${TABLE}.forecast_sales ;;
    value_format_name: usd
  }

  measure: forecast_gm {
    group_label: "Forecast"
    label: "GM ($)"
    description: "Forecasted gross margin dollars. USD."
    type: sum
    sql: ${TABLE}.forecast_gm ;;
    value_format_name: usd
  }

  measure: forecast_gm_pct {
    group_label: "Forecast"
    label: "GM %"
    description: "Forecasted gross margin percentage (Forecast GM / Forecast Sales)."
    type: number
    sql: SAFE_DIVIDE(${forecast_gm}, ${forecast_sales}) ;;
    value_format_name: percent_1
  }

  measure: forecast_upt {
    group_label: "Forecast"
    label: "UPT"
    type: average
    sql: ${TABLE}.forecast_upt ;;
    value_format_name: decimal_2
    description: "Forecast units per transaction (average across selected rows — UPT is a ratio)."
  }

  measure: forecast_atv {
    group_label: "Forecast"
    label: "ATV"
    type: average
    sql: ${TABLE}.forecast_atv ;;
    value_format_name: usd
    description: "Forecast average transaction value (average across selected rows — ATV is a ratio)."
  }

  # ══════════════════════════════════════════════════
  # BUDGET MEASURES
  # ══════════════════════════════════════════════════

  measure: budget_sales {
    group_label: "Budget"
    label: "Sales"
    description: "Budgeted net sales for the business date and location. USD."
    type: sum
    sql: ${TABLE}.budget_sales ;;
    value_format_name: usd
  }

  measure: budget_gm {
    group_label: "Budget"
    label: "GM ($)"
    description: "Budgeted gross margin dollars. USD."
    type: sum
    sql: ${TABLE}.budget_gm ;;
    value_format_name: usd
  }

  measure: budget_gm_pct {
    group_label: "Budget"
    label: "GM %"
    description: "Budgeted gross margin percentage (Budget GM / Budget Sales)."
    type: number
    sql: SAFE_DIVIDE(${budget_gm}, ${budget_sales}) ;;
    value_format_name: percent_1
  }

  measure: budget_upt {
    group_label: "Budget"
    label: "UPT"
    type: average
    sql: ${TABLE}.budget_upt ;;
    value_format_name: decimal_2
    description: "Budget units per transaction (average across selected rows — UPT is a ratio)."
  }

  measure: budget_atv {
    group_label: "Budget"
    label: "ATV"
    type: average
    sql: ${TABLE}.budget_atv ;;
    value_format_name: usd
    description: "Budget average transaction value (average across selected rows — ATV is a ratio)."
  }

  # ══════════════════════════════════════════════════
  # VARIANCE: ACTUAL vs FORECAST
  # ══════════════════════════════════════════════════

  measure: actual_vs_forecast_sales {
    group_label: "Variance (Actual vs Forecast)"
    label: "Sales ($)"
    description: "Actual Sales minus Forecast Sales. Positive = beat forecast. USD."
    type: number
    sql: ${actual_sales} - ${forecast_sales} ;;
    value_format_name: usd
  }

  measure: actual_vs_forecast_sales_pct {
    group_label: "Variance (Actual vs Forecast)"
    label: "Sales (%)"
    description: "Actual vs Forecast sales variance as a share of forecast ((Actual − Forecast) / Forecast)."
    type: number
    sql: SAFE_DIVIDE(${actual_sales} - ${forecast_sales}, NULLIF(${forecast_sales}, 0)) ;;
    value_format_name: percent_1
  }

  measure: forecast_attainment_sales {
    group_label: "Variance (Actual vs Forecast)"
    label: "Sales Attainment (%)"
    type: number
    sql: SAFE_DIVIDE(${actual_sales}, NULLIF(${forecast_sales}, 0)) ;;
    value_format_name: percent_1
    description: "Actual / Forecast. >100% = beat forecast."
  }

  measure: actual_vs_forecast_gm {
    group_label: "Variance (Actual vs Forecast)"
    label: "GM ($)"
    description: "Actual GM minus Forecast GM. Positive = margin beat forecast. USD."
    type: number
    sql: ${actual_gm} - ${forecast_gm} ;;
    value_format_name: usd
  }

  measure: actual_vs_forecast_gm_pct {
    group_label: "Variance (Actual vs Forecast)"
    label: "GM (%)"
    description: "Actual vs Forecast GM variance as a share of forecast ((Actual GM − Forecast GM) / Forecast GM)."
    type: number
    sql: SAFE_DIVIDE(${actual_gm} - ${forecast_gm}, NULLIF(${forecast_gm}, 0)) ;;
    value_format_name: percent_1
  }

  # ══════════════════════════════════════════════════
  # VARIANCE: ACTUAL vs BUDGET
  # ══════════════════════════════════════════════════

  measure: actual_vs_budget_sales {
    group_label: "Variance (Actual vs Budget)"
    label: "Sales ($)"
    description: "Actual Sales minus Budget Sales. Positive = beat plan. USD."
    type: number
    sql: ${actual_sales} - ${budget_sales} ;;
    value_format_name: usd
  }

  measure: actual_vs_budget_sales_pct {
    group_label: "Variance (Actual vs Budget)"
    label: "Sales (%)"
    description: "Actual vs Budget sales variance as a share of budget ((Actual − Budget) / Budget)."
    type: number
    sql: SAFE_DIVIDE(${actual_sales} - ${budget_sales}, NULLIF(${budget_sales}, 0)) ;;
    value_format_name: percent_1
  }

  measure: budget_attainment_sales {
    group_label: "Variance (Actual vs Budget)"
    label: "Sales Attainment (%)"
    type: number
    sql: SAFE_DIVIDE(${actual_sales}, NULLIF(${budget_sales}, 0)) ;;
    value_format_name: percent_1
    description: "Actual / Budget. >100% = beat budget."
  }

  measure: actual_vs_budget_gm {
    group_label: "Variance (Actual vs Budget)"
    label: "GM ($)"
    description: "Actual GM minus Budget GM. Positive = margin beat plan. USD."
    type: number
    sql: ${actual_gm} - ${budget_gm} ;;
    value_format_name: usd
  }

  measure: actual_vs_budget_gm_pct {
    group_label: "Variance (Actual vs Budget)"
    label: "GM (%)"
    description: "Actual vs Budget GM variance as a share of budget ((Actual GM − Budget GM) / Budget GM)."
    type: number
    sql: SAFE_DIVIDE(${actual_gm} - ${budget_gm}, NULLIF(${budget_gm}, 0)) ;;
    value_format_name: percent_1
  }

  measure: row_count {
    hidden: yes
    type: count
  }
}
