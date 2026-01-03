# CLAUDE.md - Guidelines for Claude Code

This document provides guidelines for Claude Code when working on the AI Ad Agency System.

## Project Overview

This is a production-grade, multi-agent AI system for autonomous Facebook and TikTok ad management with AI-generated creative concepts. The system must be reliable, secure, and maintainable.

---

## Code Quality Standards

### TypeScript Standards
- **Strict mode enabled** - No `any` types without explicit justification
- **Explicit return types** for all functions
- **Interface over type** for object shapes
- **Enums for constants** with multiple related values
- **Proper error handling** - never swallow errors silently

```typescript
// ✅ Good
async function createCampaign(params: CreateCampaignParams): Promise<Campaign> {
  try {
    const result = await apiCall(params);
    return result;
  } catch (error) {
    logger.error('Campaign creation failed', { error, params });
    throw new CampaignCreationError('Failed to create campaign', { cause: error });
  }
}

// ❌ Bad
async function createCampaign(params: any): Promise<any> {
  try {
    return await apiCall(params);
  } catch (e) {
    // Error swallowed
  }
}
```

### File Organization
- **One component/agent per file**
- **Co-locate tests** with source files when practical
- **Barrel exports** for clean imports (`index.ts`)
- **Separate concerns** - no god files >500 lines

### Naming Conventions
- **PascalCase** - Components, Classes, Types, Interfaces
- **camelCase** - Functions, variables, methods
- **SCREAMING_SNAKE_CASE** - Constants
- **kebab-case** - File names, URLs

```typescript
// Files
market-intelligence-agent.ts
use-campaign-data.tsx
campaign-card.tsx

// Code
const MAX_DAILY_BUDGET = 5000;
class MarketIntelligenceAgent {}
interface CampaignConfig {}
function createCampaign() {}
```

### Comments & Documentation
- **JSDoc for public APIs** - especially agent tools and utilities
- **Inline comments for complex logic** - why, not what
- **TODO comments** must include issue number or name
- **No commented-out code** - use git history

```typescript
/**
 * Scrapes Meta Ad Library for competitor ads in a specific category.
 *
 * @param params - Search parameters
 * @param params.searchTerm - Product category or advertiser name
 * @param params.country - ISO country code (default: "US")
 * @param params.maxResults - Maximum ads to return (default: 50)
 * @returns Array of ad objects with metadata
 * @throws {ScrapingError} When rate limited or blocked
 *
 * @example
 * ```typescript
 * const ads = await scrapeMetaAdLibrary({
 *   searchTerm: "fitness products",
 *   country: "US",
 *   maxResults: 20
 * });
 * ```
 */
export async function scrapeMetaAdLibrary(params: ScrapeParams): Promise<Ad[]> {
  // Implementation
}
```

---

## Agent Development Guidelines

### Agent Structure Pattern
All agents follow this structure:

```typescript
// 1. System prompt (defines agent behavior)
const SYSTEM_PROMPT = `...`;

// 2. Agent class extending BaseAgent
export class MyAgent extends BaseAgent {
  constructor() {
    super({
      name: 'my-agent',
      model: 'claude-sonnet-4-20250514',
      temperature: 0.7,
      maxTokens: 4000,
      systemPrompt: SYSTEM_PROMPT,
      tools: [tool1, tool2]
    });
  }

  // 3. Main execute method
  async execute(input: MyAgentInput): Promise<AgentResponse> {
    // Input validation
    // Call Claude with tools
    // Handle tool execution
    // Log activity
    // Return response
  }

  // 4. Helper methods
  private buildPrompt(input: any): string {}
}
```

### Tool Development Pattern
```typescript
export const myTool: Tool = {
  name: 'tool_name',
  description: 'Clear description for Claude to understand when to use this',
  input_schema: {
    type: 'object',
    properties: {
      param1: {
        type: 'string',
        description: 'What this parameter does'
      }
    },
    required: ['param1']
  },
  execute: async (input) => {
    // Input validation
    const validated = validateInput(input);

    // Execute tool logic
    const result = await performAction(validated);

    // Error handling
    if (!result.success) {
      throw new ToolExecutionError('Action failed');
    }

    // Return structured output
    return {
      success: true,
      data: result.data
    };
  }
};
```

