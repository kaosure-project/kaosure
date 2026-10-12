-- RLS policies still restrict every row to its owner.
grant select,insert,delete on public.favorites, public.followers to authenticated;
