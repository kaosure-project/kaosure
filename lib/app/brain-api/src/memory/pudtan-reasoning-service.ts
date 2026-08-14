import OpenAI from "openai";

import {
  BrainContextAssembler,
  type BrainContextAssembly,
} from "./brain-context-assembler.js";

export interface PudtanReasoningRequest {
  projectId: string;
  query: string;
  limit?: number;
}

export interface PudtanEvidence {
  source: "organizational_state" | "memory";
  memory_id?: string;
  title?: string;
  content: string;
}

export type PudtanConfidenceLevel =
  | "high"
  | "medium"
  | "low"
  | "none";

export type PudtanGateDecision =
  | "allow"
  | "caution"
  | "block";

export interface PudtanConfidenceGate {
  confidence: PudtanConfidenceLevel;
  score: number;
  decision: PudtanGateDecision;
  reason: string;
}

export interface PudtanReasoningResult {
  project_id: string;
  query: string;
  answer: string;
  understanding: string;
  evidence: PudtanEvidence[];
  recommendations: string[];
  risks: string[];
  next_actions: string[];
  context: BrainContextAssembly;
  confidence: PudtanConfidenceGate;
}

type OpenAIResult = {
  answer?: unknown;
  understanding?: unknown;
  recommendations?: unknown;
  risks?: unknown;
  next_actions?: unknown;
};

type PudtanQueryIntent =
  | "state"
  | "count"
  | "existence"
  | "memory"
  | "unknown";

export class PudtanReasoningService {
  private readonly client: OpenAI;

  constructor(
    private readonly contextAssembler: BrainContextAssembler,
  ) {
    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      throw new Error(
        "OPENAI_API_KEY is required.",
      );
    }

