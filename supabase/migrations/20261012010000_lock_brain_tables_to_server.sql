-- Kao Brain organizational memory and Pudtan memory are read and written only
-- by the Brain API through its server-side DATABASE_URL. Client roles used by
-- the Supabase Data API (anon, authenticated) get no table access.
--
-- RLS is enabled without policies, so any role that is not the table owner and
-- does not have BYPASSRLS sees no rows. The Brain API must keep connecting as
-- the table owner (postgres) or another BYPASSRLS role.

do $lock$
declare
  v_table text;
begin
  foreach v_table in array array[
    'brain_projects',
    'brain_contexts',
    'brain_decisions',
    'brain_approvals',
    'brain_tasks',
    'brain_knowledge',
    'brain_ideas',
    'brain_visions',
    'brain_business_rules',
    'brain_architectures',
    'brain_events',
    'brain_changes',
    'brain_document_references',
    'brain_memory_embeddings',
    'pudtan_memory'
  ]
  loop
    if to_regclass(format('public.%I', v_table)) is not null then
      execute format('alter table public.%I enable row level security', v_table);
      execute format('revoke all on table public.%I from anon, authenticated', v_table);
    end if;
  end loop;
end;
$lock$;
