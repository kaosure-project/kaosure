create function kaoid_private.mfa_notice_r14a() returns trigger language plpgsql security definer set search_path='' as $$
declare u uuid;fid uuid;code text;begin
 if tg_op='DELETE' then
  if old.status::text<>'verified' then return old;end if;u:=old.user_id;fid:=old.id;code:='security_factor_removed';
 else
  if new.status::text<>'verified' then return new;end if;
  if tg_op='UPDATE' and old.status::text='verified' then return new;end if;
  u:=new.user_id;fid:=new.id;code:='security_factor_added';
 end if;
 if exists(select 1 from public.profiles where id=u) and exists(select 1 from auth.users where id=u) then
  perform kaoid_private.emit_notice_r10a(u,code||':'||fid,code,fid);
  insert into public.activity_logs(profile_id,action,target_table,target_id,description)
  values(null,code,'profiles',u,'Auth MFA factor lifecycle event; no secret recorded');
 end if;
 if tg_op='DELETE' then return old;else return new;end if;
end $$;
revoke all on function kaoid_private.mfa_notice_r14a() from public,anon,authenticated;
create trigger kaoid_mfa_notice_r14a after insert or update of status or delete on auth.mfa_factors for each row execute function kaoid_private.mfa_notice_r14a();
;
