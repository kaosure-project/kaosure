DROP POLICY IF EXISTS owner_delegations_select
ON public.owner_delegations;

CREATE POLICY owner_delegations_select
ON public.owner_delegations
FOR SELECT
TO authenticated
USING (

    public.is_company_owner()

    OR (

        delegate_profile_id = auth.uid()

        AND revoked_at IS NULL

        AND starts_at <= NOW()

        AND (
            expires_at IS NULL
            OR expires_at >= NOW()
        )

    )

);