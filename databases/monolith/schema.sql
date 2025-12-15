-- =============================================================================
-- NELO - Base de Données Monolithique (Phase 1 - MVP)
-- =============================================================================
-- Architecture: Monolith-First, Microservice-Ready
-- Principe: Chaque schéma est AUTONOME (pas de FK inter-schémas)
-- Migration: Les modules communiquent via interfaces, pas via SQL JOINs
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- =============================================================================
-- SCHÉMAS (isolation logique - futurs microservices)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS orders;
CREATE SCHEMA IF NOT EXISTS deliveries;
CREATE SCHEMA IF NOT EXISTS payments;
CREATE SCHEMA IF NOT EXISTS notifications;

-- =============================================================================
-- TYPES ENUM (définis dans chaque schéma qui en a besoin)
-- Note: En microservices, chaque DB aura ses propres types
-- =============================================================================

-- Types pour auth
CREATE TYPE auth.user_role AS ENUM ('client', 'provider', 'driver', 'admin', 'support', 'finance', 'marketing');
CREATE TYPE auth.kyc_level AS ENUM ('none', 'basic', 'standard', 'business');

-- Types pour orders
CREATE TYPE orders.order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'delivering', 'delivered', 'cancelled', 'refunded');
CREATE TYPE orders.provider_type AS ENUM ('restaurant', 'gas_depot', 'grocery', 'pharmacy', 'pressing', 'artisan');
CREATE TYPE orders.payment_method AS ENUM ('wallet', 'mobile_money', 'card', 'cash');

-- Types pour deliveries
CREATE TYPE deliveries.delivery_status AS ENUM ('pending', 'assigned', 'accepted', 'picking_up', 'picked_up', 'delivering', 'delivered', 'failed', 'cancelled');
CREATE TYPE deliveries.vehicle_type AS ENUM ('bicycle', 'motorcycle', 'tricycle', 'car', 'van');

-- Types pour payments
CREATE TYPE payments.transaction_type AS ENUM ('topup', 'payment', 'refund', 'transfer', 'withdrawal', 'cashback', 'commission');
CREATE TYPE payments.transaction_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');
CREATE TYPE payments.payment_method AS ENUM ('wallet', 'mobile_money', 'card', 'cash');

-- Types pour notifications
CREATE TYPE notifications.notification_type AS ENUM ('order_update', 'delivery_update', 'payment', 'promotion', 'system', 'chat');

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

-- #############################################################################
-- SCHÉMA: auth (AUTONOME)
-- Service: auth-service
-- Dépendances externes: AUCUNE
-- #############################################################################

-- Données géographiques locales (pour sessions)
CREATE TABLE auth.cities (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL DEFAULT 'CI'
);

CREATE TABLE auth.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    phone_verified BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,
    password_hash VARCHAR(255),
    pin_hash VARCHAR(255),
    role auth.user_role NOT NULL DEFAULT 'client',
    is_active BOOLEAN DEFAULT true,
    is_blocked BOOLEAN DEFAULT false,
    blocked_reason TEXT,
    kyc_level auth.kyc_level DEFAULT 'none',
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auth_users_phone ON auth.users(phone);
CREATE INDEX idx_auth_users_role ON auth.users(role);

CREATE TABLE auth.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_id VARCHAR(255),
    device_type VARCHAR(50),
    ip_address INET,
    last_city_id UUID,  -- Pas de FK vers autre schéma
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_auth_sessions_user ON auth.sessions(user_id);

CREATE TABLE auth.otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20),
    email VARCHAR(255),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    code_hash VARCHAR(255) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    attempts INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth.kyc_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(100),
    front_image_url TEXT,
    back_image_url TEXT,
    selfie_image_url TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID,  -- Pas de FK, juste l'ID admin
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,  -- Pas de FK, peut être supprimé
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_auth_users_updated BEFORE UPDATE ON auth.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_auth_kyc_updated BEFORE UPDATE ON auth.kyc_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- #############################################################################
-- SCHÉMA: users (AUTONOME)
-- Service: user-service
-- Dépendances externes: auth.users.id (par UUID, pas FK)
-- #############################################################################

