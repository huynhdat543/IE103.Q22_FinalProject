
-- customers
-------- Trigger Không xóa khách hàng đang có đơn hàng chưa hoàn tất
CREATE OR REPLACE FUNCTION fn_check_customer_delete() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM orders WHERE customer_id = OLD.customer_id AND order_status != 'delivered') THEN
        RAISE EXCEPTION 'Không thể xóa khách hàng có đơn hàng chưa hoàn tất';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customer_delete BEFORE DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION fn_check_customer_delete();

---	 TEST
--- 	CHUẨN BỊ DỮ LIỆU MẪU
-- Thêm Khách hàng 1: Không có đơn hàng (Để test xóa thành công)
INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 1001, 'Hanoi', 'HN');
-- Thêm Khách hàng 2: Có đơn hàng đang xử lý (Để test xóa thất bại)
INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 1001, 'HCM', 'SG');
-- Thêm Đơn hàng cho Khách hàng 2
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('99999999-9999-9999-9999-999999999999', '00000000-0000-0000-0000-000000000002', 'processing', NOW());

--- 	TRƯỜNG HỢP XÓA THÀNH CÔNG
DELETE FROM customers WHERE customer_id = '00000000-0000-0000-0000-000000000001';

--- 	TRƯỜNG HỢP XÓA THẤT BẠI
DELETE FROM customers WHERE customer_id = '00000000-0000-0000-0000-000000000002';



-- orders
-------- Logic trạng thái và ngày giao hàng
CREATE OR REPLACE FUNCTION fn_order_logic() RETURNS TRIGGER AS $$
BEGIN
    -- 1. Không được sửa trạng thái ngược lại (ví dụ delivered -> processing)
    IF OLD.order_status = 'delivered' AND NEW.order_status != 'delivered' THEN
        RAISE EXCEPTION 'Không thể chuyển ngược trạng thái từ delivered';
    END IF;

    -- 2. Tự động điền ngày giao nếu trạng thái thành delivered
    IF NEW.order_status = 'delivered' AND OLD.order_status != 'delivered' THEN
        NEW.order_delivered_customer_date := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_logic BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION fn_order_logic();

---	 TEST
--- 	CHUẨN BỊ DỮ LIỆU MẪU
-- Thêm một đơn hàng đang ở trạng thái 'shipped'
-- Cột ngày giao hàng (order_delivered_customer_date) hiện tại đang để NULL
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp, order_delivered_customer_date)
VALUES (
    '00000000-0000-0000-0000-00000000000A', 
    '00000000-0000-0000-0000-000000000002',
    'shipped', 
    NOW(), 
    NULL
);

--- 	TRƯỜNG HỢP HỢP LỆ (Cập nhật thành 'delivered' và tự điền ngày) 
-- Cập nhật trạng thái
UPDATE orders 
SET order_status = 'delivered' 
WHERE order_id = '00000000-0000-0000-0000-00000000000A';
-- Kiểm tra xem ngày giao hàng có tự động được điền không
SELECT order_id, order_status, order_delivered_customer_date 
FROM orders 
WHERE order_id = '00000000-0000-0000-0000-00000000000A';

---		TRƯỜNG HỢP THẤT BẠI
-- Sau khi đơn đã giao, thử hạ cấp trạng thái
UPDATE orders 
SET order_status = 'processing' 
WHERE order_id = '00000000-0000-0000-0000-00000000000A';




-- order_items
---------- Ngăn sửa đổi nếu đã thanh toán
CREATE OR REPLACE FUNCTION fn_check_order_paid() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM order_payments WHERE order_id = COALESCE(OLD.order_id, NEW.order_id)) THEN
        RAISE EXCEPTION 'Đơn hàng đã thanh toán, không thể thay đổi chi tiết sản phẩm';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_item_lock BEFORE INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION fn_check_order_paid();

---	TEST
---		CHUẨN BỊ DỮ LIỆU MẪU
-- ĐƠN HÀNG B: Đã thanh toán
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('00000000-0000-0000-0000-00000000000B', '00000000-0000-0000-0000-000000000002', 'processing', NOW());
INSERT INTO order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
VALUES ('00000000-0000-0000-0000-00000000000B', 1, '00066f42-aeeb-9f30-0754-8bb9d3f33c38', '0015a82c-2db0-00af-6aaa-f3ae2ecb0532', NOW(), 100.00, 10.00);
INSERT INTO order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
VALUES ('00000000-0000-0000-0000-00000000000B', 1, 'credit_card', 1, 110.00);
-- ĐƠN HÀNG C: Chưa thanh toán
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('00000000-0000-0000-0000-00000000000C', '00000000-0000-0000-0000-000000000002', 'processing', NOW());
INSERT INTO order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
VALUES ('00000000-0000-0000-0000-00000000000C', 1, '00066f42-aeeb-9f30-0754-8bb9d3f33c38', '0015a82c-2db0-00af-6aaa-f3ae2ecb0532', NOW(), 50.00, 5.00);
---		TRƯỜNG HỢP THÀNH CÔNG (Sửa đơn hàng chưa thanh toán)
UPDATE order_items 
SET price = 60.00 
WHERE order_id = '00000000-0000-0000-0000-00000000000C';
---		TRƯỜNG HỢP SỬA ĐỔI KHÔNG THÀNH CÔNG (Sửa đơn hàng đã thanh toán)
UPDATE order_items 
SET price = 200.00 
WHERE order_id = '00000000-0000-0000-0000-00000000000B';



