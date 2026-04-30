# ══════════════════════════════════════════════════════════════
# PURCHASE ORDER CUSTOM FIELDS
# Header (purchase_order STRUCT) does not currently expose any
# custom field columns in the external_datamart_1.PurchaseOrder_view.
# Item-level (StyleCustom*/ItemCustom*) and Location custom fields
# are already wired through item_custom_fields / location_custom_fields.
#
# This file is a placeholder so the convention is consistent. Once
# PO header customs are added to the BigQuery view (e.g.
# purchase_order.PurchaseOrderCustomLookup1), declare them here and
# extend purchase_order.view.lkml with this view.
# ══════════════════════════════════════════════════════════════

view: purchase_order_custom_fields {
  extension: required
}
