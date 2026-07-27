-- ==========================================
-- KaoSure Database Foundation
-- Migration : setup_extensions
-- ==========================================

-- UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Text Search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Case-insensitive text
CREATE EXTENSION IF NOT EXISTS citext;

-- UUID Generator
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";