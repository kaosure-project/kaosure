-- R26: signing out of a sub-app ends the Kao ID browser session too.
--
-- The app sends the member to Kao ID /logout?return_to=<app page>. Kao ID signs
-- out, then returns there only when the page belongs to an active registered
-- app: same origin as one of its OAuth redirect URIs, http(s), no query or
-- fragment. Anything else lands on the Kao ID home page, so /logout can't be
-- used as an open redirect. Signed-out visitors ask too, hence anon.

create or replace function public.kao_id_sign_out_return_ok(p_url text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    char_length(p_url) <= 2000
    and p_url ~ '^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[^?#[:space:]]*)?$'
    and exists (
      select 1
        from kaoid_private.app_clients_r18 a
        join auth.oauth_clients c on c.id = a.oauth_client_id and c.deleted_at is null
       cross join lateral regexp_split_to_table(coalesce(c.redirect_uris, ''), '\s*,\s*') as r(uri)
       where a.status = 'active'
         and lower(substring(r.uri from '^(https?://[^/?#]+)')) = lower(substring(p_url from '^(https?://[^/?#]+)'))),
    false);
$$;

revoke all on function public.kao_id_sign_out_return_ok(text) from public, anon, authenticated;
grant execute on function public.kao_id_sign_out_return_ok(text) to anon, authenticated;
