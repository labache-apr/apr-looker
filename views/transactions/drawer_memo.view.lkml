# ══════════════════════════════════════════════════════════════
# DRAWER MEMO - Cash drawer session header
# Source: bi_star.append_window_dbo_DrawerMemo_view
# Each row = one drawer session at a workstation, from open
# (start of day) through audit / deposit / close.
#
# Reconciliation context:
#   - Drawer-level audit times/employees on this header
#   - Per-tender variance (system Amount vs counted AuditedAmount)
#     lives on drawer_memo_media (one row per payment method)
# ══════════════════════════════════════════════════════════════

view: drawer_memo {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_DrawerMemo_view` ;;

  # ── Partition / Audit ──

  dimension: date_part {
    group_label: "Audit"
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.RecModified ;;
    hidden: yes
  }

  # ── Identifiers ──

  dimension: drawer_memo_id {
    primary_key: yes
    group_label: "Identifiers"
    label: "Drawer Memo ID"
    description: "Unique identifier for a drawer session (one per workstation per opening). Primary key of this view."
    type: string
    sql: ${TABLE}.DrawerMemoId ;;
  }

  dimension: drawer_memo_num {
    group_label: "Identifiers"
    label: "Drawer Memo Number"
    description: "User-facing drawer session number (printed on closing reports)."
    type: number
    sql: ${TABLE}.DrawerMemoNum ;;
    value_format_name: id
  }

  dimension: cash_drawer_id {
    group_label: "Identifiers"
    label: "Cash Drawer ID"
    description: "Identifier of the physical cash drawer device (one workstation may have multiple drawers over time)."
    type: string
    sql: ${TABLE}.CashDrawerId ;;
  }

  dimension: workstation_id {
    group_label: "Identifiers"
    label: "Workstation ID"
    description: "Identifier of the POS workstation the drawer session was opened on."
    type: string
    sql: ${TABLE}.WorkstationId ;;
  }

  dimension: location_id {
    group_label: "Identifiers"
    label: "Location ID"
    type: string
    sql: ${TABLE}.LocationId ;;
    hidden: yes
  }

  dimension: device_transaction_number {
    group_label: "Identifiers"
    label: "Device Transaction Number"
    description: "Device-issued transaction number for the drawer session — useful for reconciling against device-level logs."
    type: string
    sql: ${TABLE}.DeviceTransactionNumber ;;
  }

  # ── Status ──

  dimension: status_code {
    group_label: "Status"
    label: "Status Code"
    type: number
    sql: ${TABLE}.Status ;;
    hidden: yes
  }

  dimension: status {
    group_label: "Status"
    type: string
    sql:
      CASE ${TABLE}.Status
        WHEN 0 THEN 'Open'
        WHEN 1 THEN 'Closed'
        WHEN 2 THEN 'Audited'
        WHEN 3 THEN 'Deposited'
        WHEN 4 THEN 'Fully Deposited'
        ELSE CAST(${TABLE}.Status AS STRING)
      END ;;
    description: "Drawer memo lifecycle status. Numeric mapping is best-effort — verify against TWC enum."
  }

  dimension: web_drawer_memo {
    group_label: "Status"
    label: "Web Drawer Memo"
    description: "Yes when the drawer session was created for web/e-commerce orders rather than a physical workstation."
    type: yesno
    sql: ${TABLE}.WebDrawerMemo ;;
  }

  dimension: logged_by_service {
    group_label: "Status"
    description: "Yes when the drawer record was logged by a background service rather than a human operator."
    type: yesno
    sql: ${TABLE}.LoggedByService ;;
  }

  dimension: version {
    group_label: "Status"
    description: "Optimistic-concurrency version number for the drawer record."
    type: number
    sql: ${TABLE}.Version ;;
  }

  # ── Lifecycle Timestamps ──

  dimension_group: created {
    group_label: "Lifecycle"
    label: "Created"
    description: "Drawer opened / memo created."
    type: time
    timeframes: [raw, time, time_of_day, hour_of_day, date, day_of_week, week, month, quarter, year]
    sql: ${TABLE}.CreateDateTime ;;
  }

  dimension: create_date_key {
    group_label: "Lifecycle"
    hidden: yes
    type: number
    sql: CAST(FORMAT_TIMESTAMP('%Y%m%d', ${TABLE}.CreateDateTime) AS INT64) ;;
  }

  dimension_group: edited {
    group_label: "Lifecycle"
    label: "Edited"
    description: "Timestamp the drawer memo header was last edited."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.EditDateTime ;;
  }

  dimension_group: closed {
    group_label: "Lifecycle"
    label: "Closed"
    description: "End-of-day close (drawer pulled / counted)."
    type: time
    timeframes: [raw, time, time_of_day, date, week, month]
    sql: ${TABLE}.CloseDateTime ;;
  }

  dimension_group: audited {
    group_label: "Lifecycle"
    label: "Audited"
    description: "Audit / reconciliation timestamp."
    type: time
    timeframes: [raw, time, date, week, month]
    sql: ${TABLE}.AuditDateTime ;;
  }

  dimension_group: audit_verified {
    group_label: "Lifecycle"
    label: "Audit Verified"
    description: "Timestamp a manager verified the audit / counted totals."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.AuditVerifiedDateTime ;;
  }

  dimension_group: fully_deposited {
    group_label: "Lifecycle"
    label: "Fully Deposited"
    description: "Timestamp the drawer's cash was fully deposited to the bank/safe."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.FullyDepositedDateTime ;;
  }

  dimension_group: sod_completed {
    group_label: "Lifecycle"
    label: "SOD Completed"
    description: "Start-of-day completion (opening count signed off)."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.SODCompletedDateTime ;;
  }

  dimension_group: sod_verified {
    group_label: "Lifecycle"
    label: "SOD Verified"
    description: "Timestamp a manager verified the start-of-day opening count."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.SODVerifiedDateTime ;;
  }

  dimension_group: fiscal {
    group_label: "Lifecycle"
    label: "Fiscal Date"
    description: "Fiscal/business date the drawer reconciles against — preferred over Created date for joining to dim_calendar."
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.FiscalDate ;;
  }

  # Bridge for joining to dim_calendar — drawers reconcile against
  # the fiscal/business date, not the row partition date.
  dimension: fiscal_date_key {
    group_label: "Lifecycle"
    hidden: yes
    type: number
    sql: CAST(FORMAT_TIMESTAMP('%Y%m%d', ${TABLE}.FiscalDate) AS INT64) ;;
  }

  # ── Actor IDs ──

  dimension: create_employee_id {
    group_label: "Actors"
    label: "Open Employee ID"
    type: string
    sql: ${TABLE}.CreateEmployeeId ;;
    hidden: yes
  }

  dimension: close_employee_id {
    group_label: "Actors"
    label: "Close Employee ID"
    type: string
    sql: ${TABLE}.CloseEmployeeId ;;
    hidden: yes
  }

  dimension: audit_employee_id {
    group_label: "Actors"
    label: "Audit Employee ID"
    type: string
    sql: ${TABLE}.AuditEmployeeId ;;
    hidden: yes
  }

  dimension: audit_verified_employee_id {
    group_label: "Actors"
    label: "Audit Verified Employee ID"
    type: string
    sql: ${TABLE}.AuditVerifiedEmployeeId ;;
    hidden: yes
  }

  dimension: sod_completed_employee_id {
    group_label: "Actors"
    label: "SOD Completed Employee ID"
    type: string
    sql: ${TABLE}.SODCompletedEmployeeId ;;
    hidden: yes
  }

  dimension: sod_verified_employee_id {
    group_label: "Actors"
    label: "SOD Verified Employee ID"
    type: string
    sql: ${TABLE}.SODVerifiedEmployeeId ;;
    hidden: yes
  }

  # Default "employee on the drawer" — open employee, falling back
  # to close/audit so the drawer always associates to a person.
  dimension: employee_id {
    group_label: "Actors"
    label: "Employee ID"
    type: string
    sql: COALESCE(${TABLE}.CreateEmployeeId, ${TABLE}.CloseEmployeeId, ${TABLE}.AuditEmployeeId) ;;
    hidden: yes
  }

  # ── Counters & Notes ──

  dimension: large_memo {
    group_label: "Notes"
    label: "Memo Note"
    description: "Free-text note attached to the drawer session (variance explanations, manager comments, etc.)."
    type: string
    sql: ${TABLE}.LargeMemo ;;
  }

  dimension: net_round_amount {
    group_label: "Amounts"
    label: "Net Round Amount"
    description: "Net cash rounding adjustment recorded during the session. USD."
    type: number
    sql: ${TABLE}.NetRoundAmount ;;
    value_format_name: usd
  }

  dimension: reprint_counter {
    group_label: "Counters"
    label: "Reprint Counter"
    description: "Number of receipt reprints during the drawer session — high counts can indicate process/training issues."
    type: number
    sql: ${TABLE}.ReprintCounter ;;
  }

  dimension: discarded_receipts_counter {
    group_label: "Counters"
    label: "Discarded Receipts"
    description: "Number of receipts started and discarded during the drawer session."
    type: number
    sql: ${TABLE}.DiscardedReceiptsCounter ;;
  }

  dimension: discarded_receipts_total_due_amount {
    group_label: "Counters"
    label: "Discarded Receipts Total Due"
    description: "Total dollar value of discarded receipts during the session. USD."
    type: number
    sql: ${TABLE}.DiscardedReceiptsTotalDueAmount ;;
    value_format_name: usd
  }

  dimension: blank_alteration_tickets_counter {
    group_label: "Counters"
    label: "Blank Alteration Tickets"
    description: "Number of blank alteration tickets issued during the session (tailoring/customization workflows)."
    type: number
    sql: ${TABLE}.BlankAlterationTicketsCounter ;;
  }

  dimension: blank_alteration_tickets_items_counter {
    group_label: "Counters"
    label: "Blank Alteration Ticket Items"
    description: "Number of items associated with blank alteration tickets."
    type: number
    sql: ${TABLE}.BlankAlterationTicketsItemsCounter ;;
  }

  # ── Measures ──

  measure: drawer_count {
    label: "Drawer Memo Count"
    description: "Distinct drawer sessions (count of DrawerMemoId)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoId ;;
  }

  measure: open_drawers {
    label: "Open Drawers"
    description: "Distinct drawer sessions still in Open status (status code = 0)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoId ;;
    filters: [status_code: "0"]
  }

  measure: closed_drawers {
    label: "Closed Drawers"
    description: "Distinct drawer sessions that have moved past Open (closed, audited, deposited, fully deposited)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoId ;;
    filters: [status_code: ">=1"]
  }

  measure: audited_drawers {
    label: "Audited Drawers"
    description: "Distinct drawer sessions that have been audited (Audited Date is non-null)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoId ;;
    filters: [audited_date: "-NULL"]
  }

  measure: total_net_round_amount {
    description: "Sum of net rounding adjustments across drawer sessions. USD."
    type: sum
    sql: ${TABLE}.NetRoundAmount ;;
    value_format_name: usd
  }

  measure: total_discarded_receipts_due {
    description: "Sum of discarded receipt dollar values across drawer sessions. USD."
    type: sum
    sql: ${TABLE}.DiscardedReceiptsTotalDueAmount ;;
    value_format_name: usd
  }

  measure: total_reprints {
    description: "Sum of receipt reprint counts across drawer sessions."
    type: sum
    sql: ${TABLE}.ReprintCounter ;;
    value_format_name: decimal_0
  }

  measure: total_discarded_receipts {
    description: "Sum of discarded receipt counts across drawer sessions."
    type: sum
    sql: ${TABLE}.DiscardedReceiptsCounter ;;
    value_format_name: decimal_0
  }
}


# ══════════════════════════════════════════════════════════════
# DRAWER MEMO MEDIA - Per-tender drawer totals & audit (over/short)
# Source: bi_star.append_window_dbo_DrawerMemoMedia_view
# One row per (drawer memo, payment method). Holds:
#   - Amount         system-expected drawer total for this tender
#   - AuditedAmount  counted total when drawer is reconciled
#   - FoundAmount    discrepancy resolution amount
#   - OpenAmount     starting drawer balance (cash float)
#   - NextDrawerAmount  cash carried to next session
#   - PaidInOutAmount  net cash drops / paid-in adjustments
# Variance (over/short) = AuditedAmount - Amount
# ══════════════════════════════════════════════════════════════

view: drawer_memo_media {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_DrawerMemoMedia_view` ;;

  dimension: date_part {
    group_label: "Audit"
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

  dimension: drawer_memo_media_id {
    primary_key: yes
    group_label: "Identifiers"
    label: "Drawer Memo Media ID"
    description: "Unique identifier for a (drawer session, payment method) row. Primary key of this view."
    type: string
    sql: ${TABLE}.DrawerMemoMediaId ;;
  }

  dimension: drawer_memo_id {
    group_label: "Identifiers"
    label: "Drawer Memo ID"
    description: "Identifier of the drawer session this media row belongs to. Join to Drawer Memo for session context."
    type: string
    sql: ${TABLE}.DrawerMemoId ;;
  }

  dimension: deposit_memo_id {
    group_label: "Identifiers"
    label: "Deposit Memo ID"
    description: "Identifier of the deposit memo this media row was rolled into (NULL until deposited)."
    type: string
    sql: ${TABLE}.DepositMemoId ;;
  }

  dimension: payment_method_id {
    group_label: "Tender"
    label: "Payment Method ID"
    type: string
    sql: ${TABLE}.PaymentMethodId ;;
    hidden: yes
  }

  dimension: payment_method_code {
    group_label: "Tender"
    label: "Payment Method Code"
    description: "Short code for the payment method (e.g. CASH, CC, GC) — the primary tender breakdown."
    type: string
    sql: ${TABLE}.PaymentMethodCode ;;
  }

  dimension: account_type {
    group_label: "Tender"
    description: "Numeric account-type code from the source system (typically distinguishes credit/debit/gift account variants)."
    type: number
    sql: ${TABLE}.AccountType ;;
  }

  dimension: currency_id {
    group_label: "Tender"
    description: "Currency identifier for the tender (most rows are USD; foreign-currency tenders use FC fields below)."
    type: string
    sql: ${TABLE}.CurrencyId ;;
  }

  dimension: list_order {
    group_label: "Tender"
    type: number
    sql: ${TABLE}.ListOrder ;;
    hidden: yes
  }

  # ── Amounts (per-row) ──

  dimension: amount {
    group_label: "Amounts"
    label: "System Amount"
    description: "System-calculated drawer balance for this tender (expected)."
    type: number
    sql: ${TABLE}.Amount ;;
    value_format_name: usd
  }

  dimension: audited_amount {
    group_label: "Amounts"
    label: "Counted Amount"
    description: "Amount physically counted at audit / close."
    type: number
    sql: ${TABLE}.AuditedAmount ;;
    value_format_name: usd
  }

  dimension: found_amount {
    group_label: "Amounts"
    label: "Found Amount"
    description: "Amount entered to resolve a discrepancy (e.g. miscount corrected later). USD."
    type: number
    sql: ${TABLE}.FoundAmount ;;
    value_format_name: usd
  }

  dimension: open_amount {
    group_label: "Amounts"
    label: "Opening Float"
    description: "Starting drawer balance for this tender."
    type: number
    sql: ${TABLE}.OpenAmount ;;
    value_format_name: usd
  }

  dimension: next_drawer_amount {
    group_label: "Amounts"
    label: "Next Drawer Amount"
    description: "Cash carried forward to the next drawer session (closing float). USD."
    type: number
    sql: ${TABLE}.NextDrawerAmount ;;
    value_format_name: usd
  }

  dimension: paid_in_out_amount {
    group_label: "Amounts"
    label: "Paid In/Out Amount"
    description: "Net of paid-in (positive) and paid-out (negative) amounts during the session. USD."
    type: number
    sql: ${TABLE}.PaidInOutAmount ;;
    value_format_name: usd
  }

  dimension: variance_amount {
    group_label: "Reconciliation"
    label: "Over / (Short)"
    description: "Counted minus System. Positive = over, negative = short."
    type: number
    sql: COALESCE(${TABLE}.AuditedAmount, 0) - COALESCE(${TABLE}.Amount, 0) ;;
    value_format_name: usd
  }

  dimension: abs_variance_amount {
    group_label: "Reconciliation"
    label: "Absolute Variance"
    type: number
    sql: ABS(COALESCE(${TABLE}.AuditedAmount, 0) - COALESCE(${TABLE}.Amount, 0)) ;;
    value_format_name: usd
    hidden: yes
  }

  dimension: is_over {
    group_label: "Reconciliation"
    description: "Yes when counted amount exceeds system amount (over)."
    type: yesno
    sql: COALESCE(${TABLE}.AuditedAmount, 0) - COALESCE(${TABLE}.Amount, 0) > 0 ;;
  }

  dimension: is_short {
    group_label: "Reconciliation"
    description: "Yes when counted amount is less than system amount (short)."
    type: yesno
    sql: COALESCE(${TABLE}.AuditedAmount, 0) - COALESCE(${TABLE}.Amount, 0) < 0 ;;
  }

  # ── Foreign Currency ──

  dimension: exchange_rate {
    group_label: "FX"
    description: "Exchange rate from the foreign tender currency to the local currency at time of transaction."
    type: number
    sql: ${TABLE}.ExchangeRate ;;
  }

  dimension: fc_open_amount {
    group_label: "FX"
    label: "FC Open Amount"
    description: "Opening drawer balance in the foreign tender currency."
    type: number
    sql: ${TABLE}.FCOpenAmount ;;
  }

  dimension: fc_audited_amount {
    group_label: "FX"
    label: "FC Audited Amount"
    description: "Counted drawer balance in the foreign tender currency."
    type: number
    sql: ${TABLE}.FCAuditedAmount ;;
  }

  # ── Audit / Edit Trail ──

  dimension_group: created {
    group_label: "Audit Trail"
    label: "Created"
    description: "Timestamp the media row was created (drawer opened for this tender)."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.CreateDateTime ;;
  }

  dimension_group: edited {
    group_label: "Audit Trail"
    label: "Edited"
    description: "Timestamp the media row was last edited."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.EditDateTime ;;
  }

  dimension_group: audited {
    group_label: "Audit Trail"
    label: "Audited"
    description: "Timestamp the media row was audited (counted)."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.AuditDateTime ;;
  }

  dimension: create_employee_id {
    group_label: "Audit Trail"
    type: string
    sql: ${TABLE}.CreateEmployeeId ;;
    hidden: yes
  }

  dimension: edit_employee_id {
    group_label: "Audit Trail"
    type: string
    sql: ${TABLE}.EditEmployeeId ;;
    hidden: yes
  }

  dimension: audit_employee_id {
    group_label: "Audit Trail"
    type: string
    sql: ${TABLE}.AuditEmployeeId ;;
    hidden: yes
  }

  # ── Measures ──

  measure: total_system_amount {
    label: "Total System Amount"
    description: "Sum of system-expected drawer balances across tenders. USD."
    type: sum
    sql: ${TABLE}.Amount ;;
    value_format_name: usd
  }

  measure: total_audited_amount {
    label: "Total Counted Amount"
    description: "Sum of physically counted drawer balances across tenders. USD."
    type: sum
    sql: ${TABLE}.AuditedAmount ;;
    value_format_name: usd
  }

  measure: total_open_amount {
    label: "Total Opening Float"
    description: "Sum of opening drawer balances across tenders (cash float). USD."
    type: sum
    sql: ${TABLE}.OpenAmount ;;
    value_format_name: usd
  }

  measure: total_paid_in_out {
    description: "Sum of net paid-in/out amounts across tenders. USD."
    type: sum
    sql: ${TABLE}.PaidInOutAmount ;;
    value_format_name: usd
  }

  measure: total_variance {
    label: "Total Over / (Short)"
    description: "Net reconciliation variance: Total Counted minus Total System. Positive = over, negative = short. USD."
    type: sum
    sql: COALESCE(${TABLE}.AuditedAmount, 0) - COALESCE(${TABLE}.Amount, 0) ;;
    value_format_name: usd
  }

  measure: total_abs_variance {
    label: "Total Absolute Variance"
    description: "Sum of absolute variances — overs and shorts both count as positive. Use when measuring total reconciliation noise. USD."
    type: sum
    sql: ABS(COALESCE(${TABLE}.AuditedAmount, 0) - COALESCE(${TABLE}.Amount, 0)) ;;
    value_format_name: usd
  }

  measure: over_count {
    label: "Over Count"
    description: "Count of tender rows where counted exceeded system (variance > 0)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoMediaId ;;
    filters: [variance_amount: ">0"]
  }

  measure: short_count {
    label: "Short Count"
    description: "Count of tender rows where counted was less than system (variance < 0)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoMediaId ;;
    filters: [variance_amount: "<0"]
  }

  measure: balanced_count {
    label: "Balanced Count"
    description: "Count of tender rows that balanced exactly (variance = 0)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoMediaId ;;
    filters: [variance_amount: "0"]
  }

  measure: media_line_count {
    description: "Total count of (drawer, tender) rows."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoMediaId ;;
  }
}


# ══════════════════════════════════════════════════════════════
# DRAWER MEMO PAID IN/OUT - Cash drops & paid-in events
# Source: bi_star.append_window_dbo_DrawerMemoPaidInOut_view
# One row per paid-in / paid-out / cash-drop action against a
# drawer session.
# ══════════════════════════════════════════════════════════════

view: drawer_memo_paid_in_out {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_DrawerMemoPaidInOut_view` ;;

  dimension: date_part {
    group_label: "Audit"
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

  dimension: paid_in_out_id {
    primary_key: yes
    group_label: "Identifiers"
    label: "Paid In/Out ID"
    description: "Unique identifier for a paid-in / paid-out / cash-drop event. Primary key of this view."
    type: string
    sql: ${TABLE}.DrawerMemoPaidInOutId ;;
  }

  dimension: drawer_memo_id {
    group_label: "Identifiers"
    description: "Drawer session this event was recorded against."
    type: string
    sql: ${TABLE}.DrawerMemoId ;;
  }

  dimension: drawer_memo_media_id {
    group_label: "Identifiers"
    description: "(Drawer, tender) row this event applies to — usually cash."
    type: string
    sql: ${TABLE}.DrawerMemoMediaId ;;
  }

  dimension: cash_drawer_action_id {
    group_label: "Identifiers"
    label: "Cash Drawer Action ID"
    description: "Identifier of the configured cash drawer action that triggered this event (e.g. specific paid-out reason)."
    type: string
    sql: ${TABLE}.CashDrawerActionId ;;
  }

  dimension: cash_drawer_action_type_code {
    group_label: "Action"
    label: "Action Type Code"
    type: number
    sql: ${TABLE}.CashDrawerActionType ;;
    hidden: yes
  }

  dimension: cash_drawer_action_type {
    group_label: "Action"
    label: "Action Type"
    description: "Numeric mapping is best-effort — verify against TWC enum."
    type: string
    sql:
      CASE ${TABLE}.CashDrawerActionType
        WHEN 0 THEN 'Paid In'
        WHEN 1 THEN 'Paid Out'
        WHEN 2 THEN 'Cash Drop'
        WHEN 3 THEN 'Pickup'
        ELSE CAST(${TABLE}.CashDrawerActionType AS STRING)
      END ;;
  }

  dimension: scope {
    group_label: "Action"
    description: "Scope code for the action — distinguishes session-level vs. drawer-level events."
    type: number
    sql: ${TABLE}.Scope ;;
  }

  dimension: large_memo {
    group_label: "Action"
    label: "Note"
    description: "Free-text note attached to the paid-in/out event (reason, vendor name, manager comment, etc.)."
    type: string
    sql: ${TABLE}.LargeMemo ;;
  }

  dimension: list_order {
    group_label: "Action"
    type: number
    sql: ${TABLE}.ListOrder ;;
    hidden: yes
  }

  # ── Amounts ──

  dimension: amount {
    group_label: "Amounts"
    description: "Recorded paid-in/out amount entered by the operator. USD."
    type: number
    sql: ${TABLE}.Amount ;;
    value_format_name: usd
  }

  dimension: audited_amount {
    group_label: "Amounts"
    label: "Audited Amount"
    description: "Counted amount at audit (may differ from operator-entered Amount). USD."
    type: number
    sql: ${TABLE}.AuditedAmount ;;
    value_format_name: usd
  }

  dimension: currency_id {
    group_label: "Amounts"
    description: "Currency identifier for the event amount."
    type: string
    sql: ${TABLE}.CurrencyId ;;
  }

  # ── Lifecycle ──

  dimension_group: created {
    group_label: "Lifecycle"
    label: "Created"
    description: "Timestamp the paid-in/out event was recorded."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.CreateDateTime ;;
  }

  dimension_group: edited {
    group_label: "Lifecycle"
    label: "Edited"
    description: "Timestamp the event was last edited."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.EditDateTime ;;
  }

  dimension_group: voided {
    group_label: "Lifecycle"
    label: "Voided"
    description: "Timestamp the event was voided (NULL if not voided)."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.VoidDateTime ;;
  }

  dimension_group: audited {
    group_label: "Lifecycle"
    label: "Audited"
    description: "Timestamp the event was audited."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.AuditDateTime ;;
  }

  dimension: is_void {
    group_label: "Lifecycle"
    label: "Voided?"
    description: "Yes when the event has been voided. Voided events are typically excluded from cash-flow analysis. Source field is named IsVoId."
    type: yesno
    sql: ${TABLE}.IsVoId ;;
  }

  dimension: create_employee_id {
    group_label: "Lifecycle"
    type: string
    sql: ${TABLE}.CreateEmployeeId ;;
    hidden: yes
  }

  dimension: void_employee_id {
    group_label: "Lifecycle"
    type: string
    sql: ${TABLE}.VoidEmployeeId ;;
    hidden: yes
  }

  # ── Measures ──

  measure: total_amount {
    description: "Sum of operator-entered amounts across paid-in/out events. USD."
    type: sum
    sql: ${TABLE}.Amount ;;
    value_format_name: usd
  }

  measure: total_audited_amount {
    description: "Sum of audited amounts across paid-in/out events. USD."
    type: sum
    sql: ${TABLE}.AuditedAmount ;;
    value_format_name: usd
  }

  measure: paid_in_total {
    description: "Total cash paid into the drawer (action type = Paid In). USD."
    type: sum
    sql: ${TABLE}.Amount ;;
    filters: [cash_drawer_action_type_code: "0"]
    value_format_name: usd
  }

  measure: paid_out_total {
    description: "Total cash paid out of the drawer (action type = Paid Out). USD."
    type: sum
    sql: ${TABLE}.Amount ;;
    filters: [cash_drawer_action_type_code: "1"]
    value_format_name: usd
  }

  measure: cash_drop_total {
    description: "Total cash dropped to the safe during the session (action type = Cash Drop). USD."
    type: sum
    sql: ${TABLE}.Amount ;;
    filters: [cash_drawer_action_type_code: "2"]
    value_format_name: usd
  }

  measure: void_count {
    description: "Count of paid-in/out events that were voided."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoPaidInOutId ;;
    filters: [is_void: "Yes"]
  }

  measure: paid_in_out_count {
    description: "Distinct paid-in/out events (count of DrawerMemoPaidInOutId)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoPaidInOutId ;;
  }
}


# ══════════════════════════════════════════════════════════════
# DRAWER MEMO PAYMENT - Drawer-attributed payments (receipt-level)
# Source: bi_star.append_window_dbo_DrawerMemoPayment_view
# Links a drawer memo session to individual receipt payments —
# for tying tender lines back to the drawer that captured them.
# ══════════════════════════════════════════════════════════════

view: drawer_memo_payment {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_DrawerMemoPayment_view` ;;

  dimension: date_part {
    group_label: "Audit"
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

  dimension: drawer_memo_payment_id {
    primary_key: yes
    group_label: "Identifiers"
    description: "Unique identifier linking a drawer session to an individual receipt payment. Primary key of this view."
    type: string
    sql: ${TABLE}.DrawerMemoPaymentId ;;
  }

  dimension: drawer_memo_id {
    group_label: "Identifiers"
    description: "Drawer session that captured this payment."
    type: string
    sql: ${TABLE}.DrawerMemoId ;;
  }

  dimension: receipt_id {
    group_label: "Identifiers"
    description: "Receipt the payment was tendered against. Join to Sales Receipt for transaction context."
    type: string
    sql: ${TABLE}.ReceiptId ;;
  }

  dimension: receipt_payment_id {
    group_label: "Identifiers"
    description: "Identifier of the specific payment line on the receipt (one receipt can have multiple split tenders)."
    type: string
    sql: ${TABLE}.ReceiptPaymentId ;;
  }

  dimension: payment_method_id {
    group_label: "Tender"
    description: "Identifier of the payment method used."
    type: string
    sql: ${TABLE}.PaymentMethodId ;;
  }

  dimension: payment_ref {
    group_label: "Tender"
    label: "Payment Reference"
    description: "Carrier-issued payment reference (e.g. authorization code for card payments)."
    type: string
    sql: ${TABLE}.PaymentRef ;;
  }

  dimension: account_number {
    group_label: "Tender"
    description: "Masked account number for the tender (e.g. last 4 digits of card). PII — restricted use."
    type: string
    sql: ${TABLE}.AccountNumber ;;
  }

  dimension: card_type {
    group_label: "Tender"
    description: "Numeric card-type code (Visa, Mastercard, Amex, etc.)."
    type: number
    sql: ${TABLE}.CardType ;;
  }

  dimension: device_id {
    group_label: "Tender"
    description: "Identifier of the payment device (terminal/PIN pad) used to capture the tender."
    type: string
    sql: ${TABLE}.DeviceId ;;
  }

  dimension: location_device_code {
    group_label: "Tender"
    description: "Location-scoped device code for the payment terminal."
    type: number
    sql: ${TABLE}.LocationDeviceCode ;;
  }

  dimension: have_payment {
    group_label: "Tender"
    description: "Yes when an actual payment was captured for this row (vs. a placeholder or auth-only)."
    type: yesno
    sql: ${TABLE}.HavePayment ;;
  }

  dimension: is_change {
    group_label: "Tender"
    description: "Yes when this row records change given back to the customer rather than a payment received."
    type: yesno
    sql: ${TABLE}.IsChange ;;
  }

  # ── Amounts ──

  dimension: amount {
    group_label: "Amounts"
    description: "Payment amount tendered for this row. USD."
    type: number
    sql: ${TABLE}.Amount ;;
    value_format_name: usd
  }

  dimension: audited_amount {
    group_label: "Amounts"
    description: "Counted/audited payment amount (may differ from Amount on disputed items). USD."
    type: number
    sql: ${TABLE}.AuditedAmount ;;
    value_format_name: usd
  }

  dimension: found_amount {
    group_label: "Amounts"
    description: "Discrepancy resolution amount (entered after audit to reconcile a difference). USD."
    type: number
    sql: ${TABLE}.FoundAmount ;;
    value_format_name: usd
  }

  dimension: fc_amount {
    group_label: "Amounts"
    label: "FC Amount"
    description: "Payment amount in the foreign tender currency."
    type: number
    sql: ${TABLE}.FCAmount ;;
  }

  dimension: exchange_rate {
    group_label: "Amounts"
    description: "Exchange rate from the foreign tender currency to local currency at time of payment."
    type: number
    sql: ${TABLE}.ExchangeRate ;;
  }

  dimension_group: payment_availability {
    group_label: "Lifecycle"
    label: "Payment Availability"
    description: "Date the payment becomes available for deposit/clearing (relevant for non-cash tenders)."
    type: time
    timeframes: [raw, date]
    sql: ${TABLE}.PaymentAvailabilityDate ;;
  }

  # ── Measures ──

  measure: total_payment_amount {
    description: "Sum of payment amounts captured by drawer sessions. USD."
    type: sum
    sql: ${TABLE}.Amount ;;
    value_format_name: usd
  }

  measure: total_audited_payment_amount {
    description: "Sum of audited payment amounts captured by drawer sessions. USD."
    type: sum
    sql: ${TABLE}.AuditedAmount ;;
    value_format_name: usd
  }

  measure: payment_count {
    description: "Distinct payments captured by drawer sessions (count of DrawerMemoPaymentId)."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoPaymentId ;;
  }

  measure: change_count {
    description: "Count of payment rows recording change back to customers."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoPaymentId ;;
    filters: [is_change: "Yes"]
  }
}


# ══════════════════════════════════════════════════════════════
# DRAWER MEMO STATUS HISTORY - Lifecycle audit trail
# Source: bi_star.append_window_dbo_DrawerMemoStatusHistory_view
# One row per status transition on a drawer memo (Open → Closed
# → Audited → Deposited).
# ══════════════════════════════════════════════════════════════

view: drawer_memo_status_history {
  sql_table_name: `aefc-prod-us-twc-b1bc.bi_star.append_window_dbo_DrawerMemoStatusHistory_view` ;;

  dimension: date_part {
    group_label: "Audit"
    type: date
    datatype: date
    sql: ${TABLE}._date_part ;;
  }

  dimension: status_history_id {
    primary_key: yes
    group_label: "Identifiers"
    description: "Unique identifier for a drawer status transition record. Primary key of this view."
    type: string
    sql: ${TABLE}.DrawerMemoStatusHistoryId ;;
  }

  dimension: drawer_memo_id {
    group_label: "Identifiers"
    description: "Drawer session this transition belongs to."
    type: string
    sql: ${TABLE}.DrawerMemoId ;;
  }

  dimension: workstation_id {
    group_label: "Identifiers"
    description: "Workstation the transition was recorded on."
    type: string
    sql: ${TABLE}.WorkstationId ;;
  }

  dimension: employee_id {
    group_label: "Identifiers"
    type: string
    sql: ${TABLE}.EmployeeId ;;
    hidden: yes
  }

  dimension: old_status_code {
    group_label: "Status"
    type: number
    sql: ${TABLE}.OldStatus ;;
    hidden: yes
  }

  dimension: new_status_code {
    group_label: "Status"
    type: number
    sql: ${TABLE}.NewStatus ;;
    hidden: yes
  }

  dimension: old_status {
    group_label: "Status"
    description: "Drawer status before the transition. Numeric mapping is best-effort — verify against TWC enum."
    type: string
    sql:
      CASE ${TABLE}.OldStatus
        WHEN 0 THEN 'Open'
        WHEN 1 THEN 'Closed'
        WHEN 2 THEN 'Audited'
        WHEN 3 THEN 'Deposited'
        WHEN 4 THEN 'Fully Deposited'
        ELSE CAST(${TABLE}.OldStatus AS STRING)
      END ;;
  }

  dimension: new_status {
    group_label: "Status"
    description: "Drawer status after the transition. Numeric mapping is best-effort — verify against TWC enum."
    type: string
    sql:
      CASE ${TABLE}.NewStatus
        WHEN 0 THEN 'Open'
        WHEN 1 THEN 'Closed'
        WHEN 2 THEN 'Audited'
        WHEN 3 THEN 'Deposited'
        WHEN 4 THEN 'Fully Deposited'
        ELSE CAST(${TABLE}.NewStatus AS STRING)
      END ;;
  }

  dimension_group: status {
    group_label: "Status"
    label: "Status Change"
    description: "Timestamp the drawer status transitioned from Old Status to New Status."
    type: time
    timeframes: [raw, time, date]
    sql: ${TABLE}.StatusDateTime ;;
  }

  measure: transition_count {
    description: "Count of drawer status transitions."
    type: count_distinct
    sql: ${TABLE}.DrawerMemoStatusHistoryId ;;
  }
}
