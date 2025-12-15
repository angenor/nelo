-- =============================================================================
-- NELO - Orders Service Database
-- =============================================================================
-- Base de données: nelo_orders
-- Service: order-service (Actix Web / Rust)
-- Responsabilité: Providers, produits, commandes, évaluations, promotions
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
-- TYPES ENUM
-- =============================================================================

CREATE TYPE order_status AS ENUM (
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'picked_up',
    'delivering',
    'delivered',
    'cancelled',
    'refunded'
);

CREATE TYPE provider_type AS ENUM (
    'restaurant',
    'gas_depot',
    'grocery',
    'pharmacy',
    'pressing',
    'artisan'
);

CREATE TYPE payment_method AS ENUM (
    'wallet',
    'mobile_money',
    'card',
    'cash'
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
    delivery_fee_base INTEGER DEFAULT 500,
    UNIQUE(city_id, slug)
);

CREATE INDEX idx_zones_polygon ON zones USING GIST (polygon);

-- =============================================================================
-- TABLE: pricing_rules
-- =============================================================================

CREATE TABLE pricing_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id UUID REFERENCES cities(id),
    zone_id UUID REFERENCES zones(id),
    provider_type provider_type,

    base_fee INTEGER NOT NULL DEFAULT 500,
    per_km_fee INTEGER NOT NULL DEFAULT 100,
    min_order_amount INTEGER DEFAULT 1000,
    free_delivery_threshold INTEGER,

    surge_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    surge_start_hour SMALLINT,
    surge_end_hour SMALLINT,

    valid_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_pricing_rules_updated_at
    BEFORE UPDATE ON pricing_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: provider_categories
-- =============================================================================

CREATE TABLE provider_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES provider_categories(id),

    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    display_order INTEGER DEFAULT 0,

    provider_type provider_type NOT NULL,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_provider_categories_parent ON provider_categories(parent_id);
CREATE INDEX idx_provider_categories_type ON provider_categories(provider_type);

-- =============================================================================
-- TABLE: providers
-- =============================================================================

CREATE TABLE providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,                          -- Référence externe (auth.users)

    -- Informations
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL,
    description TEXT,
    type provider_type NOT NULL,

    -- Contact
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    whatsapp VARCHAR(20),

    -- Localisation
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    landmark VARCHAR(255),
    city_id UUID NOT NULL REFERENCES cities(id),
    zone_id UUID REFERENCES zones(id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    location GEOMETRY(POINT, 4326) GENERATED ALWAYS AS (
        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
    ) STORED,

    -- Images
    logo_url TEXT,
    cover_image_url TEXT,
    gallery_urls TEXT[] DEFAULT '{}',

    -- Configuration
    min_order_amount INTEGER DEFAULT 0,
    average_prep_time INTEGER DEFAULT 30,
    delivery_radius_km DECIMAL(5, 2) DEFAULT 5,

    -- Finances
    commission_rate DECIMAL(5, 4) DEFAULT 0.15,
    accepts_cash BOOLEAN DEFAULT true,
    accepts_mobile_money BOOLEAN DEFAULT true,
    accepts_wallet BOOLEAN DEFAULT true,

    -- Stats
    average_rating DECIMAL(3, 2),
    rating_count INTEGER DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_revenue BIGINT DEFAULT 0,

    -- Statut
    status VARCHAR(20) DEFAULT 'pending',
    is_open BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,

    -- KYC
    business_name VARCHAR(200),
    business_registration VARCHAR(100),
    tax_id VARCHAR(50),

    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(city_id, slug)
);

-- Index
CREATE INDEX idx_providers_user ON providers(user_id);
CREATE INDEX idx_providers_city ON providers(city_id);
CREATE INDEX idx_providers_zone ON providers(zone_id);
CREATE INDEX idx_providers_type ON providers(type);
CREATE INDEX idx_providers_status ON providers(status);
CREATE INDEX idx_providers_location ON providers USING GIST (location);
CREATE INDEX idx_providers_open ON providers(is_open) WHERE is_open = true;
CREATE INDEX idx_providers_featured ON providers(is_featured, city_id) WHERE is_featured = true;
CREATE INDEX idx_providers_rating ON providers(average_rating DESC NULLS LAST);
CREATE INDEX idx_providers_search ON providers USING gin(
    to_tsvector('french', coalesce(name, '') || ' ' || coalesce(description, ''))
);

