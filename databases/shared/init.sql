-- =============================================================================
-- NELO - Script d'initialisation des données de référence
-- =============================================================================
-- Tables géographiques partagées (à dupliquer dans chaque base qui en a besoin)
-- Services concernés: orders, deliveries, users
-- =============================================================================

-- Extension PostGIS pour la géolocalisation
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =============================================================================
-- Pays supportés
-- =============================================================================

CREATE TABLE IF NOT EXISTS countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    phone_code VARCHAR(5) NOT NULL,
    currency_code CHAR(3) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Villes
-- =============================================================================

CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_id UUID NOT NULL REFERENCES countries(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50) DEFAULT 'Africa/Abidjan',
    is_active BOOLEAN DEFAULT true,
    is_pilot BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(country_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_cities_country ON cities(country_id);
CREATE INDEX IF NOT EXISTS idx_cities_active ON cities(is_active) WHERE is_active = true;

-- =============================================================================
-- Zones de livraison
-- =============================================================================

CREATE TABLE IF NOT EXISTS zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city_id UUID NOT NULL REFERENCES cities(id),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    polygon GEOMETRY(POLYGON, 4326),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(city_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_zones_city ON zones(city_id);
CREATE INDEX IF NOT EXISTS idx_zones_polygon ON zones USING GIST (polygon);

-- =============================================================================
-- Données initiales
-- =============================================================================

-- Côte d'Ivoire
INSERT INTO countries (id, code, name, phone_code, currency_code)
VALUES ('550e8400-e29b-41d4-a716-446655440001', 'CI', 'Côte d''Ivoire', '+225', 'XOF')
ON CONFLICT (code) DO NOTHING;

-- Ville pilote: Tiassalé
INSERT INTO cities (id, country_id, name, slug, latitude, longitude, is_pilot)
VALUES (
    '550e8400-e29b-41d4-a716-446655440010',
    '550e8400-e29b-41d4-a716-446655440001',
    'Tiassalé',
    'tiassale',
    5.8983,
    -4.8228,
    true
)
ON CONFLICT (country_id, slug) DO NOTHING;

-- Abidjan (pour extension future)
INSERT INTO cities (id, country_id, name, slug, latitude, longitude, is_pilot)
VALUES (
    '550e8400-e29b-41d4-a716-446655440011',
    '550e8400-e29b-41d4-a716-446655440001',
    'Abidjan',
    'abidjan',
    5.3600,
    -4.0083,
    false
)
ON CONFLICT (country_id, slug) DO NOTHING;
