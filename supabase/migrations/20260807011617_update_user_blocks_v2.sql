-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Table : user_blocks
-- ==========================================================

------------------------------------------------------------
-- Add columns
------------------------------------------------------------

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS expires_at timestamptz;

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

ALTER TABLE public.user_blocks
ADD COLUMN IF NOT EXISTS blocked_by uuid;

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker
ON public.user_blocks(blocker_profile_id);

CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked
ON public.user_blocks(blocked_profile_id);

CREATE INDEX IF NOT EXISTS idx_user_blocks_active
ON public.user_blocks(is_active);

------------------------------------------------------------
-- Foreign Key
------------------------------------------------------------

ALTER TABLE public.user_blocks
DROP CONSTRAINT IF EXISTS user_blocks_blocked_by_fkey;

ALTER TABLE public.user_blocks
ADD CONSTRAINT user_blocks_blocked_by_fkey
FOREIGN KEY (blocked_by)
REFERENCES public.profiles(id)
ON DELETE SET NULL;