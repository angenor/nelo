-- =============================================================================
-- NELO - Auth Service Database
-- =============================================================================
-- Base de données: nelo_auth
-- Service: auth-service (FastAPI)
-- Responsabilité: Authentification, sessions, tokens, OTP, KYC
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TYPES ENUM
-- =============================================================================

CREATE TYPE user_role AS ENUM (
    'client',
    'provider',
    'driver',
    'admin',
    'support',
    'finance',
    'marketing'
);

CREATE TYPE kyc_level AS ENUM (
    'none',
    'basic',
    'standard',
    'business'
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

-- =============================================================================
-- TABLE: users (données d'authentification uniquement)
-- =============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Identifiants
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    phone_verified BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,

    -- Authentification
    password_hash VARCHAR(255),
    pin_hash VARCHAR(255),
    biometric_enabled BOOLEAN DEFAULT false,

    -- Rôle et statut
    role user_role NOT NULL DEFAULT 'client',
    is_active BOOLEAN DEFAULT true,
    is_blocked BOOLEAN DEFAULT false,
    blocked_reason TEXT,
    blocked_at TIMESTAMPTZ,

    -- KYC
    kyc_level kyc_level DEFAULT 'none',
    kyc_verified_at TIMESTAMPTZ,

    -- Sécurité
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    last_login_ip INET,
    password_changed_at TIMESTAMPTZ,

    -- Métadonnées
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;

-- Trigger
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: sessions
-- =============================================================================

CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Token
    refresh_token_hash VARCHAR(255) NOT NULL,
    access_token_jti VARCHAR(255),

    -- Device info
    device_id VARCHAR(255),
    device_name VARCHAR(100),
    device_type VARCHAR(50),
    app_version VARCHAR(20),
    os_version VARCHAR(50),
    ip_address INET,
    user_agent TEXT,

    -- Géolocalisation
    last_latitude DECIMAL(10, 8),
    last_longitude DECIMAL(11, 8),
    last_city_id UUID,                          -- Référence externe (orders.cities)

    -- Statut
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    revoked_reason VARCHAR(100),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(refresh_token_hash);
CREATE INDEX idx_sessions_active ON sessions(user_id, is_active) WHERE is_active = true;
CREATE INDEX idx_sessions_expires ON sessions(expires_at) WHERE is_active = true;

-- =============================================================================
-- TABLE: otp_codes
-- =============================================================================

CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Destinataire
    phone VARCHAR(20),
    email VARCHAR(255),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Code
    code_hash VARCHAR(255) NOT NULL,
    purpose VARCHAR(50) NOT NULL,

    -- Validité
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    is_used BOOLEAN DEFAULT false,

    -- Métadonnées
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT otp_has_recipient CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

-- Index
CREATE INDEX idx_otp_phone ON otp_codes(phone, purpose) WHERE is_used = false;
CREATE INDEX idx_otp_email ON otp_codes(email, purpose) WHERE is_used = false;
CREATE INDEX idx_otp_expires ON otp_codes(expires_at) WHERE is_used = false;

-- =============================================================================
-- TABLE: kyc_documents
-- =============================================================================

CREATE TABLE kyc_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Document
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(100),
    document_country CHAR(2),

    -- Fichiers
    front_image_url TEXT,
    back_image_url TEXT,
    selfie_image_url TEXT,

    -- Vérification
    status VARCHAR(20) DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID,
    verified_at TIMESTAMPTZ,

    -- Dates document
    issued_at DATE,
    expires_at DATE,

    -- Métadonnées
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_kyc_docs_user ON kyc_documents(user_id);
CREATE INDEX idx_kyc_docs_status ON kyc_documents(status) WHERE status = 'pending';

-- Trigger
CREATE TRIGGER update_kyc_documents_updated_at
    BEFORE UPDATE ON kyc_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: audit_logs
-- =============================================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Action
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    description TEXT,

    -- Contexte
    ip_address INET,
    user_agent TEXT,
    device_id VARCHAR(255),

    -- Données
    old_values JSONB,
    new_values JSONB,

    -- Résultat
    status VARCHAR(20) DEFAULT 'success',
    error_message TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_created ON audit_logs(created_at);
CREATE INDEX idx_audit_resource ON audit_logs(resource_type, resource_id);

-- =============================================================================
-- TABLE: api_tokens (pour intégrations tierces)
-- =============================================================================

CREATE TABLE api_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    token_prefix VARCHAR(10) NOT NULL,

    -- Permissions
    scopes TEXT[] DEFAULT '{}',

    -- Limites
    rate_limit INTEGER DEFAULT 1000,
    last_used_at TIMESTAMPTZ,
    usage_count BIGINT DEFAULT 0,

    -- Validité
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_api_tokens_user ON api_tokens(user_id);
CREATE INDEX idx_api_tokens_hash ON api_tokens(token_hash) WHERE is_active = true;

-- =============================================================================
-- TABLE: rate_limits
-- =============================================================================

CREATE TABLE rate_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    window_end TIMESTAMPTZ NOT NULL,

    UNIQUE(identifier, endpoint, window_start)
);

-- Index
CREATE INDEX idx_rate_limits_lookup ON rate_limits(identifier, endpoint, window_end);
