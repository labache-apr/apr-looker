# ══════════════════════════════════════════════════════════════
# SALE RECEIPT-LEVEL CUSTOM FIELDS (28 fields)
# APR should rename labels to match their actual field mappings.
# ══════════════════════════════════════════════════════════════

view: sale_receipt_custom_fields {
  extension: required

  # ── Receipt Custom Lookups ──
  dimension: sale_custom_lookup_1 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup1 ;; }
  dimension: sale_custom_lookup_2 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup2 ;; }
  dimension: sale_custom_lookup_3 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup3 ;; }
  dimension: sale_custom_lookup_4 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup4 ;; }
  dimension: sale_custom_lookup_5 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 5" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup5 ;; }
  dimension: sale_custom_lookup_6 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 6" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup6 ;; }
  dimension: sale_custom_lookup_7 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 7" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup7 ;; }
  dimension: sale_custom_lookup_8 { group_label: "Sale Custom Lookups" label: "Sale Custom Lookup 8" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomLookup8 ;; }

  # ── Receipt Custom Dates ──
  dimension_group: sale_custom_date_1 { group_label: "Sale Custom Dates" label: "Sale Custom Date 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.CustomDate1 ;; }
  dimension_group: sale_custom_date_2 { group_label: "Sale Custom Dates" label: "Sale Custom Date 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.CustomDate2 ;; }
  dimension_group: sale_custom_date_3 { group_label: "Sale Custom Dates" label: "Sale Custom Date 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.CustomDate3 ;; }
  dimension_group: sale_custom_date_4 { group_label: "Sale Custom Dates" label: "Sale Custom Date 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.CustomDate4 ;; }

  # ── Receipt Custom Texts ──
  dimension: sale_custom_text_1 { group_label: "Sale Custom Texts" label: "Sale Custom Text 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText1 ;; }
  dimension: sale_custom_text_2 { group_label: "Sale Custom Texts" label: "Sale Custom Text 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText2 ;; }
  dimension: sale_custom_text_3 { group_label: "Sale Custom Texts" label: "Sale Custom Text 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText3 ;; }
  dimension: sale_custom_text_4 { group_label: "Sale Custom Texts" label: "Sale Custom Text 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText4 ;; }
  dimension: sale_custom_text_5 { group_label: "Sale Custom Texts" label: "Sale Custom Text 5" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText5 ;; }
  dimension: sale_custom_text_6 { group_label: "Sale Custom Texts" label: "Sale Custom Text 6" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText6 ;; }
  dimension: sale_custom_text_7 { group_label: "Sale Custom Texts" label: "Sale Custom Text 7" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText7 ;; }
  dimension: sale_custom_text_8 { group_label: "Sale Custom Texts" label: "Sale Custom Text 8" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.CustomText8 ;; }

  # ── Receipt Custom Flags ──
  dimension: sale_custom_flag_1 { group_label: "Sale Custom Flags" label: "Sale Custom Flag 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.sale.CustomFlag1 ;; }
  dimension: sale_custom_flag_2 { group_label: "Sale Custom Flags" label: "Sale Custom Flag 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.sale.CustomFlag2 ;; }
  dimension: sale_custom_flag_3 { group_label: "Sale Custom Flags" label: "Sale Custom Flag 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.sale.CustomFlag3 ;; }
  dimension: sale_custom_flag_4 { group_label: "Sale Custom Flags" label: "Sale Custom Flag 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.sale.CustomFlag4 ;; }

  # ── Receipt Custom Decimals ──
  dimension: sale_custom_decimal_1 { group_label: "Sale Custom Decimals" label: "Sale Custom Decimal 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomDecimal1 ;; }
  dimension: sale_custom_decimal_2 { group_label: "Sale Custom Decimals" label: "Sale Custom Decimal 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomDecimal2 ;; }
  dimension: sale_custom_decimal_3 { group_label: "Sale Custom Decimals" label: "Sale Custom Decimal 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomDecimal3 ;; }
  dimension: sale_custom_decimal_4 { group_label: "Sale Custom Decimals" label: "Sale Custom Decimal 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomDecimal4 ;; }

  # ── Receipt Custom Numbers ──
  dimension: sale_custom_number_1 { group_label: "Sale Custom Numbers" label: "Sale Custom Number 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomNumber1 ;; }
  dimension: sale_custom_number_2 { group_label: "Sale Custom Numbers" label: "Sale Custom Number 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomNumber2 ;; }
  dimension: sale_custom_number_3 { group_label: "Sale Custom Numbers" label: "Sale Custom Number 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomNumber3 ;; }
  dimension: sale_custom_number_4 { group_label: "Sale Custom Numbers" label: "Sale Custom Number 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.CustomNumber4 ;; }
}

# ══════════════════════════════════════════════════════════════
# SALE LINE-LEVEL CUSTOM FIELDS (14 fields)
# ══════════════════════════════════════════════════════════════

view: sale_line_custom_fields {
  extension: required

  dimension: line_custom_lookup_1 { group_label: "Line Custom Lookups" label: "Line Custom Lookup 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.LineCustomLookup1 ;; }
  dimension: line_custom_lookup_2 { group_label: "Line Custom Lookups" label: "Line Custom Lookup 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.LineCustomLookup2 ;; }
  dimension: line_custom_lookup_3 { group_label: "Line Custom Lookups" label: "Line Custom Lookup 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.LineCustomLookup3 ;; }
  dimension: line_custom_lookup_4 { group_label: "Line Custom Lookups" label: "Line Custom Lookup 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.LineCustomLookup4 ;; }

  dimension_group: line_custom_date_1 { group_label: "Line Custom Dates" label: "Line Custom Date 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.LineCustomDate1 ;; }
  dimension_group: line_custom_date_2 { group_label: "Line Custom Dates" label: "Line Custom Date 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.LineCustomDate2 ;; }
  dimension_group: line_custom_date_3 { group_label: "Line Custom Dates" label: "Line Custom Date 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.LineCustomDate3 ;; }
  dimension_group: line_custom_date_4 { group_label: "Line Custom Dates" label: "Line Custom Date 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, month, year] sql: ${TABLE}.sale.LineCustomDate4 ;; }

  dimension: line_custom_text_1 { group_label: "Line Custom Texts" label: "Line Custom Text 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.LineCustomText1 ;; }
  dimension: line_custom_text_2 { group_label: "Line Custom Texts" label: "Line Custom Text 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.sale.LineCustomText2 ;; }

  dimension: line_custom_flag_1 { group_label: "Line Custom Flags" label: "Line Custom Flag 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.sale.LineCustomFlag1 ;; }
  dimension: line_custom_flag_2 { group_label: "Line Custom Flags" label: "Line Custom Flag 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.sale.LineCustomFlag2 ;; }

  dimension: line_custom_decimal_1 { group_label: "Line Custom Decimals" label: "Line Custom Decimal 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.LineCustomDecimal1 ;; }
  dimension: line_custom_decimal_2 { group_label: "Line Custom Decimals" label: "Line Custom Decimal 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.sale.LineCustomDecimal2 ;; }
}
