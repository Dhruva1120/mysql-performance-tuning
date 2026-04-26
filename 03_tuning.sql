-- ============================================================
--  File 3: Tuning Analysis
--  For each problem: EXPLAIN before → apply fix → EXPLAIN after
-- ============================================================

USE ecom_perf;

-- ╔══════════════════════════════════════════╗
-- ║  PROBLEM 1: Full scan on email           ║
-- ╚══════════════════════════════════════════╝

-- BEFORE (type=ALL, rows≈100000)
EXPLAIN SELECT customer_id, first_name, tier
FROM customers WHERE email = 'user50000@email.com';

-- FIX
ALTER TABLE customers ADD INDEX IF NOT EXISTS idx_customers_email (email);

-- AFTER (type=ref, rows=1)
EXPLAIN SELECT customer_id, first_name, tier
FROM customers WHERE email = 'user50000@email.com';


-- ╔══════════════════════════════════════════╗
-- ║  PROBLEM 2: Missing FK indexes           ║
-- ╚══════════════════════════════════════════╝

-- BEFORE (type=ALL, rows≈200000)
EXPLAIN SELECT order_id, order_date, status, total
FROM orders WHERE customer_id = 42;

-- FIX
ALTER TABLE orders      ADD INDEX IF NOT EXISTS idx_orders_customer  (customer_id);
ALTER TABLE orders      ADD INDEX IF NOT EXISTS idx_orders_date       (order_date);
ALTER TABLE order_items ADD INDEX IF NOT EXISTS idx_items_order       (order_id);
ALTER TABLE order_items ADD INDEX IF NOT EXISTS idx_items_product     (product_id);
ALTER TABLE payments    ADD INDEX IF NOT EXISTS idx_payments_order    (order_id);
ALTER TABLE reviews     ADD INDEX IF NOT EXISTS idx_reviews_product   (product_id);

-- AFTER (type=ref, rows≈2)
EXPLAIN SELECT order_id, order_date, status, total
FROM orders WHERE customer_id = 42;


-- ╔══════════════════════════════════════════╗
-- ║  PROBLEM 3: Correlated subquery          ║
-- ╚══════════════════════════════════════════╝

-- BEFORE (DEPENDENT SUBQUERY, rows=100k × 200k)
EXPLAIN
SELECT c.customer_id, c.first_name,
  (SELECT COUNT(*)        FROM orders o WHERE o.customer_id = c.customer_id) AS order_count,
  (SELECT SUM(o.total)    FROM orders o WHERE o.customer_id = c.customer_id) AS lifetime_value
FROM customers c WHERE c.tier = 'gold' LIMIT 50;

-- FIX: rewrite as aggregated LEFT JOIN
ALTER TABLE customers ADD INDEX IF NOT EXISTS idx_customers_tier (tier);

-- AFTER (DERIVED, runs once)
EXPLAIN
SELECT c.customer_id, c.first_name,
  COALESCE(agg.order_count, 0)    AS order_count,
  COALESCE(agg.lifetime_value, 0) AS lifetime_value
FROM customers c
LEFT JOIN (
    SELECT customer_id, COUNT(*) AS order_count, SUM(total) AS lifetime_value
    FROM orders GROUP BY customer_id
) agg ON agg.customer_id = c.customer_id
WHERE c.tier = 'gold' LIMIT 50;


-- ╔══════════════════════════════════════════╗
-- ║  PROBLEM 4: Function on date column      ║
-- ╚══════════════════════════════════════════╝

-- BEFORE (type=ALL — index suppressed by YEAR/MONTH function)
EXPLAIN SELECT COUNT(*), SUM(total)
FROM orders WHERE YEAR(order_date) = 2024 AND MONTH(order_date) = 3;

-- AFTER: use range predicate instead
EXPLAIN SELECT COUNT(*), SUM(total)
FROM orders WHERE order_date >= '2024-03-01' AND order_date < '2024-04-01';


-- ╔══════════════════════════════════════════╗
-- ║  PROBLEM 5: Multi-table join, no indexes ║
-- ╚══════════════════════════════════════════╝

-- BEFORE (type=ALL across all tables, Using filesort)
EXPLAIN
SELECT p.name, c.name AS category,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.line_total) AS revenue,
  AVG(r.rating) AS avg_rating
FROM order_items oi
JOIN orders   o  ON o.order_id   = oi.order_id
JOIN products p  ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN reviews r ON r.product_id = p.product_id
WHERE o.order_date >= '2023-01-01'
  AND o.status IN ('delivered','shipped')
GROUP BY p.product_id, p.name, c.name
ORDER BY revenue DESC LIMIT 10;

-- FIX: composite index for the WHERE filter
ALTER TABLE orders ADD INDEX IF NOT EXISTS idx_orders_status_date (status, order_date);

-- AFTER (eq_ref joins, no filesort)
EXPLAIN
SELECT p.name, c.name AS category,
  SUM(oi.quantity) AS units_sold,
  SUM(oi.line_total) AS revenue,
  AVG(r.rating) AS avg_rating
FROM order_items oi
JOIN orders   o  ON o.order_id   = oi.order_id
JOIN products p  ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN reviews r ON r.product_id = p.product_id
WHERE o.order_date >= '2023-01-01'
  AND o.status IN ('delivered','shipped')
GROUP BY p.product_id, p.name, c.name
ORDER BY revenue DESC LIMIT 10;


-- ╔══════════════════════════════════════════╗
-- ║  PROBLEM 6: Covering index               ║
-- ╚══════════════════════════════════════════╝

-- BEFORE: SELECT * reads full rows including TEXT description column
EXPLAIN SELECT * FROM products WHERE is_active = 1 LIMIT 50;

-- FIX: select only needed columns + covering index
ALTER TABLE products ADD INDEX IF NOT EXISTS idx_products_covering
  (is_active, product_id, name, price, sku);

-- AFTER: Extra = "Using index" (zero table row reads)
EXPLAIN SELECT product_id, name, price, sku
FROM products WHERE is_active = 1 LIMIT 50;
