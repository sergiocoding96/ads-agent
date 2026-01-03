# AI Ad Agency System - Complete Technical Specification for Claude Code

## Project Overview

Build a production-ready, multi-agent AI system that autonomously manages Facebook and TikTok advertising campaigns with integrated creative generation using Veo 3/Sora 2 video prompts.

**Core Value Proposition:**
- Autonomous ad campaign management (targeting, bidding, optimization)
- AI-generated video creative concepts (Veo 3/Sora 2 prompts)
- Competitive intelligence via web scraping
- Self-improving learning system
- Full-stack alternative to traditional ad agencies

**Target Users:**
- Internal use: Sergio + Arinze managing agency client campaigns
- Future: SaaS product for other agencies/businesses

---

## Tech Stack

### Frontend
- **Framework:** Next.js 14+ (App Router)
- **Language:** TypeScript (strict mode)
- **UI Library:** shadcn/ui + Tailwind CSS
- **State Management:** React Context + Server Actions
- **Charts:** Recharts or Tremor
- **Forms:** React Hook Form + Zod validation

### Backend
- **API Routes:** Next.js API routes + Server Actions
- **Database:** Supabase (PostgreSQL)
  - Row Level Security enabled
  - Real-time subscriptions for live updates
- **Authentication:** Supabase Auth
- **File Storage:** Supabase Storage (for generated videos/assets)

### AI & Agent Layer
- **Orchestration:** LangChain or custom TypeScript orchestrator
- **LLM Provider:** Anthropic Claude API (Sonnet 4)
- **Agent Pattern:** Tool-calling architecture
- **Vector Store:** Supabase pgvector (for learning database)

### External APIs
- **Meta Marketing API:** Campaign management, performance data
- **TikTok Ads API:** Campaign management, performance data
- **OpenAI Whisper API:** Video transcription
- **Veo 3 API:** Video generation (when available)
- **Sora 2 API:** Video generation (when available)
- **Scrapfly/Apify:** Web scraping for competitor intelligence

### DevOps
- **Hosting:** Vercel (frontend + API routes)
- **Database:** Supabase Cloud
- **Background Jobs:** Vercel Cron or Inngest
- **Monitoring:** Sentry (errors) + Vercel Analytics
- **Logging:** Custom logging to Supabase

### Development Tools
- **Package Manager:** pnpm
- **Code Quality:** ESLint + Prettier
- **Git Hooks:** Husky + lint-staged
- **Testing:** Vitest + Playwright (e2e)

---

## Project Structure

```
ad-agency-system/
├── .github/
│   └── workflows/
│       └── ci.yml
├── src/
│   ├── app/                          # Next.js 14 app directory
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   └── signup/
│   │   ├── (dashboard)/
│   │   │   ├── campaigns/
│   │   │   ├── creatives/
│   │   │   ├── insights/
│   │   │   └── settings/
│   │   ├── api/
│   │   │   ├── webhooks/
│   │   │   ├── cron/
│   │   │   └── agents/
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── agents/                       # Core agent implementations
│   │   ├── orchestrator.ts
│   │   ├── market-intelligence/
│   │   │   ├── agent.ts
│   │   │   ├── tools.ts
│   │   │   └── types.ts
│   │   ├── performance-testing/
│   │   │   ├── agent.ts
│   │   │   ├── tools.ts
│   │   │   └── types.ts
│   │   ├── creative/
│   │   │   ├── agent.ts
│   │   │   ├── tools.ts
│   │   │   └── types.ts
│   │   ├── campaign-execution/
│   │   │   ├── agent.ts
│   │   │   ├── tools.ts
│   │   │   └── types.ts
│   │   └── shared/
│   │       ├── base-agent.ts
│   │       ├── tools.ts
│   │       └── types.ts
│   ├── lib/                          # Shared utilities
│   │   ├── api/
│   │   │   ├── meta.ts              # Meta Marketing API client
│   │   │   ├── tiktok.ts            # TikTok Ads API client
│   │   │   ├── openai.ts            # OpenAI (Whisper) client
│   │   │   ├── scrapfly.ts          # Scrapfly client
│   │   │   └── anthropic.ts         # Claude API client
│   │   ├── db/
│   │   │   ├── client.ts            # Supabase client
│   │   │   ├── queries.ts           # Database queries
│   │   │   └── migrations/          # SQL migrations
│   │   ├── utils/
│   │   │   ├── validation.ts
│   │   │   ├── formatting.ts
│   │   │   └── calculations.ts
│   │   └── constants.ts
│   ├── components/                   # React components
│   │   ├── ui/                      # shadcn/ui components
│   │   ├── campaigns/
│   │   ├── creatives/
│   │   ├── insights/
│   │   └── shared/
│   ├── types/                        # TypeScript types
│   │   ├── database.ts
│   │   ├── agents.ts
│   │   ├── apis.ts
│   │   └── index.ts
│   └── config/
│       ├── agents.ts                # Agent configuration
│       └── api.ts                   # API configuration
├── public/
├── supabase/
│   ├── migrations/
│   └── seed.sql
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── scripts/
│   └── setup.sh
├── .env.example
├── .env.local
├── package.json
├── tsconfig.json
├── tailwind.config.ts
├── next.config.js
├── CLAUDE.md                         # Claude interaction guidelines
├── TODO.md                           # Development roadmap
└── README.md
```

---

## Database Schema (Supabase/PostgreSQL)

### Core Tables