CREATE TRIGGER update_providers_updated_at
    BEFORE UPDATE ON providers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: provider_schedules
-- =============================================================================

CREATE TABLE provider_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

    day_of_week SMALLINT NOT NULL,
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT false,

    break_start TIME,
    break_end TIME,

    UNIQUE(provider_id, day_of_week)
);

CREATE INDEX idx_schedules_provider ON provider_schedules(provider_id);

-- =============================================================================
-- TABLE: provider_category_links
-- =============================================================================

CREATE TABLE provider_category_links (
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES provider_categories(id) ON DELETE CASCADE,
    PRIMARY KEY (provider_id, category_id)
);

-- =============================================================================
-- TABLE: product_categories
-- =============================================================================

CREATE TABLE product_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_categories_provider ON product_categories(provider_id);

-- =============================================================================
-- TABLE: products
-- =============================================================================

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,

    name VARCHAR(200) NOT NULL,
    description TEXT,
    image_url TEXT,

    price INTEGER NOT NULL,
    compare_at_price INTEGER,
    cost_price INTEGER,

    track_inventory BOOLEAN DEFAULT false,
    quantity_available INTEGER,
    low_stock_threshold INTEGER DEFAULT 5,

    is_available BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_vegetarian BOOLEAN DEFAULT false,
    is_spicy BOOLEAN DEFAULT false,
    allergens TEXT[] DEFAULT '{}',
    calories INTEGER,
    prep_time INTEGER,

    sku VARCHAR(50),
    barcode VARCHAR(50),
    times_ordered INTEGER DEFAULT 0,
    display_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_provider ON products(provider_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_available ON products(provider_id, is_available) WHERE is_available = true;
CREATE INDEX idx_products_featured ON products(provider_id, is_featured) WHERE is_featured = true;
CREATE INDEX idx_products_search ON products USING gin(
    to_tsvector('french', coalesce(name, '') || ' ' || coalesce(description, ''))
);

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: product_options
-- =============================================================================

CREATE TABLE product_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) DEFAULT 'single',
    is_required BOOLEAN DEFAULT false,
    min_selections INTEGER DEFAULT 0,
    max_selections INTEGER DEFAULT 1,
    display_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_options_product ON product_options(product_id);

-- =============================================================================
-- TABLE: product_option_items
-- =============================================================================

CREATE TABLE product_option_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    option_id UUID NOT NULL REFERENCES product_options(id) ON DELETE CASCADE,

    name VARCHAR(100) NOT NULL,
    price_adjustment INTEGER DEFAULT 0,
    is_default BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_option_items_option ON product_option_items(option_id);

-- =============================================================================
-- TABLE: gas_products
-- =============================================================================

CREATE TABLE gas_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

    brand VARCHAR(50) NOT NULL,
    bottle_size VARCHAR(20) NOT NULL,

    refill_price INTEGER NOT NULL,
    exchange_price INTEGER,
    new_bottle_price INTEGER,
    deposit_amount INTEGER,

    quantity_available INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_gas_products_provider ON gas_products(provider_id);
CREATE INDEX idx_gas_products_brand ON gas_products(brand);

CREATE TRIGGER update_gas_products_updated_at
    BEFORE UPDATE ON gas_products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: orders
