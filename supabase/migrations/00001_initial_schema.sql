-- AI Ad Agency System - Initial Schema
-- Migration: 00001_initial_schema
-- Description: Creates all core tables for the multi-agent ad management system

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE ad_platform AS ENUM ('meta', 'tiktok');
CREATE TYPE campaign_status AS ENUM ('ACTIVE', 'PAUSED', 'ARCHIVED', 'DELETED');
CREATE TYPE campaign_objective AS ENUM (
  'OUTCOME_AWARENESS',
  'OUTCOME_ENGAGEMENT',
  'OUTCOME_LEADS',
  'OUTCOME_SALES',
  'OUTCOME_TRAFFIC'
);
CREATE TYPE creative_format AS ENUM ('image', 'video', 'carousel');
CREATE TYPE approval_status AS ENUM ('pending', 'approved', 'rejected', 'revision_requested');
CREATE TYPE agent_type AS ENUM (
  'market-intelligence',
  'performance-testing',
  'creative',
  'campaign-execution',
  'orchestrator'
);
CREATE TYPE agent_status AS ENUM ('idle', 'running', 'paused', 'error', 'completed');

-- ============================================================================
-- TABLE: ad_accounts
-- ============================================================================

CREATE TABLE ad_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  platform ad_platform NOT NULL,
  account_id TEXT NOT NULL,
  account_name TEXT NOT NULL,
  access_token TEXT, -- Encrypted at rest by Supabase
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  daily_budget_limit DECIMAL(10, 2) DEFAULT 50.00,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(platform, account_id)
);

-- ============================================================================
-- TABLE: campaigns
-- ============================================================================

CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_account_id UUID NOT NULL REFERENCES ad_accounts(id) ON DELETE CASCADE,
  platform ad_platform NOT NULL,
  platform_campaign_id TEXT, -- ID from Meta/TikTok
  name TEXT NOT NULL,
  objective campaign_objective NOT NULL,
  status campaign_status DEFAULT 'PAUSED',
  daily_budget DECIMAL(10, 2) NOT NULL,
  lifetime_budget DECIMAL(10, 2),
  start_date DATE NOT NULL,
  end_date DATE,
  target_audience JSONB NOT NULL DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_by_agent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campaigns_ad_account ON campaigns(ad_account_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_platform ON campaigns(platform);

-- ============================================================================
-- TABLE: ad_sets
-- ============================================================================

CREATE TABLE ad_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  platform_ad_set_id TEXT,
  name TEXT NOT NULL,
  status campaign_status DEFAULT 'PAUSED',
  daily_budget DECIMAL(10, 2),
  bid_amount DECIMAL(10, 2),
  bid_strategy TEXT,
  targeting JSONB NOT NULL DEFAULT '{}',
  placements JSONB DEFAULT '{}',
  optimization_goal TEXT,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ad_sets_campaign ON ad_sets(campaign_id);
CREATE INDEX idx_ad_sets_status ON ad_sets(status);

-- ============================================================================
-- TABLE: creatives
-- ============================================================================

CREATE TABLE creatives (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_account_id UUID NOT NULL REFERENCES ad_accounts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  format creative_format NOT NULL,
  headline TEXT,
  primary_text TEXT,
  description TEXT,
  call_to_action TEXT,
  media_urls JSONB DEFAULT '[]', -- Array of URLs
  thumbnail_url TEXT,
  platform_creative_id TEXT,
  approval_status approval_status DEFAULT 'pending',
  validation_score DECIMAL(3, 1), -- 0-10 score from Creative Agent
  validation_feedback TEXT,
  metadata JSONB DEFAULT '{}',
  created_by_agent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_creatives_ad_account ON creatives(ad_account_id);
CREATE INDEX idx_creatives_approval ON creatives(approval_status);
CREATE INDEX idx_creatives_format ON creatives(format);

-- ============================================================================
-- TABLE: ads
-- ============================================================================

CREATE TABLE ads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_set_id UUID NOT NULL REFERENCES ad_sets(id) ON DELETE CASCADE,
  creative_id UUID NOT NULL REFERENCES creatives(id),
  platform_ad_id TEXT,
  name TEXT NOT NULL,
  status campaign_status DEFAULT 'PAUSED',
  tracking_url TEXT,
  utm_parameters JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ads_ad_set ON ads(ad_set_id);
CREATE INDEX idx_ads_creative ON ads(creative_id);
CREATE INDEX idx_ads_status ON ads(status);

-- ============================================================================
-- TABLE: creative_concepts
-- ============================================================================

CREATE TABLE creative_concepts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_account_id UUID NOT NULL REFERENCES ad_accounts(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  hook TEXT, -- Opening hook for video
  value_proposition TEXT,
  call_to_action TEXT,
  visual_style TEXT,
  target_emotion TEXT,
  video_prompt TEXT, -- For Veo 3/Sora 2
  copy_variations JSONB DEFAULT '[]',
  thumbnail_concept TEXT,
  validation_score DECIMAL(3, 1),
  validation_notes TEXT,
  status approval_status DEFAULT 'pending',
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_by_agent BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_creative_concepts_ad_account ON creative_concepts(ad_account_id);
CREATE INDEX idx_creative_concepts_status ON creative_concepts(status);

-- ============================================================================
-- TABLE: market_insights
-- ============================================================================

CREATE TABLE market_insights (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_account_id UUID NOT NULL REFERENCES ad_accounts(id) ON DELETE CASCADE,
  source TEXT NOT NULL, -- 'meta_ad_library', 'tiktok_creative_center', etc.
  insight_type TEXT NOT NULL, -- 'competitor_ad', 'trend', 'pattern'
  title TEXT NOT NULL,
  description TEXT,
  data JSONB NOT NULL DEFAULT '{}', -- Structured insight data
  competitors TEXT[], -- Array of competitor names
  keywords TEXT[],
  relevance_score DECIMAL(3, 2), -- 0-1 score
  embedding vector(1536), -- For semantic search
  metadata JSONB DEFAULT '{}',
  expires_at TIMESTAMPTZ, -- When insight becomes stale
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_market_insights_ad_account ON market_insights(ad_account_id);
CREATE INDEX idx_market_insights_type ON market_insights(insight_type);
CREATE INDEX idx_market_insights_source ON market_insights(source);

-- ============================================================================
-- TABLE: learnings
-- ============================================================================

CREATE TABLE learnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ad_account_id UUID NOT NULL REFERENCES ad_accounts(id) ON DELETE CASCADE,
  category TEXT NOT NULL, -- 'creative', 'targeting', 'bidding', 'timing'
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  evidence JSONB NOT NULL DEFAULT '{}', -- Data supporting the learning
  confidence_score DECIMAL(3, 2), -- 0-1 confidence
  statistical_significance DECIMAL(5, 4), -- p-value
  sample_size INTEGER,
  effect_size DECIMAL(5, 4),
  applicable_to JSONB DEFAULT '{}', -- Conditions where this applies
  embedding vector(1536), -- For semantic search
  metadata JSONB DEFAULT '{}',
  created_by_agent agent_type,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_learnings_ad_account ON learnings(ad_account_id);
CREATE INDEX idx_learnings_category ON learnings(category);

-- ============================================================================
-- TABLE: agent_runs
-- ============================================================================

CREATE TABLE agent_runs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_type agent_type NOT NULL,
  status agent_status NOT NULL DEFAULT 'idle',
  task_description TEXT,
  input_data JSONB DEFAULT '{}',
  output_data JSONB DEFAULT '{}',
  tools_used TEXT[],
  tokens_used INTEGER DEFAULT 0,
  cost_estimate DECIMAL(10, 4),
  error_message TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  parent_run_id UUID REFERENCES agent_runs(id), -- For orchestrated runs
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_agent_runs_type ON agent_runs(agent_type);
CREATE INDEX idx_agent_runs_status ON agent_runs(status);
CREATE INDEX idx_agent_runs_started ON agent_runs(started_at);

-- ============================================================================
-- TABLE: approvals
-- ============================================================================

CREATE TABLE approvals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type TEXT NOT NULL, -- 'creative', 'campaign', 'budget_change'
  entity_id UUID NOT NULL,
  requested_by agent_type,
  request_reason TEXT,
  request_data JSONB DEFAULT '{}',
  status approval_status DEFAULT 'pending',
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT,
  auto_approved BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_approvals_entity ON approvals(entity_type, entity_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_pending ON approvals(status) WHERE status = 'pending';

-- ============================================================================
-- TABLE: daily_metrics
-- ============================================================================

CREATE TABLE daily_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_type TEXT NOT NULL, -- 'campaign', 'ad_set', 'ad', 'creative'
  entity_id UUID NOT NULL,
  date DATE NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  spend DECIMAL(10, 2) DEFAULT 0,
  revenue DECIMAL(10, 2) DEFAULT 0,
  ctr DECIMAL(7, 4), -- Click-through rate
  cpc DECIMAL(10, 2), -- Cost per click
  cpm DECIMAL(10, 2), -- Cost per mille
  cpa DECIMAL(10, 2), -- Cost per acquisition
  roas DECIMAL(10, 4), -- Return on ad spend
  frequency DECIMAL(5, 2),
  reach INTEGER DEFAULT 0,
  video_views INTEGER DEFAULT 0,
  video_view_rate DECIMAL(5, 4),
  engagement_rate DECIMAL(5, 4),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(entity_type, entity_id, date)
);

CREATE INDEX idx_daily_metrics_entity ON daily_metrics(entity_type, entity_id);
CREATE INDEX idx_daily_metrics_date ON daily_metrics(date);

-- ============================================================================
-- TABLE: safety_logs
-- ============================================================================

CREATE TABLE safety_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL, -- 'budget_cap_hit', 'auto_pause', 'manual_override'
  severity TEXT NOT NULL, -- 'info', 'warning', 'critical'
  entity_type TEXT,
  entity_id UUID,
  description TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  action_taken TEXT,
  agent_type agent_type,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_safety_logs_type ON safety_logs(event_type);
CREATE INDEX idx_safety_logs_severity ON safety_logs(severity);
CREATE INDEX idx_safety_logs_created ON safety_logs(created_at);

-- ============================================================================
-- TABLE: settings
-- ============================================================================

CREATE TABLE settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, key)
);

CREATE INDEX idx_settings_user ON settings(user_id);

-- ============================================================================
-- TRIGGERS: Updated at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_ad_accounts_updated_at BEFORE UPDATE ON ad_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ad_sets_updated_at BEFORE UPDATE ON ad_sets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_creatives_updated_at BEFORE UPDATE ON creatives
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ads_updated_at BEFORE UPDATE ON ads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_creative_concepts_updated_at BEFORE UPDATE ON creative_concepts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learnings_updated_at BEFORE UPDATE ON learnings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_approvals_updated_at BEFORE UPDATE ON approvals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE ad_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE ad_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE creatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE creative_concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE learnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Ad Accounts: Users can only see their own
CREATE POLICY "Users can view own ad accounts" ON ad_accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own ad accounts" ON ad_accounts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own ad accounts" ON ad_accounts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own ad accounts" ON ad_accounts
  FOR DELETE USING (auth.uid() = user_id);

-- Campaigns: Users can access campaigns in their ad accounts
CREATE POLICY "Users can view campaigns in own ad accounts" ON campaigns
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM ad_accounts
      WHERE ad_accounts.id = campaigns.ad_account_id
      AND ad_accounts.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert campaigns in own ad accounts" ON campaigns
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM ad_accounts
      WHERE ad_accounts.id = campaigns.ad_account_id
      AND ad_accounts.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update campaigns in own ad accounts" ON campaigns
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM ad_accounts
      WHERE ad_accounts.id = campaigns.ad_account_id
      AND ad_accounts.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete campaigns in own ad accounts" ON campaigns
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM ad_accounts
      WHERE ad_accounts.id = campaigns.ad_account_id
      AND ad_accounts.user_id = auth.uid()
    )
  );

