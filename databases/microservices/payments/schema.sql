-- =============================================================================
-- NELO - Payments Service Database
-- =============================================================================
-- Base de données: nelo_payments
-- Service: payment-service (Fastify / Node.js)
-- Responsabilité: Wallets, transactions, intégration paiements, payouts
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TYPES ENUM
-- =============================================================================

CREATE TYPE payment_method AS ENUM (
    'wallet',
    'mobile_money',
    'card',
    'cash'
);

CREATE TYPE transaction_type AS ENUM (
    'topup',
    'payment',
    'refund',
    'transfer',
    'withdrawal',
    'cashback',
    'commission'
);

CREATE TYPE transaction_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled'
);

-- =============================================================================
-- FONCTIONS UTILITAIRES
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_reference(prefix TEXT, length INT DEFAULT 8)
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := prefix || '-';
    i INT;
BEGIN
    FOR i IN 1..length LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TABLE: wallets
-- =============================================================================

CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,                   -- Référence externe (auth.users)

    -- Soldes
    balance INTEGER NOT NULL DEFAULT 0,
    pending_balance INTEGER DEFAULT 0,
    reserved_balance INTEGER DEFAULT 0,

    -- Limites
    daily_limit INTEGER DEFAULT 500000,
    monthly_limit INTEGER DEFAULT 5000000,
    transaction_limit INTEGER DEFAULT 200000,

    -- Stats
    daily_spent INTEGER DEFAULT 0,
    monthly_spent INTEGER DEFAULT 0,
    last_reset_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Statut
    is_active BOOLEAN DEFAULT true,
    is_frozen BOOLEAN DEFAULT false,
    frozen_reason TEXT,
    frozen_at TIMESTAMPTZ,

    -- Sécurité
    pin_hash VARCHAR(255),
    pin_attempts INTEGER DEFAULT 0,
    pin_locked_until TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT check_positive_balance CHECK (balance >= 0)
);

CREATE INDEX idx_wallets_user ON wallets(user_id);
CREATE INDEX idx_wallets_active ON wallets(is_active) WHERE is_active = true;

CREATE TRIGGER update_wallets_updated_at
    BEFORE UPDATE ON wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: transactions
-- =============================================================================

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('TXN', 12),

    wallet_id UUID NOT NULL REFERENCES wallets(id),
    user_id UUID NOT NULL,

    type transaction_type NOT NULL,
    direction VARCHAR(10) NOT NULL,

    amount INTEGER NOT NULL,
    fee INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,

    payment_method payment_method,
    provider VARCHAR(50),

    order_id UUID,                                  -- Référence externe (orders.orders)
    delivery_id UUID,                               -- Référence externe (deliveries.deliveries)
    external_reference VARCHAR(100),
    external_transaction_id VARCHAR(100),

    sender_wallet_id UUID REFERENCES wallets(id),
    recipient_wallet_id UUID REFERENCES wallets(id),
    recipient_phone VARCHAR(20),

    status transaction_status NOT NULL DEFAULT 'pending',
    status_message TEXT,
    failure_reason TEXT,
    failure_code VARCHAR(50),

    initiated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    reversed_at TIMESTAMPTZ,

    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    device_id VARCHAR(255),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_reference ON transactions(reference);
