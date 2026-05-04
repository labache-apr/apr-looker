include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# LEDGER - General Ledger View (unified GL entries)
# ══════════════════════════════════════════════════════════════

view: ledger {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct]
  sql_table_name: `@{schema_name}.external_datamart_1.Ledger_view` ;;

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use posted_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── ledger STRUCT: Operational Dates ──

  dimension_group: posted_date {
    group_label: "Posted Date"
    label: "Posted"
    description: "Datetime the source document was posted to the general ledger"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: datetime
    sql: ${TABLE}.ledger.DocumentDateTime ;;
  }

  dimension_group: fiscal_date {
    group_label: "Fiscal Date"
    label: "Fiscal"
    description: "Fiscal date assigned to the ledger entry (may differ from posted date)"
    type: time
    timeframes: [raw, date, day_of_week, day_of_month, week, week_of_year, month, month_name, month_num, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.ledger.FiscalDate ;;
  }

  # ── Audit (record-level timestamps for ETL/diagnostics) ──

  dimension_group: dependencies_rec_modified {
    group_label: "Audit"
    label: "Dependencies Modified"
    description: "Latest modification timestamp across joined STRUCT dependencies"
    type: time
    timeframes: [raw, date, time]
    datatype: timestamp
    hidden: yes
    sql: ${TABLE}.DependenciesRecModified ;;
  }

  # ── ledger STRUCT ──

  dimension: ledger_id {
    primary_key: yes
    group_label: "Ledger"
    description: "Unique identifier for a single ledger line. Primary key of this view."
    type: string
    sql: ${TABLE}.ledger.LedgerId ;;
  }

  dimension: document_type {
    group_label: "Ledger"
    description: "Type of source document the ledger entry was generated from (e.g. sale, purchase, transfer, adjustment)."
    type: string
    sql: ${TABLE}.ledger.DocumentType ;;
  }

  dimension: document_no {
    group_label: "Ledger"
    label: "Document Number"
    description: "Source document number — combine with Document Type to look up the originating transaction."
    type: string
    sql: ${TABLE}.ledger.DocumentNo ;;
  }

  # ── Measures ──

  measure: total_ledger_qty {
    description: "Total unit quantity across ledger lines. Signed — sales out are negative, receipts in are positive."
    type: sum
    sql: ${TABLE}.ledger.Qty ;;
    value_format_name: decimal_0
  }

  measure: total_ledger_cost {
    description: "Total cost amount across ledger lines. USD."
    type: sum
    sql: ${TABLE}.ledger.CostAmt ;;
    value_format_name: usd
  }

  measure: total_ledger_net_sales {
    description: "Total net sales amount on ledger lines (zero for non-sales document types). USD."
    type: sum
    sql: ${TABLE}.ledger.NetSalesAmt ;;
    value_format_name: usd
  }

  measure: total_ledger_discount {
    description: "Total sales discount amount on ledger lines. USD."
    type: sum
    sql: ${TABLE}.ledger.SalesDiscountAmount ;;
    value_format_name: usd
  }

  measure: ledger_entry_count {
    description: "Count of ledger lines."
    type: count
  }
}