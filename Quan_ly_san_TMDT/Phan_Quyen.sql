SELECT 
    current_user AS "User_Hien_Tai",
    session_user AS "User_Goc_Dang_Nhap",
    rolsuper AS "La_Superuser",
    rolcreaterole AS "Co_Quyen_Tao_Role",
    rolcreatedb AS "Co_Quyen_Tao_DB"
FROM pg_roles 
WHERE rolname = current_user;



--------- Tạo Role Admin
--------- Tất cả các quyền
CREATE ROLE admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_role;
---	CHECK
SELECT 
    grantee AS "Role",
    table_name AS "Tên Bảng",
    string_agg(privilege_type, ', ') AS "Danh sách quyền"
FROM information_schema.table_privileges 
WHERE grantee IN ('admin_role') AND table_schema = 'public'
GROUP BY grantee, table_name
ORDER BY table_name, grantee;



--------- Tạo Role Manager
CREATE ROLE managers_role;
GRANT SELECT, UPDATE ON ALL TABLES IN SCHEMA public TO managers_role;
---	CHECK
SELECT 
    grantee AS "Role",
    table_name AS "Tên Bảng",
    string_agg(privilege_type, ', ') AS "Danh sách quyền"
FROM information_schema.table_privileges 
WHERE grantee IN ('managers_role') AND table_schema = 'public'
GROUP BY grantee, table_name
ORDER BY table_name, grantee;




--------- Tạo Role Data Analyst, Marketing,...
CREATE ROLE analyst_role;
---	Tạo View che thông tin khách hàng
CREATE VIEW v_customers_masked AS
SELECT 
    customer_id,
    customer_unique_id,
    LEFT(customer_zip_code_prefix::text, 2) || '***' as zip_code_masked,
    'HIDDEN' as customer_city, -- Che tên thành phố
    customer_state
FROM customers;
---	Cấp quyền SELECT trên View và các bảng khác (trừ bảng customer gốc)
GRANT SELECT ON v_customers_masked TO analyst_role;
GRANT SELECT ON orders, order_items, products TO analyst_role;
---	CHECK
SELECT 
    grantee AS "Role",
    table_name AS "Tên Bảng",
    string_agg(privilege_type, ', ') AS "Danh sách quyền"
FROM information_schema.table_privileges 
WHERE grantee IN ('analyst_role') AND table_schema = 'public'
GROUP BY grantee, table_name
ORDER BY table_name, grantee;



--------- Tạo Role Transport
CREATE ROLE transport_role;
---	Chỉ cho phép SELECT các cột vận chuyển và UPDATE cột trạng thái
GRANT SELECT (order_id, order_status, order_delivered_carrier_date, order_delivered_customer_date) 
ON orders TO transport_role;

GRANT UPDATE (order_status, order_delivered_carrier_date) 
ON orders TO transport_role;

---	CHECK
SELECT 
    grantee AS "Role",
    table_name AS "Tên Bảng",
    privilege_type AS "Danh sách quyền",
    '(' || string_agg(column_name, ', ') || ')' AS "Các Cột Được Phép"
FROM information_schema.column_privileges 
WHERE grantee = 'transport_role' AND table_schema = 'public'
GROUP BY grantee, table_name, privilege_type
ORDER BY table_name, privilege_type;




--------- Tạo Role Seller
CREATE ROLE sellers_role;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
-- Chỉ thao tác trên những đơn hàng thuộc về mình
CREATE POLICY seller_item_policy ON order_items
FOR ALL TO seller_role
USING (seller_id::text = current_user::text);
-- Xem toàn bộ sản phẩm
CREATE POLICY seller_product_view_policy ON products
FOR SELECT TO seller_role
USING (true); 
-- Chỉ được sửa sản phẩm của mình (kiểm tra qua bảng order_items)
CREATE POLICY seller_product_modify_policy ON products
FOR UPDATE TO seller_role
USING (
    product_id IN (
        SELECT product_id FROM order_items 
        WHERE seller_id::text = current_user::text
    )
);
-- Cấp quyền
GRANT SELECT, INSERT, UPDATE ON order_items TO seller_role;
GRANT SELECT, UPDATE ON products TO seller_role;


--- CHECK
SELECT 
    grantee AS "Role",
    table_name AS "Tên Bảng",
    privilege_type AS "Danh sách quyền",
    COALESCE(
        (SELECT qual FROM pg_policies p 
         WHERE p.tablename = tp.table_name 
         AND (p.roles @> ARRAY[tp.grantee::name] OR p.roles @> ARRAY['public'::name])
         AND (p.cmd = tp.privilege_type OR p.cmd = 'ALL')
         AND qual <> 'true'), 
        'Toàn bộ bảng'
    ) AS "Phạm vi dữ liệu (RLS)"
FROM information_schema.table_privileges tp
WHERE grantee = 'seller_role' 
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;




--------- Tạo Role Customer
CREATE ROLE customer_role;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
---		Chỉ xem đơn hàng của chính mình
CREATE POLICY customer_order_policy ON orders
FOR SELECT TO customer_role
USING (customer_id::text = current_user::text);
---	Cấp quyền
GRANT SELECT ON products TO customer_role; -- Xem sản phẩm
GRANT SELECT, INSERT ON order_reviews TO customer_role; -- Review
GRANT SELECT ON orders TO customer_role; -- Xem đơn hàng cá nhân

--- CHECK
SELECT 
    grantee AS "Role",
    table_name AS "Tên Bảng",
    string_agg(DISTINCT privilege_type, ', ') AS "Danh sách quyền",
    COALESCE(
        (SELECT qual FROM pg_policies p 
         WHERE p.tablename = tp.table_name 
		 AND (p.roles @> ARRAY[tp.grantee::name] OR p.roles @> ARRAY['public'::name]) 
         LIMIT 1), 
        'Toàn bộ bảng'
    ) AS "Phạm vi dữ liệu (RLS)"
FROM information_schema.table_privileges tp
WHERE grantee = 'customer_role' AND table_schema = 'public'
GROUP BY grantee, table_name;





