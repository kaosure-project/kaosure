import { analyzeMemory } from "./memory-analyzer.js";
import {
  buildMemoryContext,
  buildMemoryContextWithEvidence,
  type MemoryContext,
} from "./memory-context.js";

import type {
  MemoryInput,
  MemoryRecord,
  MemoryType,
} from "./memory-types.js";

import type { MemoryRepository } from "./memory-repository.js";

import { EmbeddingService } from "../embedding/embedding-service.js";

import type {
  MemoryEmbeddingRepository,
  MemoryEmbeddingSearchResult,
  MemoryEmbeddingType,
} from "../embedding/embedding-repository.js";

import {
  createContentHash,
} from "../embedding/postgres-memory-embedding-repository.js";

/**
 * Result returned when a memory is ingested.
 */
export interface MemoryIngestionResult {
  remembered: boolean;
  analysis: ReturnType<typeof analyzeMemory>;
  memory: MemoryRecord | null;
}

/**
 * Traditional lexical memory search result.
 */
export interface MemorySearchResult {
  query: string;
  project_id: string;
  count: number;
  memories: MemoryRecord[];
}

/**
 * Confidence level used by the organizational retrieval layer.
 *
 * HIGH:
 *   Strong semantic evidence and/or strong agreement
 *   between lexical and semantic retrieval.
 *
 * MEDIUM:
 *   Some relevant evidence exists, but the system
 *   should remain cautious.
 *
 * LOW:
 *   Weak evidence. Reasoning should not confidently
 *   assert organizational facts.
 *
 * NONE:
 *   No useful evidence was retrieved.
 */
export type MemoryConfidenceLevel =
  | "high"
  | "medium"
  | "low"
  | "none";

/**
 * Diagnostics describing how strongly retrieval
 * supports the current query.
 */
export interface MemoryRetrievalDiagnostics {
  confidence: MemoryConfidenceLevel;
  confidence_score: number;

  semantic_result_count: number;
  lexical_result_count: number;

  top_similarity: number;
  second_similarity: number;

  semantic_top_memory_id: string | null;
  lexical_top_memory_id: string | null;

  retrieval_agreement: boolean;

  reason: string;
}

/**
 * Recall result used by Brain Context Assembly.
 *
 * MemoryContext remains compatible with the existing
 * context builder while adding retrieval diagnostics.
 */
export interface MemoryRecallResult extends MemoryContext {
  recalled: boolean;
  retrieval: MemoryRetrievalDiagnostics;
}

/**
 * Internal scored retrieval candidate.
 */
interface ScoredMemory {
  memory: MemoryRecord;
  combinedScore: number;
  similarity: number;
  sourceQuality: number;
  queryRelevance: number;
  lexicalRank: number | null;
  semanticRank: number | null;
}

export class MemoryService {
  constructor(
    private readonly repository: MemoryRepository,
    private readonly embeddingService?: EmbeddingService,
    private readonly embeddingRepository?: MemoryEmbeddingRepository,
  ) {}

