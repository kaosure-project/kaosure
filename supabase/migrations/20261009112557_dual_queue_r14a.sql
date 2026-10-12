CREATE OR REPLACE FUNCTION kaoid_private.review_queue_before_r14a()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501';end if;
 return (select coalesce(jsonb_agg(q || jsonb_build_object('is_recovery',e.id is not null,'previous_name',d.full_name,'previous_number',d.document_number,'previous_paths',(select coalesce(jsonb_agg(f.file_path),'[]') from public.document_files f where f.document_id=e.previous_document)) order by ord),'[]')
 from jsonb_array_elements(kaoid_private.review_queue_base_r10e()) with ordinality a(q,ord)
 left join kaoid_private.recovery_evidence_r10e e on e.id=(q->>'id')::uuid
 left join public.identity_documents d on d.id=e.previous_document);
end $function$;

revoke all on function kaoid_private.review_queue_before_r14a() from public,anon,authenticated;
create or replace function kaoid_private.review_queue_r7c() returns jsonb language plpgsql security definer set search_path='' as $$ begin
 if not kaoid_private.can_review_r7c() then raise exception 'reviewer_required' using errcode='42501';end if;
 return (select coalesce(jsonb_agg(q || jsonb_build_object(
 'dual_review',(select dual_review from kaoid_private.security_policy_r14a where id),
 'first_reviewer',ar.requested_by,'first_decision',h.metadata->'approve','first_reason',ar.reason) order by ord),'[]'::jsonb)
 from jsonb_array_elements(kaoid_private.review_queue_before_r14a()) with ordinality a(q,ord)
 left join public.approval_requests ar on ar.resource_id=(q->>'id')::uuid and ar.resource in ('kaoid_review','kaoid_recovery') and ar.status='pending' and ar.expires_at>now()
 left join public.approval_histories h on h.approval_request_id=ar.id and h.event='request_created');
end $$;
;
