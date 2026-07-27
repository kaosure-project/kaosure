CREATE TABLE public.devices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    device_id text NOT NULL,
    device_name text,
    device_type text,
    operating_system text,
    app_version text,
    ip_address inet,
    user_agent text,

    is_trusted boolean NOT NULL DEFAULT false,
    last_login_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT devices_device_unique
        UNIQUE(profile_id, device_id)
);

CREATE INDEX idx_devices_profile
ON public.devices(profile_id);

CREATE INDEX idx_devices_trusted
ON public.devices(is_trusted);

CREATE INDEX idx_devices_last_login
ON public.devices(last_login_at);

CREATE TRIGGER trg_devices_updated_at
BEFORE UPDATE ON public.devices
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own devices"
ON public.devices
FOR SELECT
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Users can insert own devices"
ON public.devices
FOR INSERT
TO authenticated
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can update own devices"
ON public.devices
FOR UPDATE
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Users can delete own devices"
ON public.devices
FOR DELETE
TO authenticated
USING (profile_id = auth.uid());

CREATE POLICY "Admins can manage devices"
ON public.devices
FOR ALL
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());