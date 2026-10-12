-- Service-role-only wrappers need schema resolution; table access remains denied to clients.
grant usage on schema kaoid_private to service_role;
