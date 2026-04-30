# ══════════════════════════════════════════════════════════════
# TRANSFER CUSTOM FIELDS (12 fields)
# APR should rename labels to match their actual field mappings.
# Hide unused fields with hidden: yes
# ══════════════════════════════════════════════════════════════

view: transfer_custom_fields {
  extension: required

  # ── Transfer Custom Lookups ──
  dimension: transfer_custom_lookup_1 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup1 ;; }
  dimension: transfer_custom_lookup_2 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup2 ;; }
  dimension: transfer_custom_lookup_3 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup3 ;; }
  dimension: transfer_custom_lookup_4 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup4 ;; }
  dimension: transfer_custom_lookup_5 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 5" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup5 ;; }
  dimension: transfer_custom_lookup_6 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 6" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup6 ;; }
  dimension: transfer_custom_lookup_7 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 7" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup7 ;; }
  dimension: transfer_custom_lookup_8 { group_label: "Transfer Custom Lookups" label: "Transfer Custom Lookup 8" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.TransferCustomLookup8 ;; }

  # ── Transfer Custom Texts ──
  dimension: transfer_custom_text_1 { group_label: "Transfer Custom Texts" label: "Transfer Custom Text 1" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.CustomText1 ;; }
  dimension: transfer_custom_text_2 { group_label: "Transfer Custom Texts" label: "Transfer Custom Text 2" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.CustomText2 ;; }
  dimension: transfer_custom_text_3 { group_label: "Transfer Custom Texts" label: "Transfer Custom Text 3" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.CustomText3 ;; }
  dimension: transfer_custom_text_4 { group_label: "Transfer Custom Texts" label: "Transfer Custom Text 4" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.transfer.CustomText4 ;; }
}
