begin;
do $$
declare u uuid:=gen_random_uuid();a uuid:=gen_random_uuid();b uuid:=gen_random_uuid();o uuid;sa uuid:=gen_random_uuid();sb uuid:=gen_random_uuid();fa uuid:=gen_random_uuid();fb uuid:=gen_random_uuid();d uuid:=gen_random_uuid();req uuid;aid uuid; notice uuid; payload jsonb;
begin
 select profile_id into strict o from public.company_owners;
 insert into auth.users(id,email,email_confirmed_at) values(u,'r14-'||u||'@example.invalid',now()),(a,'r14-'||a||'@example.invalid',now()),(b,'r14-'||b||'@example.invalid',now());
 insert into public.profiles(id,seller_level,username) values(u,'standard','r14-'||u),(a,'standard','r14-'||a),(b,'standard','r14-'||b) on conflict(id) do nothing;
 insert into public.admin_assignments(profile_id,role_id,assigned_by,starts_at,is_active) select x,id,o,now(),true from public.admin_roles cross join unnest(array[a,b]) x where code='kyc_officer';
 insert into auth.mfa_factors(id,user_id,factor_type,status,created_at,updated_at) values(fa,a,'totp','verified',now(),now()),(fb,b,'totp','verified',now(),now());
 insert into auth.sessions(id,user_id,created_at,updated_at,aal,factor_id) values(sa,a,now(),now(),'aal2',fa),(sb,b,now(),now(),'aal2',fb);
 insert into auth.mfa_amr_claims(id,session_id,authentication_method,created_at,updated_at) values(gen_random_uuid(),sa,'totp',now(),now()),(gen_random_uuid(),sb,'totp',now(),now());
 insert into public.verifications(profile_id,status) values(u,'pending') on conflict(profile_id) do update set status='pending';
 insert into public.identity_documents(id,owner_id,document_type,document_number,full_name,status,issued_date,expiry_date) values(d,u,'thai_national_id','1234567890123','Rollback Person','pending_review',current_date-5,current_date+365);
 insert into public.verification_requests(document_id,requested_by,status) values(d,u,'pending') returning id into req;

 if not exists(select 1 from public.notifications where profile_id=a and target_id=req and message='review_new') or not exists(select 1 from public.notifications where profile_id=b and target_id=req and message='review_new') then raise exception 'missing reviewers';end if;
 if exists(select 1 from public.notifications where profile_id=u and target_id=req and message='review_new') then raise exception 'self notification';end if;
 update kaoid_private.security_policy_r14a set mfa_required=true,dual_review=true where id;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa,'aal','aal2')::text,true);
 set local role authenticated;

 select id into notice from public.notifications where profile_id=a and target_id=req and message='review_new';
 payload:=public.kaoid_notice_target_r14b(notice);
 if payload->>'kind'<>'review' or payload->'row'->>'id'<>req::text then raise exception 'wrong target';end if;
 if public.kyc_review_decision_r7c(req,false,'First review') then raise exception 'one person finalized';end if;
 if public.kyc_review_decision_r7c(req,false,'Repeated review') then raise exception 'same person finalized';end if;
 reset role;

 if (select count(*) from public.notifications where profile_id=b and target_id=req and message='review_second')<>1 then raise exception 'second reviewer notice missing or duplicate';end if;
 if exists(select 1 from public.notifications where profile_id in(a,u) and target_id=req and message='review_second') then raise exception 'wrong second recipient';end if;
 update public.admin_assignments set is_active=false where profile_id=a;
 set local role authenticated;
 begin perform public.kaoid_notice_target_r14b(notice);raise exception 'revoked reviewer accessed evidence';exception when insufficient_privilege then null;end;
 reset role;
 update public.admin_assignments set is_active=true where profile_id=a;
 if (select status from public.verification_requests where id=req)<>'pending' then raise exception 'first vote changed KYC';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated','session_id',sb,'aal','aal2')::text,true);
 set local role authenticated;

 begin perform public.kaoid_notice_target_r14b(notice);raise exception 'cross account notice opened';exception when insufficient_privilege then null;end;
 if not public.kyc_review_decision_r7c(req,false,'Second review') then raise exception 'second reviewer did not finish';end if;
 perform public.kyc_review_decision_r7c(req,false,'Retry');
 reset role;
 if (select status from public.verification_requests where id=req)<>'rejected' then raise exception 'result not applied';end if;

 select id into notice from public.notifications where profile_id=b and target_id=req and message='review_second';
 set local role authenticated;
 if public.kaoid_notice_target_r14b(notice)->>'kind'<>'unavailable' then raise exception 'completed request reopened';end if;
 reset role;
 if not exists(select 1 from public.notifications where profile_id=u and target_id=req and message='rejected') then raise exception 'member result missing';end if;
 if (select count(*) from public.approval_steps s join public.approval_requests r on r.id=s.approval_request_id where r.resource_id=req)<>2 then raise exception 'duplicate vote';end if;
end $$;
select 'R14B notifications, roles and target access passed; fixtures rolled back' result;
rollback;