  /**
   * Ingest a new organizational memory.
   *
   * Behaviour:
   *
   * 1. Analyze whether the memory should be remembered.
   * 2. Persist the canonical memory record.
   * 3. Automatically create/update its embedding when
   *    semantic embedding dependencies are available.
   *
   * Embedding failure NEVER prevents the canonical
   * organizational memory from being stored.
   */
  async ingest(
    input: MemoryInput,
  ): Promise<MemoryIngestionResult> {
    const analysis = analyzeMemory({
      content: input.content,
      source: input.source,
    });

    if (!analysis.should_remember) {
      return {
        remembered: false,
        analysis,
        memory: null,
      };
    }

    const explicitType: MemoryType | undefined =
      input.type !== "conversation"
        ? input.type
        : undefined;

    const resolvedType =
      explicitType ?? analysis.type;

    const memory = await this.repository.create({
      ...input,
      type: resolvedType,
      importance:
        explicitType !== undefined
          ? input.importance
          : analysis.importance,
    });

    /**
     * Only domain memories that have a corresponding
     * embedding representation participate in semantic
     * organizational retrieval.
     */
    /*
     * Narrow MemoryType to the exact union accepted by
     * MemoryEmbeddingRepository before calling getByMemory()
     * and upsert().
     *
     * A boolean such as `isEmbeddingMemory` is not enough for
     * TypeScript to narrow `memory.type`, so keep the narrowed
     * value itself and use it for repository calls.
     */
    const embeddingType =
      this.toEmbeddingMemoryType(
        memory.type,
      );

    if (
      this.embeddingService &&
      this.embeddingRepository &&
      memory.project_id &&
      embeddingType
    ) {
      try {
        const embeddingText = [
          `Title: ${memory.title ?? ""}`,
          `Content: ${memory.content}`,
        ]
          .join("\n")
          .trim();

        if (embeddingText) {
          const contentHash =
            createContentHash(
              embeddingText,
            );

          const existing =
            await this.embeddingRepository.getByMemory(
              embeddingType,
              memory.id,
            );

          /**
           * Avoid unnecessary OpenAI calls when the
           * content has not changed.
           */
          if (
            !existing ||
            existing.content_hash !== contentHash
          ) {
            const embedding =
              await this.embeddingService.embed(
                embeddingText,
              );

            await this.embeddingRepository.upsert(
              memory.project_id,
              embeddingType,
              memory.id,
              contentHash,
              embedding,
            );
          }
        }
      } catch (error) {
        /**
         * Canonical memory persistence must remain
         * independent from the embedding provider.
         */
        console.error(
          "Memory embedding failed:",
          error,
        );
      }
    }

    return {
      remembered: true,
      analysis: {
        ...analysis,
        type: resolvedType,
      },
      memory,
    };
  }

