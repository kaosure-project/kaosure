-- ==========================================
-- KaoSure Database V1.0
-- Fix: escrow update policy
-- ==========================================

DROP POLICY IF EXISTS "System can update escrow"
ON public.escrow_transactions;

CREATE POLICY "System can update escrow"
ON public.escrow_transactions
FOR UPDATE
TO authenticated
USING (true);