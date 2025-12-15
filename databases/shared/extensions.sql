-- =============================================================================
-- NELO - Extensions PostgreSQL Communes
-- =============================================================================
-- Ce fichier contient les extensions et fonctions utilitaires
-- À inclure au début de chaque schema.sql de service
-- =============================================================================

-- Extensions de base
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Full-text search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- =============================================================================
-- Fonction utilitaire: updated_at automatique
-- =============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Fonction utilitaire: génération de références uniques
-- =============================================================================

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
