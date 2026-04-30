view: retail_calendar {
  extension: required  # Cannot be used standalone - must be extended

  # ══════════════════════════════════════════════════
  # SETS
  # ══════════════════════════════════════════════════
  # Every field in this struct that is also exposed by the dim_calendar
  # bi_star view. Explores that join dim_calendar (e.g. sales_receipt)
  # should exclude this set so users see only one copy of each calendar
  # field in the picker. date_key is intentionally NOT in this set —
  # it's the join key.
  set: dim_calendar_duplicates {
    fields: [
      calendar_date_raw,
      calendar_date_date,
      calendar_date_day_of_week,
      calendar_date_week,
      calendar_date_month,
      calendar_date_month_name,
      calendar_date_quarter,
      calendar_date_year,
      date_name,
      day_of_week_no,
      day_of_week,
      calendar_month,
      calendar_month_no,
      calendar_month_desc,
      calendar_year,
      retail_date,
      retail_day_of_week,
      retail_week,
      retail_week_no,
      retail_week_desc,
      retail_month,
      retail_month_no,
      retail_month_short,
      retail_month_desc,
      retail_quarter,
      retail_quarter_no,
      retail_quarter_desc,
      retail_year,
      ly_date_key
    ]
  }

  # ══════════════════════════════════════════════════
  # DATE KEY
  # ══════════════════════════════════════════════════

  dimension: date_key {
    group_label: "Retail Calendar"
    description: "INT64 surrogate date key (YYYYMMDD format). Use for joining the transaction's date to dim_calendar."
    type: number
    sql: ${TABLE}.retailcalendar.DateKey ;;
  }

  dimension_group: calendar_date {
    group_label: "Calendar Date"
    description: "Standard (Gregorian) calendar date denormalized onto the transaction line. Use the retail fields below for retail-aligned reporting."
    type: time
    timeframes: [raw, date, day_of_week, week, month, month_name, quarter, year]
    sql: ${TABLE}.retailcalendar.Date ;;
  }

  dimension: date_name {
    group_label: "Calendar Date"
    description: "Human-readable date string (e.g. 'Mar 15, 2026')."
    type: string
    sql: ${TABLE}.retailcalendar.DateName ;;
  }

  # ══════════════════════════════════════════════════
  # CALENDAR DATE COMPONENTS
  # ══════════════════════════════════════════════════

  dimension: day_of_week_no {
    group_label: "Calendar Date"
    type: number
    sql: ${TABLE}.retailcalendar.DayOfWeekNo ;;
    hidden: yes
  }

  dimension: day_of_week {
    group_label: "Calendar Date"
    description: "Day of week as a name (Monday, Tuesday, ...). Sorted by day-of-week number."
    type: string
    sql: ${TABLE}.retailcalendar.DayOfWeek ;;
    order_by_field: day_of_week_no
  }

  dimension: calendar_month {
    group_label: "Calendar Date"
    description: "Calendar month name."
    type: number
    sql: ${TABLE}.retailcalendar.Month ;;
  }

  dimension: calendar_month_no {
    group_label: "Calendar Date"
    type: number
    sql: ${TABLE}.retailcalendar.MonthNo ;;
    hidden: yes
  }

  dimension: calendar_month_desc {
    group_label: "Calendar Date"
    description: "Human-readable calendar month with year (e.g. 'March 2026')."
    type: string
    sql: ${TABLE}.retailcalendar.MonthDesc ;;
    order_by_field: calendar_month_no
  }

  dimension: calendar_year {
    group_label: "Calendar Date"
    description: "Calendar year (e.g. 2026)."
    type: number
    sql: ${TABLE}.retailcalendar.Year ;;
  }

  # ══════════════════════════════════════════════════
  # RETAIL CALENDAR
  # ══════════════════════════════════════════════════

  dimension: retail_date {
    group_label: "Retail Calendar"
    description: "Synthetic date used to align prior retail years to the current one for like-for-like comparison (NRF 4-5-4 calendar)."
    type: date
    sql: ${TABLE}.retailcalendar.RetailDate_artificial ;;
  }

  dimension: retail_day_of_week {
    group_label: "Retail Calendar"
    description: "Day of week within the retail calendar."
    type: number
    sql: ${TABLE}.retailcalendar.RetailDayOfWeek ;;
  }

  # ── Retail Week ──

  dimension: retail_week {
    group_label: "Retail Calendar"
    description: "Retail week number relative to the retail year."
    type: number
    sql: ${TABLE}.retailcalendar.RetailWeek ;;
  }

  dimension: retail_week_no {
    group_label: "Retail Calendar"
    type: number
    sql: ${TABLE}.retailcalendar.RetailWeekNo ;;
    hidden: yes
  }

  dimension: retail_week_desc {
    group_label: "Retail Calendar"
    description: "Human-readable retail week (e.g. 'Wk 8 (Feb 22-28, 2026)'). Sorted by retail week number."
    type: string
    sql: ${TABLE}.retailcalendar.RetailWeekDesc ;;
    order_by_field: retail_week_no
  }

  # ── Retail Month ──

  dimension: retail_month {
    group_label: "Retail Calendar"
    description: "Retail month name."
    type: number
    sql: ${TABLE}.retailcalendar.RetailMonth ;;
  }

  dimension: retail_month_no {
    group_label: "Retail Calendar"
    type: number
    sql: ${TABLE}.retailcalendar.RetailMonthNo ;;
    hidden: yes
  }

  dimension: retail_month_short {
    group_label: "Retail Calendar"
    description: "Short retail month label (e.g. 'Feb')."
    type: string
    sql: ${TABLE}.retailcalendar.RetailMonthShort ;;
    order_by_field: retail_month_no
  }

  dimension: retail_month_desc {
    group_label: "Retail Calendar"
    description: "Human-readable retail month with year (e.g. 'Feb 2026')."
    type: string
    sql: ${TABLE}.retailcalendar.RetailMonthDesc ;;
    order_by_field: retail_month_no
  }

  # ── Retail Quarter ──

  dimension: retail_quarter {
    group_label: "Retail Calendar"
    description: "Retail quarter (1-4)."
    type: number
    sql: ${TABLE}.retailcalendar.RetailQuarter ;;
  }

  dimension: retail_quarter_no {
    group_label: "Retail Calendar"
    type: number
    sql: ${TABLE}.retailcalendar.RetailQuarterNo ;;
    hidden: yes
  }

  dimension: retail_quarter_desc {
    group_label: "Retail Calendar"
    description: "Human-readable retail quarter (e.g. 'Q1 2026')."
    type: string
    sql: ${TABLE}.retailcalendar.RetailQuarterDesc ;;
    order_by_field: retail_quarter_no
  }

  # ── Retail Year ──

  dimension: retail_year {
    group_label: "Retail Calendar"
    description: "Retail (NRF) year — does not necessarily align to calendar year boundaries."
    type: number
    sql: ${TABLE}.retailcalendar.RetailYear ;;
  }

  # ══════════════════════════════════════════════════
  # YEAR-OVER-YEAR SUPPORT
  # ══════════════════════════════════════════════════

  dimension: ly_date_key {
    group_label: "Year-over-Year"
    label: "LY Date Key"
    description: "Last year comparable date key for YoY analysis (retail calendar aligned)"
    type: number
    sql: ${TABLE}.retailcalendar.LYDateKey ;;
  }
}