-- =============================================================================

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(20) NOT NULL UNIQUE DEFAULT generate_reference('ORD'),

    -- Acteurs (références externes)
    user_id UUID NOT NULL,                          -- auth.users
    provider_id UUID NOT NULL REFERENCES providers(id),

    service_type VARCHAR(20) NOT NULL,

    -- Statut
    status order_status NOT NULL DEFAULT 'pending',
    status_updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Adresse
    delivery_address_id UUID,                       -- users.addresses
    delivery_address_snapshot JSONB NOT NULL,

    -- Instructions
    special_instructions TEXT,
    delivery_instructions TEXT,

    -- Montants
    subtotal INTEGER NOT NULL,
    delivery_fee INTEGER NOT NULL DEFAULT 0,
    service_fee INTEGER DEFAULT 0,
    discount_amount INTEGER DEFAULT 0,
    tip_amount INTEGER DEFAULT 0,
    total INTEGER NOT NULL,

    -- Promotion
    promotion_id UUID,
    promotion_code VARCHAR(50),

    -- Paiement
    payment_method payment_method NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending',
    paid_at TIMESTAMPTZ,
    transaction_id UUID,                            -- payments.transactions

    -- Planification
    is_scheduled BOOLEAN DEFAULT false,
    scheduled_for TIMESTAMPTZ,

    -- Commande groupée
    is_group_order BOOLEAN DEFAULT false,
    group_order_id UUID,

    -- Timing
    estimated_prep_time INTEGER,
    estimated_delivery_time INTEGER,
    actual_prep_time INTEGER,
    actual_delivery_time INTEGER,

    -- Dates clés
    confirmed_at TIMESTAMPTZ,
    ready_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    cancelled_by VARCHAR(20),

    -- Évaluation
    is_rated BOOLEAN DEFAULT false,
    provider_rating SMALLINT,
    driver_rating SMALLINT,

    -- Métadonnées
    source VARCHAR(20) DEFAULT 'app',
    device_type VARCHAR(20),
    app_version VARCHAR(20),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_provider ON orders(provider_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_reference ON orders(reference);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_scheduled ON orders(scheduled_for) WHERE is_scheduled = true;
CREATE INDEX idx_orders_pending ON orders(provider_id, status)
    WHERE status IN ('pending', 'confirmed', 'preparing');

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: order_items
-- =============================================================================

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    gas_product_id UUID REFERENCES gas_products(id) ON DELETE SET NULL,

    product_name VARCHAR(200) NOT NULL,
    product_description TEXT,
    product_image_url TEXT,

    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price INTEGER NOT NULL,
    total_price INTEGER NOT NULL,

    selected_options JSONB DEFAULT '[]'::jsonb,
    special_instructions TEXT,
    is_exchange BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- =============================================================================
-- TABLE: order_status_history
-- =============================================================================

CREATE TABLE order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,

    from_status order_status,
    to_status order_status NOT NULL,
    changed_by UUID,
    changed_by_type VARCHAR(20),
    reason TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_status_history_order ON order_status_history(order_id);
CREATE INDEX idx_status_history_created ON order_status_history(created_at);

-- =============================================================================
-- TABLE: ratings
-- =============================================================================

CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,                          -- auth.users

    rating_type VARCHAR(20) NOT NULL,
    provider_id UUID REFERENCES providers(id),
    driver_id UUID,                                 -- deliveries.drivers
    product_id UUID REFERENCES products(id),

    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    tags TEXT[] DEFAULT '{}',

    is_visible BOOLEAN DEFAULT true,
    is_flagged BOOLEAN DEFAULT false,
    flagged_reason TEXT,
    moderated_by UUID,
    moderated_at TIMESTAMPTZ,

    provider_response TEXT,
    response_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ratings_order ON ratings(order_id);
CREATE INDEX idx_ratings_provider ON ratings(provider_id);
CREATE INDEX idx_ratings_user ON ratings(user_id);
CREATE INDEX idx_ratings_type ON ratings(rating_type);
CREATE INDEX idx_ratings_flagged ON ratings(is_flagged) WHERE is_flagged = true;

CREATE TRIGGER update_ratings_updated_at
    BEFORE UPDATE ON ratings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: promotions
-- =============================================================================

CREATE TABLE promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    code VARCHAR(50) UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,

    type VARCHAR(20) NOT NULL,
    discount_value INTEGER NOT NULL,
    max_discount INTEGER,

    min_order_amount INTEGER DEFAULT 0,
    max_uses INTEGER,
    max_uses_per_user INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,

    applies_to VARCHAR(20) DEFAULT 'all',
    applicable_ids UUID[] DEFAULT '{}',

    target_users UUID[] DEFAULT '{}',
    target_cities UUID[] DEFAULT '{}',
    new_users_only BOOLEAN DEFAULT false,
    first_order_only BOOLEAN DEFAULT false,

    starts_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,

    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_promotions_code ON promotions(code);
CREATE INDEX idx_promotions_active ON promotions(is_active, starts_at, ends_at);

CREATE TRIGGER update_promotions_updated_at
    BEFORE UPDATE ON promotions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: user_promotions
-- =============================================================================

CREATE TABLE user_promotions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,                          -- auth.users
    promotion_id UUID NOT NULL REFERENCES promotions(id),
    order_id UUID REFERENCES orders(id),

    discount_applied INTEGER NOT NULL,
    used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, promotion_id, order_id)
);

CREATE INDEX idx_user_promotions_user ON user_promotions(user_id);
CREATE INDEX idx_user_promotions_promo ON user_promotions(promotion_id);

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