-- Données géographiques locales
CREATE TABLE users.countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone_code VARCHAR(5) NOT NULL,
    currency_code CHAR(3) NOT NULL
);

CREATE TABLE users.cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_id UUID NOT NULL REFERENCES users.countries(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50) DEFAULT 'Africa/Abidjan',
    is_active BOOLEAN DEFAULT true,
    UNIQUE(country_id, slug)
);

CREATE TABLE users.zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id UUID NOT NULL REFERENCES users.cities(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    polygon GEOMETRY(POLYGON, 4326),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(city_id, slug)
);

CREATE TABLE users.profiles (
    id UUID PRIMARY KEY,  -- ⚠️ Même UUID que auth.users, mais PAS de FK
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    display_name VARCHAR(100),
    avatar_url TEXT,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    default_city_id UUID REFERENCES users.cities(id),
    default_zone_id UUID REFERENCES users.zones(id),
    preferred_language CHAR(2) DEFAULT 'fr',
    notification_settings JSONB DEFAULT '{"push": true, "sms": true, "email": false}'::jsonb,
    total_orders INTEGER DEFAULT 0,
    total_spent BIGINT DEFAULT 0,
    average_rating DECIMAL(3, 2),
    referral_code VARCHAR(20) UNIQUE,
    referred_by_id UUID,  -- Pas de FK, juste UUID
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users.addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.profiles(id) ON DELETE CASCADE,
    label VARCHAR(50) DEFAULT 'home',
    name VARCHAR(100),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    landmark VARCHAR(255),
    city_id UUID REFERENCES users.cities(id),
    zone_id UUID REFERENCES users.zones(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    contact_phone VARCHAR(20),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_addresses_user ON users.addresses(user_id);
CREATE INDEX idx_users_addresses_location ON users.addresses USING GIST (location);

CREATE TABLE users.favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users.profiles(id) ON DELETE CASCADE,
    favorite_type VARCHAR(20) NOT NULL,  -- provider, product, driver
    entity_id UUID NOT NULL,  -- UUID externe, pas de FK
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, favorite_type, entity_id)
);

CREATE TABLE users.loyalty_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users.profiles(id) ON DELETE CASCADE,
    points_balance INTEGER DEFAULT 0,
    tier VARCHAR(20) DEFAULT 'bronze',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_users_profiles_updated BEFORE UPDATE ON users.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_users_addresses_updated BEFORE UPDATE ON users.addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Données initiales
INSERT INTO users.countries (id, code, name, phone_code, currency_code)
VALUES ('550e8400-e29b-41d4-a716-446655440001', 'CI', 'Côte d''Ivoire', '+225', 'XOF');

INSERT INTO users.cities (id, country_id, name, slug, latitude, longitude)
VALUES ('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440001', 'Tiassalé', 'tiassale', 5.8983, -4.8228);

-- #############################################################################
-- SCHÉMA: orders (AUTONOME)
-- Service: order-service
-- Dépendances externes: auth.users.id, users.addresses.id (par UUID)
-- #############################################################################

-- Données géographiques locales (copie pour autonomie)
CREATE TABLE orders.countries (
    id UUID PRIMARY KEY,
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    currency_code CHAR(3) NOT NULL
);

