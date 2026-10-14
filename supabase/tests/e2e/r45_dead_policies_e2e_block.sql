-- R45 checks. Appended after the migration inside one transaction that never commits.
do $$
declare
  shop uuid := (select id from public.shops where shop_status = 'active' order by created_at limit 1);
  member uuid := (select owner_id from public.shops where shop_status = 'active' order by created_at limit 1);
  member_session uuid := gen_random_uuid();
  report text := '';
  j jsonb;
  n bigint;
  step text;
begin
  insert into auth.sessions(id, user_id, created_at, updated_at, aal)
  values (member_session, member, now(), now(), 'aal1');

  foreach step in array array['dead_policies', 'extra_policies', 'counts', 'member_notifications',
      'member_mark_read', 'member_insert_notification', 'member_update_shop', 'member_reads_shop',
      'member_my_page', 'guest_shop_page', 'guest_legacy_table'] loop
    begin
      report := report || step || ': ';
      perform set_config('request.jwt.claims', json_build_object('sub', member, 'role', 'authenticated',
        'session_id', member_session, 'aal', 'aal1', 'is_anonymous', false)::text, true);

      case step
        when 'dead_policies' then
          report := report || 'dead=' || (select count(*) from pg_policies p
            join pg_class c on c.relnamespace = 'public'::regnamespace and c.relname = p.tablename
            where p.schemaname = 'public' and p.permissive = 'PERMISSIVE'
              and p.roles && array['authenticated', 'anon', 'public']::name[]
              and not (has_table_privilege('authenticated', c.oid, 'select,insert,update,delete')
                or has_table_privilege('anon', c.oid, 'select,insert,update,delete')
                or exists (select 1 from information_schema.column_privileges cp
                  where cp.table_schema = 'public' and cp.table_name = c.relname
                    and cp.grantee in ('authenticated', 'anon'))));
        when 'extra_policies' then
          report := report || 'left=' || (select count(*) from pg_policies where schemaname = 'public'
            and ((tablename = 'shops' and policyname = 'marketplace_owner_update_shop')
              or (tablename = 'notifications' and policyname = 'System can create notifications')));
        when 'counts' then
          report := report || 'public=' || (select count(*) from pg_policies where schemaname = 'public')
            || ' restrictive=' || (select count(*) from pg_policies where schemaname = 'public' and permissive = 'RESTRICTIVE')
            || ' all=' || (select count(*) from pg_policies)
            || ' rls_off=' || (select count(*) from pg_class where relnamespace = 'public'::regnamespace
              and relkind in ('r', 'p') and not relrowsecurity)
            || ' data_rows=' || ((select count(*) from public.permissions) + (select count(*) from public.role_permissions)
              + (select count(*) from public.activity_logs) + (select count(*) from public.admin_roles));
        when 'member_notifications' then
          perform set_config('role', 'authenticated', true);
          select count(*) into n from public.notifications where profile_id = member;
          report := report || 'read_ok';
        when 'member_mark_read' then
          perform set_config('role', 'authenticated', true);
          update public.notifications set is_read = is_read where profile_id = member;
          report := report || 'update_ok';
        when 'member_insert_notification' then
          perform set_config('role', 'authenticated', true);
          insert into public.notifications(profile_id, title, message, notification_type)
          values (member, 'x', 'x', 'kaoid');
          report := report || 'UNEXPECTED_OK';
        when 'member_update_shop' then
          perform set_config('role', 'authenticated', true);
          update public.shops set description = description where id = shop;
          report := report || 'UNEXPECTED_OK';
        when 'member_reads_shop' then
          perform set_config('role', 'authenticated', true);
          select count(*) into n from public.shops where id = shop;
          report := report || 'rows=' || n;
        when 'member_my_page' then
          perform set_config('role', 'authenticated', true);
          j := secondhand.get_my_page();
          report := report || 'ok=' || (j is not null);
        when 'guest_shop_page' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          report := report || 'profile=' || (secondhand.get_shop_profile(shop) is not null)
            || ' items=' || (secondhand.list_shop_items(shop, 'selling', 'newest', null, 10) is not null);
        when 'guest_legacy_table' then
          perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
          perform set_config('role', 'anon', true);
          select count(*) into n from public.disputes;
          report := report || 'UNEXPECTED_OK';
      end case;
      perform set_config('role', 'postgres', true);
      report := report || ' | ';
    exception when others then
      perform set_config('role', 'postgres', true);
      report := report || 'ERR ' || sqlstate || ' ' || sqlerrm || ' | ';
    end;
  end loop;
  raise exception 'E2E_REPORT %', report;
end $$;
