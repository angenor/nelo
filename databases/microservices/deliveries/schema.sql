-- =============================================================================
-- NELO - Deliveries Service Database
-- =============================================================================
-- Base de données: nelo_deliveries
-- Service: delivery-service (Actix Web / Rust)
-- Responsabilité: Drivers, livraisons, matching, géolocalisation
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =============================================================================
-- TYPES ENUM
-- =============================================================================

CREATE TYPE delivery_status AS ENUM (
    'pending',
    'assigned',
    'accepted',
    'picking_up',
    'picked_up',
    'delivering',
    'delivered',
    'failed',
    'cancelled'
);

CREATE TYPE vehicle_type AS ENUM (
    'bicycle',
    'motorcycle',
    'tricycle',
    'car',
    'van'
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
-- TABLES DE RÉFÉRENCE GÉOGRAPHIQUE (copie locale)
-- =============================================================================

CREATE TABLE countries (
    id UUID PRIMARY KEY,
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
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
-- TABLE: drivers
-- =============================================================================

CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE,                   -- Référence externe (auth.users)

    -- Informations
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    display_name VARCHAR(100),
    avatar_url TEXT,
    date_of_birth DATE,

    -- Contact
    phone VARCHAR(20) NOT NULL,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),

    -- Zone
    city_id UUID NOT NULL REFERENCES cities(id),
    operating_zones UUID[] DEFAULT '{}',
    max_delivery_radius_km DECIMAL(5, 2) DEFAULT 10,

    -- Véhicule
    vehicle_type vehicle_type NOT NULL,
    vehicle_brand VARCHAR(50),
    vehicle_model VARCHAR(50),
    vehicle_color VARCHAR(30),
    vehicle_plate VARCHAR(20),
    vehicle_year SMALLINT,
    vehicle_photo_url TEXT,

    -- Capacité
    max_orders INTEGER DEFAULT 2,
    can_carry_large BOOLEAN DEFAULT false,
    can_carry_fragile BOOLEAN DEFAULT true,

    -- Stats
    average_rating DECIMAL(3, 2),
    rating_count INTEGER DEFAULT 0,
    total_deliveries INTEGER DEFAULT 0,
    total_earnings BIGINT DEFAULT 0,
    completion_rate DECIMAL(5, 2) DEFAULT 100,
    on_time_rate DECIMAL(5, 2) DEFAULT 100,

    -- Niveau
    level INTEGER DEFAULT 1,
    experience_points INTEGER DEFAULT 0,
    badges TEXT[] DEFAULT '{}',

    -- Statut
    status VARCHAR(20) DEFAULT 'pending',
    is_available BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    current_order_count INTEGER DEFAULT 0,

    -- Position
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    current_location GEOMETRY(POINT, 4326),
    location_updated_at TIMESTAMPTZ,

    -- KYC
    kyc_status VARCHAR(20) DEFAULT 'pending',
    kyc_verified_at TIMESTAMPTZ,

    -- Finances
    commission_rate DECIMAL(5, 4) DEFAULT 0.10,
    wallet_id UUID,                                 -- Référence externe (payments.wallets)

    approved_at TIMESTAMPTZ,
    last_delivery_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index
CREATE INDEX idx_drivers_user ON drivers(user_id);
CREATE INDEX idx_drivers_city ON drivers(city_id);
CREATE INDEX idx_drivers_status ON drivers(status);
CREATE INDEX idx_drivers_available ON drivers(city_id, is_available, is_online)
    WHERE is_available = true AND is_online = true;
CREATE INDEX idx_drivers_location ON drivers USING GIST (current_location);
CREATE INDEX idx_drivers_rating ON drivers(average_rating DESC NULLS LAST);
CREATE INDEX idx_drivers_vehicle ON drivers(vehicle_type);

-- Trigger pour géométrie
CREATE OR REPLACE FUNCTION update_driver_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_latitude IS NOT NULL AND NEW.current_longitude IS NOT NULL THEN
        NEW.current_location := ST_SetSRID(
            ST_MakePoint(NEW.current_longitude, NEW.current_latitude),
            4326
        );
        NEW.location_updated_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_location
    BEFORE INSERT OR UPDATE OF current_latitude, current_longitude ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_driver_location();

CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: driver_documents
-- =============================================================================

CREATE TABLE driver_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,

    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(100),

    front_image_url TEXT NOT NULL,
    back_image_url TEXT,

    issued_at DATE,
    expires_at DATE,

    status VARCHAR(20) DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by UUID,
    verified_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_driver_docs_driver ON driver_documents(driver_id);
CREATE INDEX idx_driver_docs_status ON driver_documents(status);
CREATE INDEX idx_driver_docs_expires ON driver_documents(expires_at) WHERE status = 'approved';

CREATE TRIGGER update_driver_documents_updated_at
    BEFORE UPDATE ON driver_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: driver_availability
-- =============================================================================

CREATE TABLE driver_availability (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,

    day_of_week SMALLINT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,

    preferred_zone_id UUID REFERENCES zones(id),
    is_active BOOLEAN DEFAULT true,

    UNIQUE(driver_id, day_of_week, start_time)
);

CREATE INDEX idx_driver_availability_driver ON driver_availability(driver_id);

-- =============================================================================
-- TABLE: deliveries
-- =============================================================================

CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(20) NOT NULL UNIQUE DEFAULT generate_reference('DEL'),

    -- Commande (référence externe)
    order_id UUID NOT NULL,                         -- orders.orders
    order_reference VARCHAR(20) NOT NULL,

    -- Livreur
    driver_id UUID REFERENCES drivers(id),
    assigned_at TIMESTAMPTZ,

    -- Statut
    status delivery_status NOT NULL DEFAULT 'pending',
    status_updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Pickup
    pickup_latitude DECIMAL(10, 8) NOT NULL,
    pickup_longitude DECIMAL(11, 8) NOT NULL,
    pickup_location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(pickup_longitude, pickup_latitude), 4326)
    ) STORED,
    pickup_address TEXT NOT NULL,
    pickup_contact_name VARCHAR(100),
    pickup_contact_phone VARCHAR(20),
    pickup_instructions TEXT,

    -- Delivery
    delivery_latitude DECIMAL(10, 8) NOT NULL,
    delivery_longitude DECIMAL(11, 8) NOT NULL,
    delivery_location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(delivery_longitude, delivery_latitude), 4326)
    ) STORED,
    delivery_address TEXT NOT NULL,
    delivery_contact_name VARCHAR(100),
    delivery_contact_phone VARCHAR(20),
    delivery_instructions TEXT,

    -- Distances
    distance_to_pickup_km DECIMAL(6, 2),
    distance_pickup_delivery_km DECIMAL(6, 2),
    total_distance_km DECIMAL(6, 2),

    -- Timing estimé
    estimated_pickup_time TIMESTAMPTZ,
    estimated_delivery_time TIMESTAMPTZ,
    eta_minutes INTEGER,

    -- Timing réel
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    actual_duration_minutes INTEGER,

    -- Paiement
    delivery_fee INTEGER NOT NULL,
    tip_amount INTEGER DEFAULT 0,
    driver_earnings INTEGER,
    collected_cash INTEGER DEFAULT 0,

    -- Confirmation
    delivery_code VARCHAR(6),
    signature_url TEXT,
    delivery_photo_url TEXT,

    -- Échec
    failure_reason TEXT,
    failure_photo_url TEXT,
    rescheduled_for TIMESTAMPTZ,

    -- Matching
    matching_attempts INTEGER DEFAULT 0,
    matching_score DECIMAL(5, 2),

    driver_notes TEXT,
    customer_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliveries_order ON deliveries(order_id);
