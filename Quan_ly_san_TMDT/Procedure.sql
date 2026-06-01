--------- Thêm sản phẩm mới
CREATE OR REPLACE PROCEDURE sp_add_new_product(
    p_id UUID,
    p_category TEXT,
    p_name_len INT,
    p_desc_len INT,
    p_photos INT,
    p_weight INT,
    p_length INT,
    p_height INT,
    p_width INT
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO products (
        product_id, product_category_name, product_name_lenght, 
        product_description_lenght, product_photos_qty, 
        product_weight_g, product_length_cm, product_height_cm, product_width_cm
    ) 
    VALUES (p_id, p_category, p_name_len, p_desc_len, p_photos, p_weight, p_length, p_height, p_width);
    
    COMMIT;
END; $$;

---	TEST
CALL sp_add_new_product(
    '00000000-0000-0000-0000-000000000888'::UUID,
    'office_furniture', 50, 150, 2, 1200, 30, 20, 15
);
SELECT * FROM products 
WHERE product_id = '00000000-0000-0000-0000-000000000888';





-------- Hủy đơn hàng
-------- kiểm tra xem đơn hàng đã giao chưa, nếu chưa mới cho phép chuyển qua cancel
CREATE OR REPLACE PROCEDURE sp_cancel_order(p_order_id UUID)
LANGUAGE plpgsql AS $$
DECLARE
    v_status TEXT;
BEGIN
    -- Lấy trạng thái hiện tại của đơn hàng
    SELECT order_status INTO v_status FROM orders WHERE order_id = p_order_id;

    -- Kiểm tra điều kiện hủy
    IF v_status = 'delivered' THEN
        RAISE EXCEPTION 'Không thể hủy đơn hàng đã giao thành công.';
    ELSE
        UPDATE orders 
        SET order_status = 'canceled' 
        WHERE order_id = p_order_id;
    END IF;
END; $$;

--- TEST
--- 	CHUẨN BỊ DỮ LIỆU MẪU (Một đơn hàng đang chờ xử lý)
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES (
    '00000000-0000-0000-0000-000000000999', 
    '00000000-0000-0000-0000-000000000002',
    'processing', 
    NOW()
) ON CONFLICT (order_id) DO UPDATE SET order_status = 'processing';
---		SỬ DỤNG PROCEDURE HỦY ĐƠN HÀNG
CALL sp_cancel_order('00000000-0000-0000-0000-000000000999');
SELECT order_id, order_status 
FROM orders 
WHERE order_id = '00000000-0000-0000-0000-000000000999';



-------- Áp dụng mã giảm giá
-------- trừ tiền giảm trực tiếp vào thuộc tính tiền thanh toán
CREATE OR REPLACE PROCEDURE sp_apply_discount(p_order_id UUID, p_discount_value NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE order_payments
    SET payment_value = GREATEST(payment_value - p_discount_value, 0)
    WHERE order_id = p_order_id;
END; $$;

---	TEST
--- 	CHUẨN BỊ DỮ LIỆU MẪU (Đơn hàng có số tiền ban đầu là 500)
INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp)
VALUES ('00000000-0000-0000-0000-000000000123', '00000000-0000-0000-0000-000000000002', 'processing', NOW())
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value)
VALUES ('00000000-0000-0000-0000-000000000123', 1, 'credit_card', 1, 500.00)
ON CONFLICT (order_id, payment_sequential) DO UPDATE SET payment_value = 500.00;

--- 	SỬ DỤNG PROCEDURE ÁP DỤNG MÃ GIẢM GIÁ
CALL sp_apply_discount('00000000-0000-0000-0000-000000000123', 150.00);
SELECT order_id, payment_value AS gia_tri_con_lai
FROM order_payments 
WHERE order_id = '00000000-0000-0000-0000-000000000123';




















