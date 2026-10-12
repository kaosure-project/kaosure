CREATE OR REPLACE FUNCTION kaoid_private.document_health_r11a(p_profile uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare target uuid:=coalesce(p_profile,auth.uid());
begin
 if not kaoid_private.account_active_r9f() or (target<>auth.uid() and not kaoid_private.can_read_members_r9a()) then raise exception 'not_authorized' using errcode='42501';end if;
 return jsonb_build_object('eligible',kaoid_private.valid_identity_r11a(target),
 'documents',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (
 select d.id,d.document_type,case when d.status='approved' and d.expiry_date<current_date then 'expired' else d.status end status,
 d.expiry_date,d.created_at,d.rejected_reason from public.identity_documents d where d.owner_id=target and d.deleted_at is null order by d.created_at desc,d.id desc limit 100)x),
 'history',(select coalesce(jsonb_agg(to_jsonb(x)),'[]') from (select a.id,a.action,a.created_at,a.profile_id as actor_id,a.actor_name_at_event,a.actor_roles_at_event,(select account_code from kaoid_private.account_refs_r10c where profile_id=a.profile_id) as actor_code,a.description
 from public.activity_logs a where a.action in ('kyc.revoke','kyc.expire') and a.target_id in (select id from public.identity_documents where owner_id=target)
 order by a.created_at desc,a.id desc limit 100)x));
end $function$
;;