```sql
-- Users & Authentication (handled by Supabase Auth)
-- Uses built-in auth.users table

-- Organizations (for multi-tenancy)
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Organization Members
CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

-- Ad Accounts (Meta/TikTok)
CREATE TABLE ad_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('meta', 'tiktok')),
  account_id TEXT NOT NULL,
  account_name TEXT NOT NULL,
  access_token TEXT NOT NULL, -- Encrypted
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(platform, account_id)
);

-- Products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  price DECIMAL(10,2),
  target_audience JSONB, -- Demographics, interests, etc.
  brand_guidelines JSONB, -- Voice, style, colors, etc.
  notes TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Campaigns
CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  ad_account_id UUID REFERENCES ad_accounts(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  platform TEXT NOT NULL CHECK (platform IN ('meta', 'tiktok')),
  platform_campaign_id TEXT, -- External platform ID
  name TEXT NOT NULL,
  objective TEXT NOT NULL,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_review', 'active', 'paused', 'completed', 'error')),
  daily_budget DECIMAL(10,2),
  total_budget DECIMAL(10,2),
  start_date DATE,
  end_date DATE,
  targeting JSONB NOT NULL, -- Audiences, interests, locations, etc.
  bidding_strategy JSONB NOT NULL,
  performance_goal JSONB, -- Target CPA, ROAS, etc.
  metadata JSONB DEFAULT '{}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ad Sets
CREATE TABLE ad_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  platform_ad_set_id TEXT,
  name TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  daily_budget DECIMAL(10,2),
  targeting JSONB,
  placement JSONB,
  optimization_goal TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Creative Concepts (before video generation)
CREATE TABLE creative_concepts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  angle TEXT NOT NULL, -- "problem/solution", "transformation", etc.
  hook TEXT NOT NULL,
  script TEXT NOT NULL,
  veo_sora_prompt TEXT NOT NULL, -- Full prompt for Veo 3/Sora 2
  caption TEXT,
  video_length INTEGER, -- Seconds
  target_emotion TEXT[],
  source TEXT CHECK (source IN ('manual', 'ai_generated', 'competitor_inspired')),
  quality_score INTEGER CHECK (quality_score >= 1 AND quality_score <= 10),
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'rejected', 'used')),
  insights_used JSONB, -- What market/performance insights informed this
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ads
CREATE TABLE ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_set_id UUID REFERENCES ad_sets(id) ON DELETE CASCADE,
  creative_concept_id UUID REFERENCES creative_concepts(id) ON DELETE SET NULL,
  platform_ad_id TEXT,
  name TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  creative_url TEXT, -- Video/image URL
  caption TEXT,
  cta TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Metrics (time-series data)
CREATE TABLE performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_account_id UUID REFERENCES ad_accounts(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  ad_set_id UUID REFERENCES ad_sets(id) ON DELETE SET NULL,
  ad_id UUID REFERENCES ads(id) ON DELETE SET NULL,
  date DATE NOT NULL,
  platform TEXT NOT NULL,

  -- Standard metrics
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  spend DECIMAL(10,2) DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0,

  -- Calculated metrics
  ctr DECIMAL(5,2), -- Click-through rate
  cpc DECIMAL(10,2), -- Cost per click
  cpm DECIMAL(10,2), -- Cost per mille
  cpa DECIMAL(10,2), -- Cost per acquisition
  roas DECIMAL(10,2), -- Return on ad spend
  frequency DECIMAL(5,2),

  -- Additional metrics
  video_views INTEGER DEFAULT 0,
  video_completion_rate DECIMAL(5,2),
  engagement INTEGER DEFAULT 0,

  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(campaign_id, ad_set_id, ad_id, date)
);

-- Market Intelligence (competitor data)
CREATE TABLE market_intelligence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (platform IN ('meta', 'tiktok')),
  advertiser_name TEXT,
  advertiser_id TEXT,
  product_category TEXT,
  ad_url TEXT,
  video_url TEXT,
  transcript TEXT,
  caption TEXT,
  running_since DATE,
  estimated_impressions INTEGER,
  visual_analysis JSONB, -- AI analysis of visual elements
  hooks_used TEXT[],
  angles_detected TEXT[],
  sentiment TEXT,
  scraped_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Learning Database (patterns discovered by Performance Agent)
CREATE TABLE learnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('creative', 'targeting', 'bidding', 'timing', 'general')),
  insight_type TEXT NOT NULL, -- "winning_pattern", "failing_pattern", "hypothesis", "proven_fact"
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  evidence JSONB NOT NULL, -- Supporting data, campaign IDs, metrics
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
  sample_size INTEGER, -- Number of campaigns/ads this is based on
  applicable_to TEXT[], -- Product categories, audiences this applies to
  tags TEXT[],
  embedding VECTOR(1536), -- For semantic search
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'testing', 'deprecated')),
  created_by TEXT DEFAULT 'performance_agent',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- A/B Tests
CREATE TABLE ab_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  hypothesis TEXT NOT NULL,
  test_type TEXT NOT NULL CHECK (test_type IN ('creative', 'audience', 'bidding', 'placement')),
  variants JSONB NOT NULL, -- Array of variant configs
  status TEXT DEFAULT 'running' CHECK (status IN ('draft', 'running', 'completed', 'inconclusive')),
  winner_variant_id TEXT,
  results JSONB,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  statistical_significance DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Agent Activity Logs
CREATE TABLE agent_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  agent_name TEXT NOT NULL,
  action TEXT NOT NULL,
  input JSONB,
  output JSONB,
  success BOOLEAN DEFAULT true,
  error TEXT,
  execution_time_ms INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Approvals (for human-in-the-loop)
CREATE TABLE approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  approval_type TEXT NOT NULL CHECK (approval_type IN ('creative', 'campaign_launch', 'budget_change', 'test_design')),
  related_id UUID NOT NULL, -- ID of creative/campaign/etc requiring approval
  details JSONB NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  requested_by TEXT, -- Agent name
  reviewed_by UUID REFERENCES auth.users(id),
  feedback TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX idx_campaigns_org ON campaigns(organization_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_performance_campaign_date ON performance_metrics(campaign_id, date);
CREATE INDEX idx_performance_date ON performance_metrics(date DESC);
CREATE INDEX idx_learnings_embedding ON learnings USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_market_intel_category ON market_intelligence(product_category);
CREATE INDEX idx_approvals_status ON approvals(status) WHERE status = 'pending';
```

### Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE ad_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- ... (enable for all tables)

-- Example policies (apply similar patterns to all tables)

