-- ==========================================
-- KaoSure Database V1.0
-- Migration : setup_functions
-- ==========================================

-- Trigger Function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;