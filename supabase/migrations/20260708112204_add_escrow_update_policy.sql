CREATE POLICY "System can update escrow"
ON public.escrow_transactions
FOR UPDATE
TO authenticated
USING (true);