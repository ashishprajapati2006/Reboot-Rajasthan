-- SAAF-SURKSHA Database Schema
-- PostgreSQL with PostGIS Extension

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('CITIZEN', 'WORKER', 'AUTHORITY', 'ADMIN')),
    is_verified BOOLEAN DEFAULT FALSE,
    two_fa_enabled BOOLEAN DEFAULT FALSE,
    two_fa_secret VARCHAR(255),
    profile_image_url TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100) DEFAULT 'Rajasthan',
    pincode VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Worker profile table
CREATE TABLE worker_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    worker_type VARCHAR(50) NOT NULL CHECK (worker_type IN ('POTHOLE_REPAIR', 'SANITATION', 'ELECTRICIAN', 'GENERAL')),
    government_id VARCHAR(50) UNIQUE NOT NULL,
    department VARCHAR(100),
    designation VARCHAR(100),
    experience_years INTEGER,
    performance_score DECIMAL(5,2) DEFAULT 0.0,
    tasks_completed INTEGER DEFAULT 0,
    tasks_pending INTEGER DEFAULT 0,
    average_completion_time INTEGER, -- in hours
    citizen_rating DECIMAL(3,2) DEFAULT 0.0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Issues/Complaints table
CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_type VARCHAR(50) NOT NULL CHECK (issue_type IN (
        'POTHOLE', 'STREETLIGHT_FAILURE', 'ANIMAL_CARCASS', 
        'WASTE_ACCUMULATION', 'TOILET_UNCLEAN', 'STAFF_ABSENT'
    )),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(50) NOT NULL DEFAULT 'OPEN' CHECK (status IN (
        'OPEN', 'ASSIGNED', 'IN_PROGRESS', 'VERIFICATION_PENDING', 
        'COMMUNITY_VOTING', 'RESOLVED', 'REJECTED', 'ESCALATED'
    )),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT,
    landmark VARCHAR(255),
    
    -- Reporter information
    reported_by UUID REFERENCES users(id),
    device_id VARCHAR(255),
    
    -- Media
    image_url TEXT NOT NULL,
    before_image_url TEXT,
    after_image_url TEXT,
    
    -- AI Detection
    ai_confidence DECIMAL(5,3),
    ai_detected_type VARCHAR(50),
    area_percentage DECIMAL(5,2),
    fraud_risk_score DECIMAL(3,2),
    
    -- Timestamps
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_at TIMESTAMP,
    resolved_at TIMESTAMP,
    
    -- Escalation
    escalation_level INTEGER DEFAULT 0,
    escalated_at TIMESTAMP,
    rti_filed BOOLEAN DEFAULT FALSE,
    social_media_escalated BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    views INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial index on location
CREATE INDEX idx_issues_location ON issues USING GIST(location);
CREATE INDEX idx_issues_status ON issues(status);
CREATE INDEX idx_issues_type ON issues(issue_type);
CREATE INDEX idx_issues_severity ON issues(severity);

