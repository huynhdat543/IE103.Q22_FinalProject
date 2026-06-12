
CREATE TABLE category_name_translation(
    product_category_name TEXT PRIMARY KEY ,
    product_category_name_english TEXT
);


CREATE TABLE products (
    product_id UUID PRIMARY KEY,
    product_category_name TEXT REFERENCES category_name_translation(product_category_name),
    product_name_lenght FLOAT,
    product_description_lenght FLOAT,
    product_photos_qty FLOAT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);


CREATE TABLE geolocation (
    geolocation_zip_code_prefix INTEGER PRIMARY KEY,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city TEXT,
    geolocation_state TEXT
);

CREATE TABLE customers (
    customer_id UUID PRIMARY KEY,
    customer_unique_id UUID ,
    customer_zip_code_prefix INTEGER REFERENCES geolocation(geolocation_zip_code_prefix),
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE sellers (
    seller_id UUID PRIMARY KEY,
    seller_zip_code_prefix INTEGER REFERENCES geolocation(geolocation_zip_code_prefix),
    seller_city TEXT,
    seller_state TEXT
);

CREATE TABLE orders (
    order_id UUID PRIMARY KEY,
    customer_id UUID REFERENCES customers(customer_id),
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_reviews (
    review_id UUID PRIMARY KEY,                   -- Khóa chính 
    order_id UUID REFERENCES orders(order_id), -- Khóa ngoại liên kết bảng orders [cite: 12, 21]
    review_score SMALLINT CHECK (review_score BETWEEN 1 AND 5), -- Điểm đánh giá từ 1-5
    review_comment_title TEXT,                    -- Tiêu đề đánh giá
    review_comment_message TEXT,                  -- Nội dung đánh giá
    review_creation_date TIMESTAMP,               -- Ngày tạo đánh giá
    review_answer_timestamp TIMESTAMP             -- Ngày phản hồi đánh giá
);

CREATE TABLE order_payments (
    order_id UUID NOT NULL REFERENCES orders(order_id), -- Khóa ngoại 
    payment_sequential INTEGER,                   -- Số thứ tự phương thức thanh toán
    payment_type TEXT,                            -- Loại thanh toán (credit_card, voucher...)
    payment_installments INTEGER,                 -- Số lần trả góp
    payment_value DECIMAL(10, 2),                -- Giá trị thanh toán (ví dụ: 100.50)
    PRIMARY KEY (order_id, payment_sequential)    -- Khóa chính hỗn hợp 
);

CREATE TABLE order_items (
    order_id UUID NOT NULL REFERENCES orders(order_id),       -- FK: Liên kết tới bảng orders
    order_item_id INTEGER NOT NULL,                           -- Số thứ tự sản phẩm trong đơn hàng
    product_id UUID NOT NULL REFERENCES products(product_id), -- FK: Liên kết tới bảng products
    seller_id UUID NOT NULL REFERENCES sellers(seller_id),   -- FK: Liên kết tới bảng sellers
    shipping_limit_date TIMESTAMP,                            -- Thời hạn người bán phải giao hàng
    price DECIMAL(10, 2) NOT NULL,                            -- Giá của sản phẩm
    freight_value DECIMAL(10, 2),                            -- Giá vận chuyển (cước phí)
    
    -- Thiết lập Khóa chính (Composite Primary Key)
    PRIMARY KEY (order_id, order_item_id)
);

