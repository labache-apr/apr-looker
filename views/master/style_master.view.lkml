# ══════════════════════════════════════════════════════════════
# STYLE MASTER - Style-grain master data
# One row per Style. Use this view when reporting at the product
# (style) level rather than the SKU (item) level — analogous to
# Shopify's product vs variant split.
#
# Source: bi_star.append_window_dbo_InvenStyle_view (authoritative)
# joined to:
#   - InvenStyleExtended_view   (CustomLongText 1-18)
#   - mv_StyleCustomLookup_view (resolved CustomLookup 1-12 labels)
#   - mv_PrimaryVendor_view     (primary vendor + cost/lead/WoS — pre-built MV)
#   - InvenBrand_view           (brand_name)
#   - InvenSeason_view          (season_name, season_no)
#   - dim_Vendor_view           (manufacturer_name from ManufacturerId)
#   - Country_view              (country_of_origin_name + alpha codes)
#   - TaxCategory_view          (tax_category_name + ipi_tax_category_name)
#   - AttributeSet_view         (attribute_1/2/3_set_name labels)
#   - dim_Item                  (Style code + DCSS hierarchy strings)
#
# Filters out IsDeleted = TRUE on all CDC sources.
# NOTE: append_window_dbo_* tables can include historical/CDC rows;
# each lookup CTE collapses to one row per natural key via GROUP BY.
# ══════════════════════════════════════════════════════════════

