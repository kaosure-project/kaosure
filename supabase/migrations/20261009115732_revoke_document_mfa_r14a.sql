CREATE OR REPLACE FUNCTION kaoid_private.revoke_document_r11a(p_document uuid, p_reason text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare d public.identity_documents%rowtype;
begin
 perform kaoid_private.require_fresh_mfa_r14a();
 if not kaoid_private.can_read_members_r9a() then raise exception 'owner_required' using errcode='42501';end if;
 if length(btrim(coalesce(p_reason,''))) not between 3 and 1000 then raise exception 'reason_required' using errcode='22023';end if;
 select * into d from public.identity_documents where id=p_document;
 if not found or d.owner_id=auth.uid() or d.deleted_at is not null then raise exception 'not_authorized' using errcode='42501';end if;
 perform 1 from public.profiles where id=d.owner_id for update;
 select * into d from public.identity_documents where id=p_document for update;
 if d.status='revoked' then return true;end if;
 if d.status not in ('approved','expired') then raise exception 'approved_document_required';end if;
 update public.identity_documents set status='revoked',rejected_reason=btrim(p_reason),updated_at=now() where id=p_document;
 perform kaoid_private.sync_identity_r11a(d.owner_id);
 insert into public.activity_logs(profile_id,action,target_table,target_id,description)
 values(auth.uid(),'kyc.revoke','identity_documents',p_document,jsonb_build_object('owner_id',d.owner_id,'previous',d.status,'reason',btrim(p_reason))::text);
 perform kaoid_private.emit_notice_r10a(d.owner_id,'kyc-revoked:'||p_document,'kyc_revoked',p_document);
 return true;
end $function$

;
;
