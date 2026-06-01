-- customers
---		Khách hàng không được null bất kỳ cột nào
ALTER TABLE customers 
ALTER COLUMN customer_id SET NOT NULL,
ALTER COLUMN customer_unique_id SET NOT NULL,
ALTER COLUMN customer_zip_code_prefix SET NOT NULL,
ALTER COLUMN customer_city SET NOT NULL,
ALTER COLUMN customer_state SET NOT NULL;


-- orders
---		Order không được null bất kỳ cột nào
ALTER TABLE orders 
    ALTER COLUMN order_id SET NOT NULL,
    ALTER COLUMN customer_id SET NOT NULL,
    ALTER COLUMN order_status SET NOT NULL,
    ALTER COLUMN order_purchase_timestamp SET NOT NULL,
    ALTER COLUMN order_approved_at SET NOT NULL,
    ALTER COLUMN order_delivered_carrier_date SET NOT NULL,
    ALTER COLUMN order_delivered_customer_date SET NOT NULL,
    ALTER COLUMN order_estimated_delivery_date SET NOT NULL;


-- geolocation
---		Dữ liệu địa lý không được null bất kỳ cột nào,
---		Kiểm tra vĩ độ (-90 -> 90) và kinh độ (-180 -> 180)
ALTER TABLE geolocation 
ADD CONSTRAINT geo_not_null CHECK (
	geolocation_zip_code_prefix IS NOT NULL 
	AND geolocation_lat IS NOT NULL
	AND geolocation_lng IS NOT NULL
),
				
ADD CONSTRAINT check_lat_long CHECK (
	geolocation_lat BETWEEN -90 AND 90 
	AND geolocation_lng BETWEEN -180 AND 180
);


-- order_items
ALTER TABLE order_items 
    ALTER COLUMN order_id SET NOT NULL,
    ALTER COLUMN order_item_id SET NOT NULL,
    ALTER COLUMN product_id SET NOT NULL,
    ALTER COLUMN seller_id SET NOT NULL,
    ALTER COLUMN shipping_limit_date SET NOT NULL,
    ALTER COLUMN price SET NOT NULL,
    ALTER COLUMN freight_value SET NOT NULL;

---		Kiểm tra price và freight không được <0, order_item phải >0
ALTER TABLE order_items 
ADD CONSTRAINT check_items_value CHECK (
	price >= 0 AND freight_value >= 0 AND order_item_id > 0
);



-- order_payments
---		order_payments không được null bất kỳ cột nào
ALTER TABLE order_payments
    ALTER COLUMN order_id SET NOT NULL,
    ALTER COLUMN payment_sequential SET NOT NULL,
    ALTER COLUMN payment_type SET NOT NULL,
    ALTER COLUMN payment_installments SET NOT NULL,
    ALTER COLUMN payment_value SET NOT NULL;

--- 	Kiểm tra số kỳ trả góp payment_sequential phải >0, 
---		số tiền trả phải >0 nếu =0 thì phải có voucher,...
ALTER TABLE order_payments 
ADD CONSTRAINT check_payment_logic CHECK (
    payment_sequential > 0 AND 
    (payment_value > 0 OR (payment_value = 0 AND payment_type = 'voucher'))
);


-- order_reviews
---		kiểm tra điểm đánh giá phải trong giới hạn từ 1-5
ALTER TABLE order_reviews 
ADD CONSTRAINT check_review_score CHECK (review_score BETWEEN 1 AND 5);


-- products
---		product không được null bất kỳ cột nào
ALTER TABLE products 
    ALTER COLUMN product_id SET NOT NULL,
    ALTER COLUMN product_category_name SET NOT NULL,
    ALTER COLUMN product_name_lenght SET NOT NULL,
    ALTER COLUMN product_description_lenght SET NOT NULL,
    ALTER COLUMN product_photos_qty SET NOT NULL,
    ALTER COLUMN product_weight_g SET NOT NULL,
    ALTER COLUMN product_length_cm SET NOT NULL,
    ALTER COLUMN product_height_cm SET NOT NULL,
    ALTER COLUMN product_width_cm SET NOT NULL;

---		Cân nặng và kích thước không được <=0
ALTER TABLE products 
ADD CONSTRAINT check_product_dims CHECK (
    product_weight_g > 0 AND 
    product_length_cm > 0 AND 
    product_height_cm > 0 AND 
    product_width_cm > 0
);

-- sellers
---		seller không được null bất kỳ cột nào
ALTER TABLE sellers
    ALTER COLUMN seller_id SET NOT NULL,
    ALTER COLUMN seller_zip_code_prefix SET NOT NULL,
    ALTER COLUMN seller_city SET NOT NULL,
    ALTER COLUMN seller_state SET NOT NULL;

