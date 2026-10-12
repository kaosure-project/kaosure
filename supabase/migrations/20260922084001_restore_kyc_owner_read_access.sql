DO $$
DECLARE
  item record;
  actual_qual text;
  policy_count integer;
BEGIN
  FOR item IN SELECT * FROM (VALUES
    ('verifications', 'verifications_select_own', '(profile_id = auth.uid())'),
    ('verification_requests', 'verification_requests_select_own', '(requested_by = auth.uid())'),
    ('identity_documents', 'identity_documents_select_own', '(auth.uid() = owner_id)'),
    ('bank_accounts', 'Users can view own bank accounts', '(auth.uid() = profile_id)'),
    ('verification_logs', 'verification_logs_select_own',
      '(EXISTS ( SELECT 1 FROM verification_requests vr WHERE ((vr.id = verification_logs.verification_request_id) AND (vr.requested_by = auth.uid()))))')
  ) AS expected(table_name, policy_name, expected_qual)
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = item.table_name AND c.relrowsecurity
    ) THEN RAISE EXCEPTION 'RLS missing for %', item.table_name; END IF;
    SELECT count(*) INTO policy_count FROM pg_policies
      WHERE schemaname='public' AND tablename=item.table_name AND cmd IN ('SELECT','ALL');
    SELECT qual INTO actual_qual FROM pg_policies
      WHERE schemaname='public' AND tablename=item.table_name
        AND policyname=item.policy_name AND cmd='SELECT';
    IF policy_count <> 1 OR actual_qual IS NULL OR
       regexp_replace(actual_qual, '\s+', '', 'g') <>
       regexp_replace(item.expected_qual, '\s+', '', 'g') THEN
      RAISE EXCEPTION 'Read policies changed for %; review before granting', item.table_name;
    END IF;
  END LOOP;
END $$;
GRANT SELECT ON TABLE public.verifications, public.verification_requests,
  public.identity_documents, public.bank_accounts, public.verification_logs
  TO authenticated;
;
