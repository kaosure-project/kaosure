begin;do $$ declare u uuid:=gen_random_uuid();v uuid:=gen_random_uuid();p uuid:=gen_random_uuid();ship uuid:=gen_random_uuid();sid uuid:=gen_random_uuid();a uuid;b uuid;r text;t timestamptz:=now();begin
insert into auth.users(id,email) values(u,'link-'||u||'@example.invalid'),(v,'link-'||v||'@example.invalid');
insert into public.profiles(id,seller_level,username) values(u,'standard','link-'||u),(v,'standard','link-'||v) on conflict(id) do nothing;
insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,u,now(),now());
insert into kaoid_private.partners_r12b(id,code,name,environment,capabilities,approval,kind) values(p,'p-'||u,'Fixture','live',array['balance'],'approved','finance'),(ship,'s-'||u,'Carrier','sandbox',array['tracking'],'approved','shipping');
perform kaoid_private.partner_report_r12b(p,'test',true,true,array['balance'],'fixture',now()+interval '1 day');
perform kaoid_private.partner_report_r12b(ship,'test',true,true,array['tracking'],'fixture',now()+interval '1 day');
update kaoid_private.partners_r12b set enabled=true where id in (p,ship);

set local role service_role;
a:=public.wallet_link_r12c(p,'live',u,'account-a');b:=public.wallet_link_r12c(p,'live',v,'account-b');
if a=b or a<>public.wallet_link_r12c(p,'live',u,'account-a') then raise exception 'link retry failed';end if;
begin perform public.wallet_link_r12c(p,'live',v,'account-a');raise exception 'reassigned' using errcode='XX001';exception when unique_violation then null;end;
begin perform public.wallet_link_r12c(ship,'sandbox',u,'x');raise exception 'shipping linked' using errcode='XX001';exception when insufficient_privilege then null;end;
reset role;
if not (kaoid_private.closure_blockers_r10d(u) @> '[{"table":"partner_wallet"}]'::jsonb) then raise exception 'closure bypass';end if;
perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated','session_id',sid)::text,true);
set local role authenticated;
if jsonb_array_length(public.linked_wallets_r12c(u,null))<>1 then raise exception 'wrong member wallets';end if;
begin perform public.linked_wallets_r12c(u,v);raise exception 'cross user read' using errcode='XX001';exception when insufficient_privilege then null;end;
begin perform public.wallet_link_r12c(p,'live',u,'fake');raise exception 'client link allowed' using errcode='XX001';exception when insufficient_privilege then null;end;
reset role;
end $$;select 'link_regression: passed; rollback' as result;rollback;