-- order_reviews
---------	Điền ngày review và check review chứa từ ngữ thô tục
CREATE OR REPLACE FUNCTION fn_review_logic() RETURNS TRIGGER AS $$
BEGIN
    -- 1. Tự động điền ngày review nếu trống
    IF NEW.review_creation_date IS NULL THEN
        NEW.review_creation_date := CURRENT_TIMESTAMP;
    END IF;

    -- 2. Kiểm tra từ tục
    IF NEW.review_comment_message ~* '(đụ má|đụ mẹ|địt mẹ|lồn|cặc)' THEN
        RAISE EXCEPTION 'Bình luận chứa từ ngữ không phù hợp';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_review_logic BEFORE INSERT ON order_reviews
FOR EACH ROW EXECUTE FUNCTION fn_review_logic();

---	TEST
---		CHUẨN BỊ DỮ LIỆU MẪU
-- Sử dụng đơn hàng A đã tạo từ các test trước:
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('00000000-0000-0000-0000-00000000000A', '00000000-0000-0000-0000-000000000002', 'delivered', NOW())
ON CONFLICT (order_id) DO NOTHING;

---		TRƯỜNG HỢP THÊM THÀNH CÔNG
INSERT INTO order_reviews (review_id, order_id, review_score, review_comment_message, review_creation_date)
VALUES (
    '00000000-0000-0000-0000-000000000010', 
    '00000000-0000-0000-0000-00000000000A', 
    5, 
    'Sản phẩm dùng rất tốt, cảm ơn shop!', 
    NULL -- Để NULL để test trigger tự điền ngày
);
-- Kiểm tra xem đã thêm thành công và ngày đã tự điền chưa
SELECT review_id, review_comment_message, review_creation_date 
FROM order_reviews 
WHERE review_id = '00000000-0000-0000-0000-000000000010';

---		TRƯỜNG HỢP THÊM KHÔNG THÀNH CÔNG
INSERT INTO order_reviews (review_id, order_id, review_score, review_comment_message, review_creation_date)
VALUES (
    '00000000-0000-0000-0000-000000000020', 
    '00000000-0000-0000-0000-00000000000A', 
    1, 
    'Đồ làm ăn như cái lồn!', 
    NOW()
);



-- sellers_dataset
---------	Không cho phép xóa người bán nếu họ vẫn còn đơn hàng chưa hoàn thành
CREATE OR REPLACE FUNCTION fn_check_seller_delete() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM order_items i
        JOIN orders o ON i.order_id = o.order_id
        WHERE i.seller_id = OLD.seller_id AND o.order_status != 'delivered'
    ) THEN
        RAISE EXCEPTION 'Người bán đang có đơn hàng chưa hoàn tất, không thể xóa';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_seller_delete BEFORE DELETE ON sellers
FOR EACH ROW EXECUTE FUNCTION fn_check_seller_delete();

---	TEST
---		CHUẨN BỊ DỮ LIỆU MẪU
-- Người bán 1: Không có đơn hàng nào (Để test xóa thành công)
INSERT INTO sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
VALUES ('0015a82c-2db0-00af-6aaa-f3ae2ecb11a1', 1001, 'Hanoi', 'HN');
-- Người bán 2: Đang có đơn hàng chưa giao (Để test xóa thất bại)
INSERT INTO sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
VALUES ('0015a82c-2db0-00af-6aaa-f3ae2ecb11a2', 1002, 'HCM', 'SG');
-- Tạo một đơn hàng 'processing' liên kết với Người bán 2
INSERT INTO order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value)
VALUES ('99999999-9999-9999-9999-999999999999', 1, '00066f42-aeeb-9f30-0754-8bb9d3f33c38', '0015a82c-2db0-00af-6aaa-f3ae2ecb11a2', NOW(), 100.0, 10.0);

---		TRƯỜNG HỢP XÓA THÀNH CÔNG
DELETE FROM sellers WHERE seller_id = '0015a82c-2db0-00af-6aaa-f3ae2ecb11a1';

---		TRƯỜNG HỢP XÓA THẤT BẠI
DELETE FROM sellers WHERE seller_id = '0015a82c-2db0-00af-6aaa-f3ae2ecb11a2';




-- LIÊN BẢNG

