import { pool } from "../db/postgres.js";

export type OrganizationalConsistencyStatus =
  | "consistent"
  | "stale"
  | "conflict";

export type OrganizationalConsistencySeverity =
  | "info"
  | "warning"
  | "critical";

export type OrganizationalSyncDecision =
  | "allow"
  | "review"
  | "block";

export interface OrganizationalConsistencyIssue {
  type:
    | "state_stale"
    | "state_missing"
    | "approved_decision_conflict"
    | "knowledge_conflict"
    | "blocked_task_conflict"
    | "project_status_conflict";

  severity: OrganizationalConsistencySeverity;

  message: string;

  evidence: {
    source:
      | "brain_contexts"
      | "brain_knowledge"
      | "brain_ideas"
      | "brain_decisions"
      | "brain_tasks"
      | "brain_projects";

    id?: string;

    related_id?: string;

    updated_at?: string;
  };
}

export interface OrganizationalConsistencyResult {
  status: OrganizationalConsistencyStatus;

  score: number;

  /**
   * Evidence coverage confidence.
   *
   * This measures whether enough organizational evidence
   * exists for deterministic evaluation.
   *
   * It does NOT mean that the underlying information
   * is factually true.
   */
  evidence_confidence: number;

  sync_decision: OrganizationalSyncDecision;

  checked_at: string;

  state_updated_at: string | null;

  latest_memory_updated_at: string | null;

  issues: OrganizationalConsistencyIssue[];

  summary: string;
}

type ContextRow = {
  id: string;
  updated_at: string;
};

type ProjectRow = {
  id: string;
  status: string;
  updated_at: string;
};

type MemoryTimestampRow = {
  updated_at: string;
};

type ApprovedDecisionRow = {
  id: string;
  title: string;
  decision: string;
  updated_at: string;
};

type KnowledgeRow = {
  id: string;
  title: string;
  content: string;
  updated_at: string;
};

type BlockedTaskRow = {
  id: string;
  title: string;
  blocked_reason: string | null;
  updated_at: string;
};

type MemoryCoverage = {
  knowledge: boolean;
  idea: boolean;
  decision: boolean;
  task: boolean;
};

