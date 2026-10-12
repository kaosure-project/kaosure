-- R20e: keep products.favorite_count in step with public.favorites.
-- Members write favorites directly (RLS) but cannot update products, so the
-- counter is maintained by a security definer trigger and recounted once here.

create or replace function kaoid_private.sync_product_favorite_count_r20e()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op in ('DELETE', 'UPDATE') then
    update public.products
       set favorite_count = greatest(favorite_count - 1, 0)
     where id = old.product_id;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    update public.products
       set favorite_count = favorite_count + 1
     where id = new.product_id;
  end if;
  return null;
end $$;

revoke all on function kaoid_private.sync_product_favorite_count_r20e() from public, anon, authenticated;

drop trigger if exists favorites_count_insert_delete_r20e on public.favorites;
create trigger favorites_count_insert_delete_r20e
  after insert or delete on public.favorites
  for each row execute function kaoid_private.sync_product_favorite_count_r20e();

drop trigger if exists favorites_count_move_r20e on public.favorites;
create trigger favorites_count_move_r20e
  after update of product_id on public.favorites
  for each row when (old.product_id is distinct from new.product_id)
  execute function kaoid_private.sync_product_favorite_count_r20e();

-- One-time recount so existing rows match the favorites table.
update public.products p
   set favorite_count = coalesce(c.n, 0)
  from public.products p2
  left join (select product_id, count(*)::int n from public.favorites group by product_id) c on c.product_id = p2.id
 where p.id = p2.id
   and p.favorite_count is distinct from coalesce(c.n, 0);
