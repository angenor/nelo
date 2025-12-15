-- =============================================================================
-- NELO - Notifications Service Database
-- =============================================================================
-- Base de données: nelo_notifications
-- Service: notification-service + chat-service (Fastify / Node.js)
-- Responsabilité: Push notifications, SMS, email, chat en temps réel
-- =============================================================================

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TYPES ENUM
-- =============================================================================

CREATE TYPE notification_type AS ENUM (
    'order_update',
    'delivery_update',
    'payment',
    'promotion',
    'system',
    'chat'
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
-- TABLE: push_tokens
-- =============================================================================

CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,                          -- Référence externe (auth.users)

    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL,

    device_id VARCHAR(255),
    device_name VARCHAR(100),
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(20),

    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    invalid_since TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(user_id, token)
);

CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON push_tokens(user_id, is_active) WHERE is_active = true;
CREATE INDEX idx_push_tokens_token ON push_tokens(token);

CREATE TRIGGER update_push_tokens_updated_at
    BEFORE UPDATE ON push_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: notifications
-- =============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,

    type notification_type NOT NULL,
    category VARCHAR(50),

    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    image_url TEXT,

    action_type VARCHAR(50),
    action_data JSONB DEFAULT '{}'::jsonb,

    order_id UUID,                                  -- Référence externe (orders.orders)
    delivery_id UUID,                               -- Référence externe (deliveries.deliveries)
    conversation_id UUID,

    channels TEXT[] DEFAULT '{push}',

    push_sent BOOLEAN DEFAULT false,
    push_sent_at TIMESTAMPTZ,
    push_error TEXT,

    sms_sent BOOLEAN DEFAULT false,
    sms_sent_at TIMESTAMPTZ,
    sms_error TEXT,

    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMPTZ,
    email_error TEXT,

    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMPTZ,

    scheduled_for TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_order ON notifications(order_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_for) WHERE scheduled_for IS NOT NULL;

-- =============================================================================
-- TABLE: notification_templates
-- =============================================================================

CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,

    type notification_type NOT NULL,
    category VARCHAR(50),

    title_fr VARCHAR(200) NOT NULL,
    body_fr TEXT NOT NULL,
    title_en VARCHAR(200),
    body_en TEXT,

    default_channels TEXT[] DEFAULT '{push}',
    variables TEXT[] DEFAULT '{}',

    action_type VARCHAR(50),
    action_template JSONB DEFAULT '{}'::jsonb,

    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_templates_code ON notification_templates(code);

CREATE TRIGGER update_notification_templates_updated_at
    BEFORE UPDATE ON notification_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: sms_logs
-- =============================================================================

CREATE TABLE sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID REFERENCES notifications(id),

    phone_number VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    message_length INTEGER,

    provider VARCHAR(50) NOT NULL,
    provider_message_id VARCHAR(100),

    status VARCHAR(20) DEFAULT 'pending',
    status_updated_at TIMESTAMPTZ,
    error_code VARCHAR(50),
    error_message TEXT,

    cost_units INTEGER,
    cost_amount DECIMAL(10, 4),
    currency CHAR(3) DEFAULT 'XOF',

    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sms_logs_notification ON sms_logs(notification_id);
CREATE INDEX idx_sms_logs_phone ON sms_logs(phone_number);
CREATE INDEX idx_sms_logs_status ON sms_logs(status);
CREATE INDEX idx_sms_logs_created ON sms_logs(created_at);

-- =============================================================================
-- TABLE: email_logs
-- =============================================================================

CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID REFERENCES notifications(id),

    to_email VARCHAR(255) NOT NULL,
    to_name VARCHAR(200),

    subject VARCHAR(500) NOT NULL,
    body_html TEXT,
    body_text TEXT,
    template_id VARCHAR(100),

    provider VARCHAR(50) NOT NULL,
    provider_message_id VARCHAR(100),

    status VARCHAR(20) DEFAULT 'pending',
    status_updated_at TIMESTAMPTZ,
    error_message TEXT,

    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    bounced_at TIMESTAMPTZ,

    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_email_logs_notification ON email_logs(notification_id);
CREATE INDEX idx_email_logs_email ON email_logs(to_email);
CREATE INDEX idx_email_logs_status ON email_logs(status);

-- =============================================================================
-- TABLE: conversations
-- =============================================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    type VARCHAR(20) NOT NULL,

    participant_1_id UUID NOT NULL,
    participant_1_type VARCHAR(20) NOT NULL,
    participant_2_id UUID NOT NULL,
    participant_2_type VARCHAR(20) NOT NULL,

    order_id UUID,                                  -- Référence externe
    delivery_id UUID,                               -- Référence externe

    last_message_id UUID,
    last_message_at TIMESTAMPTZ,
    last_message_preview VARCHAR(200),

    unread_count_1 INTEGER DEFAULT 0,
    unread_count_2 INTEGER DEFAULT 0,

    status VARCHAR(20) DEFAULT 'active',
    closed_at TIMESTAMPTZ,
    closed_reason TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conversations_participant_1 ON conversations(participant_1_id, participant_1_type);
CREATE INDEX idx_conversations_participant_2 ON conversations(participant_2_id, participant_2_type);
CREATE INDEX idx_conversations_order ON conversations(order_id);
CREATE INDEX idx_conversations_status ON conversations(status);
CREATE INDEX idx_conversations_updated ON conversations(updated_at DESC);

CREATE TRIGGER update_conversations_updated_at
    BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: messages