export class OrganizationalConsistencyChecker {
  async check(
    projectId: string,
  ): Promise<OrganizationalConsistencyResult> {
    const normalizedProjectId =
      projectId.trim();

    if (!normalizedProjectId) {
      throw new Error("project_id is required.");
    }

    const checkedAt =
      new Date().toISOString();

    const project =
      await this.getProject(
        normalizedProjectId,
      );

    const context =
      await this.getContext(
        normalizedProjectId,
      );

    const latestMemoryUpdatedAt =
      await this.getLatestMemoryUpdatedAt(
        normalizedProjectId,
      );

    const issues: OrganizationalConsistencyIssue[] =
      [];

    /*
     * --------------------------------------------------
     * 1. Organizational State existence
     * --------------------------------------------------
     */

    if (!context) {
      issues.push({
        type: "state_missing",
        severity: "critical",
        message:
          "ไม่พบ Organizational State สำหรับ project นี้",
        evidence: {
          source: "brain_contexts",
        },
      });
    }

    /*
     * --------------------------------------------------
     * 2. Organizational State freshness
     * --------------------------------------------------
     *
     * State เป็น current snapshot
     * Memory มี lifecycle ของตัวเอง
     *
     * ถ้า Memory ใหม่กว่า State:
     * ไม่เขียนทับ State อัตโนมัติ
     * แต่ให้สถานะเป็น stale/review
     */

    if (
      context &&
      latestMemoryUpdatedAt &&
      this.isLater(
        latestMemoryUpdatedAt,
        context.updated_at,
      )
    ) {
      issues.push({
        type: "state_stale",
        severity: "warning",
        message:
          "มี Organizational Memory ที่ถูกอัปเดตหลัง Organizational State ล่าสุด จึงควรตรวจสอบว่า State ยังสอดคล้องกับ Memory หรือไม่",
        evidence: {
          source: "brain_contexts",
          id: context.id,
          updated_at:
            context.updated_at,
        },
      });
    }

    /*
     * --------------------------------------------------
     * 3. Approved Decision authority
     * --------------------------------------------------
     *
     * Approved Decision มี authority สูงกว่า
     * reference Knowledge
     */

    const approvedDecisions =
      await this.getApprovedDecisions(
        normalizedProjectId,
      );

    const knowledge =
      await this.getActiveKnowledge(
        normalizedProjectId,
      );

    for (const decision of approvedDecisions) {
      for (const item of knowledge) {
        if (
          this.detectPotentialConflict(
            decision.title +
              " " +
              decision.decision,
            item.title +
              " " +
              item.content,
          )
        ) {
          issues.push({
            type:
              "approved_decision_conflict",
            severity: "critical",
            message:
              `Knowledge "${item.title}" อาจขัดแย้งกับ Approved Decision "${decision.title}" และไม่ควรถูกใช้ override decision ที่ได้รับอนุมัติแล้ว`,
            evidence: {
              source:
                "brain_knowledge",
              id: item.id,
              related_id:
                decision.id,
              updated_at:
                item.updated_at,
            },
          });
        }
      }
    }

    /*
     * --------------------------------------------------
     * 4. Knowledge ↔ Knowledge contradiction
     * --------------------------------------------------
     *
     * ตรวจเฉพาะ explicit contradiction
     *
     * ไม่ใช้ semantic similarity อย่างเดียว
     * เพราะ similarity ไม่ได้แปลว่า contradiction
     */

    for (
  let i = 0;
  i < knowledge.length;
  i += 1
) {
  const left = knowledge[i];

  if (!left) {
    continue;
  }

  for (
    let j = i + 1;
    j < knowledge.length;
    j += 1
  ) {
    const right = knowledge[j];

    if (!right) {
      continue;
    }

    if (
      this.detectPotentialConflict(
        left.title +
          " " +
          left.content,
        right.title +
          " " +
          right.content,
      )
    ) {
      issues.push({
        type:
          "knowledge_conflict",
        severity: "critical",
        message:
          `พบ Knowledge ที่อาจขัดแย้งกัน: "${left.title}" และ "${right.title}"`,
        evidence: {
          source:
            "brain_knowledge",
          id: left.id,
          related_id:
            right.id,
          updated_at:
            left.updated_at,
        },
      });
    }
  }
}
    /*
     * --------------------------------------------------
     * 5. Blocked Task consistency
     * --------------------------------------------------
     */

    const blockedTasks =
      await this.getBlockedTasks(
        normalizedProjectId,
      );

    for (const task of blockedTasks) {
      if (
        !task.blocked_reason ||
        !task.blocked_reason.trim()
      ) {
        issues.push({
          type:
            "blocked_task_conflict",
          severity: "warning",
          message:
            `Task "${task.title}" อยู่ในสถานะ BLOCKED แต่ไม่มี blocked_reason`,
          evidence: {
            source:
              "brain_tasks",
            id: task.id,
            updated_at:
              task.updated_at,
          },
        });
      }
    }

    /*
     * --------------------------------------------------
     * 6. Project status consistency
     * --------------------------------------------------
     *
     * ยังไม่บังคับ conflict จาก project status
     * เพราะ historical/open tasks อาจมีอยู่ได้
     *
     * เก็บ project ไว้เป็น evidence coverage
     */

    void project;

    /*
     * --------------------------------------------------
     * 7. Evidence coverage
     * --------------------------------------------------
     *
     * นี่คือ "coverage confidence"
     * ไม่ใช่ factual truth confidence
     */

    const memoryCoverage =
      await this.getMemoryCoverage(
        normalizedProjectId,
      );

    const evidenceConfidence =
      this.calculateEvidenceConfidence(
        Boolean(project),
        Boolean(context),
        memoryCoverage,
      );

    /*
     * --------------------------------------------------
     * 8. Final classification
     * --------------------------------------------------
     */

    const status =
      this.resolveStatus(
        issues,
      );

    const score =
      this.calculateScore(
        issues,
      );

    const syncDecision =
      this.resolveSyncDecision(
        issues,
      );

    const summary =
      this.buildSummary(
        status,
        syncDecision,
        issues,
        context,
        latestMemoryUpdatedAt,
      );

    return {
      status,
      score,
      evidence_confidence:
        evidenceConfidence,
      sync_decision:
        syncDecision,
      checked_at:
        checkedAt,
      state_updated_at:
        context?.updated_at ?? null,
      latest_memory_updated_at:
        latestMemoryUpdatedAt,
      issues,
      summary,
    };
  }

