CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS opportunities (
    id SERIAL PRIMARY KEY,
    status VARCHAR(50),
    account_id INTEGER REFERENCES accounts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS opportunity_items (
    id SERIAL PRIMARY KEY,
    opportunityid INTEGER REFERENCES opportunities(id),
    description TEXT,
    amount DECIMAL(10, 2),
    year INTEGER
);

CREATE TABLE IF NOT EXISTS support_cases (
    id SERIAL PRIMARY KEY,
    subject TEXT NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL,
    severity VARCHAR(20) CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    account_id INTEGER NOT NULL REFERENCES accounts(id)
);

INSERT INTO accounts (name) VALUES
('Acme Corp'),
('Globex Inc'),
('Soylent Corp')
ON CONFLICT (name)
DO NOTHING;

INSERT INTO opportunities (status, account_id) VALUES
('active', 1),
('active', 2),
('closed', 3)
ON CONFLICT (account_id)
DO NOTHING;

INSERT INTO opportunity_items (opportunityid, description, amount, year) VALUES
(1, 'Subscription renewal - Tier A', 15000.00, 2025),
(1, 'Upsell - Cloud package', 5000.00, 2025),
(2, 'Enterprise license renewal', 25000.00, 2025),
(3, 'Legacy support', 8000.00, 2024)
ON CONFLICT (opporunityid)
DO NOTHING;

INSERT INTO support_cases (subject, description, status, severity, account_id) VALUES
('Login failure', 'Customer unable to log in with correct credentials.', 'open', 'High', 1),
('Slow dashboard', 'Performance issues loading analytics dashboard.', 'in progress', 'Critical', 1),
('Payment not processed', 'Invoice payment failed on retry.', 'open', 'Medium', 2),
('Email delivery issue', 'Confirmation emails not reaching clients.', 'closed', 'High', 2),
('API outage', 'Integration API returns 500 error intermittently.', 'open', 'Critical', 3),
('Feature request: Dark mode', 'Request to implement dark mode UI.', 'closed', 'Low', 1)
ON CONFLICT (account_id)
DO NOTHING;
