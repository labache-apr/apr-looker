include: "/views/structs/item_struct.view.lkml"
include: "/views/structs/location_struct.view.lkml"
include: "/views/structs/customer_struct.view.lkml"
include: "/views/structs/employee_struct.view.lkml"
include: "/views/structs/retail_calendar.view.lkml"
include: "/views/custom_fields/item_custom_fields.view.lkml"
include: "/views/custom_fields/sale_custom_fields.view.lkml"
include: "/views/custom_fields/location_custom_fields.view.lkml"
include: "/views/custom_fields/customer_custom_fields.view.lkml"

# ══════════════════════════════════════════════════════════════
# SALES RECEIPT - Primary POS Transaction View
# Each row = one item line on a receipt
# ══════════════════════════════════════════════════════════════

view: sales_receipt {
  extends: [item_struct, item_style_custom_fields, item_sku_custom_fields, location_struct, location_custom_fields, customer_struct, customer_custom_fields, employee_struct, retail_calendar, sale_receipt_custom_fields, sale_line_custom_fields]
  sql_table_name: `aefc-prod-us-twc-b1bc.external_datamart_1.SalesReceipt_view` ;;

  # ── Top-Level Columns ──

  dimension: date_part {
    hidden: yes
    description: "BigQuery partition column. Hidden — use transacted_date for analysis. Kept for explore always_filter / partition pruning."
    type: date
    datatype: date
    sql: ${TABLE}.Date_Part ;;
  }

  # ── Sale STRUCT: Receipt Timestamp ──

  dimension_group: transacted_date {
    group_label: "Transacted Date"
    label: "Transacted"
    description: "Timestamp the receipt was rung up at the POS (sales, returns, and credit memos)"
    type: time
    timeframes: [
      raw,
      time,
      time_of_day,
      hour,
      hour_of_day,
      date,
      day_of_week,
      day_of_week_index,
      day_of_month,
      day_of_year,
      week,
      week_of_year,
      month,
      month_name,
      month_num,
      quarter,
      quarter_of_year,
      year
    ]
    datatype: timestamp
    sql: ${TABLE}.sale.ReceiptDateTime ;;
  }

  dimension_group: posted_date {
    group_label: "Posted Date"
    label: "Posted"
    description: "Timestamp the receipt was posted to the general ledger"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sale.LedgerPostingDate ;;
  }

  dimension_group: original_receipt_date {
    group_label: "Original Receipt Date"
    label: "Original Receipt"
    description: "For return receipts: timestamp of the original sale being returned (NULL on non-return lines)"
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, day_of_month, week, month, month_name, quarter, year]
    datatype: timestamp
    sql: ${TABLE}.sale.OriginalReceiptDate ;;
  }

  # ── Sale STRUCT: Identifiers ──

  dimension: document_line_id {
    primary_key: yes
    group_label: "Sale Identifiers"
    description: "Unique identifier for a single line on a receipt (one item sold). Primary key of this view."
    type: string
    sql: ${TABLE}.sale.DocumentLineId ;;
  }

  dimension: universal_no {
    group_label: "Sale Identifiers"
    label: "Universal Number"
    description: "Receipt-level identifier shared across all lines of the same transaction. Use this when counting receipts (Transaction Count). Click to drill into the Receipt Detail dashboard."
    type: number
    sql: ${TABLE}.sale.UniversalNo ;;
    value_format_name: id
    link: {
      label: "View Receipt Detail"
      url: "/dashboards/twc_aefc::receipt_detail?universal_no={{ value | url_encode }}{% if _filters['date_range'] %}&date_range={{ _filters['date_range'] | url_encode }}{% endif %}"
    }
  }

  dimension: receipt_no {
    group_label: "Sale Identifiers"
    label: "Receipt Number"
    description: "Store-issued receipt number printed on the customer copy. Not globally unique — combine with store/date for lookup."
    type: number
    sql: ${TABLE}.sale.ReceiptNo ;;
    value_format_name: id
  }

  # ── Sale STRUCT: Amounts ──

  dimension: net_sales_amt {
    group_label: "Sale Amounts"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.NetSalesAmt ;;
  }

  dimension: gross_sales_amt {
    group_label: "Sale Amounts"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.GrossSalesAmt ;;
  }

  dimension: cogs {
    group_label: "Sale Amounts"
    label: "COGS"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.COGS ;;
  }

  dimension: margin_amt {
    group_label: "Sale Amounts"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.MarginAmt ;;
  }

  dimension: qty {
    group_label: "Sale Amounts"
    label: "Quantity"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.Qty ;;
  }

  dimension: discount_amt {
    group_label: "Sale Amounts"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.DiscountAmt ;;
  }

  dimension: tax_amt {
    group_label: "Sale Amounts"
    hidden: yes
    type: number
    sql: ${TABLE}.sale.TaxAmt ;;
  }

  # ── Sale STRUCT: Flags & Classification ──

  dimension: is_return {
    group_label: "Sale Flags"
    description: "Yes when the line is a return (Qty and amounts are stored as negative). Total Net Sales already nets returns out — do not stack this filter on sales totals."
    type: yesno
    sql: ${TABLE}.sale.IsReturn ;;
  }

  dimension: is_web_receipt {
    group_label: "Sale Flags"
    label: "Is Web Receipt"
    description: "Yes when the receipt originated from the e-commerce channel rather than a brick-and-mortar POS."
    type: yesno
    sql: ${TABLE}.sale.IsWebReceipt ;;
  }

  dimension: is_employee_sale {
    group_label: "Sale Flags"
    description: "Yes when the receipt was rung up under an employee discount program. Often excluded from comp-sales reporting."
    type: yesno
    sql: ${TABLE}.sale.IsEmployeeSale ;;
  }

  dimension: sales_order_type {
    group_label: "Sale Classification"
    description: "Numeric code identifying the sales order type (regular sale, layaway, special order, etc.). See Receipt Source for a friendly label."
    type: number
    sql: ${TABLE}.sale.SalesOrderType ;;
  }

  dimension: rec_source_label {
    group_label: "Sale Classification"
    label: "Receipt Source"
    description: "Friendly label for where the receipt originated (e.g. POS, web, mobile)."
    type: string
    sql: ${TABLE}.sale.RecSourceLabel ;;
  }

  # ══════════════════════════════════════════════════
  # MEASURES - Core Sales KPIs
  # ══════════════════════════════════════════════════

  measure: total_net_sales {
    description: "Gross sales less discounts and returns. Excludes tax and shipping. USD. Returns are already netted out — do not stack an is_return filter on top."
    type: sum
    sql: ${TABLE}.sale.NetSalesAmt ;;
    value_format_name: usd
    drill_fields: [receipt_detail*]
  }

  measure: total_gross_sales {
    description: "Sales before discounts and before return netting. Excludes tax. Use only when explicitly comparing pre-discount values; otherwise prefer Total Net Sales."
    type: sum
    sql: ${TABLE}.sale.GrossSalesAmt ;;
    value_format_name: usd
  }

  measure: total_cogs {
    label: "Total COGS"
    description: "Cost of goods sold for items on receipt lines. Valued FIFO (cost of the oldest on-hand units at time of sale). USD."
    type: sum
    sql: ${TABLE}.sale.COGS ;;
    value_format_name: usd
  }

  measure: total_margin {
    description: "Net sales minus COGS. USD."
    type: sum
    sql: ${TABLE}.sale.MarginAmt ;;
    value_format_name: usd
  }

  measure: margin_percent {
    description: "Margin as a percentage of net sales (Total Margin / Total Net Sales). Returns NULL when net sales is 0."
    type: number
    sql: SAFE_DIVIDE(${total_margin}, ${total_net_sales}) ;;
    value_format_name: percent_1
  }

  measure: total_quantity {
    description: "Sum of units sold. Returns are stored as negative quantities and are netted into this total."
    type: sum
    sql: ${TABLE}.sale.Qty ;;
    value_format_name: decimal_0
  }

  measure: total_discount {
    description: "Total discount value applied across receipt lines. USD."
    type: sum
    sql: ${TABLE}.sale.DiscountAmt ;;
    value_format_name: usd
  }

  measure: discount_rate {
    description: "Discount as a percentage of gross sales (Total Discount / Total Gross Sales)."
    type: number
    sql: SAFE_DIVIDE(${total_discount}, ${total_gross_sales}) ;;
    value_format_name: percent_1
  }

  measure: total_tax {
    description: "Total tax collected across receipt lines. USD."
    type: sum
    sql: ${TABLE}.sale.TaxAmt ;;
    value_format_name: usd
  }

  # ── Transaction Counts ──

  measure: transaction_count {
    description: "Distinct receipts (count of UniversalNo). Use this — not Line Count — for receipt-level metrics like ATV and UPT."
    type: count_distinct
    sql: ${TABLE}.sale.UniversalNo ;;
    drill_fields: [receipt_detail*]
  }

  measure: line_count {
    description: "Count of receipt lines. Each row in this view is one line, so this counts rows. Use Transaction Count for receipt-level analysis."
    type: count
    drill_fields: [receipt_detail*]
  }

  measure: avg_transaction_value {
    label: "ATV"
    description: "Average Transaction Value: net sales per receipt (Total Net Sales / Transaction Count). USD."
    type: number
    sql: SAFE_DIVIDE(${total_net_sales}, ${transaction_count}) ;;
    value_format_name: usd
  }

  measure: avg_units_per_transaction {
    label: "UPT"
    description: "Units Per Transaction: average units sold per receipt (Total Quantity / Transaction Count)."
    type: number
    sql: SAFE_DIVIDE(${total_quantity}, ${transaction_count}) ;;
    value_format_name: decimal_1
  }

  measure: avg_selling_price {
    label: "ASP"
    description: "Average Selling Price: net (post-discount) realized revenue per unit (Total Net Sales / Total Quantity). Pair with AUR to measure discount erosion (AUR − ASP). USD."
    type: number
    sql: SAFE_DIVIDE(${total_net_sales}, ${total_quantity}) ;;
    value_format_name: usd
  }

  measure: avg_unit_retail {
    label: "AUR"
    description: "Average Unit Retail: gross (pre-discount) ticketed retail per unit sold (Σ retail_price × qty / Total Quantity). Reflects list price at the line before register-level promo discounts. Distinct from ASP, which is post-discount; AUR − ASP is per-unit discount erosion. USD."
    type: number
    sql: SAFE_DIVIDE(SUM(${TABLE}.item.RetailPrice * ${TABLE}.sale.Qty), NULLIF(${total_quantity}, 0)) ;;
    value_format_name: usd
  }

  # ── Markdown ──
  # Markdown $ = ticketed retail (RetailPrice) − base list price (BasePrice).
  # Captures permanent retail price reductions on items that sold; does NOT
  # include register-level promo discounts (see discount_rate / total_discount).

  measure: total_markdown_amount {
    label: "Total Markdown $"
    description: "Markdown dollars on units sold: SUM((BasePrice − RetailPrice) × Qty). Captures the value of permanent retail-price reductions taken before the sale. Does not include register-level promotions or discounts — see Total Discount for those. USD."
    type: number
    sql: SUM((${TABLE}.item.BasePrice - ${TABLE}.item.RetailPrice) * ${TABLE}.sale.Qty) ;;
    value_format_name: usd
  }

  measure: markdown_pct {
    label: "Markdown %"
    description: "Markdown as a share of original ticketed value: Total Markdown $ / SUM(BasePrice × Qty). Returns NULL when there is no base-priced volume in scope."
    type: number
    sql: SAFE_DIVIDE(SUM((${TABLE}.item.BasePrice - ${TABLE}.item.RetailPrice) * ${TABLE}.sale.Qty), NULLIF(SUM(${TABLE}.item.BasePrice * ${TABLE}.sale.Qty), 0)) ;;
    value_format_name: percent_1
  }

  # ── Return Metrics ──

  measure: return_quantity {
    description: "Total returned units, expressed as a positive number. Counts only return lines (is_return = yes)."
    type: sum
    sql: ABS(${TABLE}.sale.Qty) ;;
    filters: [is_return: "yes"]
    value_format_name: decimal_0
  }

  measure: return_amount {
    description: "Total returned net sales value, expressed as a positive number. Counts only return lines. USD."
    type: sum
    sql: ABS(${TABLE}.sale.NetSalesAmt) ;;
    filters: [is_return: "yes"]
    value_format_name: usd
  }

  measure: return_rate {
    description: "Returned units as a share of total units handled (Return Quantity / (Total Quantity + Return Quantity)). Total Quantity already excludes returns; the +Return Quantity in the denominator is intentional."
    type: number
    sql: SAFE_DIVIDE(${return_quantity}, ${total_quantity} + ${return_quantity}) ;;
    value_format_name: percent_1
  }

  # ── Drill Fields ──

  set: receipt_detail {
    fields: [
      date_part,
      universal_no,
      receipt_no,
      total_net_sales,
      total_quantity,
      total_discount,
      total_margin
    ]
  }
}