    this.client = new OpenAI({
      apiKey,
    });
  }

  async reason(
    request: PudtanReasoningRequest,
  ): Promise<PudtanReasoningResult> {
    const projectId = request.projectId.trim();
    const query = request.query.trim();

    if (!projectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!query) {
      throw new Error(
        "query is required.",
      );
    }

    const limit = this.normalizeLimit(
      request.limit ?? 5,
    );

    const context =
      await this.contextAssembler.assemble(
        projectId,
        query,
        limit,
      );

    const confidence =
      this.evaluateConfidence(
        query,
        context,
      );

    /*
     * COUNT must be answered from Organizational State directly.
     * Never let the LLM count retrieved Memory rows.
     */
    if (
      this.classifyQueryIntent(query) === "count" &&
      this.hasValidMemoryCounts(
        context.project_state,
      )
    ) {
      return this.buildCountResult(
        query,
        context,
        confidence,
      );
    }

    /*
     * IMPORTANT:
     *
     * Confidence Gate เป็น deterministic rule
     * และต้องทำงานก่อน OpenAI Reasoning
     *
     * LOW / NONE:
     * ห้ามส่งต่อให้ LLM วิเคราะห์เป็นข้อเท็จจริง
     */
    if (
      confidence.decision === "block"
    ) {
      return this.buildBlockedResult(
        query,
        context,
        confidence,
      );
    }

    /*
     * MEDIUM / HIGH:
     * อนุญาตให้เข้าสู่ Reasoning Layer
     */
    const reasoning =
      await this.callOpenAI(
        query,
        context,
        confidence,
      );

    return {
      project_id: projectId,
      query,
      answer: reasoning.answer,
      understanding:
        reasoning.understanding,
      evidence:
        this.extractEvidence(context),
      recommendations:
        this.stringArray(
          reasoning.recommendations,
        ),
      risks:
        this.stringArray(
          reasoning.risks,
        ),
      next_actions:
        this.stringArray(
          reasoning.next_actions,
        ),
      context,
      confidence,
    };
  }

  /**
   * Deterministic Confidence Gate
   *
   * Policy:
   *
   * STATE:
   *   Organizational State เป็น authoritative source
   *   สำหรับคำถามสถานะปัจจุบัน
   *
   * COUNT:
   *   ใช้ memory_counts โดยตรง
   *
   * EXISTENCE:
   *   ต้องมี explicit evidence ใน Organizational State
   *   ไม่อนุมานว่า "ไม่มี" เพียงเพราะ retrieval ไม่พบ
   *
   * MEMORY:
   *   ต้องพึ่ง Organizational Memory retrieval จริง
   *
   *   สำหรับภาษาไทย semantic retrieval สามารถเป็น
   *   หลักฐานหลักได้ แม้ lexical retrieval จะไม่ agreement
   *   หาก semantic evidence แข็งแรงและมี memory recall จริง
   *
   * HIGH:
   *   evidence แข็งแรงเพียงพอสำหรับประเภทคำถามนั้น
   *
   * MEDIUM:
   *   มี evidence แต่ยังมีข้อจำกัด
   *
   * LOW / NONE:
   *   ไม่อนุญาตให้ LLM ยืนยันข้อเท็จจริง
   */
  private evaluateConfidence(
    query: string,
    context: BrainContextAssembly,
  ): PudtanConfidenceGate {
    const retrieval =
      context.memory_context.retrieval;

    const state =
      context.project_state;

    const intent =
      this.classifyQueryIntent(query);

    const rawRetrievalScore =
      typeof retrieval?.confidence_score ===
      "number"
        ? retrieval.confidence_score
        : 0;

    const retrievalScore =
      this.clamp(
        rawRetrievalScore,
        0,
        1,
      );

    const semanticTop =
      this.clamp(
        retrieval?.top_similarity ?? 0,
        0,
        1,
      );

    const semanticSecond =
      this.clamp(
        retrieval?.second_similarity ?? 0,
        0,
        1,
      );

    const semanticCount =
      this.toNonNegativeInteger(
        retrieval?.semantic_result_count,
      );

    const lexicalCount =
      this.toNonNegativeInteger(
        retrieval?.lexical_result_count,
      );

    const agreement =
      retrieval?.retrieval_agreement === true;

    const recalled =
      context.memory_context.recalled === true;

    const memoryEvidenceConflict =
      this.hasMemoryEvidenceConflict(
        query,
        context,
      );

const explicitExistenceEvidence =
  intent === "existence"
    ? this.findExplicitExistenceEvidence(
        query,
        state,
      )
    : false;


    /*
     * ---------------------------------------------------------
     * ORGANIZATIONAL STATE
     * ---------------------------------------------------------
     */
    const hasProjectState =
      Boolean(
        state?.project?.id &&
          state?.project?.name,
      );

    const hasStateContext =
      Boolean(
        state?.context &&
          (
            state.context.current_phase ||
            state.context.current_focus ||
            state.context.current_objective ||
            state.context.current_progress ||
            state.context.current_blockers ||
            state.context.current_priority ||
            state.context.next_step
          ),
      );

    /*
     * Memory counts ต้องถือว่ามีหลักฐาน
     * แม้ค่าทั้งหมดจะเป็น 0
     *
     * เพราะ "0" เป็นข้อมูลจริง ไม่ใช่ absence
     */
    const hasMemoryCounts =
      Boolean(
        state?.memory_counts &&
          Number.isFinite(
            state.memory_counts.knowledge,
          ) &&
          Number.isFinite(
            state.memory_counts.idea,
          ) &&
          Number.isFinite(
            state.memory_counts.decision,
          ) &&
          Number.isFinite(
            state.memory_counts.task,
          ),
      );

    const stateEvidence =
      hasProjectState &&
      hasStateContext;

    /*
     * ---------------------------------------------------------
     * NO EVIDENCE
     * ---------------------------------------------------------
     */
    if (
      !stateEvidence &&
      !hasMemoryCounts &&
      !recalled &&
      semanticCount === 0 &&
      lexicalCount === 0
    ) {
      return {
        confidence: "none",
        score: 0,
        decision: "block",
        reason:
          "ไม่พบ Organizational State หรือ Organizational Memory ที่เพียงพอสำหรับตอบคำถามนี้",
      };
    }

    /*
     * ---------------------------------------------------------
     * RETRIEVAL QUALITY
     * ---------------------------------------------------------
     */

    const semanticMargin =
      Math.max(
        0,
        semanticTop -
          semanticSecond,
      );

    const semanticQuality =
      semanticTop >= 0.70
        ? 1
        : semanticTop >= 0.60
          ? 0.90
          : semanticTop >= 0.50
            ? 0.75
            : semanticTop >= 0.40
              ? 0.55
              : 0.30;

    /*
     * Base Memory Evidence Score
     */
    let memoryEvidenceScore =
      retrievalScore * 0.55 +
      semanticQuality * 0.30 +
      Math.min(
        semanticMargin,
        0.10,
      );

    /*
     * Agreement เป็น reinforcement
     * ไม่ใช่ hard requirement
     *
     * โดยเฉพาะภาษาไทย lexical retrieval
     * อาจไม่ match ทั้งที่ semantic retrieval
     * พบ evidence ที่ถูกต้อง
     */
    if (agreement) {
      memoryEvidenceScore += 0.10;
    }

    /*
     * ถ้าไม่มี recall จริง
     * retrieval diagnostics อย่างเดียว
     * ห้ามสร้าง confidence ปลอม
     */
    if (
      !recalled &&
      semanticCount === 0 &&
      lexicalCount === 0
    ) {
      memoryEvidenceScore = 0;
    }

    memoryEvidenceScore =
      this.clamp(
        memoryEvidenceScore,
        0,
        1,
      );
    /*
     * =====================================================
     * MEMORY CORROBORATION
     * =====================================================
     *
     * Semantic/lexical agreement ไม่ควรเป็นตัวชี้ขาด
     * เพียงอย่างเดียว โดยเฉพาะภาษาไทย
     *
     * หาก Organizational Memory หลายรายการให้หลักฐาน
     * ที่สอดคล้องกัน ควรถือเป็น corroborated evidence
     * แม้ lexical retrieval จะไม่พบผลลัพธ์ก็ตาม
     */
    const memoryItems =
      context.memory_context.memories ?? [];

    const corroboratedMemoryCount =
      memoryItems.filter(
        (memory) => {
          const evidence =
            memory.retrieval_evidence;

          if (!evidence) {
            return false;
          }

          const semanticScore =
            this.clamp(
              evidence.semantic_score ?? 0,
              0,
              1,
            );

          const combinedScore =
            this.clamp(
              evidence.combined_score ?? 0,
              0,
              1,
            );

          const queryRelevance =
            this.clamp(
              evidence.query_relevance ?? 0,
              0,
              1,
            );

          return (
            semanticScore >= 0.35 &&
            combinedScore >= 0.25 &&
            queryRelevance >= 0.40
          );
        },
      ).length;

    /*
     * 2 supporting memories = meaningful corroboration.
     * 3+ supporting memories = strong corroboration.
     */
    const corroborationScore =
      this.clamp(
        corroboratedMemoryCount / 3,
        0,
        1,
      );

    /*
     * Corroboration reinforces Memory evidence.
     * It does not override absence of recall.
     */
    if (
      recalled &&
      corroboratedMemoryCount >= 2
    ) {
      memoryEvidenceScore =
        this.clamp(
          memoryEvidenceScore +
            corroborationScore * 0.15,
          0,
          1,
        );
    }
    /*
     * =====================================================
     * COUNT
     * =====================================================
     *
     * จำนวน Knowledge / Idea / Decision / Task
     * เป็นข้อมูลตรงจาก Project State
     *
     * ไม่ต้องพึ่ง semantic similarity
     */
    if (
      intent === "count" &&
      hasMemoryCounts
    ) {
      return {
        confidence: "high",
        score: 0.95,
        decision: "allow",
        reason:
          "คำถามเป็นข้อมูลเชิงจำนวนและมี Memory Counts จาก Organizational State โดยตรง",
      };
    }

    /*
     * =====================================================
     * STATE
     * =====================================================
     *
     * ใช้ Organizational State เป็น authoritative
     * สำหรับ current phase / focus / progress /
     * blockers / priority / next step
     */
    if (
      intent === "state" &&
      stateEvidence
    ) {
      return {
        confidence: "high",
        score: 0.90,
        decision: "allow",
        reason:
          "คำถามเป็น Current Organizational State และมีข้อมูลสถานะจากแหล่งข้อมูลภายในองค์กรโดยตรง",
      };
    }

    /*
     * =====================================================
     * EXISTENCE
     * =====================================================
     *
     *      * เช่น:
     * - มี External Intelligence Layer แล้วหรือยัง?
     * - มี Voice Interface แล้วหรือยัง?
     *
     * ต้องมี explicit evidence
     */
    /*
 * =====================================================
 * MEMORY CONTRADICTION
 * =====================================================
 */
if (
  intent === "existence" &&
  memoryEvidenceConflict &&
  !explicitExistenceEvidence
) {
  return {
    confidence: "medium",
    score: Math.min(
      memoryEvidenceScore,
      0.60,
    ),
    decision: "caution",
    reason:
      "พบหลักฐานจาก Organizational Memory ที่ขัดแย้งกัน และยังไม่มี Organizational State ที่ authoritative เพียงพอสำหรับตัดสินข้อเท็จจริง",
  };
}
    if (
  intent === "existence"
) {
  if (explicitExistenceEvidence) {
        return {
          confidence: "high",
          score: 0.95,
          decision: "allow",
          reason:
            "พบหลักฐาน explicit ใน Organizational State สำหรับยืนยันสถานะการมีอยู่หรือยังไม่มีของสิ่งที่ถาม",
        };
      }

      /*
       * มี retrieval แต่ไม่มี explicit state
       *
       * ห้ามสรุปว่า "ไม่มี"
       */
      if (
        memoryEvidenceScore >= 0.40
      ) {
        return {
          confidence: "medium",
          score: memoryEvidenceScore,
          decision: "caution",
          reason:
            "พบข้อมูลที่อาจเกี่ยวข้อง แต่ไม่มีหลักฐาน explicit ใน Organizational State เพียงพอสำหรับยืนยันสถานะการมีอยู่",
        };
      }

      return {
        confidence: "low",
        score: memoryEvidenceScore,
        decision: "block",
        reason:
          "ไม่มีหลักฐาน explicit เพียงพอสำหรับยืนยันว่าระบบมีหรือยังไม่มีสิ่งที่ถาม",
      };
    }

    /*
     * =====================================================
     * MEMORY
     * =====================================================
     *
     * เช่น:
     * - พุดตานมีหน้าที่อะไร?
     * - Organizational Memory Loop คืออะไร?
     * - ความรู้ภายในสำคัญอย่างไร?
     * - Retrieval Confidence Gate เกี่ยวข้องอย่างไร?
     *
     * ต้องพึ่ง Memory retrieval จริง
     *
     * IMPORTANT:
     * ไม่ใช้ Organizational State เพื่อดัน
     * Memory question เป็น HIGH โดยอัตโนมัติ
     *
     * แต่ semantic retrieval ที่แข็งแรงสามารถ
     * เป็นหลักฐานเพียงพอได้ แม้ lexical ไม่ agreement
     */
    if (
      intent === "memory"
    ) {
      /*
       * =====================================================
   * CORROBORATED MEMORY
   * =====================================================
   *
   * ใช้เมื่อ semantic evidence ดีพอ และมี Memory
   * หลายรายการสนับสนุนคำถามเดียวกัน
   *
   * ไม่บังคับ lexical agreement
   */
  if (
  recalled &&
  corroboratedMemoryCount >= 2 &&
  corroborationScore >= 0.66 &&
  semanticTop >= 0.50 &&
  retrievalScore >= 0.50
) {
    return {
      confidence: "high",
      score: Math.max(
        memoryEvidenceScore,
        0.82,
      ),
      decision: "allow",
      reason:
        agreement
          ? "พบหลักฐานจาก Organizational Memory หลายรายการที่สอดคล้องกัน และ retrieval channels สนับสนุนกัน"
          : "พบหลักฐานจาก Organizational Memory หลายรายการที่สนับสนุนข้อสรุปเดียวกัน แม้ lexical retrieval จะไม่เห็นพ้องกัน",
    };
  }

      /*
       * Strong semantic retrieval:
       *
       * สำหรับภาษาไทย semantic similarity
       * เป็นหลักฐานสำคัญกว่าการบังคับ lexical agreement
       *
       * เกณฑ์:
       * - มี memory recall จริง
       * - semantic top >= 0.50
       * - retrieval score >= 0.50
       *
       * ทำให้ query เช่น:
       * "พุดตานมีหน้าที่อะไร"
       * สามารถผ่านได้เมื่อ semantic evidence
       * ชี้ไปยัง canonical organizational memory
       */
      if (
  recalled &&
  semanticTop >= 0.60 &&
  retrievalScore >= 0.55 &&
  semanticMargin >= 0.03
) {
  return {
    confidence: "high",
    score: Math.max(
      memoryEvidenceScore,
      agreement ? 0.85 : 0.80,
    ),
    decision: "allow",
    reason:
      agreement
        ? "พบหลักฐานจาก Organizational Memory ที่มี semantic evidence แข็งแรงและ retrieval channels สอดคล้องกัน"
        : "พบหลักฐานจาก Organizational Memory ที่มี semantic evidence แข็งแรงเพียงพอ แม้ lexical retrieval จะไม่เห็นพ้องกัน",
  };
}

      /*
       * Strong semantic top similarity
       * แม้ confidence score ของ retriever
       * จะต่ำกว่าที่คาดจากสูตรรวม
       *
       * ใช้เฉพาะเมื่อมี recall จริง
       */
      if (
        recalled &&
        semanticTop >= 0.60
      ) {
        return {
          confidence: "high",
          score: Math.max(
            memoryEvidenceScore,
            0.80,
          ),
          decision: "allow",
          reason:
            "Semantic retrieval พบหลักฐานจาก Organizational Memory ที่มีความเกี่ยวข้องสูงเพียงพอสำหรับตอบคำถาม",
        };
      }

      /*
       * Medium evidence
       */
      if (
        memoryEvidenceScore >= 0.40
      ) {
        return {
          confidence: "medium",
          score: memoryEvidenceScore,
          decision: "caution",
          reason:
            agreement
              ? "พบหลักฐานจาก Organizational Memory ที่เกี่ยวข้อง แต่ยังไม่แข็งแรงพอสำหรับ HIGH"
              : "พบหลักฐานจาก Organizational Memory แต่ semantic และ lexical retrieval ยังไม่สอดคล้องกันเพียงพอ",
        };
      }

      /*
       * Low evidence
       */
      if (
        memoryEvidenceScore > 0
      ) {
        return {
          confidence: "low",
          score: memoryEvidenceScore,
          decision: "block",
          reason:
            "พบหลักฐานจาก Organizational Memory บางส่วน แต่ยังไม่เพียงพอสำหรับยืนยันข้อเท็จจริง",
        };
      }

      return {
        confidence: "none",
        score: 0,
        decision: "block",
        reason:
          "ไม่พบหลักฐานจาก Organizational Memory ที่เพียงพอสำหรับตอบคำถามนี้",
      };
    }

    /*
     * =====================================================
     * UNKNOWN
     * =====================================================
     *
     * Conservative fallback
     */
    if (
      recalled &&
      agreement &&
      semanticTop >= 0.60 &&
      retrievalScore >= 0.55
    ) {
      return {
        confidence: "high",
        score: Math.max(
          memoryEvidenceScore,
          0.80,
        ),
        decision: "allow",
        reason:
          "พบหลักฐานจาก Organizational Memory ที่แข็งแรงและ retrieval channels สอดคล้องกัน",
      };
    }

    if (
      recalled &&
      semanticTop >= 0.50 &&
      retrievalScore >= 0.50
    ) {
      return {
        confidence: "high",
        score: Math.max(
          memoryEvidenceScore,
          0.80,
        ),
        decision: "allow",
        reason:
          "พบหลักฐานจาก Organizational Memory ที่มี semantic evidence แข็งแรงเพียงพอสำหรับตอบคำถาม",
      };
    }

    if (
      memoryEvidenceScore >= 0.40
    ) {
      return {
        confidence: "medium",
        score: memoryEvidenceScore,
        decision: "caution",
        reason:
          "พบหลักฐานที่เกี่ยวข้อง แต่ยังไม่สามารถยืนยันได้อย่างมั่นใจจาก evidence ที่มี",
      };
    }

    if (
      memoryEvidenceScore > 0
    ) {
      return {
        confidence: "low",
        score: memoryEvidenceScore,
        decision: "block",
        reason:
          "พบหลักฐานบางส่วน แต่ยังไม่เพียงพอสำหรับยืนยันข้อเท็จจริงขององค์กร",
      };
    }

    return {
      confidence: "none",
      score: 0,
      decision: "block",
      reason:
        "ไม่พบหลักฐานที่เพียงพอสำหรับตอบคำถามนี้",
    };
  }

  /**
   * Classify query before evaluating confidence.
   *
   * Important:
   * ใช้ query จริงจากผู้ใช้
   * ไม่พยายาม reconstruct query จาก assembled context
   */
  private classifyQueryIntent(
    query: string,
  ): PudtanQueryIntent {
    const q =
      query
        .trim()
        .toLowerCase();

    /*
     * COUNT
     */
    if (
      /กี่รายการ|กี่อัน|จำนวน|อย่างละกี่|กี่ตัว|กี่งาน|กี่เรื่อง/.test(
        q,
      )
    ) {
      return "count";
    }

    /*
     * EXISTENCE
     */
    if (
      /มี.*แล้วหรือยัง|มี.*หรือยัง|มี.*ไหม|มี.*หรือไม่|ยังไม่มี|มี.*แล้วไหม/.test(
        q,
      )
    ) {
      return "existence";
    }

    /*
     * STATE
     */
    if (
      /ตอนนี้|ปัจจุบัน|สถานะ|พัฒนาไปถึงไหน|ความคืบหน้า|progress|blocker|priority|next step|เฟส|phase/.test(
        q,
      )
    ) {
      return "state";
    }

    /*
     * MEMORY
     */
    if (
      /พุดตานมีหน้าที่|หน้าที่.*พุดตาน|organizational memory|memory loop|เรียนรู้|เติบโต|ความรู้ภายใน|internal knowledge|retrieval confidence gate|organizational decision history|decision history|ความรู้|แนวคิด|การตัดสินใจ/.test(
        q,
      )
    ) {
      return "memory";
    }

    return "unknown";
  }
