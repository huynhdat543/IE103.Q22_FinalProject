--- INDEX
-- 1. Index cho bảng olist_orders_dataset (Bảng trung tâm)
-- Tối ưu việc tìm kiếm đơn hàng theo khách hàng và trạng thái
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_purchase_timestamp ON orders(order_purchase_timestamp);

-- 2. Index cho bảng olist_order_items_dataset (Bảng cầu nối nhiều nhất)
-- Tối ưu các phép JOIN giữa đơn hàng, sản phẩm và người bán
CREATE INDEX idx_items_order_id ON order_items(order_id);
CREATE INDEX idx_items_product_id ON order_items(product_id);
CREATE INDEX idx_items_seller_id ON order_items(seller_id);

-- 3. Index cho bảng olist_order_payments_dataset
CREATE INDEX idx_payments_order_id ON order_payments(order_id);
CREATE INDEX idx_payments_type ON order_payments(payment_type);

-- 4. Index cho bảng olist_order_reviews_dataset
CREATE INDEX idx_reviews_order_id ON order_reviews(order_id);
CREATE INDEX idx_reviews_score ON order_reviews(review_score);

-- 5. Index cho bảng olist_products_dataset
-- Tối ưu việc lọc sản phẩm theo danh mục
CREATE INDEX idx_products_category ON products(product_category_name);

-- 6. Index cho bảng olist_customers_dataset
-- Tối ưu tìm kiếm theo ID định danh duy nhất và khu vực
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX idx_customers_zip_prefix ON customers(customer_zip_code_prefix);
CREATE INDEX idx_customers_city ON customers(customer_city);

-- 7. Index cho bảng olist_sellers_dataset
CREATE INDEX idx_sellers_zip_prefix ON sellers(seller_zip_code_prefix);
CREATE INDEX idx_sellers_city ON sellers(seller_city);

-- 8. Index cho bảng olist_geolocation_dataset
-- Tối ưu việc tra cứu tọa độ theo mã bưu điện
CREATE INDEX idx_geo_zip_prefix ON geolocation(geolocation_zip_code_prefix);

-- 9. Index cho bảng product_category_name_translation
-- Mặc dù bảng này nhỏ nhưng vẫn nên có index trên cột tìm kiếm chính
CREATE INDEX idx_trans_category_name ON category_name_translation(product_category_name);






-- 1. Xóa Index bảng olist_orders_dataset
DROP INDEX IF EXISTS idx_orders_customer_id;
DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_purchase_timestamp;

-- 2. Xóa Index bảng olist_order_items_dataset
DROP INDEX IF EXISTS idx_items_order_id;
DROP INDEX IF EXISTS idx_items_product_id;
DROP INDEX IF EXISTS idx_items_seller_id;

-- 3. Xóa Index bảng olist_order_payments_dataset
DROP INDEX IF EXISTS idx_payments_order_id;
DROP INDEX IF EXISTS idx_payments_type;

-- 4. Index cho bảng olist_order_reviews_dataset
DROP INDEX IF EXISTS idx_reviews_order_id;
DROP INDEX IF EXISTS idx_reviews_score;

-- 5. Xóa Index bảng olist_products_dataset
DROP INDEX IF EXISTS idx_products_category;

-- 6. Xóa Index bảng olist_customers_dataset
DROP INDEX IF EXISTS idx_customers_unique_id;
DROP INDEX IF EXISTS idx_customers_zip_prefix;
DROP INDEX IF EXISTS idx_customers_city;

-- 7. Xóa Index bảng olist_sellers_dataset
DROP INDEX IF EXISTS idx_sellers_zip_prefix;
DROP INDEX IF EXISTS idx_sellers_city;

-- 8. Xóa Index bảng olist_geolocation_dataset
DROP INDEX IF EXISTS idx_geo_zip_prefix;

-- 9. Xóa Index bảng product_category_name_translation
DROP INDEX IF EXISTS idx_trans_category_name;