CREATE INDEX idx_deliveries_driver ON deliveries(driver_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
CREATE INDEX idx_deliveries_reference ON deliveries(reference);
CREATE INDEX idx_deliveries_pickup ON deliveries USING GIST (pickup_location);
CREATE INDEX idx_deliveries_delivery ON deliveries USING GIST (delivery_location);
CREATE INDEX idx_deliveries_pending ON deliveries(status)
    WHERE status IN ('pending', 'assigned', 'accepted', 'picking_up');

CREATE TRIGGER update_deliveries_updated_at
    BEFORE UPDATE ON deliveries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: delivery_location_history
-- =============================================================================

CREATE TABLE delivery_location_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id),

    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
    ) STORED,

    accuracy DECIMAL(6, 2),
    speed DECIMAL(5, 2),
    heading SMALLINT,

    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_location_history_delivery ON delivery_location_history(delivery_id);
CREATE INDEX idx_location_history_time ON delivery_location_history(recorded_at);

-- =============================================================================
-- TABLE: delivery_status_history
-- =============================================================================

CREATE TABLE delivery_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,

    from_status delivery_status,
    to_status delivery_status NOT NULL,

    changed_by UUID,
    changed_by_type VARCHAR(20),
    reason TEXT,

    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_delivery_status_history ON delivery_status_history(delivery_id);

