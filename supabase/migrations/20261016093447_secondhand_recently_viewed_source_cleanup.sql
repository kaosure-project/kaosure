DO $$
DECLARE src_count bigint;
BEGIN
 SELECT count(*) INTO src_count FROM public.recently_viewed;
 IF src_count <> 2 THEN
   RAISE EXCEPTION 'Expected 2 source recently_viewed rows; found %; refusing table drop', src_count;
 END IF;
END $$;
DROP TABLE public.recently_viewed;;