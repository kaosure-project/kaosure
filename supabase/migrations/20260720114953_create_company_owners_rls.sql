-- ============================================================
-- Migration : create_company_owners_rls
-- Module    : Governance
-- Table     : company_owners
-- ============================================================

ALTER TABLE public.company_owners
ENABLE ROW LEVEL SECURITY;

---------------------------------------------------------------
-- SELECT
---------------------------------------------------------------

CREATE POLICY company_owners_select
ON public.company_owners
FOR SELECT
TO authenticated
USING (
    public.is_company_owner()
);

---------------------------------------------------------------
-- INSERT
---------------------------------------------------------------

CREATE POLICY company_owners_insert
ON public.company_owners
FOR INSERT
TO authenticated
WITH CHECK (
    FALSE
);

---------------------------------------------------------------
-- UPDATE
---------------------------------------------------------------

CREATE POLICY company_owners_update
ON public.company_owners
FOR UPDATE
TO authenticated
USING (
    public.is_company_owner()
)
WITH CHECK (
    public.is_company_owner()
);

---------------------------------------------------------------
-- DELETE
---------------------------------------------------------------

CREATE POLICY company_owners_delete
ON public.company_owners
FOR DELETE
TO authenticated
USING (
    FALSE
);