-- Business registration RPCs are SECURITY DEFINER and meant for signed-in
-- members only. They were created without revoking the default PUBLIC execute
-- grant, which left them callable by anon. Explicit grants to authenticated
-- already exist and are kept.

revoke execute on function public.create_business_registration(text, text, text, text, text) from public, anon;
revoke execute on function public.get_current_business_registration() from public, anon;
revoke execute on function public.get_business_registration(uuid) from public, anon;
revoke execute on function public.update_business_registration(uuid, text, text, text, text, text) from public, anon;
revoke execute on function public.attach_business_registration_document(uuid, uuid) from public, anon;
revoke execute on function public.submit_business_registration(uuid) from public, anon;
revoke execute on function public.cancel_business_registration(uuid) from public, anon;
revoke execute on function public.refresh_business_registration_status(uuid) from public, anon;

grant execute on function public.create_business_registration(text, text, text, text, text) to authenticated;
grant execute on function public.get_current_business_registration() to authenticated;
grant execute on function public.get_business_registration(uuid) to authenticated;
grant execute on function public.update_business_registration(uuid, text, text, text, text, text) to authenticated;
grant execute on function public.attach_business_registration_document(uuid, uuid) to authenticated;
grant execute on function public.submit_business_registration(uuid) to authenticated;
grant execute on function public.cancel_business_registration(uuid) to authenticated;
grant execute on function public.refresh_business_registration_status(uuid) to authenticated;
