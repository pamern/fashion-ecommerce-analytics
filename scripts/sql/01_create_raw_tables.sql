BEGIN;

CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id BIGINT,
    zip INTEGER,
    city TEXT,
    signup_date DATE,
    gender TEXT,
    age_group TEXT,
    acquisition_channel TEXT
);

CREATE TABLE IF NOT EXISTS raw.geography (
    zip INTEGER,
    city TEXT,
    region TEXT,
    district TEXT
);

CREATE TABLE IF NOT EXISTS raw.inventory (
    snapshot_date DATE,
    product_id BIGINT,
    stock_on_hand INTEGER,
    units_received INTEGER,
    units_sold INTEGER,
    stockout_days INTEGER,
    days_of_supply DOUBLE PRECISION,
    fill_rate DOUBLE PRECISION,
    stockout_flag SMALLINT,
    overstock_flag SMALLINT,
    reorder_flag SMALLINT,
    sell_through_rate DOUBLE PRECISION,
    product_name TEXT,
    category TEXT,
    segment TEXT,
    year INTEGER,
    month INTEGER
);

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id BIGINT,
    product_id BIGINT,
    quantity INTEGER,
    unit_price DOUBLE PRECISION,
    discount_amount DOUBLE PRECISION,
    promo_id TEXT,
    promo_id_2 TEXT
);

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id BIGINT,
    order_date DATE,
    customer_id BIGINT,
    zip INTEGER,
    order_status TEXT,
    payment_method TEXT,
    device_type TEXT,
    order_source TEXT
);

CREATE TABLE IF NOT EXISTS raw.payments (
    order_id BIGINT,
    payment_method TEXT,
    payment_value DOUBLE PRECISION,
    installments INTEGER
);

CREATE TABLE IF NOT EXISTS raw.products (
    product_id BIGINT,
    product_name TEXT,
    category TEXT,
    segment TEXT,
    size TEXT,
    color TEXT,
    price DOUBLE PRECISION,
    cogs DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS raw.promotions (
    promo_id TEXT,
    promo_name TEXT,
    promo_type TEXT,
    discount_value DOUBLE PRECISION,
    start_date DATE,
    end_date DATE,
    applicable_category TEXT,
    promo_channel TEXT,
    stackable_flag SMALLINT,
    min_order_value INTEGER
);

CREATE TABLE IF NOT EXISTS raw.returns (
    return_id TEXT,
    order_id BIGINT,
    product_id BIGINT,
    return_date DATE,
    return_reason TEXT,
    return_quantity INTEGER,
    refund_amount DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS raw.reviews (
    review_id TEXT,
    order_id BIGINT,
    product_id BIGINT,
    customer_id BIGINT,
    review_date DATE,
    rating INTEGER,
    review_title TEXT
);

CREATE TABLE IF NOT EXISTS raw.sales (
    "Date" DATE,
    "Revenue" DOUBLE PRECISION,
    "COGS" DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS raw.sample_submission (
    "Date" DATE,
    "Revenue" DOUBLE PRECISION,
    "COGS" DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS raw.shipments (
    order_id BIGINT,
    ship_date DATE,
    delivery_date DATE,
    shipping_fee DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS raw.web_traffic (
    date DATE,
    sessions INTEGER,
    unique_visitors INTEGER,
    page_views INTEGER,
    bounce_rate DOUBLE PRECISION,
    avg_session_duration_sec DOUBLE PRECISION,
    traffic_source TEXT
);

COMMIT;