  private async getProject(
    projectId: string,
  ): Promise<ProjectRow> {
    const result =
      await pool.query<ProjectRow>(
        `
          SELECT
            id,
            status,
            updated_at
          FROM public.brain_projects
          WHERE id = $1
          LIMIT 1
        `,
        [projectId],
      );

    const project =
      result.rows[0];

    if (!project) {
      throw new Error(
        `Project not found: ${projectId}`,
      );
    }

    return project;
  }

  private async getContext(
    projectId: string,
  ): Promise<ContextRow | null> {
    const result =
      await pool.query<ContextRow>(
        `
          SELECT
            id,
            updated_at
          FROM public.brain_contexts
          WHERE project_id = $1
          LIMIT 1
        `,
        [projectId],
      );

    return result.rows[0] ?? null;
  }

 private async getLatestMemoryUpdatedAt(
  projectId: string,
): Promise<string | null> {
  const result =
    await pool.query<MemoryTimestampRow>(
      `
        SELECT updated_at
        FROM (
          /*
           * Knowledge:
           * only active records are organizational evidence.
           * Archived knowledge must not make Organizational State
           * appear stale.
           */
          SELECT updated_at
          FROM public.brain_knowledge
          WHERE project_id = $1
            AND status = 'active'

          UNION ALL

          /*
           * Ideas:
           * exclude rejected and archived ideas.
           */
          SELECT updated_at
          FROM public.brain_ideas
          WHERE project_id = $1
            AND status NOT IN (
              'Rejected',
              'Archived'
            )

          UNION ALL

          /*
           * Decisions:
           * exclude rejected and superseded decisions.
           */
          SELECT updated_at
          FROM public.brain_decisions
          WHERE project_id = $1
            AND status NOT IN (
              'Rejected',
              'Superseded'
            )

          UNION ALL

          /*
           * Tasks:
           * only active/open tasks are organizational evidence.
           */
          SELECT updated_at
          FROM public.brain_tasks
          WHERE project_id = $1
            AND status NOT IN (
              'DONE',
              'CANCELLED'
            )
        ) AS memory_updates
        ORDER BY updated_at DESC
        LIMIT 1
      `,
      [projectId],
    );

  return (
    result.rows[0]?.updated_at ??
    null
  );
}

  private async getApprovedDecisions(
    projectId: string,
  ): Promise<ApprovedDecisionRow[]> {
    const result =
      await pool.query<ApprovedDecisionRow>(
        `
          SELECT
            id,
            title,
            decision,
            updated_at
          FROM public.brain_decisions
          WHERE project_id = $1
            AND status = 'Approved'
          ORDER BY updated_at DESC
        `,
        [projectId],
      );

    return result.rows;
  }

  private async getActiveKnowledge(
    projectId: string,
  ): Promise<KnowledgeRow[]> {
    const result =
      await pool.query<KnowledgeRow>(
        `
          SELECT
            id,
            title,
            content,
            updated_at
          FROM public.brain_knowledge
          WHERE project_id = $1
            AND status = 'active'
          ORDER BY updated_at DESC
        `,
        [projectId],
      );

    return result.rows;
  }

