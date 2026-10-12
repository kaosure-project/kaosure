begin;do $$ declare u uuid:=gen_random_uuid();v uuid:=gen_random_uuid();p uuid:=gen_random_uuid();ship uuid:=gen_random_uuid();sid uuid:=gen_random_uuid();a uuid;b uuid;r text;t timestamptz:=now();begin
insert into auth.users(id,email) values(u,'link-'||u||'@example.invalid'),(v,'link-'||v||'@example.invalid');
insert into public.profiles(id,seller_level,username) values(u,'standard','link-'||u),(v,'standard','link-'||v) on conflict(id) do nothing;
insert into auth.sessions(id,user_id,created_at,updated_at) values(sid,u,now(),now());
insert into kaoid_private.partners_r12b(id,code,name,environment,capabilities,approval,kind) values(p,'p-'||u,'Fixture','live',array['balance'],'approved','finance'),(ship,'s-'||u,'Carrier','sandbox',array['tracking'],'approved','shipping');
perform kaoid_private.partner_report_r12b(p,'test',true,true,array['balance'],'fixture',now()+interval '1 day');
perform kaoid_private.partner_report_r12b(ship,'test',true,true,array['tracking'],'fixture',now()+interval '1 day');
update kaoid_private.partners_r12b set enabled=true where id in (p,ship);

begin insert into kaoid_private.partners_r12b(code,name,environment,kind,capabilities) values('x-'||u,'bad','sandbox','shipping',array['payment']);raise exception 'shipping finance scope' using errcode='XX001';exception when check_violation then null;end;
set local role service_role;
perform public.partner_receive_r12b(ship,'sandbox','tracking1','tracking',repeat('a',64));
begin perform public.partner_receive_r12b(ship,'sandbox','payment1','payment',repeat('a',64));raise exception 'shipping money event' using errcode='XX001';exception when insufficient_privilege then null;end;
reset role;update kaoid_private.partners_r12b set enabled=false where id=ship;
set local role service_role;
begin perform public.partner_receive_r12b(ship,'sandbox','tracking2','tracking',repeat('b',64));raise exception 'disabled carrier allowed' using errcode='XX001';exception when insufficient_privilege then null;end;
reset role;
end $$;select 'shipping_regression: passed; rollback' as result;rollback;