CREATE TABLE orders.cities (
    id UUID PRIMARY KEY,
    country_id UUID NOT NULL REFERENCES orders.countries(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(country_id, slug)
);

CREATE TABLE orders.zones (
    id UUID PRIMARY KEY,
    city_id UUID NOT NULL REFERENCES orders.cities(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    polygon GEOMETRY(POLYGON, 4326),
    delivery_fee_base INTEGER DEFAULT 500,
    is_active BOOLEAN DEFAULT true,
    UNIQUE(city_id, slug)
);

CREATE TABLE orders.pricing_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id UUID REFERENCES orders.cities(id),
    zone_id UUID REFERENCES orders.zones(id),
    provider_type orders.provider_type,
    base_fee INTEGER NOT NULL DEFAULT 500,
    per_km_fee INTEGER NOT NULL DEFAULT 100,
    min_order_amount INTEGER DEFAULT 1000,
    free_delivery_threshold INTEGER,
    surge_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders.provider_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES orders.provider_categories(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    icon_url TEXT,
    provider_type orders.provider_type NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE orders.providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- ⚠️ Référence auth.users, PAS de FK
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL,
    description TEXT,
    type orders.provider_type NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    whatsapp VARCHAR(20),
    address_line1 VARCHAR(255) NOT NULL,
    landmark VARCHAR(255),
    city_id UUID NOT NULL REFERENCES orders.cities(id),
    zone_id UUID REFERENCES orders.zones(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    logo_url TEXT,
    cover_image_url TEXT,
    min_order_amount INTEGER DEFAULT 0,
    average_prep_time INTEGER DEFAULT 30,
    delivery_radius_km DECIMAL(5, 2) DEFAULT 5,
    commission_rate DECIMAL(5, 4) DEFAULT 0.15,
    average_rating DECIMAL(3, 2),
    rating_count INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    is_open BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(city_id, slug)
);

CREATE INDEX idx_orders_providers_city ON orders.providers(city_id);
CREATE INDEX idx_orders_providers_location ON orders.providers USING GIST (location);
CREATE INDEX idx_orders_providers_open ON orders.providers(city_id, is_open) WHERE is_open = true;

CREATE TABLE orders.provider_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES orders.providers(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL,
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT false,
    UNIQUE(provider_id, day_of_week)
);

CREATE TABLE orders.product_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES orders.providers(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE orders.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES orders.providers(id) ON DELETE CASCADE,
    category_id UUID REFERENCES orders.product_categories(id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    image_url TEXT,
    price INTEGER NOT NULL,
    compare_at_price INTEGER,
    is_available BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_vegetarian BOOLEAN DEFAULT false,
    is_spicy BOOLEAN DEFAULT false,
    prep_time INTEGER,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_products_provider ON orders.products(provider_id);

CREATE TABLE orders.product_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES orders.products(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) DEFAULT 'single',
    is_required BOOLEAN DEFAULT false,
    max_selections INTEGER DEFAULT 1
);

CREATE TABLE orders.product_option_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    option_id UUID NOT NULL REFERENCES orders.product_options(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    price_adjustment INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true
);

CREATE TABLE orders.gas_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES orders.providers(id) ON DELETE CASCADE,
    brand VARCHAR(50) NOT NULL,
    bottle_size VARCHAR(20) NOT NULL,
    refill_price INTEGER NOT NULL,
    exchange_price INTEGER,
    quantity_available INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(20) NOT NULL UNIQUE DEFAULT generate_reference('ORD'),
    user_id UUID NOT NULL,  -- ⚠️ Référence auth.users, PAS de FK
    provider_id UUID NOT NULL REFERENCES orders.providers(id),
    service_type VARCHAR(20) NOT NULL,
    status orders.order_status NOT NULL DEFAULT 'pending',

    -- Snapshot de l'adresse (pas de FK vers users.addresses)
    delivery_address_id UUID,  -- Juste pour référence
    delivery_address_snapshot JSONB NOT NULL,  -- Copie complète

    special_instructions TEXT,
    subtotal INTEGER NOT NULL,
    delivery_fee INTEGER NOT NULL DEFAULT 0,
    service_fee INTEGER DEFAULT 0,
    discount_amount INTEGER DEFAULT 0,
    tip_amount INTEGER DEFAULT 0,
    total INTEGER NOT NULL,

    promotion_id UUID,  -- Référence interne
    promotion_code VARCHAR(50),

    payment_method orders.payment_method NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    transaction_id UUID,  -- ⚠️ Référence payments.transactions, PAS de FK

    is_scheduled BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMPTZ,

    estimated_prep_time INTEGER,
    estimated_delivery_time INTEGER,

    confirmed_at TIMESTAMPTZ,
    ready_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    cancelled_by VARCHAR(20),

    is_rated BOOLEAN DEFAULT false,
    provider_rating SMALLINT,
    driver_rating SMALLINT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_orders_user ON orders.orders(user_id);
CREATE INDEX idx_orders_orders_provider ON orders.orders(provider_id);
CREATE INDEX idx_orders_orders_status ON orders.orders(status);
CREATE INDEX idx_orders_orders_reference ON orders.orders(reference);
CREATE INDEX idx_orders_orders_created ON orders.orders(created_at DESC);

CREATE TABLE orders.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders.orders(id) ON DELETE CASCADE,
    product_id UUID,  -- Peut être NULL si produit supprimé
    gas_product_id UUID,
    product_name VARCHAR(200) NOT NULL,
    product_image_url TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price INTEGER NOT NULL,
    total_price INTEGER NOT NULL,
    selected_options JSONB DEFAULT '[]'::jsonb,
    special_instructions TEXT
);

CREATE TABLE orders.order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders.orders(id) ON DELETE CASCADE,
    from_status orders.order_status,
    to_status orders.order_status NOT NULL,
    changed_by UUID,  -- UUID sans FK
    changed_by_type VARCHAR(20),
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders.ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders.orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,  -- ⚠️ Pas de FK
    rating_type VARCHAR(20) NOT NULL,
    provider_id UUID REFERENCES orders.providers(id),
    driver_id UUID,  -- ⚠️ Référence deliveries.drivers, PAS de FK
    product_id UUID REFERENCES orders.products(id),
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    tags TEXT[] DEFAULT '{}',
    is_visible BOOLEAN DEFAULT true,
    provider_response TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders.promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(20) NOT NULL,
    discount_value INTEGER NOT NULL,
    max_discount INTEGER,
    min_order_amount INTEGER DEFAULT 0,
    max_uses INTEGER,
    max_uses_per_user INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    starts_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders.user_promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- ⚠️ Pas de FK
    promotion_id UUID NOT NULL REFERENCES orders.promotions(id),
    order_id UUID REFERENCES orders.orders(id),
    discount_applied INTEGER NOT NULL,
    used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_orders_providers_updated BEFORE UPDATE ON orders.providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_orders_products_updated BEFORE UPDATE ON orders.products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_orders_orders_updated BEFORE UPDATE ON orders.orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Données initiales
INSERT INTO orders.countries (id, code, name, currency_code)
VALUES ('550e8400-e29b-41d4-a716-446655440001', 'CI', 'Côte d''Ivoire', 'XOF');

INSERT INTO orders.cities (id, country_id, name, slug, latitude, longitude)
VALUES ('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440001', 'Tiassalé', 'tiassale', 5.8983, -4.8228);

-- #############################################################################
-- SCHÉMA: deliveries (AUTONOME)
-- Service: delivery-service
-- Dépendances externes: auth.users.id, orders.orders.id (par UUID)
-- #############################################################################

-- Données géographiques locales
CREATE TABLE deliveries.cities (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL DEFAULT 'CI',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8)
);

CREATE TABLE deliveries.zones (
    id UUID PRIMARY KEY,
    city_id UUID NOT NULL REFERENCES deliveries.cities(id),
    name VARCHAR(100) NOT NULL,
    polygon GEOMETRY(POLYGON, 4326)
);

CREATE TABLE deliveries.drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,  -- ⚠️ Référence auth.users, PAS de FK
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    avatar_url TEXT,
    city_id UUID NOT NULL REFERENCES deliveries.cities(id),
    operating_zones UUID[] DEFAULT '{}',
    vehicle_type deliveries.vehicle_type NOT NULL,
    vehicle_brand VARCHAR(50),
    vehicle_model VARCHAR(50),
    vehicle_plate VARCHAR(20),
    vehicle_photo_url TEXT,
    max_orders INTEGER DEFAULT 2,
    average_rating DECIMAL(3, 2),
    rating_count INTEGER DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    total_earnings BIGINT DEFAULT 0,
    completion_rate DECIMAL(5, 2) DEFAULT 100,
    status VARCHAR(20) DEFAULT 'pending',
    is_available BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    current_location GEOMETRY(POINT, 4326),
    location_updated_at TIMESTAMPTZ,
    commission_rate DECIMAL(5, 4) DEFAULT 0.10,
    wallet_id UUID,  -- ⚠️ Référence payments.wallets, PAS de FK
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliveries_drivers_city ON deliveries.drivers(city_id);
CREATE INDEX idx_deliveries_drivers_location ON deliveries.drivers USING GIST (current_location);
CREATE INDEX idx_deliveries_drivers_available ON deliveries.drivers(city_id, is_available, is_online)
    WHERE is_available = true AND is_online = true;

-- Trigger pour mettre à jour la géométrie
CREATE OR REPLACE FUNCTION deliveries.update_driver_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_latitude IS NOT NULL AND NEW.current_longitude IS NOT NULL THEN
        NEW.current_location := ST_SetSRID(ST_MakePoint(NEW.current_longitude, NEW.current_latitude), 4326);
        NEW.location_updated_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_deliveries_drivers_location
    BEFORE INSERT OR UPDATE OF current_latitude, current_longitude ON deliveries.drivers
    FOR EACH ROW EXECUTE FUNCTION deliveries.update_driver_location();

CREATE TABLE deliveries.driver_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES deliveries.drivers(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(100),
    front_image_url TEXT NOT NULL,
    back_image_url TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    verified_by UUID,  -- Pas de FK
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE deliveries.driver_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES deliveries.drivers(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    preferred_zone_id UUID,  -- Pas de FK
    UNIQUE(driver_id, day_of_week, start_time)
);

CREATE TABLE deliveries.deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(20) NOT NULL UNIQUE DEFAULT generate_reference('DEL'),
    order_id UUID NOT NULL,  -- ⚠️ Référence orders.orders, PAS de FK
    order_reference VARCHAR(20) NOT NULL,
    driver_id UUID REFERENCES deliveries.drivers(id),
    status deliveries.delivery_status NOT NULL DEFAULT 'pending',

    -- Pickup (copie, pas de FK)
    pickup_latitude DECIMAL(10, 8) NOT NULL,
    pickup_longitude DECIMAL(11, 8) NOT NULL,
    pickup_location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(pickup_longitude, pickup_latitude), 4326)) STORED,
    pickup_address TEXT NOT NULL,
    pickup_contact_name VARCHAR(100),
    pickup_contact_phone VARCHAR(20),

    -- Delivery (copie, pas de FK)
    delivery_latitude DECIMAL(10, 8) NOT NULL,
    delivery_longitude DECIMAL(11, 8) NOT NULL,
    delivery_location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(delivery_longitude, delivery_latitude), 4326)) STORED,
    delivery_address TEXT NOT NULL,
    delivery_contact_name VARCHAR(100),
    delivery_contact_phone VARCHAR(20),

    distance_km DECIMAL(6, 2),
    delivery_fee INTEGER NOT NULL,
    tip_amount INTEGER DEFAULT 0,
    driver_earnings INTEGER,
    collected_cash INTEGER DEFAULT 0,

    delivery_code VARCHAR(6),
    delivery_photo_url TEXT,

    estimated_delivery_time TIMESTAMPTZ,
    eta_minutes INTEGER,

    assigned_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,

    failure_reason TEXT,

    matching_score DECIMAL(5, 2),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliveries_deliveries_order ON deliveries.deliveries(order_id);
