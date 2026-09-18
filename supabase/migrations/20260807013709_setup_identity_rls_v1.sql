-- ==========================================================
-- Kao Ecosystem
-- Kao ID
-- Enable Row Level Security
-- ==========================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.oauth_clients ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.oauth_tokens ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.identity_documents ENABLE ROW LEVEL SECURITY;