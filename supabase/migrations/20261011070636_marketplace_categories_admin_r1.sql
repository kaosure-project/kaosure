-- KaoSure Secondhand category management.
-- Admin authorization is backed by Kao ID's existing RBAC permission checker.

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

INSERT INTO public.permissions
  (category, resource, action, code, name, description, scope, sort_order,
   is_active, is_dangerous, is_immutable, is_deprecated)
VALUES
  ('Marketplace', 'categories', 'manage', 'marketplace.categories.manage',
   'Marketplace Categories Manage',
   'Create, update, order, and deactivate marketplace categories.',
   'global', 210, true, false, false, false)
ON CONFLICT (code) DO UPDATE
SET is_active = true,
    is_deprecated = false,
    updated_at = now();

INSERT INTO public.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM public.admin_roles r
CROSS JOIN public.permissions p
WHERE r.code IN ('admin', 'super_admin')
  AND r.is_active = true
  AND p.code = 'marketplace.categories.manage'
  AND p.is_active = true
  AND NOT EXISTS (
    SELECT 1
    FROM public.role_permissions rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

GRANT INSERT (name, slug, icon, sort_order, is_active)
  ON public.categories TO authenticated;
GRANT UPDATE (name, slug, icon, sort_order, is_active)
  ON public.categories TO authenticated;

DROP POLICY IF EXISTS marketplace_admin_read_all_categories
  ON public.categories;
CREATE POLICY marketplace_admin_read_all_categories
  ON public.categories FOR SELECT TO authenticated
  USING (
    is_active = true
    OR (SELECT public.has_permission('marketplace.categories.manage'))
  );

DROP POLICY IF EXISTS marketplace_admin_create_categories
  ON public.categories;
CREATE POLICY marketplace_admin_create_categories
  ON public.categories FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT public.has_permission('marketplace.categories.manage'))
  );

DROP POLICY IF EXISTS marketplace_admin_update_categories
  ON public.categories;
CREATE POLICY marketplace_admin_update_categories
  ON public.categories FOR UPDATE TO authenticated
  USING (
    (SELECT public.has_permission('marketplace.categories.manage'))
  )
  WITH CHECK (
    (SELECT public.has_permission('marketplace.categories.manage'))
  );
;
