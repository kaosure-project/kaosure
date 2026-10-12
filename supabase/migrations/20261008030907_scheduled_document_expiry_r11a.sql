create extension if not exists pg_cron;
select cron.schedule('kaoid-document-expiry-r11a','5 * * * *','select kaoid_private.expire_documents_r11a();');
;