-- Users can only see data for organizations they belong to
CREATE POLICY "Users can view own organization data"
  ON organizations FOR SELECT
  USING (
    id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

-- Users can only insert/update data for their organization
CREATE POLICY "Users can modify own organization data"
  ON campaigns FOR ALL
  USING (
    organization_id IN (
      SELECT organization_id FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

-- Similar policies for all tables with organization_id
```

---

## Agent Architecture

### Base Agent Interface

```typescript
// src/agents/shared/base-agent.ts

import Anthropic from '@anthropic-ai/sdk';

export interface Tool {
  name: string;
  description: string;
  input_schema: {
    type: "object";
    properties: Record<string, any>;
    required?: string[];
  };
  execute: (input: any) => Promise<any>;
}

export interface AgentConfig {
  name: string;
  model: string;
  temperature: number;
  maxTokens: number;
  systemPrompt: string;
  tools: Tool[];
}

export interface AgentMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface AgentResponse {
  success: boolean;
  output: any;
  toolCalls?: Array<{
    tool: string;
    input: any;
    output: any;
  }>;
  reasoning?: string;
  error?: string;
}

export abstract class BaseAgent {
  protected client: Anthropic;
  protected config: AgentConfig;
  protected conversationHistory: AgentMessage[] = [];

  constructor(config: AgentConfig) {
    this.client = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY!
    });
    this.config = config;
  }

  abstract execute(input: any): Promise<AgentResponse>;

  protected async callClaude(
    messages: AgentMessage[],
    tools?: Tool[]
  ): Promise<any> {
    const response = await this.client.messages.create({
      model: this.config.model,
      max_tokens: this.config.maxTokens,
      temperature: this.config.temperature,
      system: this.config.systemPrompt,
      messages: messages.map(msg => ({
        role: msg.role,
        content: msg.content
      })),
      tools: tools?.map(tool => ({
        name: tool.name,
        description: tool.description,
        input_schema: tool.input_schema
      }))
    });

    return response;
  }

  protected async executeTool(
    toolName: string,
    toolInput: any
  ): Promise<any> {
    const tool = this.config.tools.find(t => t.name === toolName);
    if (!tool) {
      throw new Error(`Tool ${toolName} not found`);
    }
    return await tool.execute(toolInput);
  }

  protected async logActivity(
    action: string,
    input: any,
    output: any,
    success: boolean,
    error?: string,
    executionTime?: number
  ): Promise<void> {
    // Log to database via Supabase
    // Implementation in lib/db/queries.ts
  }
}
```

---

### 1. Market Intelligence Agent

**Purpose:** Scrape competitor ads, identify trends, spot opportunities

```typescript
// src/agents/market-intelligence/agent.ts

import { BaseAgent, AgentConfig, AgentResponse } from '../shared/base-agent';
import * as tools from './tools';

const SYSTEM_PROMPT = `You are a Market Intelligence Agent specialized in competitive analysis for digital advertising.

Your responsibilities:
1. Scrape Meta Ad Library and TikTok ads for competitor intelligence
2. Identify trending product categories and ad formats
3. Analyze competitor creative strategies (hooks, angles, visual patterns)
4. Spot emerging opportunities in the market
5. Provide actionable insights to other agents

When analyzing competitors:
- Focus on ads running for 30+ days (indicates success)
- Look for patterns across multiple advertisers (not just one-offs)
- Analyze both visual elements and copy/script patterns
- Identify emotional triggers and psychological angles being used

Output format:
- Clear, actionable insights
- Quantified patterns when possible ("60% of top ads use X")
- Specific examples with URLs
- Confidence scores for each insight

You have access to tools for:
- Scraping Meta Ad Library
- Scraping TikTok ads
- Transcribing video ads
- Analyzing visual elements with computer vision
- Storing insights in the learning database

CRITICAL SAFETY RULES:
- Use proxies for all scraping (built into tools)
- Rate limit: max 1 request per 2 seconds to avoid detection
- If scraping fails with 429/403, back off exponentially
- Never store raw HTML, only extracted data
`;

export class MarketIntelligenceAgent extends BaseAgent {
  constructor() {
    const config: AgentConfig = {
      name: 'market-intelligence',
      model: 'claude-sonnet-4-20250514',
      temperature: 0.7,
      maxTokens: 4000,
      systemPrompt: SYSTEM_PROMPT,
      tools: [
        tools.scrapeMetaAdLibrary,
        tools.scrapeTikTokAds,
        tools.transcribeVideo,
        tools.analyzeVisualElements,
        tools.getTrendingProducts,
        tools.saveMarketInsight
      ]
    };
    super(config);
  }

  async execute(input: {
    task: 'research_category' | 'analyze_competitor' | 'find_trends';
    productCategory?: string;
    competitorName?: string;
    timeRange?: string; // "last_30_days", "last_week"
  }): Promise<AgentResponse> {
    const startTime = Date.now();

    try {
      const userMessage = this.buildPrompt(input);

      const response = await this.callClaude(
        [{ role: 'user', content: userMessage }],
        this.config.tools
      );

      // Handle tool calls
      const toolCalls = [];
      let finalOutput = null;

      for (const content of response.content) {
        if (content.type === 'tool_use') {
          const toolResult = await this.executeTool(
            content.name,
            content.input
          );

          toolCalls.push({
            tool: content.name,
            input: content.input,
            output: toolResult
          });

          // Continue conversation with tool result
          const followUpResponse = await this.callClaude(
            [
              { role: 'user', content: userMessage },
              { role: 'assistant', content: JSON.stringify(response.content) },
              { role: 'user', content: JSON.stringify({
                type: 'tool_result',
                tool_use_id: content.id,
                content: JSON.stringify(toolResult)
              })}
            ],
            this.config.tools
          );

          if (followUpResponse.stop_reason === 'end_turn') {
            finalOutput = followUpResponse.content.find(c => c.type === 'text')?.text;
          }
        }
      }

      const executionTime = Date.now() - startTime;

      await this.logActivity(
        `market_intelligence_${input.task}`,
        input,
        finalOutput,
        true,
        undefined,
        executionTime
      );

      return {
        success: true,
        output: finalOutput || response.content.find(c => c.type === 'text')?.text,
        toolCalls,
        reasoning: 'Market intelligence research completed'
      };

    } catch (error) {
      const executionTime = Date.now() - startTime;

      await this.logActivity(
        `market_intelligence_${input.task}`,
        input,
        null,
        false,
        error.message,
        executionTime
      );

      return {
        success: false,
        output: null,
        error: error.message
      };
    }
  }

  private buildPrompt(input: any): string {
    switch (input.task) {
      case 'research_category':
        return `Research the ${input.productCategory} category:

1. Scrape top ads in this category from Meta Ad Library (last 30 days)
2. Identify the 5 most common creative patterns
3. Analyze which hooks and angles are being used most
4. Find any emerging trends or new advertisers
5. Provide specific examples with ad URLs

Timeframe: ${input.timeRange || 'last_30_days'}`;

      case 'analyze_competitor':
        return `Analyze competitor "${input.competitorName}":

1. Find all active ads from this advertiser
2. Extract and transcribe video ads
3. Identify their creative strategy and angles
4. Analyze what makes their ads successful (if running long)
5. Provide actionable insights for creating competitive alternatives

Timeframe: ${input.timeRange || 'last_30_days'}`;

      case 'find_trends':
        return `Identify current advertising trends:

1. Scan multiple product categories for emerging patterns
2. Identify which ad formats are trending (UGC, product demo, etc.)
3. Find which hooks/angles are becoming more common
4. Spot any new psychological triggers being used
5. Predict which trends will continue vs fade

Timeframe: ${input.timeRange || 'last_30_days'}`;

      default:
        throw new Error(`Unknown task: ${input.task}`);
    }
  }
}
```

**Tools Implementation:**

```typescript
// src/agents/market-intelligence/tools.ts

import { Tool } from '../shared/base-agent';
import { scrapeMetaAds, scrapeTikTokAds } from '@/lib/api/scrapfly';
import { transcribeVideoAudio } from '@/lib/api/openai';
import { analyzeImage } from '@/lib/api/anthropic';
import { saveToDatabase } from '@/lib/db/queries';

export const scrapeMetaAdLibrary: Tool = {
  name: 'scrape_meta_ad_library',
  description: 'Scrape Meta Ad Library for competitor ads in a specific category or from a specific advertiser. Returns ad URLs, copy, and metadata.',
  input_schema: {
    type: 'object',
    properties: {
      searchTerm: {
        type: 'string',
        description: 'Product category or advertiser name to search for'
      },
      country: {
        type: 'string',
        description: 'Country code (e.g., "US", "ES", "GB")',
        default: 'US'
      },
      mediaType: {
        type: 'string',
        enum: ['all', 'video', 'image'],
        description: 'Filter by media type',
        default: 'all'
      },
      activeStatus: {
        type: 'string',
        enum: ['active', 'inactive', 'all'],
        default: 'active'
      },
      maxResults: {
        type: 'integer',
        description: 'Maximum number of ads to return',
        default: 50
      }
    },
    required: ['searchTerm']
  },
  execute: async (input) => {
    // Implementation using Scrapfly API
    const results = await scrapeMetaAds({
      search: input.searchTerm,
      country: input.country,
      mediaType: input.mediaType,
      activeStatus: input.activeStatus,
      maxResults: input.maxResults
    });

    // Save to market_intelligence table
    for (const ad of results) {
      await saveToDatabase('market_intelligence', {
        platform: 'meta',
        advertiser_name: ad.advertiserName,
        product_category: input.searchTerm,
        ad_url: ad.url,
        video_url: ad.videoUrl,
        caption: ad.caption,
        running_since: ad.startDate,
        scraped_at: new Date()
      });
    }

    return {
      totalResults: results.length,
      ads: results.map(ad => ({
        id: ad.id,
        advertiser: ad.advertiserName,
        url: ad.url,
        caption: ad.caption,
        mediaType: ad.mediaType,
        videoUrl: ad.videoUrl,
        runningSince: ad.startDate,
        daysActive: ad.daysActive
      }))
    };
  }
};

export const scrapeTikTokAds: Tool = {
  name: 'scrape_tiktok_ads',
  description: 'Scrape TikTok Creative Center for trending ads. Note: TikTok has official API with public data, so this is legal.',
  input_schema: {
    type: 'object',
    properties: {
      industry: {
        type: 'string',
        description: 'Industry/category to search'
      },
      country: {
        type: 'string',
        default: 'US'
      },
      objective: {
        type: 'string',
        enum: ['all', 'conversions', 'traffic', 'app_installs'],
        default: 'all'
      },
      maxResults: {
        type: 'integer',
        default: 50
      }
    },
    required: ['industry']
  },
  execute: async (input) => {
    // Implementation using TikTok Creative Center API (official, public)
    const results = await scrapeTikTokAds(input);

    return {
      totalResults: results.length,
      ads: results
    };
  }
};

export const transcribeVideo: Tool = {
  name: 'transcribe_video',
  description: 'Download a video ad and transcribe its audio to extract the script/voiceover.',
  input_schema: {
    type: 'object',
    properties: {
      videoUrl: {
        type: 'string',
        description: 'URL of the video to transcribe'
      }
    },
    required: ['videoUrl']
  },
  execute: async (input) => {
    // 1. Download video
    const videoPath = await downloadVideo(input.videoUrl);

    // 2. Extract audio
    const audioPath = await extractAudio(videoPath);

    // 3. Transcribe with Whisper
    const transcript = await transcribeVideoAudio(audioPath);

    // 4. Cleanup temp files
    await cleanupFiles([videoPath, audioPath]);

    return {
      transcript: transcript.text,
      language: transcript.language,
      confidence: transcript.confidence
    };
  }
};

export const analyzeVisualElements: Tool = {
  name: 'analyze_visual_elements',
  description: 'Use Claude Vision to analyze visual elements in an ad image or video thumbnail.',
  input_schema: {
    type: 'object',
    properties: {
      imageUrl: {
        type: 'string',
        description: 'URL of image or video thumbnail to analyze'
      },
      analysisType: {
        type: 'string',
        enum: ['composition', 'colors', 'text_overlays', 'people', 'products', 'emotions'],
        description: 'What aspect to focus analysis on'
      }
    },
    required: ['imageUrl']
  },
  execute: async (input) => {
    const analysis = await analyzeImage(input.imageUrl, input.analysisType);

    return {
      analysis: analysis.description,
      elements: analysis.elements,
      suggestions: analysis.suggestions
    };
  }
};

export const getTrendingProducts: Tool = {
  name: 'get_trending_products',
  description: 'Get trending products from e-commerce intelligence APIs.',
  input_schema: {
    type: 'object',
    properties: {
      category: {
        type: 'string',
        description: 'Product category'
      },
      timeRange: {
        type: 'string',
        enum: ['24h', '7d', '30d'],
        default: '7d'
      }
    }
  },
  execute: async (input) => {
    // Integrate with Ecomhunt, FindNiche, or similar APIs
    // For MVP, can be a placeholder returning mock data
    return {
      products: [],
      message: 'Trending products API integration pending'
    };
  }
};

export const saveMarketInsight: Tool = {
  name: 'save_market_insight',
  description: 'Save a market intelligence insight to the database for other agents to use.',
  input_schema: {
    type: 'object',
    properties: {
      category: {
        type: 'string',
        description: 'Type of insight (trend, pattern, opportunity, etc.)'
      },
      title: {
        type: 'string',
        description: 'Short title for the insight'
      },
      description: {
        type: 'string',
        description: 'Detailed description of the insight'
      },
      evidence: {
        type: 'object',
        description: 'Supporting data, examples, URLs'
      },
      confidence: {
        type: 'number',
        description: 'Confidence score 0-1'
      }
    },
    required: ['category', 'title', 'description', 'evidence']
  },
  execute: async (input) => {
    const insight = await saveToDatabase('learnings', {
      category: 'market_intelligence',
      insight_type: input.category,
      title: input.title,
      description: input.description,
      evidence: input.evidence,
      confidence_score: input.confidence || 0.7,
      created_by: 'market_intelligence_agent'
    });

    return {
      success: true,
      insightId: insight.id
    };
  }
};
```

---

### 2. Performance & Testing Agent

**Purpose:** Analyze campaign performance, identify patterns, design A/B tests

```typescript
// src/agents/performance-testing/agent.ts

const SYSTEM_PROMPT = `You are a Performance & Testing Agent specialized in analyzing ad campaign data and designing experiments.

Your responsibilities:
1. Analyze campaign performance data to identify what's working and what's not
2. Detect patterns and correlations in the data
3. Design rigorous A/B tests to validate hypotheses
4. Ensure statistical significance before declaring winners
5. Document learnings for the entire system to benefit from

When analyzing performance:
- Look beyond surface metrics - understand WHY something performed well
- Compare against benchmarks (historical data, industry averages)
- Identify statistical outliers (positive and negative)
- Consider external factors (seasonality, platform changes, etc.)

When designing tests:
- One variable at a time for clear attribution
- Adequate sample size for statistical significance
- Appropriate test duration (respect learning phases)
- Clear success criteria defined upfront

Output format:
- Quantified insights with confidence intervals
- Clear cause-and-effect relationships when provable
- Action items prioritized by potential impact
- Test designs with full specifications

CRITICAL RULES:
- Never recommend pausing a campaign during learning phase (<50 conversions)
- Never declare a test winner before statistical significance (95%+ confidence)
- Never optimize for vanity metrics - focus on ROI/ROAS
- Always consider external factors before attributing causation
`;

export class PerformanceTestingAgent extends BaseAgent {
  constructor() {
    const config: AgentConfig = {
      name: 'performance-testing',
      model: 'claude-sonnet-4-20250514',
      temperature: 0.3, // Lower temperature for analytical work
      maxTokens: 4000,
      systemPrompt: SYSTEM_PROMPT,
      tools: [
        tools.getCampaignPerformance,
        tools.getHistoricalBenchmarks,
        tools.calculateMetrics,
        tools.detectAnomalies,
        tools.analyzeTrends,
        tools.designABTest,
        tools.checkTestSignificance,
        tools.saveLearning
      ]
    };
    super(config);
  }

  async execute(input: {
    task: 'analyze_performance' | 'design_test' | 'check_test_results';
    campaignIds?: string[];
    testId?: string;
    timeRange?: { start: Date; end: Date };
  }): Promise<AgentResponse> {
    // Implementation similar to MarketIntelligenceAgent
    // with specific prompts and tool orchestration
  }
}
```

---

### 3. Creative Agent

**Purpose:** Generate Veo 3/Sora 2 prompts and ad copy based on insights

```typescript
// src/agents/creative/agent.ts

const SYSTEM_PROMPT = `You are a Creative Agent specialized in generating high-converting video ad concepts and prompts for AI video generation.

Your responsibilities:
1. Generate Veo 3 / Sora 2 prompts that produce engaging video ads
2. Create compelling ad copy (hooks, scripts, captions)
3. Apply learnings from performance and market intelligence
4. Ensure brand consistency and quality
5. Self-validate concepts before outputting

When generating video prompts:
- Be extremely specific about visual details (lighting, camera angles, pacing)
- Include clear action/narrative structure
- Specify emotional tone and energy level
- Consider platform best practices (TikTok vs Meta format differences)
- Account for first 3 seconds (hook must grab attention)

When generating scripts:
- Lead with the hook (question, bold claim, or problem statement)
- Follow proven structures (problem-agitate-solve, before-after-bridge, etc.)
- Use active voice and conversational tone
- Include specific product benefits, not just features
- End with clear CTA

Self-validation process:
1. Generate 5 concept variations
2. Score each on: attention-grabbing (1-10), clarity (1-10), brand fit (1-10)
3. Select top 2-3 that score 8+ across all dimensions
4. Refine prompts for technical accuracy

CRITICAL RULES:
- Never generate prompts with copyrighted characters/brands
- Always specify video length (15s, 30s, 60s)
- Include safety guidelines for Veo/Sora (avoid violence, explicit content)
- Test prompts mentally - would this actually generate what you envision?
`;

export class CreativeAgent extends BaseAgent {
  constructor() {
    const config: AgentConfig = {
      name: 'creative',
      model: 'claude-sonnet-4-20250514',
      temperature: 0.8, // Higher temperature for creativity
      maxTokens: 4000,
      systemPrompt: SYSTEM_PROMPT,
      tools: [
        tools.getMarketInsights,
        tools.getPerformanceLearnings,
        tools.getBrandGuidelines,
        tools.generateVideoPrompt,
        tools.generateAdCopy,
        tools.validateConcept,
        tools.saveCreativeConcept
      ]
    };
    super(config);
  }

  async execute(input: {
    productId: string;
    briefing: string;
    numberOfVariations: number;
    platform: 'meta' | 'tiktok';
    videoLength: 15 | 30 | 60;
  }): Promise<AgentResponse> {
    // Implementation
  }
}
```

---

### 4. Campaign Execution Agent

**Purpose:** Launch campaigns, manage budgets, optimize in real-time

```typescript
// src/agents/campaign-execution/agent.ts

const SYSTEM_PROMPT = `You are a Campaign Execution Agent specialized in managing Facebook and TikTok advertising campaigns.

Your responsibilities:
1. Create campaign structures (campaigns, ad sets, ads)
2. Set targeting, bidding, and budget parameters
3. Launch campaigns with approved creatives
4. Monitor performance in real-time
5. Execute optimization actions (pause, scale, adjust budgets)
6. Enforce safety limits to prevent overspend

When creating campaigns:
- Follow platform best practices for structure
- Use appropriate naming conventions (trackable, descriptive)
- Set realistic daily budgets based on testing phase
- Configure conversion tracking properly
- Enable automated rules where appropriate

When optimizing:
- Respect learning phases (don't change budgets during learning)
- Scale winners gradually (max 20% budget increase per day)
- Pause underperformers decisively (if CPA > 2x target with spend > €50)
- Reallocate budgets from losers to winners
- Create lookalike audiences from converters

CRITICAL SAFETY RULES:
- Hard daily spend cap: €50 per campaign (unless explicitly approved higher)
- Auto-pause if spend > €50 with 0 conversions
- Require approval for any budget change > €200
- Alert human immediately if CPA > target by 50%
- Never delete campaigns/ads (pause instead for data preservation)

OPTIMIZATION PRINCIPLES:
- Frequency > 4 = creative fatigue, refresh creative
- CTR declining 3 days straight = targeting issue or creative fatigue
- CPA increasing while CTR stable = landing page or offer issue
- ROAS declining = check for attribution delays before panicking
`;

export class CampaignExecutionAgent extends BaseAgent {
  constructor() {
    const config: AgentConfig = {
      name: 'campaign-execution',
      model: 'claude-sonnet-4-20250514',
      temperature: 0.1, // Very low temperature for precise execution
      maxTokens: 4000,
      systemPrompt: SYSTEM_PROMPT,
      tools: [
        tools.createCampaign,
        tools.createAdSet,
        tools.createAd,
        tools.updateBudget,
        tools.pauseCampaign,
        tools.getPerformanceData,
        tools.createLookalikeAudience,
        tools.checkSpendLimits,
        tools.requestApproval
      ]
    };
    super(config);
  }

  async execute(input: {
    action: 'create_campaign' | 'optimize_campaign' | 'daily_check';
    campaignConfig?: any;
    campaignIds?: string[];
  }): Promise<AgentResponse> {
    // Implementation
  }
}
```

---

### 5. Orchestrator Agent

**Purpose:** Coordinate multi-agent workflows

```typescript
// src/agents/orchestrator.ts

export class OrchestratorAgent {
  private marketIntel: MarketIntelligenceAgent;
  private performance: PerformanceTestingAgent;
  private creative: CreativeAgent;
  private execution: CampaignExecutionAgent;

  constructor() {
    this.marketIntel = new MarketIntelligenceAgent();
    this.performance = new PerformanceTestingAgent();
    this.creative = new CreativeAgent();
    this.execution = new CampaignExecutionAgent();
  }

  async launchNewProductCampaign(input: {
    productId: string;
    budget: number;
    targeting: any;
  }): Promise<any> {
    // 1. Market research
    const marketInsights = await this.marketIntel.execute({
      task: 'research_category',
      productCategory: input.productCategory
    });

    // 2. Get performance learnings
    const performanceLearnings = await this.performance.execute({
      task: 'get_similar_product_learnings',
      productCategory: input.productCategory
    });

    // 3. Generate creative concepts
    const creativeConcepts = await this.creative.execute({
      productId: input.productId,
      briefing: `Create ad concepts using these insights: ${JSON.stringify({
        market: marketInsights,
        performance: performanceLearnings
      })}`,
      numberOfVariations: 5,
      platform: 'meta',
      videoLength: 30
    });

    // 4. Request human approval
    const approval = await this.requestHumanApproval({
      type: 'creative_concepts',
      concepts: creativeConcepts
    });

    if (!approval.approved) {
      return { success: false, reason: 'Concepts not approved' };
    }

    // 5. Launch campaign (after user generates videos)
    const campaign = await this.execution.execute({
      action: 'create_campaign',
      campaignConfig: {
        productId: input.productId,
        budget: input.budget,
        targeting: input.targeting,
        creativeIds: approval.selectedConcepts
      }
    });

    return {
      success: true,
      campaignId: campaign.output.campaignId,
      message: 'Campaign launched successfully'
    };
  }

  async dailyOptimization(): Promise<any> {
    // Run daily for all active campaigns
    const activeCampaigns = await this.getActiveCampaigns();

    for (const campaign of activeCampaigns) {
      // 1. Get performance data
      const performance = await this.execution.execute({
        action: 'get_performance',
        campaignIds: [campaign.id]
      });

      // 2. Analyze
      const analysis = await this.performance.execute({
        task: 'analyze_performance',
        campaignIds: [campaign.id]
      });

      // 3. Execute optimizations
      if (analysis.output.recommendations) {
        for (const rec of analysis.output.recommendations) {
          if (rec.autoExecute) {
            await this.execution.execute({
              action: 'optimize_campaign',
              recommendation: rec
            });
          } else {
            // Request approval for manual review
            await this.requestHumanApproval({
              type: 'optimization',
              recommendation: rec
            });
          }
        }
      }
    }
  }

  private async requestHumanApproval(input: any): Promise<any> {
    // Create approval record in database
    // Send notification to user (Slack, email, etc.)
    // Wait for approval (poll database or webhook)
    // Return approval result
  }

  private async getActiveCampaigns(): Promise<any[]> {
    // Query database for active campaigns
  }
}
```

---

## API Integration Specifications

### Meta Marketing API

**Setup Requirements:**
1. Facebook Business Manager account
2. App created in developers.facebook.com
3. Marketing API access granted
4. Access token with permissions:
   - `ads_management`
   - `ads_read`
   - `business_management`

**Key Endpoints:**

```typescript
// src/lib/api/meta.ts

import axios from 'axios';

const META_API_VERSION = 'v21.0';
const META_API_BASE = `https://graph.facebook.com/${META_API_VERSION}`;

export class MetaAdsAPI {
  private accessToken: string;

  constructor(accessToken: string) {
    this.accessToken = accessToken;
  }

  // Get ad account details
  async getAdAccount(accountId: string) {
    const response = await axios.get(
      `${META_API_BASE}/act_${accountId}`,
      {
        params: {
          access_token: this.accessToken,
          fields: 'account_id,name,currency,timezone_name,amount_spent,balance'
        }
      }
    );
    return response.data;
  }

  // Create campaign
  async createCampaign(accountId: string, params: {
    name: string;
    objective: string; // 'OUTCOME_SALES', 'OUTCOME_TRAFFIC', etc.
    status: 'PAUSED' | 'ACTIVE';
    special_ad_categories?: string[];
    daily_budget?: number;
    lifetime_budget?: number;
  }) {
    const response = await axios.post(
      `${META_API_BASE}/act_${accountId}/campaigns`,
      {
        access_token: this.accessToken,
        ...params,
        // Convert budget to cents
        daily_budget: params.daily_budget ? params.daily_budget * 100 : undefined,
        lifetime_budget: params.lifetime_budget ? params.lifetime_budget * 100 : undefined
      }
    );
    return response.data;
  }

  // Create ad set
  async createAdSet(accountId: string, params: {
    campaign_id: string;
    name: string;
    optimization_goal: string;
    billing_event: string;
    bid_amount?: number;
    daily_budget?: number;
    targeting: any;
    status: 'PAUSED' | 'ACTIVE';
  }) {
    const response = await axios.post(
      `${META_API_BASE}/act_${accountId}/adsets`,
      {
        access_token: this.accessToken,
        ...params,
        daily_budget: params.daily_budget ? params.daily_budget * 100 : undefined
      }
    );
    return response.data;
  }

  // Create ad creative
  async createAdCreative(accountId: string, params: {
    name: string;
    object_story_spec?: any;
    video_data?: any;
    image_url?: string;
  }) {
    const response = await axios.post(
      `${META_API_BASE}/act_${accountId}/adcreatives`,
      {
        access_token: this.accessToken,
        ...params
      }
    );
    return response.data;
  }

  // Create ad
  async createAd(accountId: string, params: {
    ad_set_id: string;
    name: string;
    creative_id: string;
    status: 'PAUSED' | 'ACTIVE';
  }) {
    const response = await axios.post(
      `${META_API_BASE}/act_${accountId}/ads`,
      {
        access_token: this.accessToken,
        ...params
      }
    );
    return response.data;
  }

  // Get insights (performance data)
  async getInsights(objectId: string, params: {
    level: 'campaign' | 'adset' | 'ad';
    date_preset?: string; // 'today', 'yesterday', 'last_7d', 'last_30d'
    time_range?: { since: string; until: string }; // YYYY-MM-DD
    fields: string[]; // Metrics to fetch
  }) {
    const response = await axios.get(
      `${META_API_BASE}/${objectId}/insights`,
      {
        params: {
          access_token: this.accessToken,
          level: params.level,
          date_preset: params.date_preset,
          time_range: params.time_range ? JSON.stringify(params.time_range) : undefined,
          fields: params.fields.join(',')
        }
      }
    );
    return response.data;
  }

  // Update campaign (pause, change budget, etc.)
  async updateCampaign(campaignId: string, updates: {
    status?: 'PAUSED' | 'ACTIVE';
    daily_budget?: number;
    lifetime_budget?: number;
    name?: string;
  }) {
    const response = await axios.post(
      `${META_API_BASE}/${campaignId}`,
      {
        access_token: this.accessToken,
        ...updates,
        daily_budget: updates.daily_budget ? updates.daily_budget * 100 : undefined,
        lifetime_budget: updates.lifetime_budget ? updates.lifetime_budget * 100 : undefined
      }
    );
    return response.data;
  }

  // Batch operations (more efficient)
  async batchRequest(requests: Array<{
    method: 'GET' | 'POST' | 'DELETE';
    relative_url: string;
    body?: string;
  }>) {
    const response = await axios.post(
      `${META_API_BASE}`,
      {
        access_token: this.accessToken,
        batch: requests
      }
    );
    return response.data;
  }
}

// Available metrics for insights:
export const AVAILABLE_METRICS = [
  'impressions',
  'clicks',
  'spend',
  'reach',
  'frequency',
  'cpc',
  'cpm',
  'cpp',
  'ctr',
  'actions', // Conversions
  'cost_per_action_type',
  'video_p25_watched_actions',
  'video_p50_watched_actions',
  'video_p75_watched_actions',
  'video_p100_watched_actions',
  'video_avg_time_watched_actions'
];
```

### TikTok Ads API

Similar implementation to Meta, adapting to TikTok's API structure.

### Scrapfly API (for web scraping)

```typescript
// src/lib/api/scrapfly.ts

import axios from 'axios';

const SCRAPFLY_API_KEY = process.env.SCRAPFLY_API_KEY!;
const SCRAPFLY_BASE_URL = 'https://api.scrapfly.io/scrape';

export async function scrapeMetaAds(params: {
  search: string;
  country: string;
  mediaType: string;
  activeStatus: string;
  maxResults: number;
}) {
  // Build Meta Ad Library URL
  const targetUrl = `https://www.facebook.com/ads/library/?active_status=${params.activeStatus}&ad_type=all&country=${params.country}&q=${encodeURIComponent(params.search)}&media_type=${params.mediaType}`;

  const response = await axios.get(SCRAPFLY_BASE_URL, {
    params: {
      key: SCRAPFLY_API_KEY,
      url: targetUrl,
      render_js: true, // Meta Ad Library requires JS rendering
      proxy_pool: 'public_residential_pool', // Use residential proxies
      country: params.country,
      asp: true // Anti-scraping protection
    }
  });

  // Parse HTML and extract ad data
  const html = response.data.result.content;
  const ads = parseMetaAdLibraryHTML(html);

  return ads.slice(0, params.maxResults);
}

function parseMetaAdLibraryHTML(html: string): any[] {
  // Implementation to parse Meta Ad Library HTML
  // Extract: advertiser name, ad copy, media URLs, start date, etc.
  // This requires careful HTML parsing with cheerio or similar
}
```

---

## UI Components & Dashboard

### Key Pages/Views

**1. Dashboard (Home)**
- Active campaigns overview
- Performance summary (spend, ROAS, conversions today)
- Pending approvals
- Recent agent activity
- Alerts/notifications

**2. Campaigns Page**
- List of all campaigns (with filters)
- Campaign performance table
- Quick actions (pause, duplicate, edit)
- Drill-down to ad sets and ads

**3. Creatives Page**
- Creative concept library
- Generate new concepts button
- Status: draft, approved, active, archived
- Performance by creative
- Video preview

**4. Insights Page**
- Market intelligence findings
- Performance learnings
- Trending products/categories
- Competitor analysis

**5. Settings**
- Ad account connections
- Budget limits and safety rules
- Approval workflows
- Team members
- API keys

### Example Component

```typescript
// src/components/campaigns/CampaignCard.tsx

import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { formatCurrency, formatNumber } from '@/lib/utils/formatting';
import type { Campaign, PerformanceMetrics } from '@/types';

interface CampaignCardProps {
  campaign: Campaign;
  metrics: PerformanceMetrics;
  onPause: () => void;
  onView: () => void;
}

export function CampaignCard({ campaign, metrics, onPause, onView }: CampaignCardProps) {
  const statusColor = {
    active: 'green',
    paused: 'yellow',
    draft: 'gray',
    error: 'red'
  }[campaign.status];

  return (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-start">
          <div>
            <CardTitle className="text-lg">{campaign.name}</CardTitle>
            <p className="text-sm text-muted-foreground mt-1">
              {campaign.platform.toUpperCase()} • {campaign.objective}
            </p>
          </div>
          <Badge variant={statusColor}>{campaign.status}</Badge>
        </div>
      </CardHeader>

      <CardContent>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
          <div>
            <p className="text-sm text-muted-foreground">Spend</p>
            <p className="text-2xl font-bold">{formatCurrency(metrics.spend)}</p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">ROAS</p>
            <p className="text-2xl font-bold">
              {metrics.roas?.toFixed(2) || '0.00'}x
            </p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">Conversions</p>
            <p className="text-2xl font-bold">{formatNumber(metrics.conversions)}</p>
          </div>
          <div>
            <p className="text-sm text-muted-foreground">CPA</p>
            <p className="text-2xl font-bold">{formatCurrency(metrics.cpa)}</p>
          </div>
        </div>

        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={onView}>
            View Details
          </Button>
          {campaign.status === 'active' && (
            <Button variant="outline" size="sm" onClick={onPause}>
              Pause
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
```

---

## Background Jobs & Cron

```typescript
// src/app/api/cron/daily-optimization/route.ts

import { NextResponse } from 'next/server';
import { OrchestratorAgent } from '@/agents/orchestrator';

export async function GET(request: Request) {
  // Verify cron secret
  const authHeader = request.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const orchestrator = new OrchestratorAgent();
    const result = await orchestrator.dailyOptimization();

    return NextResponse.json({
      success: true,
      result
    });
  } catch (error) {
    console.error('Daily optimization failed:', error);
    return NextResponse.json({
      success: false,
      error: error.message
    }, { status: 500 });
  }
}
```

**Vercel Cron Configuration (vercel.json):**

```json
{
  "crons": [
    {
      "path": "/api/cron/daily-optimization",
      "schedule": "0 9 * * *"
    },
    {
      "path": "/api/cron/performance-sync",
      "schedule": "0 */6 * * *"
    },
    {
      "path": "/api/cron/market-intelligence",
      "schedule": "0 0 * * *"
    }
  ]
}
```

---

## Environment Variables

```bash
# .env.example

# Database
NEXT_PUBLIC_SUPABASE_URL=your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Meta
META_APP_ID=
META_APP_SECRET=
META_ACCESS_TOKEN=

# TikTok
TIKTOK_APP_ID=
TIKTOK_APP_SECRET=
TIKTOK_ACCESS_TOKEN=

# OpenAI (for Whisper)
OPENAI_API_KEY=

# Scrapfly
SCRAPFLY_API_KEY=

# Veo 3 / Sora 2 (when available)
VEO_API_KEY=
SORA_API_KEY=

# Cron Security
CRON_SECRET=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

---

## Testing Requirements

### Unit Tests (Vitest)

```typescript
// tests/unit/agents/market-intelligence.test.ts

import { describe, it, expect, vi } from 'vitest';
import { MarketIntelligenceAgent } from '@/agents/market-intelligence/agent';
import * as scrapfly from '@/lib/api/scrapfly';

vi.mock('@/lib/api/scrapfly');

describe('MarketIntelligenceAgent', () => {
  it('should scrape Meta Ad Library successfully', async () => {
    const mockAds = [
      {
        id: '123',
        advertiser: 'Test Brand',
        url: 'https://...',
        caption: 'Test ad',
        videoUrl: 'https://...'
      }
    ];

    vi.mocked(scrapfly.scrapeMetaAds).mockResolvedValue(mockAds);

    const agent = new MarketIntelligenceAgent();
    const result = await agent.execute({
      task: 'research_category',
      productCategory: 'fitness'
    });

    expect(result.success).toBe(true);
    expect(result.toolCalls).toHaveLength(1);
  });

  it('should handle scraping errors gracefully', async () => {
    vi.mocked(scrapfly.scrapeMetaAds).mockRejectedValue(
      new Error('Rate limited')
    );

    const agent = new MarketIntelligenceAgent();
    const result = await agent.execute({
      task: 'research_category',
      productCategory: 'fitness'
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('Rate limited');
  });
});
```

### Integration Tests

```typescript
// tests/integration/campaign-creation.test.ts

import { describe, it, expect } from 'vitest';
import { OrchestratorAgent } from '@/agents/orchestrator';
import { createTestProduct } from './helpers';

describe('Campaign Creation Flow', () => {
  it('should create campaign end-to-end', async () => {
    const product = await createTestProduct();

    const orchestrator = new OrchestratorAgent();
    const result = await orchestrator.launchNewProductCampaign({
      productId: product.id,
      budget: 100,
      targeting: {
        countries: ['US'],
        age_min: 25,
        age_max: 45
      }
    });

    expect(result.success).toBe(true);
    expect(result.campaignId).toBeDefined();
  }, 60000); // 60 second timeout for full flow
});
```

### E2E Tests (Playwright)

```typescript
// tests/e2e/dashboard.spec.ts

import { test, expect } from '@playwright/test';

test('user can view dashboard and see campaigns', async ({ page }) => {
  await page.goto('/');

  // Login
  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('input[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  // Wait for dashboard
  await page.waitForURL('/dashboard');

  // Check campaigns are visible
  const campaignCards = page.locator('[data-testid="campaign-card"]');
  await expect(campaignCards).toHaveCount(3);
});
```

---

## Deployment & Infrastructure

### Vercel Deployment

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Set environment variables
vercel env add ANTHROPIC_API_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
# ... etc

# Deploy to production
vercel --prod
```

### Supabase Setup

```bash
# Install Supabase CLI
npm install supabase --save-dev

# Initialize
npx supabase init

# Start local development
npx supabase start

# Link to cloud project
npx supabase link --project-ref your-project-ref

# Push migrations
npx supabase db push

# Generate TypeScript types
npx supabase gen types typescript --local > src/types/database.ts
```

---

## Development Workflow

### Initial Setup

```bash
# 1. Clone repo (Claude Code will create it)
git clone <repo-url>
cd ad-agency-system

# 2. Install dependencies
pnpm install

# 3. Setup environment variables
cp .env.example .env.local
# Edit .env.local with your API keys

# 4. Setup Supabase
npx supabase start
npx supabase db reset

# 5. Run development server
pnpm dev
```

### Git Workflow

```bash
# Feature branches
git checkout -b feature/market-intelligence-agent
# ... make changes
git commit -m "feat: implement market intelligence agent"
git push origin feature/market-intelligence-agent
# Open PR

# Commits follow conventional commits:
# feat: new feature
# fix: bug fix
# docs: documentation
# refactor: code refactoring
# test: add tests
# chore: maintenance
```

---

## Security Considerations

1. **API Key Management**
   - Never commit API keys to git
   - Use environment variables
   - Rotate keys regularly
   - Different keys for dev/staging/prod

2. **Database Security**
   - Enable RLS on all tables
   - Use service role key only in server-side code
   - Validate all user inputs
   - Sanitize data before database operations

3. **Rate Limiting**
   - Implement rate limiting on API routes
   - Use Vercel's edge config for distributed rate limiting
   - Respect external API rate limits

4. **Web Scraping**
   - Use proxies (Scrapfly handles this)
   - Rate limit scraping requests
   - Handle errors gracefully
   - Don't store unnecessary data

5. **Budget Safety**
   - Hard limits in code (not just database)
   - Daily spending alerts
   - Require explicit approval for large changes
   - Audit logs for all financial operations

---

## Performance Optimization

1. **Database Queries**
   - Use indexes appropriately
   - Implement pagination for large datasets
   - Cache frequently accessed data
   - Use database connection pooling

2. **API Calls**
   - Batch operations where possible
   - Cache API responses (with TTL)
   - Use webhooks instead of polling when available
   - Implement retry logic with exponential backoff

3. **Frontend**
   - Server-side rendering for initial load
   - Client-side caching with SWR or React Query
   - Lazy load components
   - Optimize images

4. **Background Jobs**
   - Process heavy operations asynchronously
   - Use queue system for reliability
   - Implement job priority
   - Monitor job performance

---

## Monitoring & Logging

```typescript
// src/lib/monitoring/logger.ts

import { createClient } from '@/lib/db/client';

export async function logAgentActivity(data: {
  agentName: string;
  action: string;
  input: any;
  output: any;
  success: boolean;
  error?: string;
  executionTimeMs: number;
  organizationId: string;
}) {
  const supabase = createClient();

  await supabase.from('agent_logs').insert({
    agent_name: data.agentName,
    action: data.action,
    input: data.input,
    output: data.output,
    success: data.success,
    error: data.error,
    execution_time_ms: data.executionTimeMs,
    organization_id: data.organizationId
  });

  // Also send to external monitoring if configured
  if (process.env.SENTRY_DSN) {
    // Send to Sentry
  }
}

export async function logError(error: Error, context: any) {
  console.error('Error:', error, context);

  if (process.env.NODE_ENV === 'production') {
    // Send to error tracking service
  }
}
```

---

## Success Criteria

**Phase 1 Complete When:**
- [ ] User can connect Meta ad account
- [ ] Campaign Manager agent can create campaigns
- [ ] Creative agent can generate Veo 3/Sora 2 prompts
- [ ] Dashboard displays active campaigns
- [ ] Basic performance metrics tracked

**Phase 2 Complete When:**
- [ ] Performance agent analyzes campaigns and makes recommendations
- [ ] Daily optimization runs automatically
- [ ] Learning database captures patterns
- [ ] Approval workflow functional

**Phase 3 Complete When:**
- [ ] Market Intelligence agent scrapes competitors
- [ ] Creative agent uses market insights
- [ ] Full agent orchestration working
- [ ] A/B test design and tracking operational

**Production Ready When:**
- [ ] All agents working reliably
- [ ] 95%+ uptime for 2 weeks
- [ ] Successfully managing €2000+ in ad spend
- [ ] Positive ROAS on test campaigns
- [ ] No budget overruns or safety violations
- [ ] UI polished and user-friendly

---

## Next Steps After MVP

1. **Add TikTok support** (currently Meta only)
2. **Automated video generation** (when Veo 3/Sora 2 APIs available)
3. **Multi-language support** for international campaigns
4. **Advanced audience targeting** with custom algorithms
5. **Predictive analytics** for budget forecasting
6. **White-label option** for agency resale
7. **Mobile app** for on-the-go monitoring
8. **Integration marketplace** (connect more tools)

---

## Budget Estimates

**Development:**
- Claude Code time: 6-8 weeks (your review time: ~15-20 hours)
- Testing & debugging: 1-2 weeks
- **Total: 8-10 weeks**

**Operational Costs (Monthly):**
- Supabase: €25-50 (Pro plan)
- Vercel: €20-80 (depends on usage)
- Anthropic API: €100-300 (depends on agent usage)
- Scrapfly: €100-200 (scraping volume)
- Meta/TikTok APIs: Free (just ad spend)
- **Total: €245-630/month**

**Testing Budget:**
- Phase 1: €500
- Phase 2: €1,000
- Phase 3: €1,000
- **Total: €2,500**

**Grand Total to Production: €2,500-3,000 + 10 weeks**

---

## Questions to Answer Before Starting

1. **Do you have Meta Business Manager setup with verified business?**
   - This can take 1-2 weeks if not already done
   - Required for API access

2. **What's your preference on framework versions?**
   - Latest stable (Next.js 15) or proven (Next.js 14)?
   - Recommendation: Next.js 14 for stability

3. **Self-hosted or cloud Supabase?**
   - Cloud easier to start (recommended)
   - Self-hosted for cost optimization later

4. **Veo 3 / Sora 2 access?**
   - Do you have API access yet?
   - If not, build with prompt generation first, add video gen later

5. **Team access patterns?**
   - Just you + Arinze initially?
   - Need multi-user auth from day 1?

6. **Preferred deployment regions?**
   - EU (GDPR compliance) or US (faster API access)?

---

## Final Notes

This is a **production-grade specification**. Every component is designed to be:
- Scalable (can handle growth)
- Maintainable (clean code, good structure)
- Testable (unit, integration, e2e tests)
- Secure (RLS, input validation, rate limiting)
- Reliable (error handling, logging, monitoring)

**This is not a prototype.** This is a system you can build a business on.

Claude Code will scaffold all of this and provide working implementations. Your job is to:
1. Review code quality
2. Test functionality
3. Provide domain expertise feedback
4. Make strategic decisions

**Let's build this.**
