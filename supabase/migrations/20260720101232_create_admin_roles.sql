-- ============================================================
-- Migration: create_admin_roles
-- Module    : Governance
-- Table     : admin_roles
-- Description:
-- Stores all administrator roles in the KaoSure Governance system.
-- ============================================================

-- ============================================================
-- TABLE
-- ============================================================

CREATE TABLE public.admin_roles (

    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    code VARCHAR(100) NOT NULL,

    description TEXT,

    is_system BOOLEAN NOT NULL DEFAULT FALSE,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_admin_roles_name
        UNIQUE (name),

    CONSTRAINT uq_admin_roles_code
        UNIQUE (code)

);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_admin_roles_is_active
ON public.admin_roles(is_active);

CREATE INDEX idx_admin_roles_is_system
ON public.admin_roles(is_system);

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE public.admin_roles IS
'Stores administrator roles used by the Governance RBAC system.';

COMMENT ON COLUMN public.admin_roles.name IS
'Display name of the administrator role.';

COMMENT ON COLUMN public.admin_roles.code IS
'Unique system code for the role.';

COMMENT ON COLUMN public.admin_roles.description IS
'Description of the administrator role.';

COMMENT ON COLUMN public.admin_roles.is_system IS
'Indicates whether this is a protected system role.';

COMMENT ON COLUMN public.admin_roles.is_active IS
'Indicates whether this role is active.';

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.admin_roles
ENABLE ROW LEVEL SECURITY;

-- RLS Policies will be added after Governance RBAC is completed.

-- ============================================================
-- TRIGGER
-- ============================================================

CREATE TRIGGER trg_admin_roles_updated_at
BEFORE UPDATE
ON public.admin_roles
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();