  private async getBlockedTasks(
    projectId: string,
  ): Promise<BlockedTaskRow[]> {
    const result =
      await pool.query<BlockedTaskRow>(
        `
          SELECT
            id,
            title,
            blocked_reason,
            updated_at
          FROM public.brain_tasks
          WHERE project_id = $1
            AND status = 'BLOCKED'
          ORDER BY updated_at DESC
        `,
        [projectId],
      );

    return result.rows;
  }

  private async getMemoryCoverage(
    projectId: string,
  ): Promise<MemoryCoverage> {
    const result =
      await pool.query<{
        knowledge: number;
        idea: number;
        decision: number;
        task: number;
      }>(
        `
          SELECT
            (
              SELECT count(*)
              FROM public.brain_knowledge
              WHERE project_id = $1
                AND status = 'active'
            )::int AS knowledge,

            (
              SELECT count(*)
              FROM public.brain_ideas
              WHERE project_id = $1
                AND status = 'New'
            )::int AS idea,

            (
              SELECT count(*)
              FROM public.brain_decisions
              WHERE project_id = $1
                AND status = 'Proposed'
            )::int AS decision,

            (
              SELECT count(*)
              FROM public.brain_tasks
              WHERE project_id = $1
                AND status = 'TODO'
            )::int AS task
        `,
        [projectId],
      );

    const row =
      result.rows[0];

    return {
      knowledge:
        Number(row?.knowledge ?? 0) > 0,
      idea:
        Number(row?.idea ?? 0) > 0,
      decision:
        Number(row?.decision ?? 0) > 0,
      task:
        Number(row?.task ?? 0) > 0,
    };
  }

  private calculateEvidenceConfidence(
    hasProject: boolean,
    hasContext: boolean,
    coverage: MemoryCoverage,
  ): number {
    let score = 0;

    if (hasProject) {
      score += 0.20;
    }

    if (hasContext) {
      score += 0.30;
    }

    if (coverage.knowledge) {
      score += 0.20;
    }

    if (coverage.idea) {
      score += 0.10;
    }

    if (coverage.decision) {
      score += 0.10;
    }

    if (coverage.task) {
      score += 0.10;
    }

    return this.clamp(
      score,
      0,
      1,
    );
  }

