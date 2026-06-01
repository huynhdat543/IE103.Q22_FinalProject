-- Kiểm tra trước khi kích hoạt extension pg_trgm
SELECT * 
FROM pg_available_extensions
WHERE name = 'pg_trgm';

-- Kích hoạt pg_trgm
CREATE EXTENSION IF NOT EXISTS pg_trgm

-- Kiểm tra sau khi kích hoạt pg_trgm
SELECT *
FROM pg_available_extensions
WHERE name = 'pg_trgm'

-- Test thử pg_trgm
SELECT similarity(
    'cố ý gây thương tích',
    'tội cố ý gây thương tích'
)


-- Tạo GIN index
CREATE INDEX idx_chunks_embed_text_trgm
ON legal_chunks
USING gin(embed_text gin_trgm_ops)

-- Kiểm tra lại sau khi tạo GIN index
SELECT indexname
FROM pg_indexes
WHERE tablename = 'legal_chunks'

-- Kiểm tra threshold hiện tại
SHOW pg_trgm.similarity_threshold
-- Set lại threshold
SET pg_trgm.similarity_threshold = 0.1

-- Kiểm tra GIN index có chạy không
EXPLAIN ANALYZE
SELECT node_id, embed_text
FROM legal_chunks
WHERE embed_text % 'cố ý gây thương tích'

------ TEST THỬ -------
-- sử dụng word_similarity
SELECT
    node_id,
	embed_text,
    word_similarity('cố ý gây thương tích', embed_text) AS score
FROM legal_chunks
WHERE embed_text % 'cố ý gây thương tích'
ORDER BY score DESC
LIMIT 10

-- sử dụng similarity
SELECT
    node_id,
	embed_text,
    similarity(embed_text, 'cố ý gây thương tích') AS score
FROM legal_chunks
ORDER BY score DESC
LIMIT 10


--------------------------------------------------------------------------------------------
-- Thực nghiệm so sánh thời gian truy vấn giữa có index và không có index

-- Không sử dụng GIN index
DROP INDEX IF EXISTS idx_chunks_embed_text_trgm;

EXPLAIN ANALYZE
SELECT node_id
FROM legal_chunks
WHERE embed_text % 'cố ý gây thương tích'
ORDER BY similarity(embed_text,'cố ý gây thương tích') DESC
LIMIT 10;

-- Sử dụng GIN index
CREATE INDEX idx_chunks_embed_text_trgm
ON legal_chunks
USING gin (embed_text gin_trgm_ops);

EXPLAIN ANALYZE
SELECT node_id
FROM legal_chunks
WHERE embed_text % 'cố ý gây thương tích bị gì?'
ORDER BY similarity(embed_text,'cố ý gây thương tích bị gì?') DESC
LIMIT 10;
