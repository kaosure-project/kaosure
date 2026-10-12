create or replace function public.revoke_session_r11a(p_session uuid,p_others boolean,p_expected_user uuid) returns boolean language plpgsql set search_path='' as $$
begin
 if p_expected_user is distinct from auth.uid() or p_expected_user is null then raise exception 'account_changed' using errcode='42501';end if;
 return kaoid_private.revoke_session_r11a(p_session,p_others);
end $$;
revoke execute on function public.revoke_session_r11a(uuid,boolean) from public,anon,authenticated;
revoke execute on function public.revoke_session_r11a(uuid,boolean,uuid) from public,anon;
grant execute on function public.revoke_session_r11a(uuid,boolean,uuid) to authenticated;
