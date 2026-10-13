-- R38: category pages show subcategories, so guests and members need the
-- category tree. parent_id is structural, not private (get_listing_detail
-- already returns the parent's id and name); platform_id stays hidden.
grant select (parent_id) on public.categories to anon, authenticated;
