-- ==========================================================
-- Cleanup user_blocks
-- ==========================================================

ALTER TABLE public.user_blocks
DROP CONSTRAINT IF EXISTS user_blocks_blocked_by_fkey;

ALTER TABLE public.user_blocks
DROP COLUMN IF EXISTS blocked_by;