----------	Đồng bộ tổng tiền thanh toán (order_id & payment_value)
----------	mỗi khi thêm xóa sửa số lượng item trong bảng order_item thì số tiền cần thanh toán trong order phải được cập nhật
-- BỎ
CREATE OR REPLACE FUNCTION fn_sync_order_total_payment() 
RETURNS TRIGGER AS $$
DECLARE
    v_order_id UUID;
    v_new_total NUMERIC;
BEGIN
    -- Xác định order_id cần cập nhật (NEW cho insert/update, OLD cho delete)
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);

    -- Tính toán lại tổng tiền từ bảng order_items (giá + phí ship)
    SELECT SUM(price + freight_value) INTO v_new_total
    FROM order_items
    WHERE order_id = v_order_id;

    -- Cập nhật vào bảng thanh toán
    UPDATE order_payments
    SET payment_value = COALESCE(v_new_total, 0)
    WHERE order_id = v_order_id;

    RETURN NULL; -- Triggers sau khi thay đổi (AFTER) thường trả về NULL
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_payment_after_item_change
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION fn_sync_order_total_payment();


-------- Không cho thêm hoặc cập nhật nếu địa chỉ customer hay seller không tồn tại trong bảng geolocation
---		Bảng customers
CREATE OR REPLACE FUNCTION fn_validate_customer_geo() 
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM geolocation 
        WHERE geolocation_zip_code_prefix = NEW.customer_zip_code_prefix
    ) THEN
        RAISE EXCEPTION 'Mã Zip code % của khách hàng không tồn tại trong hệ thống địa lý', NEW.customer_zip_code_prefix;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_customer_geo
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION fn_validate_customer_geo();

---		Bảng sellers
CREATE OR REPLACE FUNCTION fn_validate_seller_geo() 
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM geolocation 
        WHERE geolocation_zip_code_prefix = NEW.seller_zip_code_prefix
    ) THEN
        RAISE EXCEPTION 'Mã Zip code % của người bán không tồn tại trong hệ thống địa lý', NEW.seller_zip_code_prefix;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_seller_geo
BEFORE INSERT OR UPDATE ON sellers
FOR EACH ROW EXECUTE FUNCTION fn_validate_seller_geo();

---	TEST
---		CHUẨN BỊ DỮ LIỆU MẪU
-- Thêm một địa chỉ hợp lệ vào bản đồ
INSERT INTO geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state)
VALUES (12345, -23.5, -46.6, 'Sao Paulo', 'SP');

---		TRƯỜNG HỢP THÊM THÀNH CÔNG
INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES (
    '00000000-0000-0000-0000-000000000100', 
    '00000000-0000-0000-0000-000000000100', 
    12345,
    'Sao Paulo', 
    'SP'
);

---		TRƯỜNG HỢP THÊM THẤT BẠI
INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES (
    '00000000-0000-0000-0000-000000000200', 
    '00000000-0000-0000-0000-000000000200', 
    99999, -- Mã này KHÔNG có trong geolocation
    'Unknown City', 
    'XX'
);




----------	Chỉ cho phép đánh giá khi đơn hàng đã giao thành công
CREATE OR REPLACE FUNCTION fn_validate_review_order_status() 
RETURNS TRIGGER AS $$
BEGIN
    -- Kiểm tra trạng thái đơn hàng từ bảng orders
    IF NOT EXISTS (
        SELECT 1 FROM orders 
        WHERE order_id = NEW.order_id 
        AND order_status = 'delivered'
    ) THEN
        RAISE EXCEPTION 'Không thể đánh giá đơn hàng chưa giao thành công (Trạng thái hiện tại không phải delivered)';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_review_status
BEFORE INSERT ON order_reviews
FOR EACH ROW EXECUTE FUNCTION fn_validate_review_order_status();

---	TEST
---		CHUẨN BỊ DỮ LIỆU MẪU
-- Đơn hàng A1: Đã giao thành công
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('00000000-0000-0000-0000-0000000000A1', '00000000-0000-0000-0000-000000000002', 'delivered', NOW());
-- Đơn hàng A2: Đang xử lý
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('00000000-0000-0000-0000-0000000000A2', '00000000-0000-0000-0000-000000000002', 'processing', NOW());

---		TRƯỜNG HỢP THÀNH CÔNG
INSERT INTO order_reviews (review_id, order_id, review_score, review_comment_message, review_creation_date)
VALUES (
    '00000000-0000-0000-0000-000000000999', 
    '00000000-0000-0000-0000-0000000000A1', 
    5, 
    'Hàng rất tốt!', 
    NOW()
);

---		TRƯỜNG HỢP THÊM THẤT BẠI
INSERT INTO order_reviews (review_id, order_id, review_score, review_comment_message, review_creation_date)
VALUES (
    '00000000-0000-0000-0000-000000000888', 
    '00000000-0000-0000-0000-0000000000A2', 
    1, 
    'Sao mãi chưa thấy hàng?', 
    NOW()
);






