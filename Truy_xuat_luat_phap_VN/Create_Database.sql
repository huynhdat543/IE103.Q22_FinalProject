-- Tạo database law_rag_pgvector
CREATE DATABASE law_rag_pgvector

-- Tạo bảng legal_articles
CREATE TABLE legal_articles (
    article_id TEXT PRIMARY KEY,
    article_title TEXT NOT NULL,
    article_index INTEGER NOT NULL
);

-- Tạo bảng legal_chunks
CREATE TABLE legal_chunks (
    node_id TEXT PRIMARY KEY,
    article_id TEXT NOT NULL,
    level TEXT NOT NULL,
    parent_id TEXT,
    content TEXT NOT NULL,
    embed_text TEXT NOT NULL,
    embedding VECTOR(768),
	
    CONSTRAINT fk_article
        FOREIGN KEY(article_id) REFERENCES legal_articles(article_id)
);

-- check dữ liệu sau khi import
SELECT COUNT(*) AS legal_articles
FROM legal_articles;

SELECT COUNT(*) AS legal_chunks
FROM legal_chunks;


-- tạo bảng chứa tạm embedding
CREATE TABLE chunk_embeddings (
    node_id TEXT PRIMARY KEY,
    embedding TEXT
);

-- Kiểm tra số lượng trong bảng chứa tạm embedding
SELECT COUNT(*)
FROM chunk_embeddings

-- Kiểm tra một mẫu embedding
SELECT node_id, LEFT(embedding, 100)
FROM chunk_embeddings
LIMIT 5


-- UPDATE sang dạng VECTOR(512) ở bên bảng legal_chunks
UPDATE legal_chunks lc
SET embedding = ce.embedding::vector
FROM chunk_embeddings ce
WHERE lc.node_id = ce.node_id

-- Kiểm tra sơ lại dữ liệu của bảng legal_chunks
SELECT *
FROM legal_chunks
LIMIT 5