import type {
  MemoryImportance,
  MemoryType,
} from "./memory-types.js";

export interface MemoryAnalysis {
  should_remember: boolean;
  type: MemoryType;
  importance: MemoryImportance;
  reason: string;
}

export function analyzeMemory(input: {
  content: string;
  source: string;
}): MemoryAnalysis {
  const content = input.content.trim();

  if (content.length === 0) {
    return {
      should_remember: false,
      type: "conversation",
      importance: "low",
      reason: "Empty content is not meaningful memory.",
    };
  }

  const normalized = content.toLowerCase();

  if (
    normalized.includes("ตัดสินใจ") ||
    normalized.includes("ตัดสิน") ||
    normalized.includes("decision") ||
    normalized.includes("decided")
  ) {
    return {
      should_remember: true,
      type: "decision",
      importance: "high",
      reason: "Content appears to contain a decision.",
    };
  }

  if (
    normalized.includes("ต้องทำ") ||
    normalized.includes("ต้องดำเนินการ") ||
    normalized.includes("todo") ||
    normalized.includes("task") ||
    normalized.includes("ทำต่อ") ||
    normalized.includes("ให้ทำ")
  ) {
    return {
      should_remember: true,
      type: "task",
      importance: "normal",
      reason: "Content appears to contain an actionable task.",
    };
  }

  if (
    normalized.includes("จำไว้") ||
    normalized.includes("จดจำ") ||
    normalized.includes("เก็บไว้") ||
    normalized.includes("remember") ||
    normalized.includes("save this")
  ) {
    return {
      should_remember: true,
      type: "knowledge",
      importance: "normal",
      reason: "User explicitly requested that the information be remembered.",
    };
  }

  return {
    should_remember: true,
    type: "conversation",
    importance: "low",
    reason: `Captured from ${input.source}.`,
  };
}