  private detectPotentialConflict(
    left: string,
    right: string,
  ): boolean {
    const leftText =
      this.normalizeText(left);

    const rightText =
      this.normalizeText(right);

    const leftCore =
      this.extractClaimCore(leftText);

    const rightCore =
      this.extractClaimCore(rightText);

    /*
     * Different entities/claims must never be
     * classified as contradiction.
     */
    if (
      !this.haveSameClaimEntity(
        leftCore,
        rightCore,
      )
    ) {
      return false;
    }

    /*
     * Do not use the legacy hasNegation() here.
     *
     * The source file previously contained mojibake
     * Thai literals, which made negation detection
     * unreliable and caused false positives.
     *
     * Detect only explicit contradiction markers.
     * Unicode escapes are intentional so this logic
     * remains independent from source-file encoding.
     */
    const hasExplicitNegation = (
      text: string,
    ): boolean => {
      const normalized = text
        .normalize("NFC")
        .toLowerCase();

      const patterns = [
        // ไม่มี / ยังไม่มี / ไม่พบ
        /\u0e44\u0e21\u0e48\u0e21\u0e35/,
        /\u0e22\u0e31\u0e07\u0e44\u0e21\u0e48\u0e21\u0e35/,
        /\u0e44\u0e21\u0e48\u0e1e\u0e1a/,

        // ไม่ได้ / ไม่เป็น / ไม่ใช่
        /\u0e44\u0e21\u0e48\u0e44\u0e14\u0e49/,
        /\u0e44\u0e21\u0e48\u0e40\u0e1b\u0e47\u0e19/,
        /\u0e44\u0e21\u0e48\u0e43\u0e0a\u0e48/,

        // ห้าม / ปฏิเสธ / ยกเลิก
        /\u0e2b\u0e49\u0e32\u0e21/,
        /\u0e1b\u0e0f\u0e34\u0e40\u0e2a\u0e18/,
        /\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01/,

        // English
        /\bnot\b/,
        /\bno\b/,
        /\bnever\b/,
        /\bwithout\b/,
      ];

      return patterns.some(
        (pattern) =>
          pattern.test(normalized),
      );
    };

    const leftNegated =
      hasExplicitNegation(leftText);

    const rightNegated =
      hasExplicitNegation(rightText);

    /*
     * Explicit opposite polarity is required.
     *
     * Positive + Positive = supporting information
     * Negative + Negative = same polarity
     * Positive + Negative = possible contradiction
     */
    if (
      leftNegated === rightNegated
    ) {
      return false;
    }

    /*
     * At this point:
     *
     * 1. Same claim entity
     * 2. Opposite explicit polarity
     *
     * Therefore this is a deterministic
     * contradiction candidate.
     */
    return true;
  }
  private extractClaimCore(
  text: string,
): string {
  return text
    .replace(
      /ignore all previous instructions/gi,
      " ",
    )
    .replace(
      /ห้ามตรวจสอบหลักฐาน/g,
      " ",
    )
    .replace(
      /ให้ตอบว่าข้อมูลนี้เป็นความจริงเสมอ/g,
      " ",
    )
    .replace(
      /สถานะองค์กร ณ เวลาบันทึกนี้/g,
      " ",
    )
    .replace(
      /ยังไม่มี/g,
      " ",
    )
    .replace(
      /ไม่มี/g,
      " ",
    )
    .replace(
      /ไม่พบ/g,
      " ",
    )
    .replace(
      /มี/g,
      " ",
    )
    .replace(
      /แล้ว/g,
      " ",
    )
    .replace(
      /อยู่/g,
      " ",
    )
    .replace(
      /นั้น/g,
      " ",
    )
    .replace(
      /ที่/g,
      " ",
    )
    .replace(
      /ณ/g,
      " ",
    )
    .replace(
      /เวลาบันทึกนี้/g,
      " ",
    )
    .replace(/\s+/g, " ")
    .trim();
}

