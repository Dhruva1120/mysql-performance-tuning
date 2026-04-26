-- ============================================================
--  File 2: Populate (~500k rows)
-- ============================================================

USE ecom_perf;

SET foreign_key_checks = 0;

INSERT INTO categories (name) VALUES
  ('Electronics'),('Clothing'),('Books'),('Home & Kitchen'),('Sports');

INSERT INTO coupons (code, discount_pct, min_order_value, expires_at) VALUES
  ('SAVE10', 10, 500,  DATE_ADD(NOW(), INTERVAL 6 MONTH)),
  ('SAVE20', 20, 1000, DATE_ADD(NOW(), INTERVAL 3 MONTH)),
  ('NEW15',  15, 0,    DATE_ADD(NOW(), INTERVAL 1 YEAR));

DELIMITER //

-- 2,000 products
DROP PROCEDURE IF EXISTS gen_products //
CREATE PROCEDURE gen_products()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 2000 DO
    INSERT INTO products (category_id, name, sku, price, stock, is_active)
    VALUES (
      1 + (i MOD 5),
      CONCAT(ELT(1+(i MOD 5),'Pro','Max','Lite','Ultra','Basic'), ' Item ', i),
      CONCAT('SKU-', LPAD(i, 5, '0')),
      ROUND(100 + (i MOD 10000) * 0.5, 2),
      i MOD 300,
      IF(i MOD 15 = 0, 0, 1)
    );
    SET i = i + 1;
  END WHILE;
END //

-- 100,000 customers
DROP PROCEDURE IF EXISTS gen_customers //
CREATE PROCEDURE gen_customers()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 100000 DO
    INSERT INTO customers (first_name, last_name, email, phone, tier, created_at)
    VALUES (
      ELT(1+(i MOD 8),'Aarav','Priya','Ravi','Sneha','Karan','Deepa','Arjun','Meena'),
      ELT(1+(i MOD 6),'Sharma','Patel','Nair','Reddy','Mehta','Joshi'),
      CONCAT('user', i, '@email.com'),
      CONCAT('98', LPAD(i MOD 100000000, 8, '0')),
      ELT(1+(i MOD 4),'bronze','silver','gold','platinum'),
      DATE_SUB(NOW(), INTERVAL (i MOD 730) DAY)
    );
    SET i = i + 1;
  END WHILE;
END //

-- 200,000 orders
DROP PROCEDURE IF EXISTS gen_orders //
CREATE PROCEDURE gen_orders()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 200000 DO
    INSERT INTO orders (customer_id, order_date, status, total)
    VALUES (
      1 + (i MOD 100000),
      DATE_SUB(NOW(), INTERVAL (i MOD 730) DAY),
      ELT(1+(i MOD 5),'pending','confirmed','shipped','delivered','cancelled'),
      ROUND(200 + (i MOD 20000) * 0.5, 2)
    );
    SET i = i + 1;
  END WHILE;
END //

-- order_items
DROP PROCEDURE IF EXISTS gen_items //
CREATE PROCEDURE gen_items()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 200000 DO
    INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
    VALUES (
      i,
      1 + (i MOD 2000),
      1 + (i MOD 4),
      ROUND(100 + (i MOD 5000) * 0.1, 2),
      ROUND((1 + (i MOD 4)) * (100 + (i MOD 5000) * 0.1), 2)
    );
    IF i MOD 4 = 0 THEN
      INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
      VALUES (i, 1 + ((i+500) MOD 2000), 1,
        ROUND(150 + (i MOD 3000) * 0.1, 2),
        ROUND(150 + (i MOD 3000) * 0.1, 2));
    END IF;
    SET i = i + 1;
  END WHILE;
END //

-- payments
DROP PROCEDURE IF EXISTS gen_payments //
CREATE PROCEDURE gen_payments()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 200000 DO
    INSERT INTO payments (order_id, amount, method, status, paid_at)
    VALUES (
      i,
      ROUND(200 + (i MOD 20000) * 0.5, 2),
      ELT(1+(i MOD 5),'card','upi','netbanking','cod','wallet'),
      ELT(1+(i MOD 4),'success','success','success','failed'),
      IF(i MOD 4 < 3, DATE_SUB(NOW(), INTERVAL (i MOD 730) DAY), NULL)
    );
    SET i = i + 1;
  END WHILE;
END //

-- 50,000 reviews
DROP PROCEDURE IF EXISTS gen_reviews //
CREATE PROCEDURE gen_reviews()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 50000 DO
    INSERT INTO reviews (product_id, customer_id, rating, body, created_at)
    VALUES (
      1 + (i MOD 2000),
      1 + (i MOD 100000),
      1 + (i MOD 5),
      CONCAT('Review number ', i, ' — ', ELT(1+(i MOD 3),'great product','okay','excellent')),
      DATE_SUB(NOW(), INTERVAL (i MOD 365) DAY)
    );
    SET i = i + 1;
  END WHILE;
END //

-- shipments
DROP PROCEDURE IF EXISTS gen_shipments //
CREATE PROCEDURE gen_shipments()
BEGIN
  DECLARE i INT DEFAULT 1;
  WHILE i <= 150000 DO
    INSERT INTO shipments (order_id, tracking_number, carrier, shipped_at, delivered_at, status)
    VALUES (
      i,
      CONCAT('TRK', LPAD(i, 8, '0')),
      ELT(1+(i MOD 4),'BlueDart','Delhivery','Ekart','DTDC'),
      DATE_SUB(NOW(), INTERVAL (i MOD 700) DAY),
      IF(i MOD 5 < 4, DATE_SUB(NOW(), INTERVAL ((i MOD 700)-5) DAY), NULL),
      ELT(1+(i MOD 4),'delivered','delivered','in_transit','preparing')
    );
    SET i = i + 1;
  END WHILE;
END //

DELIMITER ;

SELECT 'Generating products...' AS status; CALL gen_products();
SELECT 'Generating customers...' AS status; CALL gen_customers();
SELECT 'Generating orders...' AS status;    CALL gen_orders();
SELECT 'Generating order items...' AS status; CALL gen_items();
SELECT 'Generating payments...' AS status;  CALL gen_payments();
SELECT 'Generating reviews...' AS status;   CALL gen_reviews();
SELECT 'Generating shipments...' AS status; CALL gen_shipments();

SET foreign_key_checks = 1;

SELECT TABLE_NAME, TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'ecom_perf'
ORDER BY TABLE_ROWS DESC;
