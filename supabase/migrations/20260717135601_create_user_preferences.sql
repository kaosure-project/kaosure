CREATE TABLE public.user_preferences (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    profile_id uuid NOT NULL
        REFERENCES public.profiles(id)
        ON DELETE CASCADE,

    favorite_categories text[] NOT NULL DEFAULT '{}',
    favorite_brands text[] NOT NULL DEFAULT '{}',
    favorite_conditions text[] NOT NULL DEFAULT '{}',

    preferred_price_min numeric(15,2) DEFAULT 0,
    preferred_price_max numeric(15,2),

    preferred_language text DEFAULT 'th',

    allow_personalization boolean NOT NULL DEFAULT true,

    last_analyzed_at timestamptz,

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT user_preferences_profile_unique
        UNIQUE(profile_id),

    CONSTRAINT user_preferences_price_check
        CHECK (
            preferred_price_max IS NULL
            OR preferred_price_max >= preferred_price_min
        )

);

CREATE INDEX idx_user_preferences_profile
ON public.user_preferences(profile_id);

ALTER TABLE public.user_preferences
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own preferences"
ON public.user_preferences
FOR ALL
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

CREATE POLICY "System manage user preferences"
ON public.user_preferences
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

CREATE TRIGGER update_user_preferences_updated_at
BEFORE UPDATE
ON public.user_preferences
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

COMMENT ON TABLE public.user_preferences IS
'Stores user preferences for recommendation and personalization.';