-- ============================================================
-- Governance Permission Seed
-- ============================================================

INSERT INTO public.permissions
(
    category,
    resource,
    action,
    code,
    name,
    description,
    scope,
    sort_order,
    is_active,
    is_dangerous,
    is_immutable,
    is_deprecated
)
VALUES

-- ============================================================
-- Dashboard
-- ============================================================

('Admin','dashboard','view','admin.dashboard.view','Dashboard View','View admin dashboard','global',10,true,false,true,false),

-- ============================================================
-- Company Owner
-- ============================================================

('Admin','owners','view','admin.owners.view','Owner View','View company owners','global',20,false,false,true,false),
('Admin','owners','update','admin.owners.update','Owner Update','Update company owners','global',21,true,true,true,false),

-- ============================================================
-- Roles
-- ============================================================

('Admin','roles','view','admin.roles.view','Role View','View admin roles','global',30,true,false,true,false),
('Admin','roles','create','admin.roles.create','Role Create','Create admin roles','global',31,true,true,true,false),
('Admin','roles','update','admin.roles.update','Role Update','Update admin roles','global',32,true,true,true,false),
('Admin','roles','delete','admin.roles.delete','Role Delete','Delete admin roles','global',33,true,true,true,false),

-- ============================================================
-- Permissions
-- ============================================================

('Admin','permissions','view','admin.permissions.view','Permission View','View permissions','global',40,true,false,true,false),

-- ============================================================
-- Assignments
-- ============================================================

('Admin','assignments','view','admin.assignments.view','Assignment View','View assignments','global',50,true,false,true,false),
('Admin','assignments','create','admin.assignments.create','Assignment Create','Create assignments','global',51,true,true,true,false),
('Admin','assignments','update','admin.assignments.update','Assignment Update','Update assignments','global',52,true,true,true,false),
('Admin','assignments','delete','admin.assignments.delete','Assignment Delete','Delete assignments','global',53,true,true,true,false),

-- ============================================================
-- Sessions
-- ============================================================

('Admin','sessions','view','admin.sessions.view','Session View','View admin sessions','global',60,true,false,true,false),

-- ============================================================
-- Approval Policy
-- ============================================================

('Approval','policy','view','approval.policy.view','Approval Policy View','View approval policies','global',70,true,false,true,false),
('Approval','policy','create','approval.policy.create','Approval Policy Create','Create approval policies','global',71,true,true,true,false),
('Approval','policy','update','approval.policy.update','Approval Policy Update','Update approval policies','global',72,true,true,true,false),

-- ============================================================
-- Approval Request
-- ============================================================

('Approval','request','view','approval.request.view','Approval Request View','View approval requests','global',80,true,false,true,false),
('Approval','request','approve','approval.request.approve','Approval Request Approve','Approve requests','global',81,true,true,true,false),
('Approval','request','reject','approval.request.reject','Approval Request Reject','Reject requests','global',82,true,true,true,false),

-- ============================================================
-- Approval History
-- ============================================================

('Approval','history','view','approval.history.view','Approval History View','View approval history','global',90,true,false,true,false)

ON CONFLICT (code)
DO NOTHING;