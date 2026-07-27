-- ============================================================
-- Migration : create_permissions
-- Module    : Governance
-- Table     : permissions
-- Description:
-- Stores all permissions used by the Enterprise RBAC system.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.permissions (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    category VARCHAR(100) NOT NULL,

    resource VARCHAR(100) NOT NULL,

    action VARCHAR(100) NOT NULL,

    code VARCHAR(200) NOT NULL,

    name VARCHAR(150) NOT NULL,

    description TEXT,

    scope VARCHAR(30) NOT NULL DEFAULT 'global',

    sort_order INTEGER NOT NULL DEFAULT 0,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    is_dangerous BOOLEAN NOT NULL DEFAULT FALSE,

    is_immutable BOOLEAN NOT NULL DEFAULT FALSE,

    is_deprecated BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_permissions_code
        UNIQUE (code),

    CONSTRAINT chk_permissions_scope
        CHECK (
            scope IN (
                'global',
                'own',
                'custom'
            )
        )

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_permissions_category
ON public.permissions(category);

CREATE INDEX idx_permissions_resource
ON public.permissions(resource);

CREATE INDEX idx_permissions_action
ON public.permissions(action);

CREATE INDEX idx_permissions_scope
ON public.permissions(scope);

CREATE INDEX idx_permissions_category_resource
ON public.permissions(category, resource);

CREATE INDEX idx_permissions_resource_action
ON public.permissions(resource, action);

CREATE INDEX idx_permissions_is_active
ON public.permissions(is_active);

CREATE INDEX idx_permissions_is_dangerous
ON public.permissions(is_dangerous);

CREATE INDEX idx_permissions_is_immutable
ON public.permissions(is_immutable);

CREATE INDEX idx_permissions_is_deprecated
ON public.permissions(is_deprecated);

CREATE INDEX idx_permissions_sort_order
ON public.permissions(sort_order);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.permissions IS
'Stores all permissions used by the Enterprise RBAC authorization system.';

COMMENT ON COLUMN public.permissions.category IS
'Top-level business domain such as Kao ID, Marketplace, Finance, Governance or Future Apps.';

COMMENT ON COLUMN public.permissions.resource IS
'Protected business resource.';

COMMENT ON COLUMN public.permissions.action IS
'Operation that can be performed on the resource.';

COMMENT ON COLUMN public.permissions.code IS
'Globally unique permission code such as users.view or wallet.withdraw.approve.';

COMMENT ON COLUMN public.permissions.name IS
'Human-readable permission name.';

COMMENT ON COLUMN public.permissions.description IS
'Detailed permission description.';

COMMENT ON COLUMN public.permissions.scope IS
'Default authorization scope (global, own or custom).';

COMMENT ON COLUMN public.permissions.sort_order IS
'Display order used in administration interfaces.';

COMMENT ON COLUMN public.permissions.is_active IS
'Whether this permission can currently be assigned.';

COMMENT ON COLUMN public.permissions.is_dangerous IS
'Indicates a high-risk permission requiring additional approval.';

COMMENT ON COLUMN public.permissions.is_immutable IS
'Indicates a built-in system permission that cannot be modified or deleted.';

COMMENT ON COLUMN public.permissions.is_deprecated IS
'Indicates a legacy permission retained for backward compatibility.';

COMMENT ON COLUMN public.permissions.created_at IS
'Record creation timestamp.';

COMMENT ON COLUMN public.permissions.updated_at IS
'Record last update timestamp.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.permissions
ENABLE ROW LEVEL SECURITY;

-- RLS policies will be created after the RBAC infrastructure
-- (roles, assignments, permission checks) is fully implemented.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_permissions_updated_at
BEFORE UPDATE
ON public.permissions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();