### Error Handling in Agents
```typescript
// Always wrap agent execution in try-catch
async execute(input: any): Promise<AgentResponse> {
  const startTime = Date.now();

  try {
    // Agent logic
    const result = await this.performTask(input);

    // Log success
    await this.logActivity(
      'task_completed',
      input,
      result,
      true,
      undefined,
      Date.now() - startTime
    );

    return {
      success: true,
      output: result
    };

  } catch (error) {
    // Log failure
    await this.logActivity(
      'task_failed',
      input,
      null,
      false,
      error.message,
      Date.now() - startTime
    );

    return {
      success: false,
      output: null,
      error: error.message
    };
  }
}
```

---

## Database Guidelines

### Query Patterns
```typescript
// ✅ Use typed queries
import { Database } from '@/types/database';
import { createClient } from '@/lib/db/client';

const supabase = createClient();

const { data, error } = await supabase
  .from('campaigns')
  .select('id, name, status, performance_metrics(*)')
  .eq('organization_id', orgId)
  .eq('status', 'active')
  .order('created_at', { ascending: false })
  .limit(10);

if (error) throw new DatabaseError('Failed to fetch campaigns', { cause: error });

// ✅ Use transactions for related operations
const { data, error } = await supabase.rpc('create_campaign_with_adsets', {
  campaign_data: campaignData,
  adset_data: adSetData
});

// ❌ Don't use raw SQL unless absolutely necessary
```

### RLS Policies
- **Never bypass RLS** in application code
- **Test RLS policies** with different user contexts
- **Document policy logic** in migration files

```sql
-- ✅ Good: Clear, tested policy
CREATE POLICY "Users can view own org campaigns"
  ON campaigns FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id
      FROM organization_members
      WHERE user_id = auth.uid()
    )
  );

-- ✅ Include comment explaining why
COMMENT ON POLICY "Users can view own org campaigns" ON campaigns IS
  'Ensures users can only see campaigns belonging to their organization';
```

---

## API Integration Guidelines

### External API Calls
```typescript
// ✅ Proper error handling and retry logic
async function callExternalAPI<T>(
  apiCall: () => Promise<T>,
  retries = 3
): Promise<T> {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      return await apiCall();
    } catch (error) {
      if (attempt === retries) throw error;

      // Exponential backoff
      await sleep(Math.pow(2, attempt) * 1000);

      // Log retry
      logger.warn(`API call failed, retrying (${attempt}/${retries})`);
    }
  }

  throw new Error('Should not reach here');
}

// Usage
const result = await callExternalAPI(() =>
  metaAPI.createCampaign(params)
);
```

### Rate Limiting
```typescript
// ✅ Implement rate limiting for external APIs
import { RateLimiter } from 'limiter';

const metaAPILimiter = new RateLimiter({
  tokensPerInterval: 200,
  interval: 'hour'
});

async function makeMetaAPICall(fn: () => Promise<any>) {
  await metaAPILimiter.removeTokens(1);
  return await fn();
}
```

---

## Testing Guidelines

### Unit Tests
```typescript
// tests/unit/agents/market-intelligence.test.ts

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { MarketIntelligenceAgent } from '@/agents/market-intelligence/agent';

// ✅ Mock external dependencies
vi.mock('@/lib/api/scrapfly');

describe('MarketIntelligenceAgent', () => {
  let agent: MarketIntelligenceAgent;

  beforeEach(() => {
    agent = new MarketIntelligenceAgent();
    vi.clearAllMocks();
  });

  describe('execute', () => {
    it('should research category successfully', async () => {
      // Arrange
      const input = { task: 'research_category', productCategory: 'fitness' };

      // Act
      const result = await agent.execute(input);

      // Assert
      expect(result.success).toBe(true);
      expect(result.output).toBeDefined();
    });

    it('should handle scraping failures gracefully', async () => {
      // Arrange
      const input = { task: 'research_category', productCategory: 'fitness' };
      vi.mocked(scrapfly.scrape).mockRejectedValue(new Error('Rate limited'));

      // Act
      const result = await agent.execute(input);

      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toContain('Rate limited');
    });
  });
});
```

