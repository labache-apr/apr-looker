# ══════════════════════════════════════════════════════════════
# ADJUSTMENT CUSTOM FIELDS
# Header (adjustment STRUCT) does not currently expose any custom
# field columns in the external_datamart_1.Adjustment_view.
# Item-level (StyleCustom*/ItemCustom*) custom fields are already
# wired through item_custom_fields.
#
# This file is a placeholder so the convention is consistent. Once
# adjustment header customs are added to the BigQuery view (e.g.
# adjustment.AdjustmentCustomLookup1), declare them here and extend
# adjustment.view.lkml with this view.
# ══════════════════════════════════════════════════════════════

view: adjustment_custom_fields {
  extension: required
}