  /**
   * Lexical search.
   *
   * This remains intentionally independent from semantic
   * retrieval so the system can compare both retrieval
   * strategies.
   */
  async search(
    projectId: string,
    query: string,
    limit = 10,
  ): Promise<MemorySearchResult> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedQuery =
      query.trim();

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!normalizedQuery) {
      throw new Error(
        "query is required.",
      );
    }

    const normalizedLimit =
      this.normalizeLimit(limit);

    const memories =
      await this.repository.search(
        normalizedProjectId,
        normalizedQuery,
        normalizedLimit,
      );

    return {
      query: normalizedQuery,
      project_id: normalizedProjectId,
      count: memories.length,
      memories,
    };
  }

  /**
   * Build organizational context.
   *
   * This now uses hybrid retrieval and exposes
   * retrieval diagnostics to the next intelligence layer.
   */
  async buildContext(
    projectId: string,
    query: string,
    limit = 5,
  ): Promise<MemoryRecallResult> {
    const normalizedProjectId =
      projectId.trim();

    const normalizedQuery =
      query.trim();

    if (!normalizedProjectId) {
      throw new Error(
        "project_id is required.",
      );
    }

    if (!normalizedQuery) {
      throw new Error(
        "query is required.",
      );
    }

    const normalizedLimit =
      this.normalizeLimit(limit);

    const retrieval =
      await this.hybridSearch(
        normalizedProjectId,
        normalizedQuery,
        normalizedLimit,
      );

    const memoryContext =
  buildMemoryContextWithEvidence(
    normalizedQuery,
    normalizedProjectId,
    (
      retrieval.scored ?? []
    ).map(
      (item) => ({
        memory: item.memory,
        retrieval_evidence: {
          semantic_score:
            Number(
              item.similarity.toFixed(4),
            ),

          combined_score:
            Number(
              item.combinedScore.toFixed(4),
            ),

          source_quality:
            Number(
              item.sourceQuality.toFixed(4),
            ),

          query_relevance:
            Number(
              item.queryRelevance.toFixed(4),
            ),

          semantic_rank:
            item.semanticRank,

          lexical_rank:
            item.lexicalRank,
        },
      }),
    ),
  );

    return {
      ...memoryContext,

      recalled:
        retrieval.memories.length > 0,

      retrieval:
        retrieval.diagnostics,
    };
  }

  /**
   * Recall organizational memory.
   */
  async recall(
    projectId: string,
    query: string,
    limit = 5,
  ): Promise<MemoryRecallResult> {
    return this.buildContext(
      projectId,
      query,
      limit,
    );
  }

  /**
   * Hybrid retrieval.
   *
   * Lexical retrieval provides exact textual relevance.
   *
   * Semantic retrieval provides conceptual relevance.
   *
   * RRF combines their rankings, while semantic
   * similarity contributes an additional quality signal.
   */
  private async hybridSearch(
    projectId: string,
    query: string,
    limit: number,
  ): Promise<{
    memories: MemoryRecord[];
     scored?: ScoredMemory[];
    diagnostics: MemoryRetrievalDiagnostics;
  }> {
    const lexicalMemories =
      await this.repository.search(
        projectId,
        query,
        Math.max(limit, 10),
      );

    /**
     * Without embedding dependencies, preserve the
     * original lexical-search behaviour.
     */
    if (
      !this.embeddingService ||
      !this.embeddingRepository
    ) {
      return {
        memories:
          lexicalMemories.slice(0, limit),

        diagnostics:
          this.buildLexicalOnlyDiagnostics(
            lexicalMemories,
          ),
      };
    }

    let semanticResults:
      MemoryEmbeddingSearchResult[];

    try {
      const queryEmbedding =
        await this.embeddingService.embed(
          query,
        );

      semanticResults =
        await this.embeddingRepository.searchSimilar(
          projectId,
          queryEmbedding,
          Math.max(limit * 3, 10),
        );
    } catch (error) {
      /**
       * Semantic search is an enhancement, not a
       * dependency of the core memory system.
       */
      console.error(
        "Semantic memory search failed:",
        error,
      );

      return {
        memories:
          lexicalMemories.slice(0, limit),

        diagnostics:
          this.buildLexicalOnlyDiagnostics(
            lexicalMemories,
          ),
      };
    }

    if (semanticResults.length === 0) {
      return {
        memories:
          lexicalMemories.slice(0, limit),

        diagnostics:
          this.buildLexicalOnlyDiagnostics(
            lexicalMemories,
          ),
      };
    }

    const lexicalMap =
      new Map<
        string,
        {
          memory: MemoryRecord;
          lexicalRank: number;
        }
      >(
        lexicalMemories.map(
          (memory, index) => [
            memory.id,
            {
              memory,
              lexicalRank: index,
            },
          ],
        ),
      );

    const semanticMap =
      new Map<
        string,
        {
          result: MemoryEmbeddingSearchResult;
          semanticRank: number;
        }
      >(
        semanticResults.map(
          (result, index) => [
            result.memory_id,
            {
              result,
              semanticRank: index,
            },
          ],
        ),
      );

    const candidateIds =
      new Set<string>([
        ...lexicalMap.keys(),
        ...semanticMap.keys(),
      ]);

    const records =
      new Map<string, MemoryRecord>();

    /**
     * Lexical results already contain canonical
     * MemoryRecords.
     */
    for (const memory of lexicalMemories) {
      records.set(
        memory.id,
        memory,
      );
    }

    /**
     * Semantic search only returns IDs.
     *
     * Resolve those IDs back to the canonical
     * organizational memory.
     */
    for (
      const semantic of semanticResults
    ) {
      if (
        records.has(
          semantic.memory_id,
        )
      ) {
        continue;
      }

      const memory =
        await this.repository.getById(
          semantic.memory_id,
        );

      if (
        memory &&
        memory.project_id === projectId
      ) {
        records.set(
          memory.id,
          memory,
        );
      }
    }

    const scored =
      Array.from(candidateIds)
        .map(
          (
            memoryId,
          ): ScoredMemory | null => {
            const memory =
              records.get(memoryId);

            if (!memory) {
              return null;
            }

            const lexical =
              lexicalMap.get(
                memoryId,
              );

            const semantic =
              semanticMap.get(
                memoryId,
              );

            /**
             * Reciprocal Rank Fusion.
             *
             * k=60 is intentionally conservative.
             */
            const k = 60;

            const lexicalScore =
              lexical
                ? 1 /
                  (k +
                    lexical.lexicalRank +
                    1)
                : 0;

            const semanticScore =
              semantic
                ? 1 /
                  (k +
                    semantic.semanticRank +
                    1)
                : 0;

            /**
             * Clamp provider similarity to [0, 1].
             */
            const similarity =
              semantic
                ? Math.max(
                    0,
                    Math.min(
                      1,
                      semantic.result
                        .similarity,
                    ),
                  )
                : 0;

            /**
             * Ranking v2 combines four signals:
             *
             * - lexical RRF rank: exact textual relevance
             * - semantic RRF rank: conceptual relevance
             * - embedding similarity: semantic strength
             * - source quality: organizational provenance
             *
             * Source quality is a ranking signal, not a truth guarantee.
             */
            const sourceQuality =
              this.getSourceQuality(memory.source);

            const queryRelevance =
              this.getQueryRelevance(
                query,
                memory,
              );

            /**
             * Ranking v3 adds direct query-to-memory relevance.
             *
             * This prevents a broadly related organizational memory
             * from outranking a memory that actually contains the
             * concepts requested by the user.
             */
            const combinedScore =
              lexicalScore +
              semanticScore +
              similarity * 0.25 +
              sourceQuality * 0.12 +
              queryRelevance * 0.28;

            return {
              memory,
              combinedScore,
              similarity,
              sourceQuality,
              queryRelevance,
              lexicalRank:
                lexical?.lexicalRank ?? null,
              semanticRank:
                semantic?.semanticRank ?? null,
            };
          },
        )
        .filter(
          (
            item,
          ): item is ScoredMemory =>
            item !== null,
        );

    scored.sort(
  (a, b) => {
    if (
      b.combinedScore !==
      a.combinedScore
    ) {
      return (
        b.combinedScore -
        a.combinedScore
      );
    }

    if (
      b.similarity !==
      a.similarity
    ) {
      return (
        b.similarity -
        a.similarity
      );
    }

    return (
      new Date(
        b.memory.updated_at,
      ).getTime() -
      new Date(
        a.memory.updated_at,
      ).getTime()
    );
  },
);

// ===== TEMP DEBUG: Ranking v3 =====
console.table(
  scored.slice(0, 10).map(
    (item, index) => ({
      rank: index + 1,
      id: item.memory.id,
      title: item.memory.title,
      combinedScore:
        Number(
          item.combinedScore.toFixed(6),
        ),
      similarity:
        Number(
          item.similarity.toFixed(6),
        ),
      sourceQuality:
        Number(
          item.sourceQuality.toFixed(6),
        ),
      queryRelevance:
        Number(
          item.queryRelevance.toFixed(6),
        ),
      lexicalRank:
        item.lexicalRank,
      semanticRank:
        item.semanticRank,
    }),
  ),
);
// ===== END TEMP DEBUG =====


    const top =
      scored.slice(0, limit);

    const diagnostics =
      this.buildRetrievalDiagnostics(
        lexicalMemories,
        semanticResults,
        top,
      );

    return {
  memories:
    top.map(
      (item) =>
        item.memory,
    ),

  scored: top,

  diagnostics,
};
  }

  /**
   * Assign a provenance quality score to the memory source.
   *
   * Test fixtures are intentionally down-weighted so they do not
   * outrank stronger organizational evidence merely because their
   * wording happens to be semantically similar to the query.
   */
  private getSourceQuality(
    source: string | undefined,
  ): number {
    const normalized =
      source?.trim().toLowerCase() ?? "";

    if (!normalized) {
      return 0.50;
    }

    if (
      normalized.includes("ranking-test") ||
      normalized.includes("encoding-test") ||
      normalized.includes("auto-embedding-test") ||
      normalized.includes("test")
    ) {
      return 0.10;
    }

    if (
      normalized.includes("organizational-seed-v1") ||
      normalized.includes("organization") ||
      normalized.includes("organizational") ||
      normalized.includes("production") ||
      normalized.includes("official")
    ) {
      return 1.00;
    }

    return 0.60;
  }

  /**
   * Score direct query-to-memory relevance.
   *
   * This is intentionally lightweight and deterministic. It uses
   * normalized query terms plus title/content matches so exact
   * concepts such as "ฐานข้อมูล", "embedding", "pgvector", and
   * "PostgreSQL" can outrank broadly related organizational prose.
   */
  private getQueryRelevance(
    query: string,
    memory: MemoryRecord,
  ): number {
    const queryTerms =
      this.extractQueryTerms(query);

    if (queryTerms.length === 0) {
      return 0;
    }

    const title =
      this.normalizeSearchText(
        memory.title ?? "",
      );

    const content =
      this.normalizeSearchText(
        memory.content,
      );

    const combined =
      `${title} ${content}`.trim();

    if (!combined) {
      return 0;
    }

    let matchedWeight = 0;
    let totalWeight = 0;

    for (const term of queryTerms) {
      const weight =
        this.queryTermWeight(term);

      totalWeight += weight;

      if (title.includes(term)) {
        matchedWeight +=
          weight * 1.50;
        continue;
      }

      if (content.includes(term)) {
        matchedWeight += weight;
      }
    }

    if (totalWeight === 0) {
      return 0;
    }

    const matchedTerms =
      queryTerms.filter(
        (term) =>
          title.includes(term) ||
          content.includes(term),
      );

    const coverage =
      matchedTerms.length /
      queryTerms.length;

    let score =
      (matchedWeight / totalWeight) *
        0.70 +
      coverage * 0.30;

    /**
     * Strong boost when a memory contains
     * multiple high-value technical concepts.
     */
    const technicalTerms =
      queryTerms.filter((term) =>
        this.isTechnicalQueryTerm(term),
      );

    if (technicalTerms.length > 0) {
      const matchedTechnicalTerms =
        technicalTerms.filter(
          (term) =>
            title.includes(term) ||
            content.includes(term),
        );

      const technicalCoverage =
        matchedTechnicalTerms.length /
        technicalTerms.length;

      score =
        score * 0.75 +
        technicalCoverage * 0.25;
    }

    return this.clamp(score);
  }

  private queryTermWeight(
    term: string,
  ): number {
    if (
      this.isTechnicalQueryTerm(term)
    ) {
      return 2.50;
    }

    if (term.length >= 8) {
      return 1.50;
    }

    if (term.length >= 5) {
      return 1.25;
    }

    return 1.00;
  }

  private isTechnicalQueryTerm(
    term: string,
  ): boolean {
    const technicalTerms = [
      "postgresql",
      "postgres",
      "supabase",
      "pgvector",
      "embedding",
      "embeddings",
      "vector",
      "vectors",
      "database",
      "databases",
      "ฐานข้อมูล",
      "ฐานข้อมูล",
      "เวกเตอร์",
      "embedding",
      "text-embedding-3-small",
      "openai",
      "api",
      "memory",
      "semantic",
      "semantic-search",
      "retrieval",
    ];

    return technicalTerms.includes(
      term,
    );
  }

  private extractQueryTerms(
    query: string,
  ): string[] {
    const normalized =
      this.normalizeSearchText(query);

    const terms =
      new Set<string>();

    /**
     * English / technical terms.
     *
     * This intentionally preserves terms such as:
     * PostgreSQL, pgvector, embedding,
     * text-embedding-3-small.
     */
    const latinTerms =
      normalized.match(
        /[a-z0-9][a-z0-9._-]*/giu,
      ) ?? [];

    for (const rawTerm of latinTerms) {
      const term =
        rawTerm.trim().toLowerCase();

      if (
        term.length >= 2 &&
        !this.isQueryStopWord(term)
      ) {
        terms.add(term);
      }
    }

    /**
     * Thai terms.
     *
     * Thai does not reliably use whitespace
     * between words, so we explicitly recognize
     * important organizational / technical concepts.
     */
    const thaiConcepts = [
      "ฐานข้อมูล",
      "ฐานข้อมูล",
      "ระบบฐานข้อมูล",
      "สร้าง embedding",
      "สร้างเอ็มเบดดิ้ง",
      "เอ็มเบดดิ้ง",
      "เวกเตอร์",
      "ค้นคืน",
      "ค้นหา",
      "ความรู้",
      "หน่วยความจำ",
      "องค์กร",
      "สถานะองค์กร",
      "พุดตาน",
      "พัฒนา",
      "ความคืบหน้า",
      "โครงการ",
      "ระบบ",
      "ข้อมูล",
    ];

    for (const concept of thaiConcepts) {
      const normalizedConcept =
        this.normalizeSearchText(
          concept,
        );

      if (
        normalized.includes(
          normalizedConcept,
        ) &&
        !this.isQueryStopWord(
          normalizedConcept,
        )
      ) {
        terms.add(
          normalizedConcept,
        );
      }
    }

    /**
     * Preserve meaningful whitespace chunks
     * as additional phrases.
     */
    for (
      const chunk of normalized.split(
        /\s+/u,
      )
    ) {
      const term =
        chunk.trim();

      if (
        term.length >= 3 &&
        !this.isQueryStopWord(term)
      ) {
        terms.add(term);
      }
    }

    /**
     * Remove broad conversational terms.
     */
    const filtered =
      [...terms].filter(
        (term) =>
          !this.isQueryStopWord(term),
      );

    return [
      ...new Set(filtered),
    ];
  }

  private isQueryStopWord(
    term: string,
  ): boolean {
    const stopWords = new Set([
      "และ",
      "หรือ",
      "ที่",
      "เป็น",
      "คือ",
      "ใช้",
      "ระบบ",
      "สร้าง",
      "ทำ",
      "ทำไม",
      "อย่างไร",
      "อะไร",
      "ไหน",
      "ใคร",
      "เมื่อไร",
      "ตอนนี้",
      "กำลัง",
      "แล้ว",
      "ไปถึง",
      "ถึงไหน",
      "ควร",
      "เรื่อง",
      "ของ",
      "ใน",
      "จาก",
      "กับ",
      "และ",
      "ให้",
      "ได้",
      "ไหม",
      "หรือไม่",
      "ตอน",
      "the",
      "and",
      "or",
      "what",
      "how",
      "why",
      "which",
      "where",
      "is",
      "are",
      "use",
      "using",
      "system",
    ]);

    return stopWords.has(
      term.trim().toLowerCase(),
    );
  }

  private normalizeSearchText(
    value: string,
  ): string {
    return value
      .toLowerCase()
      .replace(/[\u200B-\u200D\uFEFF]/gu, "")
      .replace(/[.,!?;:"'`()\[\]{}<>/\\|_+=*#@~^$%&:-]+/gu, " ")
      .replace(/\s+/gu, " ")
      .trim();
  }

  /**
   * Build diagnostics from both retrieval channels.
   *
   * Important:
   * This is a retrieval confidence signal.
   * It is NOT a statement that the retrieved
   * organizational fact is objectively true.
   */
  private buildRetrievalDiagnostics(
    lexicalMemories: MemoryRecord[],
    semanticResults: MemoryEmbeddingSearchResult[],
    scored: ScoredMemory[],
  ): MemoryRetrievalDiagnostics {
    /**
     * Diagnostics deliberately separates three concepts:
     *
     * 1. Raw semantic evidence
     * 2. Lexical evidence
     * 3. Final hybrid ranking
     *
     * semanticResults is ordered by vector similarity.
     * scored is ordered by Ranking v3.
     */

    const semanticTop =
      semanticResults[0];

    const semanticSecond =
      semanticResults[1];

    const semanticTopSimilarity =
      semanticTop
        ? this.clamp(
            semanticTop.similarity,
          )
        : 0;

    const semanticSecondSimilarity =
      semanticSecond
        ? this.clamp(
            semanticSecond.similarity,
          )
        : 0;

    const semanticTopMemoryId =
      semanticTop?.memory_id ??
      null;

    const semanticSecondMemoryId =
      semanticSecond?.memory_id ??
      null;

    const lexicalTopMemoryId =
      lexicalMemories[0]?.id ??
      null;

    /**
     * Agreement is a genuine retrieval-channel
     * agreement:
     *
     * semantic winner === lexical winner
     *
     * It must NOT use the hybrid-ranked winner.
     */
    const retrievalAgreement =
      semanticTopMemoryId !== null &&
      lexicalTopMemoryId !== null &&
      semanticTopMemoryId ===
        lexicalTopMemoryId;

    /**
     * Final hybrid winner.
     *
     * This is the memory actually returned first
     * by Ranking v3.
     */
    const firstScored =
      scored[0];

    const secondScored =
      scored[1];

    const finalTopMemoryId =
      firstScored?.memory.id ??
      null;

    const finalSecondMemoryId =
      secondScored?.memory.id ??
      null;

    const finalTopSimilarity =
      firstScored
        ? this.clamp(
            firstScored.similarity,
          )
        : 0;

    const finalSecondSimilarity =
      secondScored
        ? this.clamp(
            secondScored.similarity,
          )
        : 0;

    /**
     * Confidence should be based primarily on
     * the strongest semantic evidence, because
     * semantic similarity represents direct
     * query-to-memory relevance.
     *
     * The final hybrid ranking is used for
     * selecting the returned memories, but it
     * should not redefine what "top semantic
     * similarity" means.
     */
    let score =
      semanticTopSimilarity * 0.70;

    /**
     * Agreement between independent retrieval
     * channels is meaningful evidence.
     */
    if (retrievalAgreement) {
      score += 0.15;
    }

    /**
     * Semantic margin measures whether the best
     * semantic result is clearly ahead of the
     * second result.
     */
    const semanticMargin =
      Math.max(
        0,
        semanticTopSimilarity -
          semanticSecondSimilarity,
      );

    score +=
      Math.min(
        semanticMargin,
        0.10,
      );

    /**
     * Ranking-level signals provide bounded
     * reinforcement.
     *
     * They cannot dominate semantic evidence.
     */
    const queryRelevance =
      firstScored
        ? this.clamp(
            firstScored.queryRelevance,
          )
        : 0;

    score +=
      queryRelevance * 0.10;

    const sourceQuality =
      firstScored
        ? this.clamp(
            firstScored.sourceQuality,
          )
        : 0;

    score +=
      sourceQuality * 0.05;

    score =
      this.clamp(score);

    const confidence =
      this.confidenceLevel(
        score,
        semanticTopSimilarity,
        scored.length,
      );

    return {
      confidence,

      confidence_score:
        Number(
          score.toFixed(4),
        ),

      semantic_result_count:
        semanticResults.length,

      lexical_result_count:
        lexicalMemories.length,

      /**
       * These fields now have precise semantics:
       *
       * top_similarity =
       * highest raw semantic similarity.
       *
       * second_similarity =
       * second highest raw semantic similarity.
       */
      top_similarity:
        Number(
          semanticTopSimilarity.toFixed(4),
        ),

      second_similarity:
        Number(
          semanticSecondSimilarity.toFixed(4),
        ),

      semantic_top_memory_id:
        semanticTopMemoryId,

      lexical_top_memory_id:
        lexicalTopMemoryId,

      retrieval_agreement:
        retrievalAgreement,

      /**
       * The final hybrid winner is intentionally
       * not overloaded into semantic_top_memory_id.
       *
       * It remains internal to diagnostics.
       */
      reason:
        this.buildConfidenceReason(
          confidence,
          semanticTopSimilarity,
          retrievalAgreement,
          scored.length,
        ),
    };
  }

  private confidenceLevel(
    score: number,
    topSimilarity: number,
    resultCount: number,
  ): MemoryConfidenceLevel {
    if (
      resultCount === 0 ||
      topSimilarity <= 0
    ) {
      return "none";
    }

    /**
     * HIGH:
     *
     * Strong overall evidence and strong semantic
     * relevance. This remains intentionally strict.
     */
    if (
      score >= 0.70 &&
      topSimilarity >= 0.50
    ) {
      return "high";
    }

    /**
     * MEDIUM:
     *
     * The retrieval contains enough evidence for
     * Pudtan to reason about the result, even when
     * semantic similarity is not exceptionally high.
     *
     * This is important for organizational queries
     * where lexical relevance, query relevance,
     * provenance, and hybrid ranking can together
     * identify a useful memory.
     */
    if (
      score >= 0.40 &&
      topSimilarity >= 0.40
    ) {
      return "medium";
    }

    /**
     * LOW:
     *
     * Evidence exists, but it is too weak or too
     * semantically distant for confident reasoning.
     */
    if (score > 0) {
      return "low";
    }

    return "none";
  }

  private buildConfidenceReason(
    confidence: MemoryConfidenceLevel,
    topSimilarity: number,
    retrievalAgreement: boolean,
    resultCount: number,
  ): string {
    if (
      resultCount === 0 ||
      topSimilarity <= 0
    ) {
      return "ไม่พบหลักฐานจาก Organizational Memory ที่เกี่ยวข้อง";
    }

    if (confidence === "high") {
      return retrievalAgreement
        ? "Semantic และ lexical retrieval สอดคล้องกัน และหลักฐานโดยรวมมีความแข็งแรง"
        : "Hybrid retrieval พบหลักฐานที่มีความแข็งแรงเพียงพอสำหรับการให้ความมั่นใจสูง";
    }

    if (confidence === "medium") {
      return retrievalAgreement
        ? "Semantic และ lexical retrieval สนับสนุนหลักฐานเดียวกันในระดับที่เพียงพอสำหรับการวิเคราะห์"
        : "Semantic และ lexical retrieval เลือกหลักฐานต่างกัน แต่ Hybrid Ranking พบหลักฐานที่เกี่ยวข้องเพียงพอสำหรับการวิเคราะห์อย่างระมัดระวัง";
    }

    if (confidence === "low") {
      return "พบผลการค้นคืน แต่หลักฐานโดยรวมยังอ่อนเกินไปสำหรับการยืนยันข้อเท็จจริง";
    }

    return "ไม่พบหลักฐานที่เพียงพอสำหรับการยืนยันข้อเท็จจริง";
  }

  /**
   * Lexical-only fallback diagnostics.
   *
   * This deliberately never claims high confidence,
   * because lexical presence alone is insufficient
   * for organizational semantic reasoning.
   */
  private buildLexicalOnlyDiagnostics(
    lexicalMemories: MemoryRecord[],
  ): MemoryRetrievalDiagnostics {
    const hasResults =
      lexicalMemories.length > 0;

    return {
      confidence:
        hasResults
          ? "low"
          : "none",

      confidence_score:
        hasResults
          ? 0.25
          : 0,

      semantic_result_count: 0,

      lexical_result_count:
        lexicalMemories.length,

      top_similarity: 0,

      second_similarity: 0,

      semantic_top_memory_id:
        null,

      lexical_top_memory_id:
        lexicalMemories[0]?.id ??
        null,

      retrieval_agreement:
        false,

      reason:
        hasResults
          ? "ใช้ lexical retrieval เนื่องจาก semantic retrieval ไม่พร้อมใช้งาน จึงยังไม่ควรถือเป็นหลักฐาน semantic ที่มีความมั่นใจสูง"
          : "ไม่พบ Organizational Memory",
    };
  }

  /**
   * Convert the broad MemoryType union to the narrower
   * MemoryEmbeddingType union accepted by the embedding
   * repository.
   *
   * Supported embedding memory types:
   * - knowledge
   * - idea
   * - decision
   * - task
   *
   * Conversation/current_context/deprecated memories are
   * intentionally not embedded by this pipeline.
   */
  private toEmbeddingMemoryType(
    type: MemoryType,
  ): MemoryEmbeddingType | null {
    switch (type) {
      case "knowledge":
      case "idea":
      case "decision":
      case "task":
        return type;

      default:
        return null;
    }
  }

  private normalizeLimit(
    limit: number,
  ): number {
    if (
      !Number.isFinite(limit)
    ) {
      return 5;
    }

    return Math.min(
      Math.max(
        Math.trunc(limit),
        1,
      ),
      20,
    );
  }

  private clamp(
    value: number,
  ): number {
    return Math.max(
      0,
      Math.min(1, value),
    );
  }
}