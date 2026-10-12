create or replace function kaoid_private.review_fingerprint_r14a(p_id uuid) returns text language sql stable security definer set search_path='' as $$
 select encode(sha256(convert_to(jsonb_build_object(
 'request',(select to_jsonb(r) from public.verification_requests r where r.id=p_id),
 'document',(select to_jsonb(d) from public.identity_documents d join public.verification_requests r on r.document_id=d.id where r.id=p_id),
 'files',(select jsonb_agg(to_jsonb(f) order by f.id) from public.document_files f join public.verification_requests r on r.document_id=f.document_id where r.id=p_id),
 'bank_check',(select to_jsonb(v) from public.financial_verifications v where v.id=p_id),
 'bank',(select to_jsonb(b) from public.bank_accounts b join public.financial_verifications v on v.bank_account_id=b.id where v.id=p_id),
 'previous_document',(select to_jsonb(d) from public.identity_documents d join kaoid_private.recovery_evidence_r10e e on e.previous_document=d.id where e.id=p_id),
 'previous_files',(select jsonb_agg(to_jsonb(f) order by f.id) from public.document_files f join kaoid_private.recovery_evidence_r10e e on e.previous_document=f.document_id where e.id=p_id),
 'objects',(select jsonb_agg(jsonb_build_object('id',o.id,'name',o.name,'updated_at',o.updated_at,'metadata',o.metadata) order by o.name) from storage.objects o where o.bucket_id='identity-documents' and (o.name in (select f.file_path from public.document_files f join public.verification_requests r on r.document_id=f.document_id where r.id=p_id) or o.name in (select f.file_path from public.document_files f join kaoid_private.recovery_evidence_r10e e on e.previous_document=f.document_id where e.id=p_id) or o.name in (select b.evidence_path from public.bank_accounts b join public.financial_verifications v on v.bank_account_id=b.id where v.id=p_id))),
 'recovery',(select to_jsonb(e) from kaoid_private.recovery_evidence_r10e e where e.id=p_id)
 )::text,'UTF8')),'hex'); $$;
;