private hasMemoryEvidenceConflict(
    query: string,
    context: BrainContextAssembly,
  ): boolean {
  const memories =
    context.memory_context.memories ?? [];

  if (memories.length < 2) {
    return false;
  }

  const relevantMemories =
    memories.filter((memory) => {
      const evidence =
        memory.retrieval_evidence;

      if (!evidence) {
        return false;
      }

      return (
        evidence.semantic_score >= 0.35 &&
        evidence.combined_score >= 0.25 &&
        evidence.query_relevance >= 0.40
      );
    });

  if (relevantMemories.length < 2) {
    return false;
  }

    /*
     * Conflict detection must compare the SAME subject.
     * Unrelated memories must never manufacture a contradiction.
     */
    const topicKeywords =
      this.getExistenceTopicKeywords(query);

    if (topicKeywords.length === 0) {
      return false;
    }

    const topicMemories =
      relevantMemories.filter((memory) => {
        const content =
          `${memory.title} ${memory.content}`.toLowerCase();

        return topicKeywords.every((keyword) =>
          content.includes(keyword),
        );
      });

    if (topicMemories.length < 2) {
      return false;
    }

    const positivePatterns = [
    /มีสำนักงาน/,
    /เปิดสำนักงาน/,
    /สำนักงาน.*แล้ว/,
    /เปิดแล้ว/,
    /พร้อมใช้งาน/,
    /มี.*แล้ว/,
  ];

  const negativePatterns = [
    /ยังไม่มีสำนักงาน/,
    /ไม่มีสำนักงาน/,
    /ยังไม่เปิด/,
    /ยังไม่มี/,
  ];

  let positiveEvidence = 0;
  let negativeEvidence = 0;

  for (
    const memory of topicMemories
  ) {
    const content =
      `${memory.title} ${memory.content}`.trim();

    const isNegative =
      negativePatterns.some(
        (pattern) =>
          pattern.test(content),
      );

    // Negative wording wins. For example,
    // "ยังไม่มีสำนักงาน" contains the substring "มีสำนักงาน"
    // but is semantically NEGATIVE, not positive.
    const isPositive =
      !isNegative &&
      positivePatterns.some(
        (pattern) =>
          pattern.test(content),
      );

    if (isPositive) {
      positiveEvidence += 1;
    }

    if (isNegative) {
      negativeEvidence += 1;
    }
  }

  return (
    positiveEvidence > 0 &&
    negativeEvidence > 0
  );
}
  private getExistenceTopicKeywords(
    query: string,
  ): string[] {
    const q =
      query
        .trim()
        .toLowerCase();

    if (q.includes("เชียงใหม่")) {
      return ["สำนักงาน", "เชียงใหม่"];
    }

    if (q.includes("ดวงจันทร์")) {
      return ["สำนักงาน", "ดวงจันทร์"];
    }

    if (q.includes("external intelligence")) {
      return ["external intelligence"];
    }

    if (
      q.includes("voice interface") ||
      q.includes("voice") ||
      q.includes("พูดคุยกับพุดตาน")
    ) {
      return ["voice"];
    }

    return [];
  }

  private findExplicitExistenceEvidence(
    query: string,
    state: BrainContextAssembly["project_state"],
  ): boolean {
    const stateText = [
      state.context?.current_phase ?? "",
      state.context?.current_focus ?? "",
      state.context?.current_objective ?? "",
      state.context?.current_progress ?? "",
      state.context?.current_blockers ?? "",
      state.context?.current_priority ?? "",
      state.context?.next_step ?? "",
    ]
      .join("\n")
      .toLowerCase();

    const q =
      query
        .trim()
        .toLowerCase();

    /*
     * External Intelligence
     */
    if (
      q.includes(
        "external intelligence",
      )
    ) {
      return this.hasExplicitStatus(
        stateText,
        [
          "external intelligence",
          "external intelligence layer",
        ],
      );
    }

    /*
     * Voice Interface
     */
    if (
      q.includes(
        "voice interface",
      ) ||
      q.includes("voice") ||
      q.includes(
        "พูดคุยกับพุดตาน",
      )
    ) {
      return this.hasExplicitStatus(
        stateText,
        [
          "voice interface",
          "voice",
          "พูดคุยกับพุดตาน",
        ],
      );
    }

    /*
     * Generic existence question:
     *
     * ถ้าไม่มี keyword ที่เรารู้จัก
     * อย่าอนุมานจาก retrieval
     */
    return false;
  }

  private hasExplicitStatus(
    stateText: string,
    keywords: string[],
  ): boolean {
    const keywordFound =
      keywords.some(
        (keyword) =>
          stateText.includes(
            keyword,
          ),
      );

    if (!keywordFound) {
      return false;
    }

    return (
      stateText.includes(
        "ยังไม่มี",
      ) ||
      stateText.includes(
        "ไม่มี",
      ) ||
      stateText.includes(
        "สำเร็จ",
      ) ||
      stateText.includes(
        "มีแล้ว",
      ) ||
      stateText.includes(
        "เปิดใช้งาน",
      )
    );
  }

  private async callOpenAI(
    query: string,
    context: BrainContextAssembly,
    confidence: PudtanConfidenceGate,
  ): Promise<
    OpenAIResult & {
      answer: string;
      understanding: string;
    }
  > {
    const systemPrompt = `
You are Pudtan, the organizational intelligence layer
of KaoSure Brain.

Your responsibility is to understand and analyze
the organization's own knowledge, project state,
progress, blockers, decisions, ideas, and tasks.

SOURCE RULES:

1. Organizational State and Memory are organizational facts.
2. For questions about current project status, progress,
   blockers, priorities, current focus, objectives,
   or next steps, treat ORGANIZATIONAL STATE as the
   primary authoritative source.
3. Use RELEVANT ORGANIZATIONAL MEMORY to explain,
   support, or supplement organizational state.
4. Retrieval diagnostics such as confidence score,
   semantic rank, lexical rank, and retrieval agreement
   are metadata about retrieval quality.
   They are NOT organizational facts.
5. Do not invent organizational facts.
6. Use ONLY the supplied organizational context.
7. Clearly distinguish facts from analysis.
8. Recommendations are suggestions, not existing facts.
9. Do not claim an action has been completed unless
   the supplied context proves it.
10. Do not create decisions or tasks.
11. Do not modify organizational state.
12. Answer in Thai when the user asks in Thai.
13. Be precise and concise.

SOURCE PRIORITY:

- Current Organizational State:
  authoritative for current status.
- Organizational Memory:
  authoritative for recorded organizational knowledge.
- Retrieval diagnostics:
  only indicate evidence quality.

EXISTENCE QUESTIONS:

If the user asks whether something exists,
do not infer existence or non-existence merely
from semantic similarity.

Only claim that something exists or does not exist
when the supplied organizational context explicitly
supports that conclusion.

CONFIDENCE GATE:

Confidence:
${confidence.confidence}

Confidence Score:
${confidence.score.toFixed(3)}

Gate Decision:
${confidence.decision}

Gate Reason:
${confidence.reason}

IMPORTANT:

The confidence gate has already been evaluated
by the application.

If confidence is MEDIUM:

- Be cautious.
- Explicitly identify limitations.
- Do not present uncertain evidence as established fact.

If confidence is HIGH:

- You may provide a normal evidence-based analysis.
- Still do not invent facts.

Return ONLY valid JSON matching:

{
  "answer": "string",
  "understanding": "string",
  "recommendations": ["string"],
  "risks": ["string"],
  "next_actions": ["string"]
}
`.trim();

    const userPrompt = `
USER QUERY:
${query}

CONFIDENCE GATE:
${JSON.stringify(
  confidence,
  null,
  2,
)}

ORGANIZATIONAL AND MEMORY CONTEXT:

${context.assembled_text}

Analyze the query using ONLY the supplied
organizational context and memory.

Do not invent missing facts.
`.trim();

    const model =
      process.env.PUDTAN_REASONING_MODEL ??
      "gpt-5-mini";
      

    const response =
      await this.client.responses.create({
        model,
        input: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: userPrompt,
          },
        ],
        text: {
          format: {
            type: "json_object",
          },
        },
      });

    const raw =
      response.output_text?.trim();

    if (!raw) {
      throw new Error(
        "OpenAI returned an empty reasoning response.",
      );
    }

    let parsed: OpenAIResult;

    try {
      parsed = JSON.parse(raw);
    } catch {
      throw new Error(
        "Pudtan reasoning response was not valid JSON.",
      );
    }

    const answer =
      typeof parsed.answer === "string"
        ? parsed.answer.trim()
        : "";

    const understanding =
      typeof parsed.understanding ===
      "string"
        ? parsed.understanding.trim()
        : "";

    if (!answer) {
      throw new Error(
        "Pudtan reasoning response is missing answer.",
      );
    }

    return {
      ...parsed,
      answer,
      understanding,
    };
  }

  /**
   * Response สำหรับ LOW / NONE
   *
   * จุดสำคัญ:
   * ไม่เรียก OpenAI
   * ไม่ให้ LLM ตีความ evidence อ่อน
   */
  private hasValidMemoryCounts(
    state: BrainContextAssembly["project_state"],
  ): boolean {
    const counts =
      state?.memory_counts;

    return Boolean(
      counts &&
      Number.isInteger(counts.knowledge) &&
      counts.knowledge >= 0 &&
      Number.isInteger(counts.idea) &&
      counts.idea >= 0 &&
      Number.isInteger(counts.decision) &&
      counts.decision >= 0 &&
      Number.isInteger(counts.task) &&
      counts.task >= 0,
    );
  }

  private buildCountResult(
    query: string,
    context: BrainContextAssembly,
    confidence: PudtanConfidenceGate,
  ): PudtanReasoningResult {
    const counts =
      context.project_state.memory_counts!;

    const total =
      counts.knowledge +
      counts.idea +
      counts.decision +
      counts.task;

    return {
      project_id: context.project_state.project.id,
      query,
      answer:
        `จาก Organizational State ล่าสุด มี Knowledge ${counts.knowledge} รายการ, ` +
        `Idea ${counts.idea} รายการ, Decision ${counts.decision} รายการ และ ` +
        `Task ${counts.task} รายการ รวมทั้งหมด ${total} รายการ`,
      understanding:
        "คำถามนี้เป็นคำถามเชิงจำนวน จึงใช้ memory_counts จาก Organizational State โดยตรง และไม่ใช้จำนวน Memory ที่ retrieval คืนมาเป็นตัวแทนของจำนวนจริง",
      evidence: this.extractEvidence(context),
      recommendations: [],
      risks: [],
      next_actions: [],
      context,
      confidence,
    };
  }

  private buildBlockedResult(
    query: string,
    context: BrainContextAssembly,
    confidence: PudtanConfidenceGate,
  ): PudtanReasoningResult {
    const retrieval =
      context.memory_context.retrieval;

    const answer =
      confidence.confidence === "none"
        ? "ยังไม่มีข้อมูลใน Organizational Memory เพียงพอสำหรับตอบคำถามนี้อย่างน่าเชื่อถือ"
        : "ยังไม่สามารถยืนยันคำตอบจาก Organizational Memory ได้ เนื่องจากหลักฐานที่ค้นคืนมามีความเชื่อมั่นต่ำ";

    const understanding =
      confidence.confidence === "none"
        ? "ไม่พบหลักฐานที่เพียงพอจาก Organizational Memory สำหรับคำถามนี้ จึงไม่ควรสรุปเป็นข้อเท็จจริง"
        : [
            "พบ Memory ที่อาจเกี่ยวข้องบางส่วน",
            `แต่ Retrieval Confidence อยู่ที่ ${confidence.score.toFixed(3)}`,
            `Semantic Results: ${
              retrieval?.semantic_result_count ??
              0
            }`,
            `Lexical Results: ${
              retrieval?.lexical_result_count ??
              0
            }`,
            `Retrieval Agreement: ${
              retrieval?.retrieval_agreement ===
              true
                ? "true"
                : "false"
            }`,
            "จึงไม่ควรนำผลลัพธ์เหล่านี้มายืนยันเป็นข้อเท็จจริงขององค์กร",
          ].join("\n");

    return {
      project_id: context.project_state.project.id,
      query,
      answer,
      understanding,
      evidence:
        this.extractEvidence(context),
      recommendations: [
        "ค้นหาหรือจัดเตรียมข้อมูลจากแหล่งข้อมูลภายในองค์กรที่เป็นทางการ",
        "บันทึกข้อมูลที่ได้รับการยืนยันเข้าสู่ Organizational Memory พร้อม source และ provenance",
        "ปรับปรุง Retrieval Ranking และ Confidence Gate สำหรับคำถามประเภทนี้",
      ],
      risks: [
        "หากนำผลการค้นคืนที่มี confidence ต่ำไปใช้เป็นข้อเท็จจริง อาจทำให้เกิดการวิเคราะห์ผิดพลาด",
        "ข้อมูลภายในองค์กรอาจยังไม่ครบถ้วนสำหรับตอบคำถามนี้",
      ],
      next_actions: [
        "ตรวจสอบว่าข้อมูลที่ต้องการมีอยู่ใน Organizational Memory หรือไม่",
        "หากไม่มี ให้นำข้อมูลจากแหล่งข้อมูลภายในที่เชื่อถือได้เข้าสู่ Memory",
        "ทดสอบคำถามเดิมอีกครั้งหลังมีหลักฐานที่เพียงพอ",
      ],
      context,
      confidence,
    };
  }

  private normalizeConfidence(
    value: unknown,
  ): PudtanConfidenceLevel {
    if (
      value === "high" ||
      value === "medium" ||
      value === "low" ||
      value === "none"
    ) {
      return value;
    }

    return "none";
  }

  private normalizeLimit(
    value: number,
  ): number {
    if (!Number.isFinite(value)) {
      return 5;
    }

    return Math.min(
      20,
      Math.max(
        1,
        Math.floor(value),
      ),
    );
  }

  private clamp(
    value: number,
    min: number,
    max: number,
  ): number {
    return Math.min(
      max,
      Math.max(min, value),
    );
  }

  private toNonNegativeInteger(
    value: unknown,
  ): number {
    if (
      typeof value !== "number" ||
      !Number.isFinite(value)
    ) {
      return 0;
    }

    return Math.max(
      0,
      Math.floor(value),
    );
  }

  private stringArray(
    value: unknown,
  ): string[] {
    if (!Array.isArray(value)) {
      return [];
    }

    return value.filter(
      (
        item,
      ): item is string =>
        typeof item === "string" &&
        item.trim().length > 0,
    );
  }

  private extractEvidence(
    context: BrainContextAssembly,
  ): PudtanEvidence[] {
    const evidence: PudtanEvidence[] = [];

    const state =
      context.project_state;

    evidence.push({
      source:
        "organizational_state",
      content: [
        `Project: ${state.project.name}`,
        `Status: ${state.project.status}`,
        `Phase: ${
          state.context?.current_phase ??
          "unknown"
        }`,
        `Focus: ${
          state.context?.current_focus ??
          "unknown"
        }`,
        `Objective: ${
          state.context?.current_objective ??
          "unknown"
        }`,
        `Priority: ${
          state.context?.current_priority ??
          "unknown"
        }`,
        `Next Step: ${
          state.context?.next_step ??
          "unknown"
        }`,
      ].join("\n"),
    });

    for (
      const memory
      of context.memory_context.memories
    ) {
      evidence.push({
        source: "memory",
        memory_id: memory.id,
        title: memory.title,
        content: memory.content,
      });
    }

    return evidence;
  }
}