-- =============================================================================
-- NELO - Users Service Database
-- =============================================================================
-- Base de données: nelo_users
-- Service: user-service (FastAPI)
-- Responsabilité: Profils, adresses, préférences, fidélité, admins
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

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
-- TABLES DE RÉFÉRENCE GÉOGRAPHIQUE (copie locale)
-- =============================================================================

CREATE TABLE countries (
    id UUID PRIMARY KEY,
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone_code VARCHAR(5) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE cities (
    id UUID PRIMARY KEY,
    country_id UUID NOT NULL REFERENCES countries(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50) DEFAULT 'Africa/Abidjan',
    is_active BOOLEAN DEFAULT true,
    UNIQUE(country_id, slug)
);

CREATE TABLE zones (
    id UUID PRIMARY KEY,
    city_id UUID NOT NULL REFERENCES cities(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    polygon GEOMETRY(POLYGON, 4326),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(city_id, slug)
);

CREATE INDEX idx_zones_polygon ON zones USING GIST (polygon);

-- =============================================================================
-- TABLE: profiles
-- =============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY,                        -- Même ID que auth.users (référence externe)

    -- Informations personnelles
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    display_name VARCHAR(100),
    avatar_url TEXT,

    -- Contact
    phone VARCHAR(20) NOT NULL,
    secondary_phone VARCHAR(20),
    email VARCHAR(255),

    -- Localisation
    default_city_id UUID REFERENCES cities(id),
    default_zone_id UUID REFERENCES zones(id),
    preferred_language CHAR(2) DEFAULT 'fr',

    -- Préférences
    preferences JSONB DEFAULT '{}'::jsonb,
    notification_settings JSONB DEFAULT '{
        "push_enabled": true,
        "sms_enabled": true,
        "email_enabled": false,
        "order_updates": true,
        "promotions": true,
        "newsletter": false
    }'::jsonb,

    -- Stats
    total_orders INTEGER DEFAULT 0,
    total_spent BIGINT DEFAULT 0,
    average_rating DECIMAL(3, 2),
    rating_count INTEGER DEFAULT 0,

    -- Personnel
    date_of_birth DATE,
    gender VARCHAR(10),

    -- Référencement
    referral_code VARCHAR(20) UNIQUE,
    referred_by_id UUID REFERENCES profiles(id),
    referral_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_profiles_city ON profiles(default_city_id);
CREATE INDEX idx_profiles_referral ON profiles(referral_code);
CREATE INDEX idx_profiles_phone ON profiles(phone);

-- Trigger
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: addresses
-- =============================================================================

CREATE TABLE addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Libellé
    label VARCHAR(50) NOT NULL DEFAULT 'home',
    name VARCHAR(100),

    -- Adresse
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    landmark VARCHAR(255),

    -- Localisation
    city_id UUID REFERENCES cities(id),
    zone_id UUID REFERENCES zones(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
    ) STORED,

    -- Contact
    contact_phone VARCHAR(20),
    delivery_instructions TEXT,

    -- Statut
    is_default BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_addresses_user ON addresses(user_id);
CREATE INDEX idx_addresses_location ON addresses USING GIST (location);
CREATE INDEX idx_addresses_default ON addresses(user_id, is_default) WHERE is_default = true;

-- Trigger updated_at
CREATE TRIGGER update_addresses_updated_at
    BEFORE UPDATE ON addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour un seul default par user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        UPDATE addresses
        SET is_default = false
        WHERE user_id = NEW.user_id AND id != NEW.id AND is_default = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_single_default_address
    BEFORE INSERT OR UPDATE OF is_default ON addresses
    FOR EACH ROW WHEN (NEW.is_default = true)
    EXECUTE FUNCTION ensure_single_default_address();

-- =============================================================================
-- TABLE: favorites
-- =============================================================================

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    favorite_type VARCHAR(20) NOT NULL,         -- provider, product, driver
    entity_id UUID NOT NULL,                    -- Référence externe

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, favorite_type, entity_id)
);

-- Index
CREATE INDEX idx_favorites_user ON favorites(user_id);
CREATE INDEX idx_favorites_entity ON favorites(favorite_type, entity_id);

-- =============================================================================
-- TABLE: loyalty_points
-- =============================================================================

CREATE TABLE loyalty_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,

    -- Points
    points_balance INTEGER DEFAULT 0,
    points_earned_total BIGINT DEFAULT 0,
    points_spent_total BIGINT DEFAULT 0,

    -- Niveau
    tier VARCHAR(20) DEFAULT 'bronze',
    tier_updated_at TIMESTAMPTZ,

    -- Stats période
    current_month_orders INTEGER DEFAULT 0,
    current_month_spent BIGINT DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_loyalty_user ON loyalty_points(user_id);

-- Trigger
CREATE TRIGGER update_loyalty_points_updated_at
    BEFORE UPDATE ON loyalty_points
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: loyalty_transactions
-- =============================================================================

CREATE TABLE loyalty_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Transaction
    type VARCHAR(20) NOT NULL,
    points INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,

    -- Référence
    order_id UUID,                              -- Référence externe (orders)
    promotion_id UUID,                          -- Référence externe (orders)
    description TEXT,

    -- Expiration
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_loyalty_tx_user ON loyalty_transactions(user_id);
CREATE INDEX idx_loyalty_tx_created ON loyalty_transactions(created_at);

-- =============================================================================
-- TABLE: admin_profiles
-- =============================================================================

CREATE TABLE admin_profiles (
    id UUID PRIMARY KEY,                        -- Même ID que auth.users

    -- Informations
    employee_id VARCHAR(50) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    department VARCHAR(50),
    position VARCHAR(100),

    -- Permissions
    permissions TEXT[] DEFAULT '{}',

    -- Supervision
    supervisor_id UUID REFERENCES admin_profiles(id),

    -- Statut
    is_active BOOLEAN DEFAULT true,
    hired_at DATE,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Trigger
CREATE TRIGGER update_admin_profiles_updated_at
    BEFORE UPDATE ON admin_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: search_history
-- =============================================================================

CREATE TABLE search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    query VARCHAR(255) NOT NULL,
    search_type VARCHAR(20) DEFAULT 'general',
    result_count INTEGER,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_search_history_user ON search_history(user_id);
CREATE INDEX idx_search_history_query ON search_history USING gin(query gin_trgm_ops);

-- Limitation à 50 recherches par utilisateur
CREATE OR REPLACE FUNCTION limit_search_history()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM search_history
    WHERE user_id = NEW.user_id
    AND id NOT IN (
        SELECT id FROM search_history
        WHERE user_id = NEW.user_id
        ORDER BY created_at DESC
        LIMIT 49
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_limit_search_history
    AFTER INSERT ON search_history
    FOR EACH ROW EXECUTE FUNCTION limit_search_history();

-- =============================================================================
-- DONNÉES INITIALES
-- =============================================================================

INSERT INTO countries (id, code, name, phone_code, currency_code)
VALUES ('550e8400-e29b-41d4-a716-446655440001', 'CI', 'Côte d''Ivoire', '+225', 'XOF')
ON CONFLICT (code) DO NOTHING;

INSERT INTO cities (id, country_id, name, slug, latitude, longitude)
VALUES (
    '550e8400-e29b-41d4-a716-446655440010',
    '550e8400-e29b-41d4-a716-446655440001',
    'Tiassalé', 'tiassale', 5.8983, -4.8228
)
ON CONFLICT (country_id, slug) DO NOTHING;
