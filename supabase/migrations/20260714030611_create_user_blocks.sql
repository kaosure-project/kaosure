-- ==========================================================
-- KaoSure Marketplace
-- Phase 1
-- Module : Core System
-- Table  : user_blocks
-- ==========================================================

CREATE TABLE public.user_blocks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    blocker_id uuid NOT NULL,
    blocked_id uuid NOT NULL,

    reason text,

    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT user_blocks_unique
        UNIQUE (blocker_id, blocked_id),

    CONSTRAINT user_blocks_not_self
        CHECK (blocker_id <> blocked_id)
);

------------------------------------------------------------
-- COMMENT
------------------------------------------------------------

COMMENT ON TABLE public.user_blocks
IS 'Stores blocked users.';

COMMENT ON COLUMN public.user_blocks.blocker_id
IS 'User who blocks another user';

COMMENT ON COLUMN public.user_blocks.blocked_id
IS 'Blocked user';

COMMENT ON COLUMN public.user_blocks.reason
IS 'Reason for blocking';

------------------------------------------------------------
-- FOREIGN KEY
------------------------------------------------------------

ALTER TABLE public.user_blocks
ADD CONSTRAINT user_blocks_blocker_fkey
FOREIGN KEY (blocker_id)
REFERENCES public.profiles(id)
ON UPDATE CASCADE
ON DELETE CASCADE;

ALTER TABLE public.user_blocks
ADD CONSTRAINT user_blocks_blocked_fkey
FOREIGN KEY (blocked_id)
REFERENCES public.profiles(id)
ON UPDATE CASCADE
ON DELETE CASCADE;

------------------------------------------------------------
-- INDEX
------------------------------------------------------------

CREATE INDEX idx_user_blocks_blocker
ON public.user_blocks(blocker_id);

CREATE INDEX idx_user_blocks_blocked
ON public.user_blocks(blocked_id);

------------------------------------------------------------
-- ENABLE RLS
------------------------------------------------------------

ALTER TABLE public.user_blocks
ENABLE ROW LEVEL SECURITY;

------------------------------------------------------------
-- POLICIES
------------------------------------------------------------

CREATE POLICY "Users can create blocks"
ON public.user_blocks
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Users can delete their blocks"
ON public.user_blocks
FOR DELETE
TO authenticated
USING (true);

CREATE POLICY "Users can read blocks"
ON public.user_blocks
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Admins can update blocks"
ON public.user_blocks
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

------------------------------------------------------------
-- SAMPLE DATA
------------------------------------------------------------

-- ไม่มี