-- =============================================================================
-- TABLE: delivery_offers
-- =============================================================================

CREATE TABLE delivery_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id),

    matching_score DECIMAL(5, 2) NOT NULL,
    distance_km DECIMAL(6, 2),
    estimated_earnings INTEGER,

    status VARCHAR(20) DEFAULT 'pending',
    response_at TIMESTAMPTZ,
    rejection_reason TEXT,

    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(delivery_id, driver_id)
);

CREATE INDEX idx_offers_delivery ON delivery_offers(delivery_id);
CREATE INDEX idx_offers_driver ON delivery_offers(driver_id);
CREATE INDEX idx_offers_pending ON delivery_offers(driver_id, status) WHERE status = 'pending';

-- =============================================================================
-- TABLE: driver_earnings
-- =============================================================================

CREATE TABLE driver_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id),
    delivery_id UUID REFERENCES deliveries(id),

    type VARCHAR(20) NOT NULL,
    description TEXT,

    gross_amount INTEGER NOT NULL,
    commission_amount INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,

    status VARCHAR(20) DEFAULT 'pending',
    processed_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    payout_id UUID,                                 -- Référence externe (payments.payouts)

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_earnings_driver ON driver_earnings(driver_id);
CREATE INDEX idx_earnings_delivery ON driver_earnings(delivery_id);
CREATE INDEX idx_earnings_status ON driver_earnings(status);
CREATE INDEX idx_earnings_created ON driver_earnings(created_at);

-- =============================================================================
-- TABLE: driver_daily_stats
-- =============================================================================

CREATE TABLE driver_daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id),
    date DATE NOT NULL,

    deliveries_completed INTEGER DEFAULT 0,
    deliveries_cancelled INTEGER DEFAULT 0,
    deliveries_failed INTEGER DEFAULT 0,
    online_minutes INTEGER DEFAULT 0,
    active_minutes INTEGER DEFAULT 0,

    total_distance_km DECIMAL(8, 2) DEFAULT 0,

    delivery_earnings INTEGER DEFAULT 0,
    tip_earnings INTEGER DEFAULT 0,
    bonus_earnings INTEGER DEFAULT 0,
    total_earnings INTEGER DEFAULT 0,

    average_rating DECIMAL(3, 2),
    on_time_count INTEGER DEFAULT 0,
    late_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(driver_id, date)
);

CREATE INDEX idx_daily_stats_driver ON driver_daily_stats(driver_id);
CREATE INDEX idx_daily_stats_date ON driver_daily_stats(date);

-- =============================================================================
-- DONNÉES INITIALES
-- =============================================================================

INSERT INTO countries (id, code, name, currency_code)
VALUES ('550e8400-e29b-41d4-a716-446655440001', 'CI', 'Côte d''Ivoire', 'XOF')
ON CONFLICT (code) DO NOTHING;

INSERT INTO cities (id, country_id, name, slug, latitude, longitude)
VALUES (
    '550e8400-e29b-41d4-a716-446655440010',
    '550e8400-e29b-41d4-a716-446655440001',
    'Tiassalé', 'tiassale', 5.8983, -4.8228
)
ON CONFLICT (country_id, slug) DO NOTHING;
