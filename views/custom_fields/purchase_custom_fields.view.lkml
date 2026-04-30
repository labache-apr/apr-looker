# ══════════════════════════════════════════════════════════════
# PURCHASE RECEIPT CUSTOM FIELDS
# Header (purchase STRUCT) does not currently expose any custom
# field columns in the external_datamart_1.Purchase_view.
# Item-level (StyleCustom*/ItemCustom*) custom fields are already
# wired through item_custom_fields.
#
# This file is a placeholder so the convention is consistent. Once
# purchase receipt customs are added to the BigQuery view (e.g.
# purchase.PurchaseCustomLookup1), declare them here and extend
# purchase.view.lkml with this view.
# ══════════════════════════════════════════════════════════════

view: purchase_custom_fields {
  extension: required
}
