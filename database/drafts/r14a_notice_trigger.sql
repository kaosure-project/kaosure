create trigger kaoid_mfa_notice_r14a after insert or update of status or delete on auth.mfa_factors for each row execute function kaoid_private.mfa_notice_r14a();