CREATE INDEX idx_deliveries_deliveries_driver ON deliveries.deliveries(driver_id);
CREATE INDEX idx_deliveries_deliveries_status ON deliveries.deliveries(status);
CREATE INDEX idx_deliveries_deliveries_pickup ON deliveries.deliveries USING GIST (pickup_location);

CREATE TABLE deliveries.delivery_location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id UUID NOT NULL REFERENCES deliveries.deliveries(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL,  -- Pas de FK pour perf
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    speed DECIMAL(5, 2),
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliveries_location_history ON deliveries.delivery_location_history(delivery_id, recorded_at);

CREATE TABLE deliveries.delivery_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id UUID NOT NULL REFERENCES deliveries.deliveries(id) ON DELETE CASCADE,
    from_status deliveries.delivery_status,
    to_status deliveries.delivery_status NOT NULL,
    changed_by UUID,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE deliveries.delivery_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id UUID NOT NULL REFERENCES deliveries.deliveries(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES deliveries.drivers(id),
    matching_score DECIMAL(5, 2) NOT NULL,
    distance_km DECIMAL(6, 2),
    estimated_earnings INTEGER,
    status VARCHAR(20) DEFAULT 'pending',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(delivery_id, driver_id)
);

CREATE TABLE deliveries.driver_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES deliveries.drivers(id),
    delivery_id UUID REFERENCES deliveries.deliveries(id),
    type VARCHAR(20) NOT NULL,
    gross_amount INTEGER NOT NULL,
    commission_amount INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payout_id UUID,  -- ⚠️ Référence payments.payouts, PAS de FK
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_deliveries_drivers_updated BEFORE UPDATE ON deliveries.drivers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_deliveries_deliveries_updated BEFORE UPDATE ON deliveries.deliveries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Données initiales
INSERT INTO deliveries.cities (id, name, latitude, longitude)
VALUES ('550e8400-e29b-41d4-a716-446655440010', 'Tiassalé', 5.8983, -4.8228);

-- #############################################################################
-- SCHÉMA: payments (AUTONOME)
-- Service: payment-service
-- Dépendances externes: auth.users.id, orders.orders.id (par UUID)
-- #############################################################################

CREATE TABLE payments.wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,  -- ⚠️ Référence auth.users, PAS de FK
    balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
    pending_balance INTEGER DEFAULT 0,
    reserved_balance INTEGER DEFAULT 0,
    daily_limit INTEGER DEFAULT 500000,
    monthly_limit INTEGER DEFAULT 5000000,
    daily_spent INTEGER DEFAULT 0,
    monthly_spent INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_frozen BOOLEAN DEFAULT false,
    frozen_reason TEXT,
    pin_hash VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_wallets_user ON payments.wallets(user_id);

CREATE TABLE payments.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('TXN', 12),
    wallet_id UUID NOT NULL REFERENCES payments.wallets(id),
    user_id UUID NOT NULL,  -- ⚠️ Pas de FK
    type payments.transaction_type NOT NULL,
    direction VARCHAR(10) NOT NULL,
    amount INTEGER NOT NULL,
    fee INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    payment_method payments.payment_method,
    provider VARCHAR(50),
    order_id UUID,  -- ⚠️ Référence orders.orders, PAS de FK
    delivery_id UUID,  -- ⚠️ Référence deliveries.deliveries, PAS de FK
    external_reference VARCHAR(100),
    external_transaction_id VARCHAR(100),
    sender_wallet_id UUID REFERENCES payments.wallets(id),
    recipient_wallet_id UUID REFERENCES payments.wallets(id),
    status payments.transaction_status NOT NULL DEFAULT 'pending',
    failure_reason TEXT,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_transactions_wallet ON payments.transactions(wallet_id);
CREATE INDEX idx_payments_transactions_order ON payments.transactions(order_id);
CREATE INDEX idx_payments_transactions_status ON payments.transactions(status);

CREATE TABLE payments.payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- ⚠️ Pas de FK
    wallet_id UUID REFERENCES payments.wallets(id),
    type payments.payment_method NOT NULL,
    provider VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20),
    card_last_four CHAR(4),
    card_brand VARCHAR(20),
    provider_token VARCHAR(255),
    display_name VARCHAR(100),
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments.topup_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('TOP', 12),
    wallet_id UUID NOT NULL REFERENCES payments.wallets(id),
    user_id UUID NOT NULL,
    amount INTEGER NOT NULL,
    fee INTEGER DEFAULT 0,
    total_amount INTEGER NOT NULL,
    payment_method payments.payment_method NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_reference VARCHAR(100),
    checkout_url TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments.order_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('PAY', 12),
    order_id UUID NOT NULL,  -- ⚠️ Pas de FK
    user_id UUID NOT NULL,
    wallet_id UUID REFERENCES payments.wallets(id),
    subtotal INTEGER NOT NULL,
    delivery_fee INTEGER NOT NULL,
    service_fee INTEGER DEFAULT 0,
    discount_amount INTEGER DEFAULT 0,
    tip_amount INTEGER DEFAULT 0,
    total_amount INTEGER NOT NULL,
    payment_method payments.payment_method NOT NULL,
    provider VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending',
    cash_collected INTEGER,
    collected_by UUID,  -- ⚠️ Référence deliveries.drivers, PAS de FK
    refund_amount INTEGER,
    refunded_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_order_payments_order ON payments.order_payments(order_id);

