-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Migration : Update Devices V1
-- Table : devices
-- ==========================================================

------------------------------------------------------------
-- Add new columns
------------------------------------------------------------

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS device_model text;

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS manufacturer text;

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS os_version text;

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS app_build text;

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS push_token text;

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS locale text;

ALTER TABLE public.devices
ADD COLUMN IF NOT EXISTS country_code text;

------------------------------------------------------------
-- Default values
------------------------------------------------------------

ALTER TABLE public.devices
ALTER COLUMN is_trusted SET DEFAULT false;

ALTER TABLE public.devices
ALTER COLUMN last_seen_at SET DEFAULT now();

ALTER TABLE public.devices
ALTER COLUMN created_at SET DEFAULT now();

ALTER TABLE public.devices
ALTER COLUMN updated_at SET DEFAULT now();

------------------------------------------------------------
-- Indexes
------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_devices_profile_id
ON public.devices(profile_id);

CREATE INDEX IF NOT EXISTS idx_devices_device_id
ON public.devices(device_id);

CREATE INDEX IF NOT EXISTS idx_devices_last_seen
ON public.devices(last_seen_at);

CREATE INDEX IF NOT EXISTS idx_devices_is_trusted
ON public.devices(is_trusted);