-- Settings: Users can only see their own
CREATE POLICY "Users can view own settings" ON settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings" ON settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" ON settings
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own settings" ON settings
  FOR DELETE USING (auth.uid() = user_id);

-- Service role bypass for agents (server-side operations)
-- Note: Service role key bypasses RLS by default

COMMENT ON TABLE ad_accounts IS 'Connected advertising platform accounts';
COMMENT ON TABLE campaigns IS 'Advertising campaigns across platforms';
COMMENT ON TABLE ad_sets IS 'Ad sets/groups within campaigns';
COMMENT ON TABLE ads IS 'Individual advertisements';
COMMENT ON TABLE creatives IS 'Ad creative assets (images, videos)';
COMMENT ON TABLE creative_concepts IS 'AI-generated creative concepts awaiting production';
COMMENT ON TABLE market_insights IS 'Competitive intelligence and market trends';
COMMENT ON TABLE learnings IS 'Validated insights from performance analysis';
COMMENT ON TABLE agent_runs IS 'Audit log of AI agent executions';
COMMENT ON TABLE approvals IS 'Human approval workflow for agent actions';
COMMENT ON TABLE daily_metrics IS 'Aggregated daily performance metrics';
COMMENT ON TABLE safety_logs IS 'Safety and budget control events';
COMMENT ON TABLE settings IS 'User preferences and configuration';