CREATE TABLE payments.payouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(30) NOT NULL UNIQUE DEFAULT generate_reference('OUT', 12),
    recipient_type VARCHAR(20) NOT NULL,
    recipient_id UUID NOT NULL,  -- provider ou driver
    recipient_wallet_id UUID REFERENCES payments.wallets(id),
    gross_amount INTEGER NOT NULL,
    commission_amount INTEGER DEFAULT 0,
    fee_amount INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    orders_count INTEGER DEFAULT 0,
    payout_method VARCHAR(50) NOT NULL,
    recipient_phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'pending',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments.webhook_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_id VARCHAR(100),
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    related_transaction_id UUID,
    received_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_payments_wallets_updated BEFORE UPDATE ON payments.wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_payments_transactions_updated BEFORE UPDATE ON payments.transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- #############################################################################
-- SCHÉMA: notifications (AUTONOME)
-- Service: notification-service + chat-service
-- Dépendances externes: auth.users.id (par UUID)
-- #############################################################################

CREATE TABLE notifications.push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- ⚠️ Pas de FK vers auth.users
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    device_id VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, token)
);

CREATE INDEX idx_notifications_push_tokens_user ON notifications.push_tokens(user_id);

CREATE TABLE notifications.notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    type notifications.notification_type NOT NULL,
    title_fr VARCHAR(200) NOT NULL,
    body_fr TEXT NOT NULL,
    title_en VARCHAR(200),
    body_en TEXT,
    variables TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- ⚠️ Pas de FK
    type notifications.notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,
    action_type VARCHAR(50),
    action_data JSONB DEFAULT '{}'::jsonb,
    order_id UUID,  -- ⚠️ Pas de FK
    delivery_id UUID,  -- ⚠️ Pas de FK
    conversation_id UUID,
    channels TEXT[] DEFAULT '{push}',
    push_sent BOOLEAN DEFAULT false,
    sms_sent BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_notifications_user ON notifications.notifications(user_id);
