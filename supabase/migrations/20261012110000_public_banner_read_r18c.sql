-- R18c: guests and members can read public banner fields. Rows stay limited to
-- active banners by the existing "Everyone can view active banners" policy;
-- created_by (staff identity) and audit timestamps stay private.
grant select (id, title, description, image_url, mobile_image_url, link_url, button_text, banner_type,
  position, display_order, is_active, starts_at, ends_at)
  on public.banners to anon, authenticated;

notify pgrst, 'reload schema';
