-- Thống kê doanh thu người bán
---		Tính toán tổng tiền của người bán trong khoảng thời gian nhất định
CREATE OR REPLACE FUNCTION fn_get_seller_revenue(
    p_seller_id UUID, 
    p_start_date TIMESTAMP, 
    p_end_date TIMESTAMP
) 
RETURNS NUMERIC AS $$
DECLARE
    v_revenue NUMERIC;
BEGIN
    SELECT SUM(i.price + i.freight_value) INTO v_revenue
    FROM order_items i
    JOIN orders o ON i.order_id = o.order_id
    WHERE i.seller_id = p_seller_id 
      AND o.order_purchase_timestamp BETWEEN p_start_date AND p_end_date
      AND o.order_status = 'delivered'; -- Chỉ tính đơn giao thành công

    RETURN COALESCE(v_revenue, 0);
END; $$ LANGUAGE plpgsql;

--	TEST
SELECT fn_get_seller_revenue(
    '9d7a1d34-a505-2409-0064-25275ba1c2b4', 
    '2017-01-01 00:00:00', 
    '2017-12-31 23:59:59'
) AS doanh_thu_nam_2017;




-- Tính điểm đánh giá trung bình của người bán
---		Tính điểm trung bình của người bán trên review_score của khách hàng
CREATE OR REPLACE FUNCTION fn_get_seller_rating(p_seller_id UUID) 
RETURNS NUMERIC AS $$
DECLARE
    v_avg_score NUMERIC;
BEGIN
    SELECT AVG(r.review_score) INTO v_avg_score
    FROM order_reviews r
    JOIN order_items i ON r.order_id = i.order_id
    WHERE i.seller_id = p_seller_id;

    RETURN ROUND(COALESCE(v_avg_score, 0), 2);
END; $$ LANGUAGE plpgsql;

-- TEST
SELECT fn_get_seller_rating('9d7a1d34-a505-2409-0064-25275ba1c2b4')
AS Diem_danh_gia_trung_binh


