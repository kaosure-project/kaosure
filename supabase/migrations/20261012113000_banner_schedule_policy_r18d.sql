-- R18d: scheduled and expired banners are not readable before/after their window,
-- so upcoming campaigns cannot be discovered through the public API.
alter policy "Everyone can view active banners" on public.banners
  using (
    is_active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

notify pgrst, 'reload schema';