CREATE INDEX idx_transactions_external ON transactions(external_reference);
CREATE INDEX idx_transactions_order ON transactions(order_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: payment_methods
-- =============================================================================

CREATE TABLE payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    wallet_id UUID REFERENCES wallets(id),

    type payment_method NOT NULL,
    provider VARCHAR(50) NOT NULL,

    phone_number VARCHAR(20),
    card_last_four CHAR(4),
    card_brand VARCHAR(20),
    card_expiry_month SMALLINT,
    card_expiry_year SMALLINT,

    provider_token VARCHAR(255),
    provider_customer_id VARCHAR(100),

    display_name VARCHAR(100),
    is_default BOOLEAN DEFAULT false,

    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_methods_user ON payment_methods(user_id);
CREATE INDEX idx_payment_methods_wallet ON payment_methods(wallet_id);
CREATE INDEX idx_payment_methods_default ON payment_methods(user_id, is_default) WHERE is_default = true;

CREATE TRIGGER update_payment_methods_updated_at
    BEFORE UPDATE ON payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: topup_requests
-- =============================================================================

CREATE TABLE topup_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('TOP', 12),

    wallet_id UUID NOT NULL REFERENCES wallets(id),
    user_id UUID NOT NULL,

    amount INTEGER NOT NULL,
    fee INTEGER DEFAULT 0,
    total_amount INTEGER NOT NULL,

    payment_method payment_method NOT NULL,
    provider VARCHAR(50) NOT NULL,
    payment_method_id UUID REFERENCES payment_methods(id),

    provider_reference VARCHAR(100),
    provider_transaction_id VARCHAR(100),
    checkout_url TEXT,

    status VARCHAR(20) DEFAULT 'pending',
    failure_reason TEXT,

    callback_received_at TIMESTAMPTZ,
    callback_data JSONB,

    expires_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_topup_wallet ON topup_requests(wallet_id);
CREATE INDEX idx_topup_reference ON topup_requests(reference);
CREATE INDEX idx_topup_provider_ref ON topup_requests(provider_reference);
CREATE INDEX idx_topup_status ON topup_requests(status);

CREATE TRIGGER update_topup_requests_updated_at
    BEFORE UPDATE ON topup_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: order_payments
-- =============================================================================

CREATE TABLE order_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('PAY', 12),

    order_id UUID NOT NULL,                         -- Référence externe (orders.orders)
    user_id UUID NOT NULL,
    wallet_id UUID REFERENCES wallets(id),

    subtotal INTEGER NOT NULL,
    delivery_fee INTEGER NOT NULL,
    service_fee INTEGER DEFAULT 0,
    discount_amount INTEGER DEFAULT 0,
    tip_amount INTEGER DEFAULT 0,
    total_amount INTEGER NOT NULL,

    payment_method payment_method NOT NULL,
    provider VARCHAR(50),
    payment_method_id UUID REFERENCES payment_methods(id),

    provider_reference VARCHAR(100),
    provider_transaction_id VARCHAR(100),

    status VARCHAR(20) DEFAULT 'pending',
    failure_reason TEXT,

    cash_collected INTEGER,
    cash_collected_at TIMESTAMPTZ,
    collected_by UUID,                              -- Référence externe (deliveries.drivers)

    refund_amount INTEGER,
    refund_reason TEXT,
    refunded_at TIMESTAMPTZ,
    refund_transaction_id UUID REFERENCES transactions(id),

    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_payments_order ON order_payments(order_id);
CREATE INDEX idx_order_payments_user ON order_payments(user_id);
CREATE INDEX idx_order_payments_reference ON order_payments(reference);
CREATE INDEX idx_order_payments_status ON order_payments(status);

CREATE TRIGGER update_order_payments_updated_at
    BEFORE UPDATE ON order_payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: payouts
-- =============================================================================

CREATE TABLE payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('OUT', 12),

    recipient_type VARCHAR(20) NOT NULL,
    recipient_id UUID NOT NULL,                     -- Référence externe (orders.providers ou deliveries.drivers)
    recipient_wallet_id UUID REFERENCES wallets(id),

    gross_amount INTEGER NOT NULL,
    commission_amount INTEGER DEFAULT 0,
    fee_amount INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,

    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    orders_count INTEGER DEFAULT 0,
    deliveries_count INTEGER DEFAULT 0,

    payout_method VARCHAR(50) NOT NULL,
    recipient_phone VARCHAR(20),
    bank_account_id UUID,

    provider VARCHAR(50),
    provider_reference VARCHAR(100),
    provider_transaction_id VARCHAR(100),

    status VARCHAR(20) DEFAULT 'pending',
    failure_reason TEXT,

    scheduled_for TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    approved_by UUID,
    approved_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payouts_recipient ON payouts(recipient_type, recipient_id);
CREATE INDEX idx_payouts_reference ON payouts(reference);
CREATE INDEX idx_payouts_status ON payouts(status);
CREATE INDEX idx_payouts_scheduled ON payouts(scheduled_for) WHERE status = 'pending';

CREATE TRIGGER update_payouts_updated_at
    BEFORE UPDATE ON payouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: payout_items
-- =============================================================================

CREATE TABLE payout_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payout_id UUID NOT NULL REFERENCES payouts(id) ON DELETE CASCADE,

    order_id UUID,
    delivery_id UUID,
    transaction_id UUID REFERENCES transactions(id),

    type VARCHAR(20) NOT NULL,

    gross_amount INTEGER NOT NULL,
    commission_amount INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,

    description TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payout_items_payout ON payout_items(payout_id);
CREATE INDEX idx_payout_items_order ON payout_items(order_id);

-- =============================================================================
-- TABLE: bank_accounts
-- =============================================================================

CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,

    bank_name VARCHAR(100) NOT NULL,
    bank_code VARCHAR(20),
    branch_code VARCHAR(20),

    account_number VARCHAR(50) NOT NULL,
    account_name VARCHAR(200) NOT NULL,
    iban VARCHAR(50),
    swift_code VARCHAR(20),

    account_type VARCHAR(20) DEFAULT 'checking',

    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,

    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_user ON bank_accounts(user_id);

CREATE TRIGGER update_bank_accounts_updated_at
    BEFORE UPDATE ON bank_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: webhook_logs
-- =============================================================================

CREATE TABLE webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    provider VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_id VARCHAR(100),

    headers JSONB,
    payload JSONB NOT NULL,
    signature VARCHAR(255),
    is_signature_valid BOOLEAN,

    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    processing_error TEXT,
    related_transaction_id UUID REFERENCES transactions(id),

    received_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_webhook_logs_provider ON webhook_logs(provider);
CREATE INDEX idx_webhook_logs_event ON webhook_logs(event_id);
CREATE INDEX idx_webhook_logs_processed ON webhook_logs(processed) WHERE processed = false;
CREATE INDEX idx_webhook_logs_received ON webhook_logs(received_at);

-- =============================================================================
-- TABLE: cashback_rules
-- =============================================================================

CREATE TABLE cashback_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    name VARCHAR(100) NOT NULL,
    description TEXT,

    min_order_amount INTEGER DEFAULT 0,
    payment_method payment_method,

    cashback_type VARCHAR(20) NOT NULL,
    cashback_value INTEGER NOT NULL,
    max_cashback INTEGER,

    starts_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cashback_rules_active ON cashback_rules(is_active, starts_at, ends_at);