view: style_master {
  derived_table: {
    sql:
      WITH style AS (
        SELECT *
        FROM `@{schema_name}.bi_star.append_window_dbo_InvenStyle_view`
        WHERE IsDeleted = FALSE
      ),
      extended AS (
        SELECT
          StyleId,
          CustomLongText1, CustomLongText2, CustomLongText3, CustomLongText4, CustomLongText5, CustomLongText6,
          CustomLongText7, CustomLongText8, CustomLongText9, CustomLongText10, CustomLongText11, CustomLongText12,
          CustomLongText13, CustomLongText14, CustomLongText15, CustomLongText16, CustomLongText17, CustomLongText18
        FROM `@{schema_name}.bi_star.append_window_dbo_InvenStyleExtended_view`
        WHERE IsDeleted = FALSE
      ),
      lookups AS (
        SELECT
          StyleId,
          CustomLookup1, CustomLookup2, CustomLookup3, CustomLookup4, CustomLookup5, CustomLookup6,
          CustomLookup7, CustomLookup8, CustomLookup9, CustomLookup10, CustomLookup11, CustomLookup12
        FROM `@{schema_name}.bi_star.mv_StyleCustomLookup_view`
      ),
      primary_vendor AS (
        -- mv_PrimaryVendor_view is at ItemId grain with denormalized StyleId.
        -- Aggregate to StyleId via MAX() — IsPrimary is a style-level flag, so
        -- vendor identity is consistent across SKUs of a style; numeric fields
        -- (cost, lead time, WoS) may vary slightly by SKU but MAX is deterministic.
        SELECT
          StyleId,
          MAX(VendorID)                       AS vendor_id,
          MAX(VendorName)                     AS vendor_name,
          MAX(VendorCode)                     AS vendor_code,
          MAX(OrderCost)                      AS order_cost,
          MAX(ForeignCurrencyOrderCost)       AS foreign_currency_order_cost,
          MAX(LeadTime)                       AS lead_time,
          MAX(DaysInTransit)                  AS days_in_transit,
          MAX(MinQty)                         AS min_qty,
          MAX(MinPurchaseAmount)              AS min_purchase_amount,
          MAX(WeeksOfSupply)                  AS weeks_of_supply,
          MAX(WeeksOfSupplyMax)               AS weeks_of_supply_max,
          MAX(DefaultVendorWeeksOfSupply)     AS default_vendor_weeks_of_supply,
          MAX(DefaultVendorWeeksOfSupplyMax)  AS default_vendor_weeks_of_supply_max,
          MAX(DefaultVendorLeadTime)          AS default_vendor_lead_time
        FROM `@{schema_name}.bi_star.mv_PrimaryVendor_view`
        WHERE StyleId IS NOT NULL
        GROUP BY StyleId
      ),
      brands AS (
        SELECT InvenBrandID AS brand_id, MAX(Name) AS brand_name
        FROM `@{schema_name}.bi_star.append_window_dbo_InvenBrand_view`
        WHERE IsDeleted = FALSE
        GROUP BY InvenBrandID
      ),
      seasons AS (
        SELECT InvenSeasonId AS season_id, MAX(Name) AS season_name, MAX(No) AS season_no
        FROM `@{schema_name}.bi_star.append_window_dbo_InvenSeason_view`
        WHERE IsDeleted = FALSE
        GROUP BY InvenSeasonId
      ),
      manufacturers AS (
        -- ManufacturerId is a vendor reference; resolve via dim_Vendor_view.
        SELECT VendorId AS manufacturer_id, MAX(VendorName) AS manufacturer_name, MAX(VendorNo) AS manufacturer_no
        FROM `@{schema_name}.bi_star.dim_Vendor_view`
        GROUP BY VendorId
      ),
      countries AS (
        SELECT
          CountryID                AS country_id,
          MAX(Code)                AS country_code,
          MAX(ShortName)           AS country_short_name,
          MAX(Alpha3Code)          AS country_alpha3_code
        FROM `@{schema_name}.bi_star.append_window_dbo_Country_view`
        WHERE IsDeleted = FALSE
        GROUP BY CountryID
      ),
      tax_categories AS (
        SELECT
          TaxCategoryID            AS tax_category_id,
          MAX(Name)                AS tax_category_name,
          MAX(Description)         AS tax_category_description
        FROM `@{schema_name}.bi_star.append_window_dbo_TaxCategory_view`
        WHERE IsDeleted = FALSE
        GROUP BY TaxCategoryID
      ),
      attribute_sets AS (
        SELECT
          AttributeSetID           AS attribute_set_id,
          MAX(DisplayLabel)        AS attribute_set_label,
          MAX(Description)         AS attribute_set_description,
          MAX(Code)                AS attribute_set_code
        FROM `@{schema_name}.bi_star.append_window_dbo_AttributeSet_view`
        WHERE IsDeleted = FALSE
        GROUP BY AttributeSetID
      ),
      style_code AS (
        -- dim_Item is the denormalized item dim — use it to bridge from
        -- StyleId (bi_star key) to Style (the human-readable code that
        -- joins to item_master) and to pull DCSS hierarchy strings.
        SELECT
          StyleId,
          MAX(Style)      AS style,
          MAX(Department) AS department,
          MAX(Class)      AS class,
          MAX(Subclass1)  AS subclass1,
          MAX(Subclass2)  AS subclass2,
          MAX(DCSS)       AS dcss
        FROM `@{schema_name}.bi_star.dim_Item`
        WHERE StyleId IS NOT NULL
        GROUP BY StyleId
      )
      SELECT
        s.*,
        sc.style                                  AS style_code,
        sc.department                             AS department,
        sc.class                                  AS class,
        sc.subclass1                              AS subclass1,
        sc.subclass2                              AS subclass2,
        sc.dcss                                   AS dcss,
        ext.CustomLongText1, ext.CustomLongText2, ext.CustomLongText3,
        ext.CustomLongText4, ext.CustomLongText5, ext.CustomLongText6,
        ext.CustomLongText7, ext.CustomLongText8, ext.CustomLongText9,
        ext.CustomLongText10, ext.CustomLongText11, ext.CustomLongText12,
        ext.CustomLongText13, ext.CustomLongText14, ext.CustomLongText15,
        ext.CustomLongText16, ext.CustomLongText17, ext.CustomLongText18,
        lkp.CustomLookup1, lkp.CustomLookup2, lkp.CustomLookup3,
        lkp.CustomLookup4, lkp.CustomLookup5, lkp.CustomLookup6,
        lkp.CustomLookup7, lkp.CustomLookup8, lkp.CustomLookup9,
        lkp.CustomLookup10, lkp.CustomLookup11, lkp.CustomLookup12,
        b.brand_name,
        se.season_name,
        se.season_no,
        mfg.manufacturer_name,
        mfg.manufacturer_no,
        c.country_code                            AS country_of_origin_code,
        c.country_short_name                      AS country_of_origin_name,
        c.country_alpha3_code                     AS country_of_origin_alpha3_code,
        tc.tax_category_name                      AS tax_category_name,
        tc.tax_category_description               AS tax_category_description,
        ipi.tax_category_name                     AS ipi_tax_category_name,
        ipi.tax_category_description              AS ipi_tax_category_description,
        a1.attribute_set_label                    AS attribute_1_set_label,
        a1.attribute_set_description              AS attribute_1_set_description,
        a1.attribute_set_code                     AS attribute_1_set_code,
        a2.attribute_set_label                    AS attribute_2_set_label,
        a2.attribute_set_description              AS attribute_2_set_description,
        a2.attribute_set_code                     AS attribute_2_set_code,
        a3.attribute_set_label                    AS attribute_3_set_label,
        a3.attribute_set_description              AS attribute_3_set_description,
        a3.attribute_set_code                     AS attribute_3_set_code,
        pv.vendor_id                              AS primary_vendor_id,
        pv.vendor_name                            AS primary_vendor_name,
        pv.vendor_code                            AS primary_vendor_code,
        pv.order_cost                             AS primary_vendor_order_cost,
        pv.foreign_currency_order_cost            AS primary_vendor_foreign_currency_order_cost,
        pv.lead_time                              AS primary_vendor_lead_time,
        pv.days_in_transit                        AS primary_vendor_days_in_transit,
        pv.min_qty                                AS primary_vendor_min_qty,
        pv.min_purchase_amount                    AS primary_vendor_min_purchase_amount,
        pv.weeks_of_supply                        AS primary_vendor_weeks_of_supply,
        pv.weeks_of_supply_max                    AS primary_vendor_weeks_of_supply_max,
        pv.default_vendor_weeks_of_supply         AS primary_vendor_default_weeks_of_supply,
        pv.default_vendor_weeks_of_supply_max     AS primary_vendor_default_weeks_of_supply_max,
        pv.default_vendor_lead_time               AS primary_vendor_default_lead_time
      FROM style s
      LEFT JOIN extended       ext ON ext.StyleId            = s.StyleId
      LEFT JOIN lookups        lkp ON lkp.StyleId            = s.StyleId
      LEFT JOIN primary_vendor pv  ON pv.StyleId             = s.StyleId
      LEFT JOIN style_code     sc  ON sc.StyleId             = s.StyleId
      LEFT JOIN brands         b   ON b.brand_id             = s.BrandId
      LEFT JOIN seasons        se  ON se.season_id           = s.SeasonId
      LEFT JOIN manufacturers  mfg ON mfg.manufacturer_id    = s.ManufacturerId
      LEFT JOIN countries      c   ON c.country_id           = s.CountryOfOriginId
      LEFT JOIN tax_categories tc  ON tc.tax_category_id     = s.TaxCategoryId
      LEFT JOIN tax_categories ipi ON ipi.tax_category_id    = s.IPITaxCategoryId
      LEFT JOIN attribute_sets a1  ON a1.attribute_set_id    = s.Attribute1SetId
      LEFT JOIN attribute_sets a2  ON a2.attribute_set_id    = s.Attribute2SetId
      LEFT JOIN attribute_sets a3  ON a3.attribute_set_id    = s.Attribute3SetId
    ;;
  }

  # ══════════════════════════════════════════════════════════════
  # Identifiers
  # ══════════════════════════════════════════════════════════════

  dimension: style_id {
    primary_key: yes
    group_label: "Style Identifiers"
    label: "Style ID"
    description: "Internal style GUID (foreign key in bi_star fact tables). Hidden by default — use Style (human-readable code) for filtering and joining to item_master."
    type: string
    sql: ${TABLE}.StyleId ;;
    hidden: yes
  }

  dimension: style {
    group_label: "Style Identifiers"
    description: "Human-readable style code (e.g. 'ABC123'). Groups SKUs that share the same product. Joins to item_master.style."
    type: string
    sql: ${TABLE}.style_code ;;
  }

  dimension: style_no {
    group_label: "Style Identifiers"
    label: "Style Number"
    description: "Vendor or merchandiser style number associated with the style."
    type: string
    sql: ${TABLE}.StyleNo ;;
  }

  dimension: style_no_sort {
    group_label: "Style Identifiers"
    label: "Style Number (Sortable)"
    description: "Sortable variant of Style Number (zero-padded for ordering)."
    type: string
    sql: ${TABLE}.StyleNoSort ;;
    hidden: yes
  }

  dimension: external_style_id {
    group_label: "Style Identifiers"
    label: "External Style ID"
    description: "External system identifier for the style (e.g. e-commerce platform reference)."
    type: string
    sql: ${TABLE}.ExternalStyleId ;;
  }

  dimension: like_style_id {
    group_label: "Style Identifiers"
    label: "Like Style ID"
    description: "StyleId of a similar/predecessor style — used for new-item analogs and forecasting."
    type: string
    sql: ${TABLE}.LikeStyleId ;;
  }

  # ══════════════════════════════════════════════════════════════
  # DCSS Hierarchy (resolved strings via dim_Item)
  # ══════════════════════════════════════════════════════════════

  dimension: dcss {
    group_label: "DCSS Hierarchy"
    label: "DCSS"
    description: "Concatenated merchandise hierarchy (Department / Class / Subclass1 / Subclass2). Use the individual levels for filtering and pivoting."
    type: string
    sql: ${TABLE}.dcss ;;
  }

  dimension: department {
    group_label: "DCSS Hierarchy"
    description: "Top level of the merchandise hierarchy."
    type: string
    sql: ${TABLE}.department ;;
  }

  dimension: class {
    group_label: "DCSS Hierarchy"
    description: "Second level of the merchandise hierarchy, beneath Department."
    type: string
    sql: ${TABLE}.class ;;
  }

  dimension: subclass1 {
    group_label: "DCSS Hierarchy"
    label: "Subclass 1"
    description: "Third level of the merchandise hierarchy, beneath Class."
    type: string
    sql: ${TABLE}.subclass1 ;;
  }

  dimension: subclass2 {
    group_label: "DCSS Hierarchy"
    label: "Subclass 2"
    description: "Fourth level of the merchandise hierarchy — most granular DCSS level."
    type: string
    sql: ${TABLE}.subclass2 ;;
  }

  dimension: dcss_id { group_label: "DCSS Hierarchy" label: "DCSS ID" description: "Foreign key to the DCSS hierarchy node. Use the resolved Department/Class/Subclass1/Subclass2 strings above for reporting." type: string sql: ${TABLE}.DCSSId ;; hidden: yes }

  # ══════════════════════════════════════════════════════════════
  # Brand / Manufacturer / Season (resolved labels)
  # ══════════════════════════════════════════════════════════════

  dimension: brand {
    group_label: "Brand & Manufacturer"
    description: "Brand name (resolved from BrandId via InvenBrand_view)."
    type: string
    sql: ${TABLE}.brand_name ;;
  }

  dimension: brand_id {
    group_label: "Brand & Manufacturer"
    label: "Brand ID"
    description: "Foreign key to brand dimension."
    type: string
    sql: ${TABLE}.BrandId ;;
    hidden: yes
  }

  dimension: manufacturer {
    group_label: "Brand & Manufacturer"
    description: "Manufacturer name (resolved from ManufacturerId via dim_Vendor — manufacturer is modeled as a vendor with IsManufacturer=TRUE)."
    type: string
    sql: ${TABLE}.manufacturer_name ;;
  }

  dimension: manufacturer_no {
    group_label: "Brand & Manufacturer"
    label: "Manufacturer Number"
    description: "Manufacturer's vendor number (resolved from ManufacturerId)."
    type: string
    sql: ${TABLE}.manufacturer_no ;;
  }

  dimension: manufacturer_id {
    group_label: "Brand & Manufacturer"
    label: "Manufacturer ID"
    description: "Foreign key to manufacturer (which is a row in dim_Vendor)."
    type: string
    sql: ${TABLE}.ManufacturerId ;;
    hidden: yes
  }

  dimension: season {
    group_label: "Season"
    description: "Merchandising season name (resolved from SeasonId via InvenSeason_view, e.g. 'Spring 2026', 'Holiday')."
    type: string
    sql: ${TABLE}.season_name ;;
  }

  dimension: season_no {
    group_label: "Season"
    label: "Season Number"
    description: "Numeric season code (sortable)."
    type: number
    sql: ${TABLE}.season_no ;;
  }

  dimension: season_id {
    group_label: "Season"
    label: "Season ID"
    description: "Foreign key to season dimension."
    type: string
    sql: ${TABLE}.SeasonId ;;
    hidden: yes
  }

  # ══════════════════════════════════════════════════════════════
  # Country of Origin (resolved labels)
  # ══════════════════════════════════════════════════════════════

  dimension: country_of_origin {
    group_label: "Country Of Origin"
    description: "Country of origin short name (resolved from CountryOfOriginId)."
    type: string
    sql: ${TABLE}.country_of_origin_name ;;
  }

  dimension: country_of_origin_code        { group_label: "Country Of Origin" label: "Country Of Origin Code"        description: "Short country code (e.g. 'US', 'CN')."           type: string sql: ${TABLE}.country_of_origin_code ;; }
  dimension: country_of_origin_alpha3_code { group_label: "Country Of Origin" label: "Country Of Origin Alpha-3 Code" description: "ISO 3166-1 alpha-3 country code (e.g. 'USA', 'CHN')." type: string sql: ${TABLE}.country_of_origin_alpha3_code ;; }
  dimension: country_of_origin_id          { group_label: "Country Of Origin" label: "Country Of Origin ID"          description: "Foreign key to country dimension."               type: string sql: ${TABLE}.CountryOfOriginId ;; hidden: yes }

  # ══════════════════════════════════════════════════════════════
  # Tax Categories (resolved labels)
  # ══════════════════════════════════════════════════════════════

  dimension: tax_category {
    group_label: "Tax Categories"
    description: "Standard tax category name (resolved from TaxCategoryId)."
    type: string
    sql: ${TABLE}.tax_category_name ;;
  }

  dimension: tax_category_description {
    group_label: "Tax Categories"
    label: "Tax Category Description"
    description: "Long-form description of the tax category."
    type: string
    sql: ${TABLE}.tax_category_description ;;
  }

  dimension: ipi_tax_category {
    group_label: "Tax Categories"
    label: "IPI Tax Category"
    description: "IPI tax category name (Brazilian indirect tax — resolved from IPITaxCategoryId)."
    type: string
    sql: ${TABLE}.ipi_tax_category_name ;;
  }

  dimension: ipi_tax_category_description {
    group_label: "Tax Categories"
    label: "IPI Tax Category Description"
    description: "Long-form description of the IPI tax category."
    type: string
    sql: ${TABLE}.ipi_tax_category_description ;;
  }

  dimension: tax_category_id     { group_label: "Tax Categories" label: "Tax Category ID"     description: "Foreign key to standard tax category." type: string sql: ${TABLE}.TaxCategoryId ;;    hidden: yes }
  dimension: ipi_tax_category_id { group_label: "Tax Categories" label: "IPI Tax Category ID" description: "Foreign key to IPI tax category."      type: string sql: ${TABLE}.IPITaxCategoryId ;; hidden: yes }

  # ══════════════════════════════════════════════════════════════
  # Variant Attribute Sets (defines size/color axes per style)
  # ══════════════════════════════════════════════════════════════

  dimension: attribute_1_set            { group_label: "Variant Attribute Sets" label: "Attribute 1 Set"            description: "Display label for the Attribute 1 axis (e.g. 'Size', 'Color') — what variant dimension this style uses."     type: string sql: ${TABLE}.attribute_1_set_label ;; }
  dimension: attribute_1_set_code       { group_label: "Variant Attribute Sets" label: "Attribute 1 Set Code"       description: "Code identifier for the Attribute 1 set."                                                                       type: string sql: ${TABLE}.attribute_1_set_code ;; }
  dimension: attribute_1_set_description { group_label: "Variant Attribute Sets" label: "Attribute 1 Set Description" description: "Long description of the Attribute 1 set."                                                                       type: string sql: ${TABLE}.attribute_1_set_description ;; }
  dimension: attribute1_set_id          { group_label: "Variant Attribute Sets" label: "Attribute 1 Set ID"         description: "Foreign key to AttributeSet for the Attribute 1 axis."                                                          type: string sql: ${TABLE}.Attribute1SetId ;; hidden: yes }

  dimension: attribute_2_set            { group_label: "Variant Attribute Sets" label: "Attribute 2 Set"            description: "Display label for the Attribute 2 axis."           type: string sql: ${TABLE}.attribute_2_set_label ;; }
  dimension: attribute_2_set_code       { group_label: "Variant Attribute Sets" label: "Attribute 2 Set Code"       description: "Code identifier for the Attribute 2 set."          type: string sql: ${TABLE}.attribute_2_set_code ;; }
  dimension: attribute_2_set_description { group_label: "Variant Attribute Sets" label: "Attribute 2 Set Description" description: "Long description of the Attribute 2 set."          type: string sql: ${TABLE}.attribute_2_set_description ;; }
  dimension: attribute2_set_id          { group_label: "Variant Attribute Sets" label: "Attribute 2 Set ID"         description: "Foreign key to AttributeSet for the Attribute 2 axis." type: string sql: ${TABLE}.Attribute2SetId ;; hidden: yes }

  dimension: attribute_3_set            { group_label: "Variant Attribute Sets" label: "Attribute 3 Set"            description: "Display label for the Attribute 3 axis."           type: string sql: ${TABLE}.attribute_3_set_label ;; }
  dimension: attribute_3_set_code       { group_label: "Variant Attribute Sets" label: "Attribute 3 Set Code"       description: "Code identifier for the Attribute 3 set."          type: string sql: ${TABLE}.attribute_3_set_code ;; }
  dimension: attribute_3_set_description { group_label: "Variant Attribute Sets" label: "Attribute 3 Set Description" description: "Long description of the Attribute 3 set."          type: string sql: ${TABLE}.attribute_3_set_description ;; }
  dimension: attribute3_set_id          { group_label: "Variant Attribute Sets" label: "Attribute 3 Set ID"         description: "Foreign key to AttributeSet for the Attribute 3 axis." type: string sql: ${TABLE}.Attribute3SetId ;; hidden: yes }

  # ══════════════════════════════════════════════════════════════
  # Other Foreign Keys
  # ══════════════════════════════════════════════════════════════

  dimension: acss_id           { group_label: "Other FKs" label: "ACSS ID"           description: "Foreign key to alternate hierarchy (Analytical Class/Subclass)."                                                  type: string sql: ${TABLE}.ACSSId ;; }
  dimension: service_fee_id    { group_label: "Other FKs" label: "Service Fee ID"    description: "Foreign key to service fee configuration."                                                                          type: string sql: ${TABLE}.ServiceFeeId ;; }
  dimension: owner_location_id { group_label: "Other FKs" label: "Owner Location ID" description: "Location that owns this style (used for franchise / consignment models)."                                          type: string sql: ${TABLE}.OwnerLocationId ;; }
  dimension: company_id        { group_label: "Other FKs" label: "Company ID"        description: "Owning company identifier."                                                                                          type: string sql: ${TABLE}.CompanyId ;; }
  dimension: location_id       { group_label: "Other FKs" label: "Location ID"       description: "Originating location identifier."                                                                                    type: string sql: ${TABLE}.LocationId ;; }

  # ══════════════════════════════════════════════════════════════
  # Descriptions
  # ══════════════════════════════════════════════════════════════

  dimension: description       { group_label: "Descriptions" label: "Description"       description: "Primary style description used on receipts, signage, and reports." type: string sql: ${TABLE}.Description ;; }
  dimension: description2      { group_label: "Descriptions" label: "Description 2"     description: "Secondary description (long-form or alternate language)." type: string sql: ${TABLE}.Description2 ;; }
  dimension: description3      { group_label: "Descriptions" label: "Description 3"     description: "Tertiary description (purpose varies by retailer convention)." type: string sql: ${TABLE}.Description3 ;; }
  dimension: description4      { group_label: "Descriptions" label: "Description 4"     description: "Fourth description slot." type: string sql: ${TABLE}.Description4 ;; }
  dimension: ecomm_description { group_label: "Descriptions" label: "E-Comm Description" description: "Description used on the e-commerce storefront." type: string sql: ${TABLE}.ECommDescription ;; }
  dimension: notes             { group_label: "Descriptions" label: "Notes"             description: "Free-text internal notes on the style." type: string sql: ${TABLE}.Notes ;; }

  # ══════════════════════════════════════════════════════════════
  # Status & Flags (Built-In)
  # ══════════════════════════════════════════════════════════════

  dimension: is_inactive {
    group_label: "Status"
    label: "Is Inactive"
    description: "Yes when the style has been deactivated and should not be sold or reordered."
    type: yesno
    sql: ${TABLE}.Inactive ;;
  }

  dimension: is_held               { group_label: "Status" label: "Is Held"               description: "Yes when the style is currently held (e.g. quality issue, vendor recall)."                                              type: yesno sql: ${TABLE}.IsHeld ;; }
  dimension: is_style_record       { group_label: "Status" label: "Is Style Record"       description: "Internal flag — Yes when this row represents a true style (vs. a non-style item record)."                              type: yesno sql: ${TABLE}.IsStyle ;; hidden: yes }
  dimension: is_weighted           { group_label: "Status" label: "Is Weighted"           description: "Yes when the style is sold by weight (e.g. produce, deli)."                                                            type: yesno sql: ${TABLE}.IsWeighted ;; }
  dimension: not_track_oh          { group_label: "Status" label: "Not Track On-Hand"     description: "Yes when on-hand inventory is not tracked for this style (services, fees, gift cards)."                              type: yesno sql: ${TABLE}.NotTrackOH ;; }
  dimension: replenishment         { group_label: "Status" label: "Replenishment"         description: "Yes when the style is auto-replenished by purchasing."                                                                  type: yesno sql: ${TABLE}.Replenishment ;; }
  dimension: rental                { group_label: "Status" label: "Rental"                description: "Yes when the style is available for rental."                                                                            type: yesno sql: ${TABLE}.Rental ;; }
  dimension: repair                { group_label: "Status" label: "Repair"                description: "Yes when the style represents a repair service item."                                                                   type: yesno sql: ${TABLE}.Repair ;; }
  dimension: trade                 { group_label: "Status" label: "Trade"                 description: "Yes when the style is eligible for trade-in transactions."                                                              type: yesno sql: ${TABLE}.Trade ;; }
  dimension: can_be_used           { group_label: "Status" label: "Can Be Used"           description: "Yes when the style supports being sold as 'used' (e.g. resale)."                                                       type: yesno sql: ${TABLE}.CanBeUsed ;; }
  dimension: require_item_availability { group_label: "Status" label: "Require Item Availability" description: "Yes when sales of this style require explicit item availability checks (no overselling)."                  type: yesno sql: ${TABLE}.RequireItemAvailability ;; }
  dimension: require_discount_authorization_code { group_label: "Status" label: "Require Discount Authorization Code" description: "Yes when discounting this style requires an authorization code." type: yesno sql: ${TABLE}.RequireDiscountAuthorizationCode ;; }
  dimension: auto_prompt_to_pay_with_tokens { group_label: "Status" label: "Auto Prompt Tokens" description: "Yes when the POS auto-prompts to redeem tokens at sale time."             type: yesno sql: ${TABLE}.AutoPromptToPayWithTokens ;; }

  # ── Loyalty ──

  dimension: eligible_for_loyalty_rewards   { group_label: "Loyalty" label: "Eligible For Loyalty Rewards"   description: "Yes when the style accrues primary loyalty rewards."   type: yesno  sql: ${TABLE}.EligibleForLoyaltyRewards ;; }
  dimension: eligible_for_loyalty_rewards_2 { group_label: "Loyalty" label: "Eligible For Loyalty Rewards 2" description: "Yes when the style accrues secondary loyalty rewards." type: yesno  sql: ${TABLE}.EligibleForLoyaltyRewards2 ;; }
  dimension: loyalty_rewards_1_ratio        { group_label: "Loyalty" label: "Loyalty Rewards 1 Ratio"        description: "Multiplier applied to primary loyalty point accrual." type: number sql: ${TABLE}.LoyaltyRewards1Ratio ;; value_format_name: decimal_2 }
  dimension: loyalty_rewards_2_ratio        { group_label: "Loyalty" label: "Loyalty Rewards 2 Ratio"        description: "Multiplier applied to secondary loyalty point accrual." type: number sql: ${TABLE}.LoyaltyRewards2Ratio ;; value_format_name: decimal_2 }

  # ── Inventory Mode ──

  dimension: inven_type {
    group_label: "Inventory Mode"
    label: "Inventory Type"
    description: "Inventory tracking mode (integer enum from source). Resolve to label via the inventory type lookup."
    type: number
    sql: ${TABLE}.InvenType ;;
  }

  dimension: serial_number_tracking {
    group_label: "Inventory Mode"
    label: "Serial Number Tracking"
    description: "Serial-number tracking mode (integer enum: none / on receipt / on sale)."
    type: number
    sql: ${TABLE}.SerialNumberTracking ;;
  }

  # ── Special Order ──

  dimension: so_deposit_required_option { group_label: "Special Order" label: "Deposit Required Option" description: "Special-order deposit policy (integer enum)." type: number sql: ${TABLE}.SODepositRequiredOption ;; }
  dimension: so_deposit_amount          { group_label: "Special Order" label: "Deposit Amount"          description: "Required deposit amount for special orders. USD." type: number sql: ${TABLE}.SODepositAmount ;; value_format_name: usd }

  # ══════════════════════════════════════════════════════════════
  # Physical Dimensions
  # ══════════════════════════════════════════════════════════════

  dimension: width  { group_label: "Physical" description: "Style width (units per source system convention)."  type: number sql: ${TABLE}.Width ;;  value_format_name: decimal_2 }
  dimension: height { group_label: "Physical" description: "Style height (units per source system convention)." type: number sql: ${TABLE}.Height ;; value_format_name: decimal_2 }
  dimension: length { group_label: "Physical" description: "Style length (units per source system convention)." type: number sql: ${TABLE}.Length ;; value_format_name: decimal_2 }
  dimension: weight { group_label: "Physical" description: "Style weight (units per source system convention)." type: number sql: ${TABLE}.Weight ;; value_format_name: decimal_2 }

  # ══════════════════════════════════════════════════════════════
  # Image
  # ══════════════════════════════════════════════════════════════

  dimension: image_blob {
    group_label: "Media"
    label: "Image Blob"
    description: "Style image — base64-encoded blob or URL. Hidden by default; reveal in custom Looks if needed."
    type: string
    sql: ${TABLE}.ImageBlob ;;
    hidden: yes
  }

  # ══════════════════════════════════════════════════════════════
  # Lifecycle Dates
  # ══════════════════════════════════════════════════════════════

  dimension_group: date_available {
    group_label: "Lifecycle Dates"
    label: "Date Available"
    description: "Date the style first became available for sale."
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.DateAvailable ;;
  }

  dimension_group: last_sent {
    group_label: "Lifecycle Dates"
    label: "Last Sent"
    description: "Last date the style record was synced to a downstream system."
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.LastSent ;;
  }

  # ══════════════════════════════════════════════════════════════
  # Audit
  # ══════════════════════════════════════════════════════════════

  dimension_group: rec_created {
    group_label: "Audit"
    label: "Record Created"
    description: "Timestamp when the style record was first created in the source system."
    type: time
    timeframes: [raw, date, time, week, month, quarter, year]
    sql: ${TABLE}.RecCreated ;;
  }

  dimension_group: rec_modified {
    group_label: "Audit"
    label: "Record Modified"
    description: "Timestamp of the most recent modification to the style record in the source system."
    type: time
    timeframes: [raw, date, time, week, month, quarter, year]
    sql: ${TABLE}.RecModified ;;
  }

  # ══════════════════════════════════════════════════════════════
  # Primary Vendor (resolved via mv_PrimaryVendor_view, aggregated to StyleId)
  # ══════════════════════════════════════════════════════════════

  dimension: primary_vendor                              { group_label: "Primary Vendor" label: "Primary Vendor"                              description: "Primary vendor name (resolved from VendorID)."                                                                          type: string sql: ${TABLE}.primary_vendor_name ;; }
  dimension: primary_vendor_code                         { group_label: "Primary Vendor" label: "Primary Vendor Code"                         description: "Primary vendor code."                                                                                                    type: string sql: ${TABLE}.primary_vendor_code ;; }
  dimension: primary_vendor_id                          { group_label: "Primary Vendor" label: "Primary Vendor ID"                           description: "Foreign key to the primary vendor in dim_Vendor."                                                                       type: string sql: ${TABLE}.primary_vendor_id ;; hidden: yes }
  dimension: primary_vendor_order_cost                  { group_label: "Primary Vendor" label: "Primary Vendor Order Cost"                   description: "Negotiated unit cost from the primary vendor. USD. Aggregated MAX across the style's SKUs (consistent if vendor sets one cost per style)." type: number sql: ${TABLE}.primary_vendor_order_cost ;; value_format_name: usd }
  dimension: primary_vendor_foreign_currency_order_cost { group_label: "Primary Vendor" label: "Primary Vendor Foreign Currency Order Cost"  description: "Order cost denominated in the vendor's foreign currency."                                                                type: number sql: ${TABLE}.primary_vendor_foreign_currency_order_cost ;; value_format_name: decimal_2 }
  dimension: primary_vendor_lead_time                   { group_label: "Primary Vendor" label: "Primary Vendor Lead Time"                    description: "Lead time in days from primary vendor."                                                                                  type: number sql: ${TABLE}.primary_vendor_lead_time ;; }
  dimension: primary_vendor_days_in_transit             { group_label: "Primary Vendor" label: "Primary Vendor Days In Transit"              description: "Days in transit from primary vendor (separate from lead time)."                                                          type: number sql: ${TABLE}.primary_vendor_days_in_transit ;; }
  dimension: primary_vendor_min_qty                     { group_label: "Primary Vendor" label: "Primary Vendor Min Qty"                      description: "Minimum order quantity required by the primary vendor."                                                                  type: number sql: ${TABLE}.primary_vendor_min_qty ;; }
  dimension: primary_vendor_min_purchase_amount         { group_label: "Primary Vendor" label: "Primary Vendor Min Purchase Amount"          description: "Minimum order dollar amount required by the primary vendor. USD."                                                       type: number sql: ${TABLE}.primary_vendor_min_purchase_amount ;; value_format_name: usd }
  dimension: primary_vendor_weeks_of_supply             { group_label: "Primary Vendor" label: "Primary Vendor Weeks Of Supply"              description: "Target weeks of supply on the primary vendor link."                                                                       type: number sql: ${TABLE}.primary_vendor_weeks_of_supply ;; value_format_name: decimal_1 }
  dimension: primary_vendor_weeks_of_supply_max         { group_label: "Primary Vendor" label: "Primary Vendor Weeks Of Supply Max"          description: "Upper bound on weeks of supply (replenishment cap)."                                                                      type: number sql: ${TABLE}.primary_vendor_weeks_of_supply_max ;; value_format_name: decimal_1 }
  dimension: primary_vendor_default_weeks_of_supply     { group_label: "Primary Vendor" label: "Primary Vendor Default Weeks Of Supply"      description: "Default weeks of supply when no SKU-specific override exists."                                                            type: number sql: ${TABLE}.primary_vendor_default_weeks_of_supply ;; value_format_name: decimal_1 }
  dimension: primary_vendor_default_weeks_of_supply_max { group_label: "Primary Vendor" label: "Primary Vendor Default Weeks Of Supply Max"  description: "Default upper-bound weeks of supply when no SKU-specific override exists."                                                type: number sql: ${TABLE}.primary_vendor_default_weeks_of_supply_max ;; value_format_name: decimal_1 }
  dimension: primary_vendor_default_lead_time           { group_label: "Primary Vendor" label: "Primary Vendor Default Lead Time"            description: "Default lead time in days when no SKU-specific override exists."                                                          type: number sql: ${TABLE}.primary_vendor_default_lead_time ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Lookups (resolved labels via mv_StyleCustomLookup)
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_lookup_1  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 1"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup1 ;; }
  dimension: style_custom_lookup_2  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 2"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup2 ;; }
  dimension: style_custom_lookup_3  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 3"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup3 ;; }
  dimension: style_custom_lookup_4  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 4"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup4 ;; }
  dimension: style_custom_lookup_5  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 5"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup5 ;; }
  dimension: style_custom_lookup_6  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 6"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup6 ;; }
  dimension: style_custom_lookup_7  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 7"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup7 ;; }
  dimension: style_custom_lookup_8  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 8"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup8 ;; }
  dimension: style_custom_lookup_9  { group_label: "Style Custom Lookups" label: "Style Custom Lookup 9"  description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup9 ;; }
  dimension: style_custom_lookup_10 { group_label: "Style Custom Lookups" label: "Style Custom Lookup 10" description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup10 ;; }
  dimension: style_custom_lookup_11 { group_label: "Style Custom Lookups" label: "Style Custom Lookup 11" description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup11 ;; }
  dimension: style_custom_lookup_12 { group_label: "Style Custom Lookups" label: "Style Custom Lookup 12" description: "Client-configured custom lookup (resolved label). Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLookup12 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Texts (1-12)
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_text_1  { group_label: "Style Custom Texts" label: "Style Custom Text 1"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText1 ;; }
  dimension: style_custom_text_2  { group_label: "Style Custom Texts" label: "Style Custom Text 2"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText2 ;; }
  dimension: style_custom_text_3  { group_label: "Style Custom Texts" label: "Style Custom Text 3"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText3 ;; }
  dimension: style_custom_text_4  { group_label: "Style Custom Texts" label: "Style Custom Text 4"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText4 ;; }
  dimension: style_custom_text_5  { group_label: "Style Custom Texts" label: "Style Custom Text 5"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText5 ;; }
  dimension: style_custom_text_6  { group_label: "Style Custom Texts" label: "Style Custom Text 6"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText6 ;; }
  dimension: style_custom_text_7  { group_label: "Style Custom Texts" label: "Style Custom Text 7"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText7 ;; }
  dimension: style_custom_text_8  { group_label: "Style Custom Texts" label: "Style Custom Text 8"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText8 ;; }
  dimension: style_custom_text_9  { group_label: "Style Custom Texts" label: "Style Custom Text 9"  description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText9 ;; }
  dimension: style_custom_text_10 { group_label: "Style Custom Texts" label: "Style Custom Text 10" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText10 ;; }
  dimension: style_custom_text_11 { group_label: "Style Custom Texts" label: "Style Custom Text 11" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText11 ;; }
  dimension: style_custom_text_12 { group_label: "Style Custom Texts" label: "Style Custom Text 12" description: "Client-configured custom field — meaning is unmapped. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomText12 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Long Texts (1-18) — from InvenStyleExtended
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_long_text_1  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 1"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText1 ;; }
  dimension: style_custom_long_text_2  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 2"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText2 ;; }
  dimension: style_custom_long_text_3  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 3"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText3 ;; }
  dimension: style_custom_long_text_4  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 4"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText4 ;; }
  dimension: style_custom_long_text_5  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 5"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText5 ;; }
  dimension: style_custom_long_text_6  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 6"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText6 ;; }
  dimension: style_custom_long_text_7  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 7"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText7 ;; }
  dimension: style_custom_long_text_8  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 8"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText8 ;; }
  dimension: style_custom_long_text_9  { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 9"  description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText9 ;; }
  dimension: style_custom_long_text_10 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 10" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText10 ;; }
  dimension: style_custom_long_text_11 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 11" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText11 ;; }
  dimension: style_custom_long_text_12 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 12" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText12 ;; }
  dimension: style_custom_long_text_13 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 13" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText13 ;; }
  dimension: style_custom_long_text_14 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 14" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText14 ;; }
  dimension: style_custom_long_text_15 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 15" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText15 ;; }
  dimension: style_custom_long_text_16 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 16" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText16 ;; }
  dimension: style_custom_long_text_17 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 17" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText17 ;; }
  dimension: style_custom_long_text_18 { group_label: "Style Custom Long Texts" label: "Style Custom Long Text 18" description: "Client-configured long-text custom field. Edit this description with the actual business definition before report developers rely on it." type: string sql: ${TABLE}.CustomLongText18 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Dates (1-12)
  # ══════════════════════════════════════════════════════════════

  dimension_group: style_custom_date_1  { group_label: "Style Custom Dates" label: "Style Custom Date 1"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate1 ;; }
  dimension_group: style_custom_date_2  { group_label: "Style Custom Dates" label: "Style Custom Date 2"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate2 ;; }
  dimension_group: style_custom_date_3  { group_label: "Style Custom Dates" label: "Style Custom Date 3"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate3 ;; }
  dimension_group: style_custom_date_4  { group_label: "Style Custom Dates" label: "Style Custom Date 4"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate4 ;; }
  dimension_group: style_custom_date_5  { group_label: "Style Custom Dates" label: "Style Custom Date 5"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate5 ;; }
  dimension_group: style_custom_date_6  { group_label: "Style Custom Dates" label: "Style Custom Date 6"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate6 ;; }
  dimension_group: style_custom_date_7  { group_label: "Style Custom Dates" label: "Style Custom Date 7"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate7 ;; }
  dimension_group: style_custom_date_8  { group_label: "Style Custom Dates" label: "Style Custom Date 8"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate8 ;; }
  dimension_group: style_custom_date_9  { group_label: "Style Custom Dates" label: "Style Custom Date 9"  description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate9 ;; }
  dimension_group: style_custom_date_10 { group_label: "Style Custom Dates" label: "Style Custom Date 10" description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate10 ;; }
  dimension_group: style_custom_date_11 { group_label: "Style Custom Dates" label: "Style Custom Date 11" description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate11 ;; }
  dimension_group: style_custom_date_12 { group_label: "Style Custom Dates" label: "Style Custom Date 12" description: "Client-configured custom date. Edit this description with the actual business definition before report developers rely on it." type: time timeframes: [raw, date, week, month, quarter, year] sql: ${TABLE}.CustomDate12 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Flags (1-18)
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_flag_1  { group_label: "Style Custom Flags" label: "Style Custom Flag 1"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag1 ;; }
  dimension: style_custom_flag_2  { group_label: "Style Custom Flags" label: "Style Custom Flag 2"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag2 ;; }
  dimension: style_custom_flag_3  { group_label: "Style Custom Flags" label: "Style Custom Flag 3"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag3 ;; }
  dimension: style_custom_flag_4  { group_label: "Style Custom Flags" label: "Style Custom Flag 4"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag4 ;; }
  dimension: style_custom_flag_5  { group_label: "Style Custom Flags" label: "Style Custom Flag 5"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag5 ;; }
  dimension: style_custom_flag_6  { group_label: "Style Custom Flags" label: "Style Custom Flag 6"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag6 ;; }
  dimension: style_custom_flag_7  { group_label: "Style Custom Flags" label: "Style Custom Flag 7"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag7 ;; }
  dimension: style_custom_flag_8  { group_label: "Style Custom Flags" label: "Style Custom Flag 8"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag8 ;; }
  dimension: style_custom_flag_9  { group_label: "Style Custom Flags" label: "Style Custom Flag 9"  description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag9 ;; }
  dimension: style_custom_flag_10 { group_label: "Style Custom Flags" label: "Style Custom Flag 10" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag10 ;; }
  dimension: style_custom_flag_11 { group_label: "Style Custom Flags" label: "Style Custom Flag 11" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag11 ;; }
  dimension: style_custom_flag_12 { group_label: "Style Custom Flags" label: "Style Custom Flag 12" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag12 ;; }
  dimension: style_custom_flag_13 { group_label: "Style Custom Flags" label: "Style Custom Flag 13" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag13 ;; }
  dimension: style_custom_flag_14 { group_label: "Style Custom Flags" label: "Style Custom Flag 14" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag14 ;; }
  dimension: style_custom_flag_15 { group_label: "Style Custom Flags" label: "Style Custom Flag 15" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag15 ;; }
  dimension: style_custom_flag_16 { group_label: "Style Custom Flags" label: "Style Custom Flag 16" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag16 ;; }
  dimension: style_custom_flag_17 { group_label: "Style Custom Flags" label: "Style Custom Flag 17" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag17 ;; }
  dimension: style_custom_flag_18 { group_label: "Style Custom Flags" label: "Style Custom Flag 18" description: "Client-configured custom flag. Edit this description with the actual business definition before report developers rely on it." type: yesno sql: ${TABLE}.CustomFlag18 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Decimals (1-12)
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_decimal_1  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 1"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal1 ;; }
  dimension: style_custom_decimal_2  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 2"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal2 ;; }
  dimension: style_custom_decimal_3  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 3"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal3 ;; }
  dimension: style_custom_decimal_4  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 4"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal4 ;; }
  dimension: style_custom_decimal_5  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 5"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal5 ;; }
  dimension: style_custom_decimal_6  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 6"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal6 ;; }
  dimension: style_custom_decimal_7  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 7"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal7 ;; }
  dimension: style_custom_decimal_8  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 8"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal8 ;; }
  dimension: style_custom_decimal_9  { group_label: "Style Custom Decimals" label: "Style Custom Decimal 9"  description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal9 ;; }
  dimension: style_custom_decimal_10 { group_label: "Style Custom Decimals" label: "Style Custom Decimal 10" description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal10 ;; }
  dimension: style_custom_decimal_11 { group_label: "Style Custom Decimals" label: "Style Custom Decimal 11" description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal11 ;; }
  dimension: style_custom_decimal_12 { group_label: "Style Custom Decimals" label: "Style Custom Decimal 12" description: "Client-configured custom decimal. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomDecimal12 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom Numbers (1-12)
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_number_1  { group_label: "Style Custom Numbers" label: "Style Custom Number 1"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber1 ;; }
  dimension: style_custom_number_2  { group_label: "Style Custom Numbers" label: "Style Custom Number 2"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber2 ;; }
  dimension: style_custom_number_3  { group_label: "Style Custom Numbers" label: "Style Custom Number 3"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber3 ;; }
  dimension: style_custom_number_4  { group_label: "Style Custom Numbers" label: "Style Custom Number 4"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber4 ;; }
  dimension: style_custom_number_5  { group_label: "Style Custom Numbers" label: "Style Custom Number 5"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber5 ;; }
  dimension: style_custom_number_6  { group_label: "Style Custom Numbers" label: "Style Custom Number 6"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber6 ;; }
  dimension: style_custom_number_7  { group_label: "Style Custom Numbers" label: "Style Custom Number 7"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber7 ;; }
  dimension: style_custom_number_8  { group_label: "Style Custom Numbers" label: "Style Custom Number 8"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber8 ;; }
  dimension: style_custom_number_9  { group_label: "Style Custom Numbers" label: "Style Custom Number 9"  description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber9 ;; }
  dimension: style_custom_number_10 { group_label: "Style Custom Numbers" label: "Style Custom Number 10" description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber10 ;; }
  dimension: style_custom_number_11 { group_label: "Style Custom Numbers" label: "Style Custom Number 11" description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber11 ;; }
  dimension: style_custom_number_12 { group_label: "Style Custom Numbers" label: "Style Custom Number 12" description: "Client-configured custom integer. Edit this description with the actual business definition before report developers rely on it." type: number sql: ${TABLE}.CustomNumber12 ;; }

  # ══════════════════════════════════════════════════════════════
  # Style Custom GUIDs (1-12) — hidden by default; usually internal
  # ══════════════════════════════════════════════════════════════

  dimension: style_custom_guid_1  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 1"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID1 ;;  hidden: yes }
  dimension: style_custom_guid_2  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 2"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID2 ;;  hidden: yes }
  dimension: style_custom_guid_3  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 3"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID3 ;;  hidden: yes }
  dimension: style_custom_guid_4  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 4"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID4 ;;  hidden: yes }
  dimension: style_custom_guid_5  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 5"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID5 ;;  hidden: yes }
  dimension: style_custom_guid_6  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 6"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID6 ;;  hidden: yes }
  dimension: style_custom_guid_7  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 7"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID7 ;;  hidden: yes }
  dimension: style_custom_guid_8  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 8"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID8 ;;  hidden: yes }
  dimension: style_custom_guid_9  { group_label: "Style Custom GUIDs" label: "Style Custom GUID 9"  description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID9 ;;  hidden: yes }
  dimension: style_custom_guid_10 { group_label: "Style Custom GUIDs" label: "Style Custom GUID 10" description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID10 ;; hidden: yes }
  dimension: style_custom_guid_11 { group_label: "Style Custom GUIDs" label: "Style Custom GUID 11" description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID11 ;; hidden: yes }
  dimension: style_custom_guid_12 { group_label: "Style Custom GUIDs" label: "Style Custom GUID 12" description: "Client-configured custom GUID reference (internal — usually a foreign key)." type: string sql: ${TABLE}.CustomGUID12 ;; hidden: yes }

  # ══════════════════════════════════════════════════════════════
  # Measures
  # ══════════════════════════════════════════════════════════════

  measure: style_count {
    description: "Count of style rows. Each row is one unique style."
    type: count
    drill_fields: [style, style_no, description, brand, department, class, season]
  }

  measure: active_style_count {
    description: "Count of styles where Is Inactive = no. Use for current assortment sizing at the product level."
    type: count
    filters: [is_inactive: "no"]
  }

  measure: replenished_style_count {
    description: "Count of styles flagged for auto-replenishment."
    type: count
    filters: [replenishment: "yes", is_inactive: "no"]
  }
}