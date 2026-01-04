/**
 * Shared agent type definitions
 */

import type { AgentStatus, AgentType } from '@/types';

/**
 * Tool definition interface for agent tools
 */
export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: Record<string, unknown>;
}

/**
 * Tool execution result
 */
export interface ToolResult<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

/**
 * Agent context passed between tool executions
 */
export interface AgentContext {
  agentId: string;
  agentType: AgentType;
  sessionId: string;
  userId: string;
  startedAt: Date;
  metadata?: Record<string, unknown>;
}

/**
 * Agent state interface
 */
export interface AgentState {
  id: string;
  type: AgentType;
  status: AgentStatus;
  currentTask?: string;
  progress?: number;
  error?: string;
  lastActivity: Date;
  context: AgentContext;
}

/**
 * Agent message for Claude API
 */
export interface AgentMessage {
  role: 'user' | 'assistant';
  content: string;
}

/**
 * Agent log entry
 */
export interface AgentLogEntry {
  timestamp: Date;
  level: 'info' | 'warn' | 'error' | 'debug';
  agentId: string;
  agentType: AgentType;
  message: string;
  data?: Record<string, unknown>;
}
