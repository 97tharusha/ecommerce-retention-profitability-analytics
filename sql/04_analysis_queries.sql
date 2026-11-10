--Q1. Monthly Revenue & Profit Trend
SELECT 
    EXTRACT(YEAR FROM order_date) AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(net_sales_usd)::numeric, 2) AS revenue_usd,
    ROUND(SUM(profit_usd)::numeric, 2) AS profit_usd,
    ROUND((100.0 * SUM(profit_usd) / SUM(net_sales_usd))::numeric, 2) AS margin_pct
FROM orders
WHERE order_status = 'Completed'
GROUP BY 1, 2
ORDER BY 1, 2;

-- Q2. Revenue by Country
SELECT 
    customer_country,
    COUNT(order_id) AS orders,
    ROUND(SUM(net_sales_usd)::numeric, 2) AS revenue_usd
FROM orders
WHERE order_status = 'Completed'
GROUP BY customer_country
ORDER BY revenue_usd DESC;


-- Q3. The RFM Segmentation 
WITH customer_rfm AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date,
        (SELECT MAX(order_date) FROM orders) - MAX(order_date) AS recency_days,
        COUNT(order_id) AS frequency,
        SUM(net_sales_usd) AS monetary
    FROM orders
    WHERE order_status = 'Completed'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm
)
SELECT 
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN f_score >= 4 AND m_score >= 4 THEN 'Loyal'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Others'
    END AS customer_segment,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(monetary)::numeric, 2) AS avg_monetary_usd
FROM rfm_scores
GROUP BY 1
ORDER BY total_customers DESC;


-- Q4. Discount Leakage (Loss-Making Orders) 
SELECT 
    CASE 
        WHEN discount_amount_usd = 0 THEN '0%'
        WHEN discount_amount_usd / net_sales_usd < 0.1 THEN '<10%'
        WHEN discount_amount_usd / net_sales_usd < 0.2 THEN '10-20%'
        WHEN discount_amount_usd / net_sales_usd < 0.3 THEN '20-30%'
        ELSE '>30%' 
    END AS discount_band,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(profit_margin_percentage)::numeric, 2) AS avg_margin,
    SUM(CASE WHEN is_loss_making THEN 1 ELSE 0 END) AS loss_making_orders
FROM orders
WHERE order_status = 'Completed'
GROUP BY 1
ORDER BY 1;