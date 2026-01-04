# Supabase Setup

## Prerequisites

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Install Supabase CLI: `npm install -g supabase`

## Setup Instructions

### 1. Initialize Supabase locally

```bash
supabase init
```

### 2. Link to your project

```bash
supabase link --project-ref <your-project-ref>
```

### 3. Apply migrations

```bash
supabase db push
```

### 4. Generate TypeScript types

```bash
pnpm supabase gen types typescript --project-id <your-project-id> > src/types/database.ts
```

## Environment Variables

Copy `.env.example` to `.env.local` and fill in your Supabase credentials:

```
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

## Database Schema

The initial migration creates 13 tables:

| Table             | Description                                        |
| ----------------- | -------------------------------------------------- |
| ad_accounts       | Connected Meta/TikTok advertising accounts         |
| campaigns         | Advertising campaigns                              |
| ad_sets           | Ad groups/sets within campaigns                    |
| ads               | Individual advertisements                          |
| creatives         | Creative assets (images, videos, carousels)        |
| creative_concepts | AI-generated concepts awaiting human approval      |
| market_insights   | Competitive intelligence from ad libraries         |
| learnings         | Validated performance insights (with vector store) |
| agent_runs        | Audit log of AI agent executions                   |
| approvals         | Human approval workflow for agent actions          |
| daily_metrics     | Aggregated daily performance metrics               |
| safety_logs       | Budget safety and anomaly events                   |
| settings          | User preferences and configuration                 |

## Vector Search (pgvector)

The `learnings` and `market_insights` tables include `embedding` columns using pgvector for semantic search. Ensure the `vector` extension is enabled:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

## Row Level Security (RLS)

All tables have RLS enabled. Users can only access data associated with their ad accounts. The service role key bypasses RLS for server-side agent operations.