# ══════════════════════════════════════════════════════════════
# PAYMENTS ARRAY - Unnested derived table
# ══════════════════════════════════════════════════════════════

view: sales_receipt_payments {
  derived_table: {
    sql:
      SELECT
        sr.sale.UniversalNo   AS universal_no,
        sr.sale.ReceiptNo     AS receipt_no,
        sr.Date_Part          AS date_part,
        p.Code                AS payment_code,
        p.Description         AS payment_description,
        p.PaymentAmount       AS payment_amount,
        p.CardTypeDescription AS card_type,
        p.CurrencyCode        AS currency_code,
        p.ChangeAmount        AS change_amount
      FROM `aefc-prod-us-twc-b1bc.external_datamart_1.SalesReceipt_view` sr,
           UNNEST(sr.sale.Payments) AS p
    ;;
  }

  dimension: universal_no {
    type: number
    sql: ${TABLE}.universal_no ;;
    value_format_name: id
    hidden: yes
    link: {
      label: "View Receipt Detail"
      url: "/dashboards/twc_aefc::receipt_detail?universal_no={{ value | url_encode }}{% if _filters['date_range'] %}&date_range={{ _filters['date_range'] | url_encode }}{% endif %}"
    }
  }

  dimension: receipt_no {
    type: number
    sql: ${TABLE}.receipt_no ;;
    value_format_name: id
    hidden: yes
  }

  dimension: date_part {
    type: date
    datatype: date
    sql: ${TABLE}.date_part ;;
    hidden: yes
  }

  dimension: payment_code {
    description: "Short code identifying the payment method (e.g. CASH, CC, GC). See Payment Description for the friendly name."
    type: string
    sql: ${TABLE}.payment_code ;;
  }

  dimension: payment_description {
    description: "Friendly name of the payment method (e.g. Cash, Visa, Gift Card)."
    type: string
    sql: ${TABLE}.payment_description ;;
  }

  dimension: card_type {
    description: "Card brand for credit/debit payments (Visa, Mastercard, Amex, etc.). NULL for non-card tenders."
    type: string
    sql: ${TABLE}.card_type ;;
  }

  dimension: currency_code {
    description: "ISO currency code of the payment (e.g. USD, CAD)."
    type: string
    sql: ${TABLE}.currency_code ;;
  }

  measure: total_payment_amount {
    description: "Sum of payment amounts tendered across all payment methods on the receipt. Includes change given as a positive amount on the original tender. USD."
    type: sum
    sql: ${TABLE}.payment_amount ;;
    value_format_name: usd
  }

  measure: total_change_amount {
    description: "Sum of change given back to customers. USD."
    type: sum
    sql: ${TABLE}.change_amount ;;
    value_format_name: usd
  }

  measure: payment_count {
    description: "Count of payment records (one per tender on a receipt — split tenders count as multiple). For distinct receipts use Sales Receipts → Transaction Count."
    type: count
  }
}
