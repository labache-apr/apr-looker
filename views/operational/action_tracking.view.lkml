# ══════════════════════════════════════════════════════════════
# ACTION TRACKING - System audit log of user/device actions
# Source: bi_star.append_window_dbo_ActionsTracking_view
# Each row = one tracked action (login, void, refund, drawer
# open, etc.) performed at a workstation/device.
# ══════════════════════════════════════════════════════════════

view: action_tracking {
  sql_table_name: `@{schema_name}.bi_star.append_window_dbo_ActionsTracking_view` ;;

  # ── Partition / Audit ──

  dimension: date_part {
    group_label: "Audit"
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

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

  # ── Identifiers ──

  dimension: actions_tracking_id {
    primary_key: yes
    group_label: "Identifiers"
    label: "Action ID"
    description: "Unique identifier for a tracked action. Primary key of this view."
    type: string
    sql: ${TABLE}.ActionsTrackingId ;;
  }

  dimension: object_id {
    group_label: "Identifiers"
    type: string
    sql: ${TABLE}.ObjectId ;;
    description: "ID of the object the action was performed on (e.g. receipt, drawer memo, document)."
  }

  dimension: parent_id {
    group_label: "Identifiers"
    type: string
    sql: ${TABLE}.ParentId ;;
    description: "Parent object ID (e.g. parent receipt, drawer memo header)."
  }

  dimension: sale_receipt_id {
    group_label: "Identifiers"
    label: "Sale Receipt ID"
    description: "Receipt the action relates to. NOTE: this column is always NULL in the current source — receipt context lives inside ObjectId (the receipt's GUID, lowercased) for sale-related actions, or embedded in the DetailedInfo XML payload."
    type: string
    sql: ${TABLE}.SaleReceiptID ;;
    hidden: yes
  }

  dimension: drawer_station_id {
    group_label: "Identifiers"
    label: "Drawer Station ID"
    description: "Drawer/station the action was performed at."
    type: string
    sql: ${TABLE}.DrawerStationID ;;
  }

  # ── Action Details ──

  dimension: action {
    group_label: "Action"
    description: "Name of the action performed (e.g. Login, Logout, Void, Refund, Open Drawer, No Sale)."
    type: string
    sql: ${TABLE}.Action ;;
  }

  dimension: document_type {
    group_label: "Action"
    description: "Type of document the action targeted (Receipt, Drawer Memo, Adjustment, etc.)."
    type: string
    sql: ${TABLE}.DocumentType ;;
  }

  dimension: reason {
    group_label: "Action"
    description: "Reason supplied by the operator (required for actions like Void or Refund)."
    type: string
    sql: ${TABLE}.Reason ;;
  }

  dimension: detailed_info {
    group_label: "Action"
    label: "Detailed Info"
    description: "Free-text detail captured with the action. Often contains structured payload — check before parsing."
    type: string
    sql: ${TABLE}.DetailedInfo ;;
  }

  dimension: application {
    group_label: "Action"
    description: "Application that recorded the action (POS, manager UI, web admin, etc.)."
    type: string
    sql: ${TABLE}.Application ;;
  }

  dimension_group: action_at {
    group_label: "Action"
    label: "Action"
    description: "Timestamp the action was performed."
    type: time
    timeframes: [
      raw,
      time,
      time_of_day,
      hour,
      hour_of_day,
      date,
      day_of_week,
      day_of_month,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.ActionDate ;;
  }

  dimension: action_date_key {
    group_label: "Action"
    hidden: yes
    type: number
    sql: CAST(FORMAT_TIMESTAMP('%Y%m%d', ${TABLE}.ActionDate) AS INT64) ;;
  }

  # ── Actor / Device ──

  dimension: employee_id {
    group_label: "Actor"
    label: "Employee ID"
    type: string
    sql: ${TABLE}.EmployeeId ;;
    hidden: yes
  }

  dimension: location_id {
    group_label: "Actor"
    label: "Location ID"
    type: string
    sql: ${TABLE}.LocationId ;;
    hidden: yes
  }

  dimension: workstation_id {
    group_label: "Actor"
    label: "Workstation ID"
    description: "Workstation the action was performed at."
    type: string
    sql: ${TABLE}.WorkstationId ;;
  }

  dimension: device_id {
    group_label: "Actor"
    label: "Device ID"
    description: "Device (terminal/scanner/printer) involved in the action."
    type: string
    sql: ${TABLE}.DeviceID ;;
  }

  dimension: device_unique_id {
    group_label: "Actor"
    label: "Device Unique ID"
    description: "Globally unique device serial/UUID — useful when a workstation has been re-paired with new hardware."
    type: string
    sql: ${TABLE}.DeviceUniqueId ;;
  }

  # ══════════════════════════════════════════════════════════════
  # PARSED FROM DetailedInfo XML
  # The DetailedInfo column holds an XML payload whose shape varies
  # by action type. BigQuery has no native XML parser, so these
  # dimensions use REGEXP_EXTRACT on the flat header tags that
  # appear directly under the root (<root>, <Receipt>, <Employee>,
  # or <CashDrawerOpen> depending on the action).
  #
  # Self-closing tags like <SellToLastName/> return NULL — correct.
  # Nested ReceiptItems are NOT extracted here to avoid row explosion;
  # use the SaleReceipt explore via ObjectId for line-item context.
  # ══════════════════════════════════════════════════════════════

  # ── Receipt Context (sale-related actions) ──

  dimension: receipt_num {
    group_label: "Receipt Detail"
    label: "Receipt Number"
    description: "Receipt number parsed from DetailedInfo. Populated for sale-related actions (DiscountApplied, DiscountVoided, ItemRemoved, ItemPriceChanged, DocumentDiscarded, etc.)."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<ReceiptNum>([^<]*)</ReceiptNum>') ;;
  }

  dimension: receipt_code {
    group_label: "Receipt Detail"
    label: "Receipt Code"
    description: "Alphanumeric receipt code (printed on the customer receipt) parsed from DetailedInfo."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<ReceiptCode>([^<]*)</ReceiptCode>') ;;
  }

  dimension: receipt_total_with_tax {
    group_label: "Receipt Detail"
    label: "Receipt Total (with tax)"
    description: "Receipt total amount including tax, parsed from DetailedInfo. Use to size the value of voided/discarded transactions."
    type: number
    sql: SAFE_CAST(REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<TotalAmountWithTax>([^<]*)</TotalAmountWithTax>') AS NUMERIC) ;;
    value_format_name: usd
  }

  dimension: receipt_total_without_tax {
    group_label: "Receipt Detail"
    label: "Receipt Total (without tax)"
    description: "Receipt total amount excluding tax, parsed from DetailedInfo."
    type: number
    sql: SAFE_CAST(REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<TotalAmountWithoutTax>([^<]*)</TotalAmountWithoutTax>') AS NUMERIC) ;;
    value_format_name: usd
  }

  dimension: receipt_total_qty {
    group_label: "Receipt Detail"
    label: "Receipt Quantity"
    description: "Total quantity of items on the receipt, parsed from DetailedInfo."
    type: number
    sql: SAFE_CAST(REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<TotalQty>([^<]*)</TotalQty>') AS NUMERIC) ;;
  }

  dimension: receipt_price_level_code {
    group_label: "Receipt Detail"
    label: "Price Level"
    description: "Price level code (pricing tier) on the receipt, parsed from DetailedInfo. e.g. WO1, HE1, FR1, ST1, HA1."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<PriceLevelCode>([^<]*)</PriceLevelCode>') ;;
  }

  # ── Customer Context ──

  dimension: customer_first_name {
    group_label: "Customer"
    label: "Customer First Name"
    description: "Sell-to customer's first name parsed from DetailedInfo. PII — restricted use."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<SellToFirstName>([^<]*)</SellToFirstName>') ;;
  }

  dimension: customer_last_name {
    group_label: "Customer"
    label: "Customer Last Name"
    description: "Sell-to customer's last name parsed from DetailedInfo. PII — restricted use."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<SellToLastName>([^<]*)</SellToLastName>') ;;
  }

  dimension: customer_phone {
    group_label: "Customer"
    label: "Customer Phone"
    description: "Sell-to customer's primary phone number parsed from DetailedInfo. PII — restricted use."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<SellToPhone1>([^<]*)</SellToPhone1>') ;;
  }

  dimension: membership_code {
    group_label: "Customer"
    label: "Membership Code"
    description: "Loyalty/membership code on the receipt, parsed from DetailedInfo."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<MembershipCode>([^<]*)</MembershipCode>') ;;
  }

  # ── Discount Context (DiscountApplied / DiscountVoided / LineDiscount*) ──

  dimension: global_discount_percent {
    group_label: "Discount"
    label: "Global Discount %"
    description: "Whole-receipt discount percentage parsed from DetailedInfo. Populated for DiscountApplied/DiscountVoided. Source value carries 30+ decimals; rounded for display."
    type: number
    sql: ROUND(SAFE_CAST(REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<GlobalDiscountPercent>([^<]*)</GlobalDiscountPercent>') AS NUMERIC), 2) ;;
    value_format_name: decimal_2
  }

  dimension: global_discount_reason_id {
    group_label: "Discount"
    label: "Global Discount Reason ID"
    description: "ID of the reason supplied for a global discount, parsed from DetailedInfo. Resolves to a reason name via the Reasons dimension (not currently joined)."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<GlobalDiscReasonId>([^<]*)</GlobalDiscReasonId>') ;;
  }

  dimension: global_discount_employee_id {
    group_label: "Discount"
    label: "Discount Authorized By (Employee ID)"
    description: "Employee who authorized the global discount, parsed from DetailedInfo. May differ from the employee who recorded the action — useful for catching manager-override patterns."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<GlobalDiscEmployeeId>([^<]*)</GlobalDiscEmployeeId>') ;;
  }

  # ── Cash Drawer Context (CashDrawerOpened) ──

  dimension: drawer_open_type {
    group_label: "Cash Drawer"
    label: "Drawer Open Type"
    description: "Why the cash drawer opened, parsed from DetailedInfo. Common values: 'Change Due' (routine — accompanies a sale), 'No Sale' (manual open — loss-prevention signal). Filter to non-'Change Due' to surface manual opens."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<OpenType>([^<]*)</OpenType>') ;;
  }

  # ── Login Context (ChangePasswordLogin / login-related actions) ──

  dimension: detail_login_name {
    group_label: "Login"
    label: "Login Name (from DetailedInfo)"
    description: "Username from the DetailedInfo XML on login-related actions (ChangePasswordLogin etc.). For most actions employee identity comes from the EmployeeId column instead."
    type: string
    sql: REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<LoginName>([^<]*)</LoginName>') ;;
  }

  # ── Measures ──

  measure: action_count {
    description: "Distinct actions logged (count of ActionsTrackingId)."
    type: count_distinct
    sql: ${TABLE}.ActionsTrackingId ;;
  }

  measure: distinct_employees {
    description: "Distinct employees who performed actions in the selected slice."
    type: count_distinct
    sql: ${TABLE}.EmployeeId ;;
  }

  measure: distinct_workstations {
    description: "Distinct workstations where actions were performed."
    type: count_distinct
    sql: ${TABLE}.WorkstationId ;;
  }

  measure: distinct_objects {
    description: "Distinct objects (receipts, drawer memos, etc.) that had actions performed against them."
    type: count_distinct
    sql: ${TABLE}.ObjectId ;;
  }

  measure: total_receipt_value_with_tax {
    group_label: "Receipt Detail"
    label: "Total Receipt Value (with tax)"
    description: "Sum of receipt totals (with tax) parsed from DetailedInfo. Only meaningful when filtered to receipt-bearing actions (e.g. DiscountVoided, DocumentDiscarded) — sizes the dollar value of those actions."
    type: sum
    sql: SAFE_CAST(REGEXP_EXTRACT(${TABLE}.DetailedInfo, r'<TotalAmountWithTax>([^<]*)</TotalAmountWithTax>') AS NUMERIC) ;;
    value_format_name: usd
  }
}