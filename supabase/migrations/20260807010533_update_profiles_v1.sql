-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update Profiles V1
-- Description : Standardize profiles table
-- ==========================================================

------------------------------------------------------------
-- Remove deprecated column
------------------------------------------------------------

ALTER TABLE public.profiles
DROP COLUMN IF EXISTS position;

------------------------------------------------------------
-- Add new columns
------------------------------------------------------------

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS country_code text;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS timezone text;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS last_login_at timestamptz;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS email_verified_at timestamptz;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS phone_verified_at timestamptz;

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

------------------------------------------------------------
-- Seller defaults
------------------------------------------------------------

ALTER TABLE public.profiles
ALTER COLUMN seller_level DROP DEFAULT;

ALTER TABLE public.profiles
ALTER COLUMN is_seller SET DEFAULT false;