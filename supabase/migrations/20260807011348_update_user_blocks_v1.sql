-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update User Blocks V1
-- Table : user_blocks
-- ==========================================================

------------------------------------------------------------
-- Add columns
------------------------------------------------------------

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS updated_at timestamptz;

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS expires_at timestamptz;

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS is_active boolean;

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS blocked_by uuid;

------------------------------------------------------------
-- Defaults
------------------------------------------------------------

ALTER TABLE public.user_blocks
ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.user_blocks
ALTER COLUMN updated_at SET DEFAULT now();

ALTER TABLE public.user_blocks
ALTER COLUMN is_active SET DEFAULT true;

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker
ON public.user_blocks(blocker_id);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked
ON public.user_blocks(blocked_id);

CREATE INDEX IF NOT EXISTS idx_user_blocks_active
ON public.user_blocks(is_active);

------------------------------------------------------------
-- Foreign Keys
------------------------------------------------------------

ALTER TABLE public.user_blocks
DROP CONSTRAINT IF EXISTS user_blocks_blocked_by_fkey;

ALTER TABLE public.user_blocks
ADD CONSTRAINT user_blocks_blocked_by_fkey
FOREIGN KEY (blocked_by)
REFERENCES public.profiles(id)
ON DELETE SET NULL;