-- ============================================================
-- Migration : create_role_permissions
-- Module    : Governance
-- Table     : role_permissions
-- Description:
-- Maps administrator roles to permissions.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.role_permissions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    role_id UUID NOT NULL,

    permission_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_role_permissions_role
        FOREIGN KEY (role_id)
        REFERENCES public.admin_roles(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_role_permissions_permission
        FOREIGN KEY (permission_id)
        REFERENCES public.permissions(id)
        ON DELETE CASCADE,

    CONSTRAINT uq_role_permissions
        UNIQUE (
            role_id,
            permission_id
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_role_permissions_role
ON public.role_permissions(role_id);

CREATE INDEX idx_role_permissions_permission
ON public.role_permissions(permission_id);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.role_permissions IS
'Maps administrator roles to permissions.';

COMMENT ON COLUMN public.role_permissions.role_id IS
'Reference to the administrator role.';

COMMENT ON COLUMN public.role_permissions.permission_id IS
'Reference to the permission granted to the role.';

COMMENT ON COLUMN public.role_permissions.created_at IS
'Record creation timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.role_permissions
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the RBAC infrastructure
-- is fully implemented.