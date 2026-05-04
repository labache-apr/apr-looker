---
- dashboard: customer_overview
  title: "Customer Overview"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Executive view of customer base health, lifetime value distribution, and key customer metrics."

  filters:
    - name: customer_type
      title: "Customer Type"
      type: field_filter
      explore: customer_performance
      field: customer_attributes.type
      default_value: ""
      allow_multiple_values: true

    - name: location
      title: "Home Location"
      type: field_filter
      explore: customer_performance
      field: customer_performance.location
      default_value: ""
      allow_multiple_values: true

  elements:

    # ── KPI Row ──

    - title: "Total Customers"
      name: total_customers
      model: "@{model_name}"
      explore: customer_performance
      type: single_value
      fields: [customer_performance.customer_count]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 0
      width: 5
      height: 3

    - title: "Active Customers"
      name: active_customers
      model: "@{model_name}"
      explore: customer_performance
      type: single_value
      fields: [customer_performance.active_customer_count]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 5
      width: 5
      height: 3

    - title: "Avg Lifetime Spend"
      name: avg_spend
      model: "@{model_name}"
      explore: customer_performance
      type: single_value
      fields: [customer_metrics.avg_customer_spend]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 10
      width: 5
      height: 3

    - title: "Avg Transactions"
      name: avg_txns
      model: "@{model_name}"
      explore: customer_performance
      type: single_value
      fields: [customer_metrics.avg_customer_transactions]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 15
      width: 4
      height: 3

    - title: "Avg Days Since Purchase"
      name: avg_recency
      model: "@{model_name}"
      explore: customer_performance
      type: single_value
      fields: [customer_metrics.avg_days_since_last_purchase]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 19
      width: 5
      height: 3

    # ── Distributions ──

    - title: "Customers by Spend Tier"
      name: spend_tiers
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.lifetime_spend_tier, customer_metrics.customer_count]
      sorts: [customer_metrics.lifetime_spend_tier]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 3
      col: 0
      width: 8
      height: 7

    - title: "Customers by Purchase Frequency"
      name: frequency_tiers
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.purchase_frequency_tier, customer_metrics.customer_count]
      sorts: [customer_metrics.purchase_frequency_tier]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 3
      col: 8
      width: 8
      height: 7

    - title: "Customers by Recency"
      name: recency_tiers
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.recency_tier, customer_metrics.customer_count]
      sorts: [customer_metrics.recency_tier]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 3
      col: 16
      width: 8
      height: 7

    # ── Top Customers ──

    - title: "Top 20 Customers by Lifetime Spend"
      name: top_customers
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_performance.full_name, customer_performance.email, customer_performance.city,
               customer_performance.state, customer_metrics.total_lifetime_spend,
               customer_metrics.total_transactions, customer_metrics.avg_transaction_value,
               customer_metrics.avg_margin_percent, customer_metrics.days_since_last_purchase]
      sorts: [customer_metrics.total_lifetime_spend desc]
      limit: 20
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 10
      col: 0
      width: 24
      height: 8

    # ── Customer by Location ──

    - title: "Customers by Home Location"
      name: by_location
      model: "@{model_name}"
      explore: customer_performance
      type: looker_bar
      fields: [customer_performance.location, customer_performance.customer_count]
      sorts: [customer_performance.customer_count desc]
      limit: 15
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 18
      col: 0
      width: 12
      height: 7

    - title: "Customers by Type"
      name: by_type
      model: "@{model_name}"
      explore: customer_performance
      type: looker_pie
      fields: [customer_attributes.type, customer_performance.customer_count]
      sorts: [customer_performance.customer_count desc]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 18
      col: 12
      width: 12
      height: 7