CREATE INDEX idx_notifications_notifications_unread ON notifications.notifications(user_id, is_read) WHERE is_read = false;

CREATE TABLE notifications.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) NOT NULL,
    participant_1_id UUID NOT NULL,  -- ⚠️ Pas de FK
    participant_1_type VARCHAR(20) NOT NULL,
    participant_2_id UUID NOT NULL,
    participant_2_type VARCHAR(20) NOT NULL,
    order_id UUID,
    last_message_at TIMESTAMPTZ,
    last_message_preview VARCHAR(200),
    unread_count_1 INTEGER DEFAULT 0,
    unread_count_2 INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_conversations_p1 ON notifications.conversations(participant_1_id);
CREATE INDEX idx_notifications_conversations_p2 ON notifications.conversations(participant_2_id);

CREATE TABLE notifications.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES notifications.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,  -- ⚠️ Pas de FK
    sender_type VARCHAR(20) NOT NULL,
    content TEXT,
    message_type VARCHAR(20) DEFAULT 'text',
    media_url TEXT,
    status VARCHAR(20) DEFAULT 'sent',
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_messages_conversation ON notifications.messages(conversation_id);

CREATE TABLE notifications.sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID REFERENCES notifications.notifications(id),
    phone_number VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_message_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending',
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Triggers
CREATE TRIGGER trg_notifications_conversations_updated BEFORE UPDATE ON notifications.conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Templates de notification
INSERT INTO notifications.notification_templates (code, name, type, title_fr, body_fr, title_en, body_en, variables)
VALUES
    ('order_confirmed', 'Commande confirmée', 'order_update',
     'Commande confirmée', 'Votre commande {order_reference} a été confirmée.',
     'Order confirmed', 'Your order {order_reference} has been confirmed.',
     '{order_reference, provider_name}'),
    ('driver_assigned', 'Livreur assigné', 'delivery_update',
     'Livreur en route', '{driver_name} arrive dans environ {eta} minutes.',
     'Driver on the way', '{driver_name} will arrive in about {eta} minutes.',
     '{driver_name, eta}'),
    ('order_delivered', 'Commande livrée', 'delivery_update',
     'Commande livrée!', 'Votre commande a été livrée. Bon appétit!',
     'Order delivered!', 'Your order has been delivered. Enjoy!',
     '{order_reference}');
