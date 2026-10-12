-- Personal bank submissions only. Approval and payment capabilities are unchanged.
alter table public.bank_accounts add column if not exists evidence_path text;
create or replace function kaoid_private.submit_bank_r8c(
 p_id uuid,p_bank text,p_name text,p_number text,p_branch text,p_type text,p_evidence text
) returns uuid language plpgsql security definer set search_path='' as $$
declare
 u uuid:=auth.uid(); b public.bank_accounts%rowtype; o storage.objects%rowtype;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
  raise exception 'authentication_required' using errcode='42501'; end if;
 if p_id is null or p_bank is null or length(btrim(p_bank)) not between 2 and 100
  or p_name is null or length(btrim(p_name)) not between 1 and 200
  or p_number is null or p_number !~ '^[0-9]{6,20}$'
  or p_branch is null or length(btrim(p_branch))>100
  or (p_bank||p_name||p_branch) ~ '[[:cntrl:]]'
  or p_type is null or p_type not in ('savings','current') then
  raise exception 'invalid_bank' using errcode='22023'; end if;
 if p_evidence is null or p_evidence<>u::text||'/bank-account/'||p_id::text||'/evidence.jpg' then
  raise exception 'invalid_document_paths' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(u::text,718));
 if not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null) then
  raise exception 'inactive_account' using errcode='42501'; end if;
 select * into b from public.bank_accounts where id=p_id;
 if found then
  if b.profile_id=u and b.organization_id is null and b.bank_name=btrim(p_bank)
   and b.account_name=btrim(p_name) and b.account_number=p_number and b.branch_name=btrim(p_branch)
   and b.account_type=p_type and b.currency_code='THB' and b.evidence_path=p_evidence
   and b.deleted_at is null and exists(select 1 from public.financial_verifications where bank_account_id=b.id) then
   return p_id; end if;
  raise exception 'bank_conflict' using errcode='42501'; end if;
 -- Financial review is separate from identity-document review.
 if exists(select 1 from public.bank_accounts where profile_id=u and deleted_at is null and is_active
   and status in ('pending','manual_review')) then
  raise exception 'bank_review_active' using errcode='55000'; end if;
 if exists(select 1 from public.bank_accounts where profile_id=u and deleted_at is null and is_active
   and status not in ('rejected','expired') and lower(btrim(bank_name))=lower(btrim(p_bank)) and account_number=p_number) then
  raise exception 'bank_duplicate' using errcode='23505'; end if;
 if not exists(select 1 from storage.buckets where id='identity-documents' and not public) then
  raise exception 'private_storage_required'; end if;
 select * into o from storage.objects where bucket_id='identity-documents' and name=p_evidence for update;
 if not found or o.owner_id is distinct from u::text
  or coalesce((o.metadata->>'size')::bigint,0) not between 1 and 10485760
  or coalesce(o.metadata->>'mimetype','')<>'image/jpeg' then
  raise exception 'invalid_uploaded_file' using errcode='22023'; end if;
 insert into public.bank_accounts(id,profile_id,bank_code,bank_name,account_name,account_number,
  branch_name,account_type,currency_code,evidence_path,is_default,is_verified,is_active,status)
 values(p_id,u,'manual',btrim(p_bank),btrim(p_name),p_number,btrim(p_branch),p_type,'THB',p_evidence,false,false,true,'pending');
 insert into public.financial_verifications(bank_account_id,identity_type,profile_id,name_match_status,status)
 values(p_id,'personal',u,'pending','pending');
 return p_id;
end;
$$;
revoke all on function kaoid_private.submit_bank_r8c(uuid,text,text,text,text,text,text) from public,anon;
grant execute on function kaoid_private.submit_bank_r8c(uuid,text,text,text,text,text,text) to authenticated;
create or replace function public.submit_bank_r8c(
 p_id uuid,p_bank text,p_name text,p_number text,p_branch text,p_type text,p_evidence text
) returns uuid language sql security invoker set search_path='' as $$
 select kaoid_private.submit_bank_r8c(p_id,p_bank,p_name,p_number,p_branch,p_type,p_evidence);
$$;
revoke all on function public.submit_bank_r8c(uuid,text,text,text,text,text,text) from public,anon;
grant execute on function public.submit_bank_r8c(uuid,text,text,text,text,text,text) to authenticated;
-- No caller-supplied owner; never return an unmasked account number.
create or replace function kaoid_private.list_banks_r8c() returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); result jsonb;
begin
 if u is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
  or not exists(select 1 from public.profiles where id=u and account_status='active' and deleted_at is null) then
  raise exception 'authentication_required' using errcode='42501'; end if;
 select coalesce(jsonb_agg(jsonb_build_object(
  'id',b.id,'profile_id',b.profile_id,'bank_code',b.bank_code,'bank_name',b.bank_name,
  'account_name',b.account_name,'account_number','•••• '||right(b.account_number,4),
  'branch_name',b.branch_name,'account_type',b.account_type,'currency_code',b.currency_code,
  'status',case when b.status in ('rejected','expired') then b.status
    when f.status in ('rejected','expired') then f.status
    when b.is_verified and b.status='verified' and f.status='approved' and f.name_match_status='matched' then 'approved'
    when b.status in ('pending','manual_review') then b.status else 'unknown' end,
  'name_match_status',coalesce(f.name_match_status,'pending'),
  'is_verified',b.is_verified,'is_default',b.is_default,
  'verified_at',b.verified_at,'verified_by',b.verified_by,
  'evidence_path',b.evidence_path,'created_at',b.created_at,'updated_at',b.updated_at
 ) order by b.created_at desc,b.id), '[]'::jsonb) into result
 from public.bank_accounts b left join public.financial_verifications f on f.bank_account_id=b.id
 where b.profile_id=u and b.organization_id is null and b.is_active and b.deleted_at is null;
 return result;
end;
$$;
revoke all on function kaoid_private.list_banks_r8c() from public,anon;
grant execute on function kaoid_private.list_banks_r8c() to authenticated;
create or replace function public.list_banks_r8c() returns jsonb
language sql security invoker set search_path='' as $$select kaoid_private.list_banks_r8c();$$;
revoke all on function public.list_banks_r8c() from public,anon;
grant execute on function public.list_banks_r8c() to authenticated;