-- Tasks table
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID REFERENCES issues(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES users(id),
    task_status VARCHAR(50) NOT NULL DEFAULT 'PENDING' CHECK (task_status IN (
        'PENDING', 'ACCEPTED', 'WORKER_EN_ROUTE', 'AT_LOCATION', 
        'IN_PROGRESS', 'COMPLETED', 'VERIFIED', 'REJECTED'
    )),
    
    -- Geofence verification
    geofence_entered BOOLEAN DEFAULT FALSE,
    geofence_entry_time TIMESTAMP,
    geofence_exit_time TIMESTAMP,
    time_spent_minutes INTEGER,
    
    -- Completion verification
    completion_photo_url TEXT,
    ai_verification_score DECIMAL(5,3),
    ai_verification_status VARCHAR(50),
    
    -- Community voting
    community_votes_approve INTEGER DEFAULT 0,
    community_votes_reject INTEGER DEFAULT 0,
    community_voting_closed BOOLEAN DEFAULT FALSE,
    
    -- Deadlines
    deadline TIMESTAMP,
    sla_breach BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    verified_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_issue ON tasks(issue_id);
CREATE INDEX idx_tasks_worker ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(task_status);

-- Geofences table
CREATE TABLE geofences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    geofence_type VARCHAR(50) CHECK (geofence_type IN ('WARD', 'ZONE', 'CUSTOM')),
    geometry GEOGRAPHY(POLYGON, 4326) NOT NULL,
    center_point GEOGRAPHY(POINT, 4326),
    radius_meters INTEGER,
    metadata JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_geofences_geometry ON geofences USING GIST(geometry);

-- Worker location tracking
CREATE TABLE worker_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID REFERENCES users(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    accuracy DECIMAL(6,2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_within_geofence BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_worker_locations_worker ON worker_locations(worker_id);
CREATE INDEX idx_worker_locations_task ON worker_locations(task_id);
CREATE INDEX idx_worker_locations_location ON worker_locations USING GIST(location);

-- Community voting
CREATE TABLE community_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    voter_id UUID REFERENCES users(id),
    vote VARCHAR(10) NOT NULL CHECK (vote IN ('APPROVE', 'REJECT')),
    comment TEXT,
    voted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(task_id, voter_id)
);

CREATE INDEX idx_votes_task ON community_votes(task_id);

-- RTI (Right to Information) tracking
CREATE TABLE rti_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID REFERENCES issues(id) ON DELETE CASCADE,
    complaint_id VARCHAR(50) UNIQUE NOT NULL,
    rti_content TEXT NOT NULL,
    authority_name VARCHAR(255),
    authority_email VARCHAR(255),
    authority_address TEXT,
    
    status VARCHAR(50) DEFAULT 'DRAFT' CHECK (status IN (
        'DRAFT', 'FILED', 'ACKNOWLEDGED', 'RESPONSE_RECEIVED', 'CLOSED'
    )),
    
    filed_at TIMESTAMP,
    response_deadline TIMESTAMP,
    response_received_at TIMESTAMP,
    response_content TEXT,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rti_issue ON rti_requests(issue_id);

-- Social media escalations
CREATE TABLE social_escalations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID REFERENCES issues(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('TWITTER', 'FACEBOOK', 'INSTAGRAM')),
    post_id VARCHAR(255),
    post_url TEXT,
    post_content TEXT,
    hashtags TEXT[],
    
    impressions INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    
    posted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_social_issue ON social_escalations(issue_id);

-- Analytics - Civic health metrics
CREATE TABLE civic_health_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    region_name VARCHAR(255) NOT NULL,
    region_geometry GEOGRAPHY(POLYGON, 4326),
    
    calculation_date DATE NOT NULL,
    
    -- Metrics
    total_issues INTEGER DEFAULT 0,
    resolved_issues INTEGER DEFAULT 0,
    resolution_rate DECIMAL(5,2),
    average_resolution_time INTEGER, -- hours
    
    severity_distribution JSONB,
    issue_type_distribution JSONB,
    
    civic_health_score DECIMAL(5,2), -- 0-100
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(region_name, calculation_date)
);

CREATE INDEX idx_civic_health_region ON civic_health_metrics(region_name);
CREATE INDEX idx_civic_health_date ON civic_health_metrics(calculation_date);

-- B2B API provisioning
CREATE TABLE api_customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) UNIQUE NOT NULL,
    contact_phone VARCHAR(20),
    api_key VARCHAR(255) UNIQUE NOT NULL,
    api_secret_hash VARCHAR(255) NOT NULL,
    
    subscription_tier VARCHAR(50) CHECK (subscription_tier IN ('FREE', 'BASIC', 'PREMIUM', 'ENTERPRISE')),
    rate_limit INTEGER DEFAULT 100, -- requests per hour
    
    allowed_data_types TEXT[], -- ['HEATMAP', 'CIVIC_HEALTH', 'RISK_ASSESSMENT']
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- API usage logs
CREATE TABLE api_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES api_customers(id),
    endpoint VARCHAR(255),
    request_count INTEGER DEFAULT 1,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_usage_customer ON api_usage_logs(customer_id);
CREATE INDEX idx_api_usage_timestamp ON api_usage_logs(timestamp);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- Update triggers for updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_issues_updated_at BEFORE UPDATE ON issues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_worker_profiles_updated_at BEFORE UPDATE ON worker_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data
INSERT INTO users (id, phone_number, email, full_name, password_hash, role, is_verified) VALUES
('550e8400-e29b-41d4-a716-446655440001', '+919876543210', 'admin@saaf-surksha.gov.in', 'System Admin', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lWvDWRy4AO5i', 'ADMIN', true),
('550e8400-e29b-41d4-a716-446655440002', '+919876543211', 'citizen@example.com', 'Test Citizen', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lWvDWRy4AO5i', 'CITIZEN', true),
('550e8400-e29b-41d4-a716-446655440003', '+919876543212', 'worker@example.com', 'Test Worker', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5lWvDWRy4AO5i', 'WORKER', true);

-- Create view for issue analytics
CREATE VIEW issue_analytics AS
SELECT 
    i.issue_type,
    i.severity,
    i.status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (i.resolved_at - i.reported_at))/3600) as avg_resolution_hours,
    AVG(i.ai_confidence) as avg_ai_confidence
FROM issues i
GROUP BY i.issue_type, i.severity, i.status;

COMMENT ON TABLE users IS 'User accounts for citizens, workers, and authorities';
COMMENT ON TABLE issues IS 'Civic issues reported by citizens';
COMMENT ON TABLE tasks IS 'Work assignments for addressing issues';
COMMENT ON TABLE geofences IS 'Geographic boundaries for location verification';
COMMENT ON TABLE rti_requests IS 'Right to Information requests for unresolved issues';
COMMENT ON TABLE civic_health_metrics IS 'Aggregated civic health scores by region';
