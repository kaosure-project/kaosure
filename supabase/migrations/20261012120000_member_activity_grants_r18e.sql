-- R18e: members can use their own viewing history and read their own recommendations.
-- The existing owner policies (profile_id = auth.uid()) and the account closure policy
-- still limit rows; recommendation internals stay private.
grant select (id, profile_id, product_id, viewed_at, view_count),
      insert (profile_id, product_id, viewed_at, view_count),
      update (viewed_at, view_count, updated_at)
  on public.recently_viewed to authenticated;

grant select (id, profile_id, product_id, score, expires_at)
  on public.recommendation_scores to authenticated;

notify pgrst, 'reload schema';
