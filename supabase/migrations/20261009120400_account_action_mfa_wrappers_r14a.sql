alter function kaoid_private.set_account_state_r9f(uuid,text,text,text) rename to set_account_state_execute_r14a;
revoke all on function kaoid_private.set_account_state_execute_r14a(uuid,text,text,text) from public,anon,authenticated;
create function kaoid_private.set_account_state_r9f(p_target uuid,p_expected text,p_next text,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$ begin
perform kaoid_private.require_fresh_mfa_r14a();
return kaoid_private.set_account_state_execute_r14a(p_target,p_expected,p_next,p_reason);end $$;
revoke all on function kaoid_private.set_account_state_r9f(uuid,text,text,text) from public,anon;
grant execute on function kaoid_private.set_account_state_r9f(uuid,text,text,text) to authenticated;
alter function kaoid_private.close_account_r10d(uuid,text) rename to close_account_execute_r14a;
revoke all on function kaoid_private.close_account_execute_r14a(uuid,text) from public,anon,authenticated;
create function kaoid_private.close_account_r10d(p_request uuid,p_reason text) returns boolean language plpgsql security definer set search_path='' as $$ begin
perform kaoid_private.require_fresh_mfa_r14a();
return kaoid_private.close_account_execute_r14a(p_request,p_reason);end $$;
revoke all on function kaoid_private.close_account_r10d(uuid,text) from public,anon;
grant execute on function kaoid_private.close_account_r10d(uuid,text) to authenticated;