### Integration Tests
```typescript
// tests/integration/campaign-flow.test.ts

describe('Campaign Creation Flow', () => {
  // ✅ Test full workflows
  it('should create campaign from product to launch', async () => {
    // Setup test data
    const product = await createTestProduct();

    // Execute workflow
    const orchestrator = new OrchestratorAgent();
    const result = await orchestrator.launchNewProductCampaign({
      productId: product.id,
      budget: 100,
      targeting: testTargeting
    });

    // Verify end state
    expect(result.success).toBe(true);

    const campaign = await getCampaign(result.campaignId);
    expect(campaign.status).toBe('active');
  });
});
```

### Test Data Management
```typescript
// tests/helpers/factories.ts

// ✅ Use factories for test data
export function createTestProduct(overrides = {}) {
  return {
    name: 'Test Product',
    category: 'fitness',
    price: 49.99,
    ...overrides
  };
}

export function createTestCampaign(overrides = {}) {
  return {
    name: 'Test Campaign',
    daily_budget: 50,
    status: 'active',
    ...overrides
  };
}
```

---

## Security Best Practices

### Input Validation
```typescript
// ✅ Always validate and sanitize inputs
import { z } from 'zod';

const CreateCampaignSchema = z.object({
  name: z.string().min(1).max(100),
  daily_budget: z.number().min(5).max(10000),
  targeting: z.object({
    age_min: z.number().min(18).max(65),
    age_max: z.number().min(18).max(65),
    countries: z.array(z.string().length(2))
  })
});

export async function createCampaign(input: unknown) {
  // Validate
  const validated = CreateCampaignSchema.parse(input);

  // Now safe to use
  return await db.insert(validated);
}
```

### Secrets Management
```typescript
// ✅ Never log secrets
function logAPICall(url: string, headers: Record<string, string>) {
  const sanitized = { ...headers };
  delete sanitized.Authorization;
  delete sanitized['X-API-Key'];

  logger.info('API call', { url, headers: sanitized });
}

// ✅ Never commit secrets
// Use .env files (gitignored)
// Use Vercel environment variables for production
```

### SQL Injection Prevention
```typescript
// ✅ Use parameterized queries (Supabase does this automatically)
const { data } = await supabase
  .from('campaigns')
  .select('*')
  .eq('name', userInput); // Safe - parameterized

// ❌ Never build raw SQL with string concatenation
const query = `SELECT * FROM campaigns WHERE name = '${userInput}'`; // DANGEROUS
```

---

## Performance Optimization

### Database Optimization
```typescript
// ✅ Use proper indexes
CREATE INDEX idx_campaigns_org_status ON campaigns(organization_id, status);

// ✅ Fetch only needed columns
const { data } = await supabase
  .from('campaigns')
  .select('id, name, status') // Not SELECT *
  .eq('organization_id', orgId);

// ✅ Use pagination for large datasets
const pageSize = 50;
const { data } = await supabase
  .from('campaigns')
  .select('*')
  .range(page * pageSize, (page + 1) * pageSize - 1);
```

### React Performance
```typescript
// ✅ Use React.memo for expensive components
export const CampaignCard = React.memo(({ campaign, metrics }: Props) => {
  // Component code
});

// ✅ Use useMemo for expensive calculations
const sortedCampaigns = useMemo(() => {
  return campaigns.sort((a, b) => b.spend - a.spend);
}, [campaigns]);

// ✅ Use useCallback for callbacks passed to children
const handlePause = useCallback((id: string) => {
  pauseCampaign(id);
}, [pauseCampaign]);
```

### API Call Optimization
```typescript
// ✅ Batch API calls when possible
const results = await Promise.all([
  getMetrics(id1),
  getMetrics(id2),
  getMetrics(id3)
]);

// ✅ Better: Use batch endpoint if available
const results = await getBatchMetrics([id1, id2, id3]);

// ✅ Cache frequent requests
const getCampaignsCached = cache(async (orgId: string) => {
  return await db.getCampaigns(orgId);
}, { ttl: 60 }); // 60 second cache
```

