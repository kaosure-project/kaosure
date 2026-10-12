alter function public.update_updated_at_column() set search_path='';
alter function public.set_updated_at() set search_path='';
alter function public.update_platforms_updated_at() set search_path='';
alter function public.generate_kao_id() set search_path='';
alter function public.is_admin() set search_path='';
revoke execute on function public.handle_new_user(),public.handle_auth_user_updated() from public,anon,authenticated;;
