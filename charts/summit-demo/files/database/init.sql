CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
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

INSERT INTO accounts (id, name) VALUES
(1, 'Acme Corp'),
(2, 'Globex Inc'),
(3, 'Soylent Corp')
ON CONFLICT (id)
DO NOTHING;

INSERT INTO opportunities (id, status, account_id) VALUES
(1, 'active', 1),
(2, 'active', 2),
(3, 'closed', 3)
ON CONFLICT (id)
DO NOTHING;

INSERT INTO opportunity_items (id, opportunityid, description, amount, year) VALUES
(1, 1, 'Subscription renewal - Tier A', 15000.00, 2025),
(2, 1, 'Upsell - Cloud package', 5000.00, 2025),
(3, 2, 'Enterprise license renewal', 25000.00, 2025),
(4, 3, 'Legacy support', 8000.00, 2024)
ON CONFLICT (id)
DO NOTHING;

INSERT INTO support_cases (id, subject, description, status, severity, account_id) VALUES
(1, 'Login failure', 'Customer unable to log in with correct credentials.', 'open', 'High', 1),
(2, 'Slow dashboard', 'Performance issues loading analytics dashboard.', 'in progress', 'Critical', 1),
(3, 'Payment not processed', 'Invoice payment failed on retry.', 'open', 'Medium', 2),
(4, 'Email delivery issue', 'Confirmation emails not reaching clients.', 'closed', 'High', 2),
(5, 'API outage', 'Integration API returns 500 error intermittently.', 'open', 'Critical', 3),
(6, 'Feature request: Dark mode', 'Request to implement dark mode UI.', 'closed', 'Low', 1)
ON CONFLICT (id)
DO NOTHING;
