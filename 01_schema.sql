-- ============================================================
--  MySQL Performance Tuning Project (Simplified)
--  10 Tables | All 6 tuning problems still covered
--  Run this first, then 02_populate.sql, then 03_tuning.sql
-- ============================================================

DROP DATABASE IF EXISTS ecom_perf;
CREATE DATABASE ecom_perf CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecom_perf;

CREATE TABLE categories (
    category_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    product_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id  INT UNSIGNED NOT NULL,
    name         VARCHAR(200) NOT NULL,
    sku          VARCHAR(50)  NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    stock        INT          DEFAULT 0,
    is_active    TINYINT(1)   DEFAULT 1,
    description  TEXT,
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    -- No index on sku, name intentionally
);

CREATE TABLE customers (
    customer_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name   VARCHAR(80)  NOT NULL,
    last_name    VARCHAR(80)  NOT NULL,
    email        VARCHAR(150) NOT NULL,
    phone        VARCHAR(20),
    tier         ENUM('bronze','silver','gold','platinum') DEFAULT 'bronze',
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP
    -- No index on email intentionally
);

CREATE TABLE orders (
    order_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT UNSIGNED NOT NULL,
    order_date   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('pending','confirmed','shipped','delivered','cancelled') DEFAULT 'pending',
    total        DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    -- No index on customer_id, order_date intentionally
);

CREATE TABLE order_items (
    item_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id     INT UNSIGNED NOT NULL,
    product_id   INT UNSIGNED NOT NULL,
    quantity     INT          NOT NULL DEFAULT 1,
    unit_price   DECIMAL(10,2) NOT NULL,
    line_total   DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    -- No index on order_id, product_id intentionally
);

CREATE TABLE payments (
    payment_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id     INT UNSIGNED NOT NULL,
    amount       DECIMAL(12,2) NOT NULL,
    method       ENUM('card','upi','netbanking','cod','wallet') DEFAULT 'card',
    status       ENUM('pending','success','failed') DEFAULT 'pending',
    paid_at      DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    -- No index on order_id, paid_at intentionally
);

CREATE TABLE reviews (
    review_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id   INT UNSIGNED NOT NULL,
    customer_id  INT UNSIGNED NOT NULL,
    rating       TINYINT      NOT NULL CHECK (rating BETWEEN 1 AND 5),
    body         TEXT,
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    -- No index on product_id intentionally
);

CREATE TABLE shipments (
    shipment_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id         INT UNSIGNED NOT NULL,
    tracking_number  VARCHAR(100),
    carrier          VARCHAR(50),
    shipped_at       DATETIME,
    delivered_at     DATETIME,
    status           ENUM('preparing','in_transit','delivered','returned') DEFAULT 'preparing',
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE coupons (
    coupon_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(50)  NOT NULL,
    discount_pct    DECIMAL(5,2) NOT NULL,
    min_order_value DECIMAL(10,2) DEFAULT 0,
    expires_at      DATETIME,
    is_active       TINYINT(1)   DEFAULT 1
);

CREATE TABLE coupon_usage (
    usage_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    coupon_id    INT UNSIGNED NOT NULL,
    customer_id  INT UNSIGNED NOT NULL,
    order_id     INT UNSIGNED NOT NULL,
    used_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (coupon_id)   REFERENCES coupons(coupon_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id)    REFERENCES orders(order_id)
);

SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'ecom_perf' ORDER BY TABLE_NAME;
