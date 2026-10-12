begin;do $$ declare u uuid:=gen_random_uuid();v uuid:=gen_random_uuid();p uuid:=gen_random_uuid();ship uuid:=gen_random_uuid();sid uuid:=gen_random_uuid();a uuid;b uuid;r text;t timestamptz:=now();begin
insert into auth.users(id,email) values(u,'link-'||u||'@example.invalid'),(v,'link-'||v||'@example.invalid');
insert into public.profiles(id,seller_level,username) values(u,'standard','link-'||u),(v,'standard','link-'||v) on conflict(id) do nothing;
insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,u,now(),now());
insert into kaoid_private.partners_r12b(id,code,name,environment,capabilities,approval,kind) values(p,'p-'||u,'Fixture','live',array['balance'],'approved','finance'),(ship,'s-'||u,'Carrier','sandbox',array['tracking'],'approved','shipping');
perform kaoid_private.partner_report_r12b(p,'test',true,true,array['balance'],'fixture',now()+interval '1 day');
perform kaoid_private.partner_report_r12b(ship,'test',true,true,array['tracking'],'fixture',now()+interval '1 day');
update kaoid_private.partners_r12b set enabled=true where id in (p,ship);

a:=kaoid_private.wallet_link_r12c(p,'live',u,'account-a');
set local role service_role;
r:=public.wallet_sync_r12c(p,'live','account-a','e1',repeat('a',64),2,100.25,10,5,t);
if r<>'applied' then raise exception 'not applied';end if;
if public.wallet_sync_r12c(p,'live','account-a','e1',repeat('a',64),2,100.25,10,5,t)<>'duplicate' then raise exception 'not deduped';end if;
if public.wallet_sync_r12c(p,'live','account-a','e2',repeat('b',64),1,1,0,0,t-interval '1 second')<>'older' then raise exception 'old overwrote';end if;
begin perform public.wallet_sync_r12c(p,'live','account-a','e1',repeat('a',64),2,999,10,5,t);raise exception 'normalized conflict allowed' using errcode='XX001';exception when unique_violation then null;end;
begin perform public.wallet_sync_r12c(p,'sandbox','account-a','e3',repeat('c',64),3,999,0,0,t);raise exception 'wrong mode allowed' using errcode='XX001';exception when insufficient_privilege then null;end;
reset role;
if (select available from kaoid_private.wallet_snapshots_r12c where link_id=a)<>100.25 then raise exception 'wrong final amount';end if;
if (select count(*) from kaoid_private.wallet_updates_r12c where link_id=a)<>2 then raise exception 'wrong event count';end if;
end $$;select 'sync_regression: passed; rollback' as result;rollback;