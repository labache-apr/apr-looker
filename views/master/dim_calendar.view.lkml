# ══════════════════════════════════════════════════════════════
# DIM CALENDAR - Retail calendar dimension from bi_star
# Maps standard calendar dates to the retail (4-5-4) calendar.
# Provides retail week, month, quarter, and year breakdowns
# plus last-year / next-year date keys for period comparison.
# ══════════════════════════════════════════════════════════════

view: dim_calendar {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view` ;;

  # ── Primary Key ──

  dimension: date_key {
    primary_key: yes
    hidden: yes
    type: number
    sql: ${TABLE}.DateKey ;;
    description: "INT64 surrogate key (YYYYMMDD format) - use for joins"
  }

  # ── Calendar Date ──

  dimension_group: calendar {
    group_label: "Calendar Date"
    description: "Standard (Gregorian) calendar date. Use the retail calendar fields for retail-aligned reporting."
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    convert_tz: no
    datatype: date
    sql: ${TABLE}.Date ;;
  }

  dimension: date_name {
    group_label: "Calendar Date"
    label: "Date Name"
    description: "Human-readable date string (e.g. 'Mar 15, 2026')."
    type: string
    sql: ${TABLE}.DateName ;;
  }

  dimension: day_of_week_no {
    group_label: "Calendar Date"
    label: "Day of Week Number"
    description: "Day of week as a number (1-7). See source for which day = 1."
    type: number
    sql: ${TABLE}.DayOfWeekNo ;;
  }

  dimension: day_of_week {
    group_label: "Calendar Date"
    label: "Day of Week"
    description: "Day of week as a name (Monday, Tuesday, ...)."
    type: string
    sql: ${TABLE}.DayOfWeek ;;
  }

  # ── Calendar Period ──

  dimension: month {
    group_label: "Calendar Period"
    label: "Month"
    description: "Calendar month name (e.g. March)."
    type: number
    sql: ${TABLE}.Month ;;
  }

  dimension: month_no {
    group_label: "Calendar Period"
    label: "Month Number"
    description: "Calendar month number (1-12)."
    type: number
    sql: ${TABLE}.MonthNo ;;
  }

  dimension: month_desc {
    group_label: "Calendar Period"
    label: "Month Description"
    description: "Calendar month with year (e.g. 'March 2026')."
    type: string
    sql: ${TABLE}.MonthDesc ;;
  }

  dimension: year {
    group_label: "Calendar Period"
    label: "Year"
    description: "Calendar year (e.g. 2026)."
    type: number
    sql: ${TABLE}.Year ;;
  }

  # ── Retail Calendar ──

  dimension: retail_date_artificial {
    group_label: "Retail Calendar"
    label: "Retail Date (Artificial)"
    description: "Synthetic date used to align prior retail years to the current one for like-for-like comparison (NRF 4-5-4 calendar)."
    type: date
    convert_tz: no
    datatype: date
    sql: ${TABLE}.RetailDate_artificial ;;
  }

  dimension: retail_day_of_week {
    group_label: "Retail Calendar"
    label: "Retail Day of Week"
    description: "Day of week within the retail calendar (typically 1 = Sunday under NRF)."
    type: number
    sql: ${TABLE}.RetailDayOfWeek ;;
  }

  dimension: retail_week_id {
    group_label: "Retail Calendar"
    label: "Retail Week ID"
    description: "Stable identifier for a retail week (e.g. 2026W08). Use for week-level joins and last-year comparisons."
    type: string
    sql: ${TABLE}.RetailWeekId ;;
  }

  dimension: retail_week {
    group_label: "Retail Calendar"
    label: "Retail Week"
    description: "Retail week number relative to the retail year."
    type: number
    sql: ${TABLE}.RetailWeek ;;
  }

  dimension: retail_week_no {
    group_label: "Retail Calendar"
    label: "Retail Week Number"
    description: "Retail week number (1-52 or 1-53)."
    type: number
    sql: ${TABLE}.RetailWeekNo ;;
  }

  dimension: retail_week_desc {
    group_label: "Retail Calendar"
    label: "Retail Week Description"
    description: "Human-readable retail week (e.g. 'Wk 8 (Feb 22-28, 2026)')."
    type: string
    sql: ${TABLE}.RetailWeekDesc ;;
  }

  dimension: retail_month_week {
    group_label: "Retail Calendar"
    label: "Retail Month Week"
    description: "Week-of-month within the retail month under the 4-5-4 pattern (1-5)."
    type: number
    sql: ${TABLE}.RetailMonthWeek ;;
  }

  dimension: retail_month {
    group_label: "Retail Calendar"
    label: "Retail Month"
    description: "Retail month name."
    type: number
    sql: ${TABLE}.RetailMonth ;;
  }

  dimension: retail_month_short {
    group_label: "Retail Calendar"
    label: "Retail Month (Short)"
    description: "Short retail month label (e.g. 'Feb')."
    type: string
    sql: ${TABLE}.RetailMonthShort ;;
  }

  dimension: retail_month_no {
    group_label: "Retail Calendar"
    label: "Retail Month Number"
    description: "Retail month number (1-12)."
    type: number
    sql: ${TABLE}.RetailMonthNo ;;
  }

  dimension: retail_month_desc {
    group_label: "Retail Calendar"
    label: "Retail Month Description"
    description: "Human-readable retail month with year (e.g. 'Feb 2026')."
    type: string
    sql: ${TABLE}.RetailMonthDesc ;;
  }

  dimension: retail_quarter {
    group_label: "Retail Calendar"
    label: "Retail Quarter"
    description: "Retail quarter (1-4)."
    type: number
    sql: ${TABLE}.RetailQuarter ;;
  }

  dimension: retail_quarter_no {
    group_label: "Retail Calendar"
    label: "Retail Quarter Number"
    description: "Retail quarter number (1-4)."
    type: number
    sql: ${TABLE}.RetailQuarterNo ;;
  }

  dimension: retail_quarter_desc {
    group_label: "Retail Calendar"
    label: "Retail Quarter Description"
    description: "Human-readable retail quarter (e.g. 'Q1 2026')."
    type: string
    sql: ${TABLE}.RetailQuarterDesc ;;
  }

  dimension: retail_year {
    group_label: "Retail Calendar"
    label: "Retail Year"
    description: "Retail (NRF) year — does not necessarily align to calendar year boundaries."
    type: number
    sql: ${TABLE}.RetailYear ;;
  }

  # ── Period Comparison ──

  dimension: ly_date_key {
    group_label: "Period Comparison"
    hidden: yes
    label: "Last Year Date Key"
    type: number
    sql: ${TABLE}.LYDateKey ;;
    description: "Last year's equivalent date key - use for LY joins"
  }

  dimension: ny_date_key {
    group_label: "Period Comparison"
    hidden: yes
    label: "Next Year Date Key"
    type: number
    sql: ${TABLE}.NYDateKey ;;
    description: "Next year's equivalent date key - use for NY joins"
  }

  # ── Current Period Filters ──

  dimension: is_current_retail_year {
    group_label: "Current Period Filters"
    label: "Is Current Retail Year"
    description: "Yes when the row falls in the current retail year (as of today). Use as a filter for 'YTD' style analyses."
    type: yesno
    sql: ${retail_year} = (
      SELECT MAX(RetailYear)
      FROM `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view`
      WHERE Date <= CURRENT_DATE()
    ) ;;
  }

  dimension: is_current_retail_month {
    group_label: "Current Period Filters"
    label: "Is Current Retail Month"
    description: "Yes when the row falls in the current retail month (as of today). Use as a filter for 'MTD' style analyses."
    type: yesno
    sql: ${retail_year} = (
      SELECT MAX(RetailYear)
      FROM `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view`
      WHERE Date <= CURRENT_DATE()
    )
    AND ${retail_month_no} = (
      SELECT MAX(RetailMonthNo)
      FROM `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view`
      WHERE Date <= CURRENT_DATE()
        AND RetailYear = (
          SELECT MAX(RetailYear)
          FROM `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view`
          WHERE Date <= CURRENT_DATE()
        )
    ) ;;
  }

  dimension: is_current_retail_week {
    group_label: "Current Period Filters"
    label: "Is Current Retail Week"
    description: "Yes when the row falls in the current retail week (as of today). Use as a filter for 'WTD' style analyses."
    type: yesno
    sql: ${retail_week_id} = (
      SELECT MAX(RetailWeekId)
      FROM `aefc-prod-us-twc-b1bc.bi_star.dim_Calendar_view`
      WHERE Date <= CURRENT_DATE()
    ) ;;
  }

  # ── Measures ──

  measure: day_count {
    description: "Count of distinct calendar days. Use to size periods (e.g. days in retail month)."
    type: count
    drill_fields: [calendar_date, day_of_week, retail_week_desc, retail_month_desc, retail_year]
  }

  measure: distinct_date_count {
    type: count_distinct
    sql: ${TABLE}.Date ;;
    description: "Count of distinct calendar dates"
  }
}
