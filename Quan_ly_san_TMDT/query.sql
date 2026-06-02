--------------------------------------------------------------------------------------------------
-- Truy vấn cơ bản trên 1 bảng dữ liệu
--------------------------------------------------------------------------------------------------

-- Lấy thông tin khách hàng tại Sao Paulo và sắp xếp theo mã bưu điện
SELECT 
    customer_id, 
    customer_city, 
    customer_state, 
    customer_zip_code_prefix
FROM customers 
WHERE customer_city = 'sao paulo' 
ORDER BY customer_zip_code_prefix ASC; 

----------------------------------------------------------------

-- Liệt kê 10 danh mục sản phẩm khác nhau hiện có trong hệ thống
SELECT DISTINCT 
    product_category_name 
FROM products 
WHERE product_category_name IS NOT NULL 
LIMIT 10; 

--------------------------------------------------------------------------------------------------
-- Các hàm tổng hợp (Aggregation)
--------------------------------------------------------------------------------------------------

-- Đếm tổng số mã đơn hàng trong bảng orders
SELECT 
    COUNT(order_id) AS tong_so_don_hang 
FROM orders

----------------------------------------------------------------

-- Tính toán các chỉ số tài chính từ bảng thanh toán (order_payments)
SELECT 
    SUM(payment_value) AS tong_doanh_thu,          
    AVG(payment_value) AS trung_binh_thanh_toan,   
    MAX(payment_value) AS thanh_toan_cao_nhat      
FROM order_payments;

--------------------------------------------------------------------------------------------------
-- Truy vấn năng cao có sự kết hợp của 2 bảng dữ liệu
--------------------------------------------------------------------------------------------------

-- Kết nối bảng orders và customers để lấy địa chỉ khách hàng cho mỗi đơn hàng
EXPLAIN ANALYZE
SELECT 
    o.order_id, 
    c.customer_city, 
    c.customer_state
FROM orders AS o
JOIN customers AS c ON o.customer_id = c.customer_id; 

----------------------------------------------------------------

-- Kết nối bảng sản phẩm với bảng dịch thuật danh mục
EXPLAIN ANALYZE
SELECT 
    p.product_id, 
    p.product_category_name AS ten_goc,
    t.product_category_name_english AS ten_tieng_anh
FROM products AS p
JOIN category_name_translation AS t ON p.product_category_name = t.product_category_name;

--------------------------------------------------------------------------------------------------
-- Truy vấn năng cao có sự kết hợp của 3 bảng dữ liệu trở lên
--------------------------------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Kết hợp orders (đơn hàng), order_items (chi tiết), products (sản phẩm) để thấy thông tin của các sản phẩm trong từng đơn hàng
EXPLAIN ANALYZE
SELECT 
    o.order_id, 
    o.order_purchase_timestamp AS ngay_mua, 
    p.product_category_name AS danh_muc
FROM orders AS o
JOIN order_items AS i ON o.order_id = i.order_id     
JOIN products AS p ON i.product_id = p.product_id   
LIMIT 10;

----------------------------------------------------------------

-- Kết hợp customers (khách), orders (đơn), order_reviews (đánh giá) 
-- để hiển thị thành phố của khách hàng và điểm số đánh giá mà họ đã để lại cho các đơn hàng
EXPLAIN ANALYZE
SELECT 
    c.customer_city, 
    o.order_id, 
    r.review_score
FROM customers AS c
JOIN orders AS o ON c.customer_id = o.customer_id   
JOIN order_reviews AS r ON o.order_id = r.order_id                            
LIMIT 10;

--------------------------------------------------------------------------------------------------
-- Group By và 	Having 
--------------------------------------------------------------------------------------------------

-- Thống kê số lượng khách hàng theo từng bang
EXPLAIN ANALYZE
SELECT 
    customer_state, 
    COUNT(customer_id) AS so_luong_khach
FROM customers
GROUP BY customer_state         
ORDER BY so_luong_khach DESC;  

----------------------------------------------------------------

-- Tìm các danh mục hàng hóa có trên 500 sản phẩm
EXPLAIN ANALYZE
SELECT 
    product_category_name, 
    COUNT(product_id) AS so_luong_sp
FROM products
WHERE product_category_name IS NOT NULL 
GROUP BY product_category_name          
HAVING COUNT(product_id) > 500          
ORDER BY so_luong_sp DESC;



