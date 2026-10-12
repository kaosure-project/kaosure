create schema kaoid_gateway;
revoke all on schema kaoid_gateway from public;
grant usage on schema kaoid_gateway to anon,authenticated,service_role;
create function kaoid_gateway.pre_request_r10d() returns void language sql security definer set search_path='' as $$select kaoid_private.pre_request_r10d();$$;
revoke all on function kaoid_gateway.pre_request_r10d() from public;
grant execute on function kaoid_gateway.pre_request_r10d() to anon,authenticated,service_role;
alter role authenticator set pgrst.db_pre_request='kaoid_gateway.pre_request_r10d';
notify pgrst,'reload config';;