---

## Git Commit Guidelines

### Commit Message Format
```
type(scope): brief description

Longer explanation if needed.

Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code change (no feature/fix)
- `perf`: Performance improvement
- `test`: Add/update tests
- `chore`: Maintenance (deps, config)

**Examples:**
```bash
feat(agents): add market intelligence agent with scraping
fix(campaign-execution): prevent budget overrun on Meta API
docs(readme): update setup instructions
refactor(db): extract query helpers to separate file
test(agents): add unit tests for creative agent
chore(deps): update Next.js to 14.2.0
```

### Branch Naming
```
feature/agent-market-intelligence
fix/budget-calculation-error
refactor/database-queries
docs/api-integration-guide
```

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manually tested

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] No TypeScript errors
- [ ] Environment variables configured
- [ ] Database migrations applied
- [ ] API keys validated
- [ ] Rate limits configured

### Post-Deployment
- [ ] Health check endpoint responding
- [ ] Cron jobs running
- [ ] Error tracking working (Sentry)
- [ ] Database connections stable
- [ ] Monitor for 24 hours

### Rollback Plan
- [ ] Previous deployment tag known
- [ ] Database rollback script ready
- [ ] API keys preserved
- [ ] Monitoring alerts configured

---

## Common Pitfalls to Avoid

### Agent Development
❌ **Don't:** Create agents without clear system prompts
✅ **Do:** Write detailed system prompts that define behavior

❌ **Don't:** Ignore tool execution failures
✅ **Do:** Implement robust error handling and retries

❌ **Don't:** Make agents too smart (trying to do everything)
✅ **Do:** Keep agents focused on single responsibilities

### API Integration
❌ **Don't:** Assume external APIs are always available
✅ **Do:** Implement timeouts, retries, and fallbacks

❌ **Don't:** Make synchronous calls to slow APIs
✅ **Do:** Use async/await properly and consider queues

❌ **Don't:** Ignore rate limits
✅ **Do:** Implement rate limiting from day one

### Database
❌ **Don't:** Fetch entire tables into memory
✅ **Do:** Use pagination and proper indexing

❌ **Don't:** Update without transactions
✅ **Do:** Use transactions for related operations

❌ **Don't:** Store sensitive data in plain text
✅ **Do:** Encrypt sensitive fields

### React/Frontend
❌ **Don't:** Fetch data in useEffect without cleanup
✅ **Do:** Use SWR or React Query for data fetching

❌ **Don't:** Pass huge objects as props
✅ **Do:** Pass only needed data

❌ **Don't:** Forget loading and error states
✅ **Do:** Handle all UI states (loading, error, empty, success)

---

## Questions? Clarifications Needed?

When Claude Code encounters something ambiguous:

1. **Check this document first**
2. **Check the main spec** (CLAUDE_CODE_PROMPT.md)
3. **Look for similar patterns** in existing code
4. **Ask Sergio** if truly unclear

When asking for clarification:
- State what you're trying to do
- Explain the ambiguity
- Suggest 2-3 possible approaches
- Recommend one with rationale

---

## Code Review Checklist

Before marking work complete, verify:

- [ ] Code compiles with no TypeScript errors
- [ ] All tests pass
- [ ] Code follows style guidelines
- [ ] No security vulnerabilities introduced
- [ ] Performance implications considered
- [ ] Error handling implemented
- [ ] Logging added for important operations
- [ ] Documentation updated if needed
- [ ] No console.logs left in production code
- [ ] Environment variables properly used

---

## Additional Resources

- **Next.js Docs:** https://nextjs.org/docs
- **Supabase Docs:** https://supabase.com/docs
- **Anthropic API:** https://docs.anthropic.com
- **Meta Marketing API:** https://developers.facebook.com/docs/marketing-apis
- **TikTok Ads API:** https://ads.tiktok.com/marketing_api/docs

---

**Remember:** This is production code. Quality over speed. Test thoroughly. Document clearly. Security first.
