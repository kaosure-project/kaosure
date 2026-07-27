-- ==========================================
-- KaoSure Database V1.0
-- Table : review_images
-- ==========================================

CREATE TABLE public.review_images (

    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    review_id uuid NOT NULL
        REFERENCES public.reviews(id)
        ON DELETE CASCADE,

    image_url text NOT NULL,

    image_order integer NOT NULL DEFAULT 1,

    created_at timestamptz NOT NULL DEFAULT now()

);

-- ==========================================
-- INDEX
-- ==========================================

CREATE INDEX idx_review_images_review
ON public.review_images(review_id);

CREATE INDEX idx_review_images_order
ON public.review_images(image_order);

-- ==========================================
-- ROW LEVEL SECURITY
-- ==========================================

ALTER TABLE public.review_images
ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- POLICY : SELECT
-- ==========================================

CREATE POLICY "Users can view review images"
ON public.review_images
FOR SELECT
TO authenticated
USING (true);

-- ==========================================
-- POLICY : INSERT
-- ==========================================

CREATE POLICY "Users can upload review images"
ON public.review_images
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.reviews
        WHERE reviews.id = review_images.review_id
        AND reviews.reviewer_id = auth.uid()
    )
);

-- ==========================================
-- POLICY : DELETE
-- ==========================================

CREATE POLICY "Users can delete own review images"
ON public.review_images
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.reviews
        WHERE reviews.id = review_images.review_id
        AND reviews.reviewer_id = auth.uid()
    )
);

-- ==========================================
-- END OF FILE
-- ==========================================