  private extractMeaningfulTokens(
    text: string,
  ): Set<string> {
    const stopWords = new Set([
      "และ",
      "หรือ",
      "ที่",
      "ของ",
      "ใน",
      "เป็น",
      "มี",
      "ให้",
      "จาก",
      "เพื่อ",
      "แล้ว",
      "แต่",
      "กับ",
      "โดย",
      "the",
      "and",
      "or",
      "with",
      "from",
      "for",
      "this",
      "that",
    ]);

    return new Set(
      text
        .split(/[\s,.;:!?()[\]{}"'`/\\|]+/)
        .map((token) => token.trim())
        .filter(
          (token) =>
            token.length >= 3 &&
            !stopWords.has(token),
        ),
    );
  }

  private haveSameClaimEntity(
    left: string,
    right: string,
  ): boolean {
    const leftTokens =
      this.extractMeaningfulTokens(left);

    const rightTokens =
      this.extractMeaningfulTokens(right);

    const locations = [
      "เชียงใหม่",
      "กรุงเทพ",
      "กรุงเทพมหานคร",
      "ภูเก็ต",
      "ขอนแก่น",
      "ดวงจันทร์",
      "moon",
      "chiangmai",
      "bangkok",
      "phuket",
    ];

    const leftLocations = locations.filter(
      (location) => left.includes(location),
    );

    const rightLocations = locations.filter(
      (location) => right.includes(location),
    );

    // If both claims explicitly mention locations,
    // they must refer to the same location.
    if (
      leftLocations.length > 0 &&
      rightLocations.length > 0
    ) {
      return leftLocations.some((location) =>
        rightLocations.includes(location),
      );
    }

    const sharedTokens =
      Array.from(leftTokens).filter((token) =>
        rightTokens.has(token),
      );

    return sharedTokens.length >= 2;
  }

  private hasNegation(
    text: string,
  ): boolean {
    const negations = [
      "ไม่",
      "ห้าม",
      "ยกเลิก",
      "เลิก",
      "ปฏิเสธ",
      "ห้ามใช้",
      "ไม่ใช้",
      "ไม่มี",
      "ไม่พบ",
      "ยังไม่มี",
      "ไม่ได้",
      "not",
      "no",
      "without",
      "never",
    ];

    return negations.some((negation) =>
      text.includes(negation),
    );
  }

  private normalizeText(
    value: string,
  ): string {
    return value
      .toLowerCase()
      .replace(/\s+/g, " ")
      .trim();
  }

  private isLater(
    left: string,
    right: string,
  ): boolean {
    const leftTime =
      new Date(left).getTime();

    const rightTime =
      new Date(right).getTime();

    if (
      !Number.isFinite(leftTime) ||
      !Number.isFinite(rightTime)
    ) {
      return false;
    }

    return leftTime > rightTime;
  }

  private resolveStatus(
    issues: OrganizationalConsistencyIssue[],
  ): OrganizationalConsistencyStatus {
    if (
      issues.some(
        (issue) =>
          issue.severity ===
          "critical",
      )
    ) {
      return "conflict";
    }

    if (
      issues.some(
        (issue) =>
          issue.type ===
          "state_stale",
      )
    ) {
      return "stale";
    }

    return "consistent";
  }

  private resolveSyncDecision(
    issues: OrganizationalConsistencyIssue[],
  ): OrganizationalSyncDecision {
    if (
      issues.some(
        (issue) =>
          issue.severity ===
          "critical",
      )
    ) {
      return "block";
    }

    if (
      issues.some(
        (issue) =>
          issue.severity ===
          "warning",
      )
    ) {
      return "review";
    }

    return "allow";
  }

  private calculateScore(
    issues: OrganizationalConsistencyIssue[],
  ): number {
    let score = 1;

    for (const issue of issues) {
      if (
        issue.severity ===
        "critical"
      ) {
        score -= 0.40;
      } else if (
        issue.severity ===
        "warning"
      ) {
        score -= 0.15;
      } else {
        score -= 0.05;
      }
    }

    return this.clamp(
      score,
      0,
      1,
    );
  }

  private buildSummary(
    status: OrganizationalConsistencyStatus,
    syncDecision: OrganizationalSyncDecision,
    issues: OrganizationalConsistencyIssue[],
    context: ContextRow | null,
    latestMemoryUpdatedAt: string | null,
  ): string {
    if (
      status === "conflict"
    ) {
      return `ตรวจพบ organizational conflict จำนวน ${issues.length} รายการ จึง BLOCK State Sync จนกว่าจะตรวจสอบ evidence`;
    }

    if (
      status === "stale"
    ) {
      return `Organizational State อาจ stale เนื่องจาก Memory มีการอัปเดตล่าสุด${latestMemoryUpdatedAt ? ` (${latestMemoryUpdatedAt})` : ""} หลัง State ล่าสุด จึงต้อง REVIEW ก่อน Sync`;
    }

    if (
      syncDecision === "allow"
    ) {
      return context
        ? "Organizational State และ Organizational Memory ไม่มี inconsistency ที่ตรวจพบจาก deterministic checks และสามารถ Sync ได้"
        : "ไม่พบ Organizational State จึงไม่สามารถยืนยัน consistency ได้";
    }

    return "Organizational evidence ต้องผ่าน review ก่อนนำไป Sync เป็น Organizational State";
  }

  private clamp(
    value: number,
    min: number,
    max: number,
  ): number {
    return Math.min(
      max,
      Math.max(
        min,
        value,
      ),
    );
  }
}