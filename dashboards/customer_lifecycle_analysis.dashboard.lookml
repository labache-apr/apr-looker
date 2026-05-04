---
- dashboard: customer_lifecycle_analysis
  title: "Customer Lifecycle Analysis"
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Track customer progression through lifecycle stages based on recency, frequency, and spend patterns."

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

    # ── Recency Distribution ──

    - title: "Customer Recency Distribution"
      name: recency_dist
      model: "@{model_name}"
      explore: customer_performance
      type: looker_column
      fields: [customer_metrics.recency_tier, customer_metrics.customer_count]
      sorts: [customer_metrics.recency_tier]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 0
      width: 12
      height: 7

    - title: "Frequency vs Spend Tier"
      name: frequency_spend
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_metrics.purchase_frequency_tier, customer_metrics.lifetime_spend_tier,
               customer_metrics.customer_count]
      pivots: [customer_metrics.lifetime_spend_tier]
      sorts: [customer_metrics.purchase_frequency_tier]
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 0
      col: 12
      width: 12
      height: 7

    # ── At-Risk Customers (high spend, long recency) ──

    - title: "At-Risk High-Value Customers"
      name: at_risk
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_performance.full_name, customer_performance.email,
               customer_performance.location, customer_metrics.total_lifetime_spend,
               customer_metrics.total_transactions, customer_metrics.days_since_last_purchase,
               customer_metrics.avg_transaction_value]
      filters:
        customer_metrics.lifetime_spend_tier: "500 to 999,1000 to 4999,5000 or above"
        customer_metrics.recency_tier: "91 to 180,181 to 365,366 or above"
      sorts: [customer_metrics.total_lifetime_spend desc]
      limit: 25
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 7
      col: 0
      width: 24
      height: 8

    # ── New Customers (first purchase last 90 days) ──

    - title: "Recently Acquired Customers (Last 90 Days)"
      name: new_customers
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_performance.full_name, customer_performance.email,
               customer_performance.city, customer_performance.state,
               customer_metrics.first_purchase_date, customer_metrics.total_lifetime_spend,
               customer_metrics.total_transactions]
      filters:
        customer_metrics.first_purchase_date: "last 90 days"
      sorts: [customer_metrics.first_purchase_date desc]
      limit: 25
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 15
      col: 0
      width: 24
      height: 8

    # ── Lapsed Customers (no purchase in 365+ days) ──

    - title: "Lapsed Customers (No Purchase in 1+ Year)"
      name: lapsed
      model: "@{model_name}"
      explore: customer_performance
      type: looker_grid
      fields: [customer_performance.full_name, customer_performance.email,
               customer_performance.location, customer_metrics.total_lifetime_spend,
               customer_metrics.total_transactions, customer_metrics.days_since_last_purchase,
               customer_metrics.last_purchase_date]
      filters:
        customer_metrics.recency_tier: "366 or above"
      sorts: [customer_metrics.total_lifetime_spend desc]
      limit: 25
      listen:
        customer_type: customer_attributes.type
        location: customer_performance.location
      row: 23
      col: 0
      width: 24
      height: 8
