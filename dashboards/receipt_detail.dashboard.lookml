---
- dashboard: receipt_detail
  title: "Receipt Detail"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Look up a single receipt by Universal Number to see header totals, item lines, payment tenders, and metadata."
  preferred_slug: receipt-detail

  filters:
    - name: universal_no
      title: "Universal Number"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.universal_no
      default_value: ""
      allow_multiple_values: false
      required: true

    - name: date_range
      title: "Date Range"
      type: date_filter
      default_value: "last 90 days"

    - name: location
      title: "Location"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.location_name
      default_value: ""
      allow_multiple_values: true

    - name: receipt_no
      title: "Receipt Number"
      type: field_filter
      explore: sales_receipt
      field: sales_receipt.receipt_no
      default_value: ""
      allow_multiple_values: false

  elements:

    # ── Header KPIs ──

    - title: "Net Sales"
      name: hdr_net_sales
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_net_sales]
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 0
      col: 0
      width: 5
      height: 3

    - title: "Units"
      name: hdr_units
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_quantity]
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 0
      col: 5
      width: 5
      height: 3

    - title: "Discount"
      name: hdr_discount
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_discount]
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 0
      col: 10
      width: 5
      height: 3

    - title: "Tax"
      name: hdr_tax
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.total_tax]
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 0
      col: 15
      width: 4
      height: 3

    - title: "Margin %"
      name: hdr_margin_pct
      model: twc_aefc
      explore: sales_receipt
      type: single_value
      fields: [sales_receipt.margin_percent]
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 0
      col: 19
      width: 5
      height: 3

    # ── Receipt Metadata ──

    - title: "Receipt Header"
      name: receipt_header
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [
        sales_receipt.universal_no,
        sales_receipt.receipt_no,
        sales_receipt.transacted_date_time,
        sales_receipt.location_name,
        sales_receipt.employee_name,
        sales_receipt.full_name,
        sales_receipt.rec_source_label,
        sales_receipt.is_return,
        sales_receipt.is_web_receipt
      ]
      sorts: [sales_receipt.transacted_date_time desc]
      limit: 1
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 3
      col: 0
      width: 24
      height: 4

    # ── Line Items ──

    - title: "Line Items"
      name: line_items
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [
        sales_receipt.document_line_id,
        sales_receipt.style,
        sales_receipt.description1,
        sales_receipt.department,
        sales_receipt.class,
        sales_receipt.brand,
        sales_receipt.retail_price,
        sales_receipt.is_return,
        sales_receipt.total_quantity,
        sales_receipt.total_gross_sales,
        sales_receipt.total_discount,
        sales_receipt.total_net_sales,
        sales_receipt.total_tax,
        sales_receipt.total_cogs,
        sales_receipt.total_margin
      ]
      sorts: [sales_receipt.document_line_id]
      limit: 500
      show_row_numbers: true
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 7
      col: 0
      width: 24
      height: 10

    # ── Payment Tenders ──

    - title: "Payment Tenders"
      name: payment_tenders
      model: twc_aefc
      explore: sales_receipt
      type: looker_grid
      fields: [
        sales_receipt_payments.payment_description,
        sales_receipt_payments.card_type,
        sales_receipt_payments.currency_code,
        sales_receipt_payments.total_payment_amount,
        sales_receipt_payments.total_change_amount,
        sales_receipt_payments.payment_count
      ]
      sorts: [sales_receipt_payments.total_payment_amount desc]
      limit: 50
      listen:
        universal_no: sales_receipt.universal_no
        date_range: sales_receipt.date_part
        location: sales_receipt.location_name
        receipt_no: sales_receipt.receipt_no
      row: 17
      col: 0
      width: 24
      height: 6