-- =============================================================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,

    sender_id UUID NOT NULL,
    sender_type VARCHAR(20) NOT NULL,

    content TEXT,
    message_type VARCHAR(20) DEFAULT 'text',

    media_url TEXT,
    media_type VARCHAR(50),
    media_size INTEGER,
    thumbnail_url TEXT,

    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    reply_to_id UUID REFERENCES messages(id),

    status VARCHAR(20) DEFAULT 'sent',
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,

    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID,

    is_flagged BOOLEAN DEFAULT false,
    flagged_at TIMESTAMPTZ,
    flagged_reason TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_status ON messages(conversation_id, status);

-- =============================================================================
-- TABLE: message_reactions
-- =============================================================================

CREATE TABLE message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,

    reaction VARCHAR(20) NOT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(message_id, user_id)
);

CREATE INDEX idx_reactions_message ON message_reactions(message_id);

-- =============================================================================
-- TABLE: presence
-- =============================================================================

CREATE TABLE presence (
    user_id UUID PRIMARY KEY,

    status VARCHAR(20) DEFAULT 'offline',
    last_seen_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    active_conversation_id UUID REFERENCES conversations(id),

    device_id VARCHAR(255),
    platform VARCHAR(20),

    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_presence_status ON presence(status);
CREATE INDEX idx_presence_conversation ON presence(active_conversation_id);

-- =============================================================================
-- TABLE: campaigns
-- =============================================================================

CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    name VARCHAR(200) NOT NULL,
    description TEXT,

    type VARCHAR(20) NOT NULL,
    template_id UUID REFERENCES notification_templates(id),

    title VARCHAR(200),
    body TEXT,
    image_url TEXT,
    action_type VARCHAR(50),
    action_data JSONB DEFAULT '{}'::jsonb,

    target_audience JSONB DEFAULT '{}'::jsonb,
    target_user_ids UUID[] DEFAULT '{}',
    estimated_reach INTEGER,

    status VARCHAR(20) DEFAULT 'draft',
    scheduled_for TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    total_sent INTEGER DEFAULT 0,
    total_delivered INTEGER DEFAULT 0,
    total_opened INTEGER DEFAULT 0,
    total_clicked INTEGER DEFAULT 0,
    total_failed INTEGER DEFAULT 0,

    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_scheduled ON campaigns(scheduled_for) WHERE status = 'scheduled';

CREATE TRIGGER update_campaigns_updated_at
    BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: campaign_sends
-- =============================================================================

CREATE TABLE campaign_sends (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    notification_id UUID REFERENCES notifications(id),

    status VARCHAR(20) DEFAULT 'pending',
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    error_message TEXT,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_campaign_sends_campaign ON campaign_sends(campaign_id);
CREATE INDEX idx_campaign_sends_user ON campaign_sends(user_id);
CREATE INDEX idx_campaign_sends_status ON campaign_sends(status);

-- =============================================================================
-- DONNÉES INITIALES: Templates de notification
-- =============================================================================

INSERT INTO notification_templates (code, name, type, category, title_fr, body_fr, title_en, body_en, variables, default_channels)
VALUES
    ('order_confirmed', 'Commande confirmée', 'order_update', 'order',
     'Commande confirmée', 'Votre commande {order_reference} a été confirmée par {provider_name}.',
     'Order confirmed', 'Your order {order_reference} has been confirmed by {provider_name}.',
     '{order_reference, provider_name}', '{push}'),

    ('order_preparing', 'Commande en préparation', 'order_update', 'order',
     'En préparation', '{provider_name} prépare votre commande. Temps estimé: {prep_time} min.',
     'Being prepared', '{provider_name} is preparing your order. Estimated time: {prep_time} min.',
     '{provider_name, prep_time}', '{push}'),

    ('driver_assigned', 'Livreur assigné', 'delivery_update', 'delivery',
     'Livreur en route', '{driver_name} arrive dans environ {eta} minutes.',
     'Driver on the way', '{driver_name} will arrive in about {eta} minutes.',
     '{driver_name, eta}', '{push}'),

    ('order_picked_up', 'Commande récupérée', 'delivery_update', 'delivery',
     'En route vers vous', '{driver_name} a récupéré votre commande et arrive dans {eta} minutes.',
     'On the way', '{driver_name} has picked up your order and will arrive in {eta} minutes.',
     '{driver_name, eta}', '{push}'),

    ('order_delivered', 'Commande livrée', 'delivery_update', 'delivery',
     'Commande livrée!', 'Votre commande {order_reference} a été livrée. Bon appétit!',
     'Order delivered!', 'Your order {order_reference} has been delivered. Enjoy!',
     '{order_reference}', '{push}'),

    ('payment_received', 'Paiement reçu', 'payment', 'payment',
     'Paiement confirmé', 'Votre paiement de {amount} XOF a été reçu.',
     'Payment confirmed', 'Your payment of {amount} XOF has been received.',
     '{amount}', '{push}'),

    ('wallet_topup', 'Rechargement wallet', 'payment', 'payment',
     'Rechargement effectué', 'Votre portefeuille a été crédité de {amount} XOF. Nouveau solde: {balance} XOF.',
     'Top-up completed', 'Your wallet has been credited with {amount} XOF. New balance: {balance} XOF.',
     '{amount, balance}', '{push}'),

    ('new_message', 'Nouveau message', 'chat', 'chat',
     'Nouveau message', '{sender_name}: {message_preview}',
     'New message', '{sender_name}: {message_preview}',
     '{sender_name, message_preview}', '{push}')

ON CONFLICT (code) DO NOTHING;
