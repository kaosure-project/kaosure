-- R19e: Secondhand shows its own market profile (secondhand.member_profiles), so
-- its tokens no longer read Kao ID's profiles table. Name, photo and locale the
-- app needs from Kao ID come from kao_id_claims_r18.

update kaoid_private.app_clients_r18
   set allowed_tables = array_remove(allowed_tables, 'public.profiles'),
       updated_at = now()
 where app_code = 'secondhand_web';
