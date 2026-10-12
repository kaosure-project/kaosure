-- REVIEW ONLY: no production migration has been applied.
-- Current Kao ID profile editor writes exactly these four editable columns.
-- Keep existing RLS ownership policies and server/trigger privileges.
-- Username and legal-name writes will need reviewed server operations.
BEGIN;
SET LOCAL lock_timeout = '5s';

REVOKE UPDATE ON TABLE public.profiles FROM authenticated;
GRANT UPDATE (display_name, avatar_url, bio, language_code)
  ON TABLE public.profiles TO authenticated;

DO $review$
DECLARE
  v_column text;
BEGIN
  FOREACH v_column IN ARRAY ARRAY[
    'role', 'account_level', 'account_status', 'seller_level', 'trust_score',
    'is_seller', 'email_verified_at', 'phone_verified_at', 'deleted_at'
  ] LOOP
    IF has_column_privilege('authenticated', 'public.profiles', v_column, 'UPDATE') THEN
      RAISE EXCEPTION 'Unexpected remaining write grant for %', v_column;
    END IF;
  END LOOP;
  FOREACH v_column IN ARRAY ARRAY['display_name', 'avatar_url', 'bio', 'language_code'] LOOP
    IF NOT has_column_privilege('authenticated', 'public.profiles', v_column, 'UPDATE') THEN
      RAISE EXCEPTION 'Missing profile-editor write grant for %', v_column;
    END IF;
  END LOOP;
END;
$review$;

SELECT column_name,
  has_column_privilege('authenticated', 'public.profiles', column_name, 'UPDATE') AS can_update
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Intentionally no COMMIT: review script does not persist changes.
ROLLBACK;
