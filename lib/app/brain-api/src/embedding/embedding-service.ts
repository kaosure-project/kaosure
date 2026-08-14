import OpenAI from "openai";

export interface EmbeddingResult {
  model: string;
  dimensions: number;
  embedding: number[];
}

export class EmbeddingService {
  private readonly client: OpenAI;
  private readonly model: string;
  private readonly dimensions: number;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      throw new Error(
        "OPENAI_API_KEY is required for EmbeddingService.",
      );
    }

    this.client = new OpenAI({
      apiKey,
    });

    this.model =
      process.env.OPENAI_EMBEDDING_MODEL ??
      "text-embedding-3-small";

    this.dimensions = Number(
      process.env.OPENAI_EMBEDDING_DIMENSIONS ?? "1536",
    );

    if (!Number.isInteger(this.dimensions) || this.dimensions <= 0) {
      throw new Error(
        "OPENAI_EMBEDDING_DIMENSIONS must be a positive integer.",
      );
    }
  }

  async embed(text: string): Promise<EmbeddingResult> {
    const normalizedText = text.trim();

    if (!normalizedText) {
      throw new Error("Embedding text must not be empty.");
    }

    const response = await this.client.embeddings.create({
      model: this.model,
      input: normalizedText,
      dimensions: this.dimensions,
    });

    const embedding = response.data[0]?.embedding;

    if (!embedding) {
      throw new Error(
        "Embedding provider returned no embedding.",
      );
    }

    if (embedding.length !== this.dimensions) {
      throw new Error(
        `Embedding dimension mismatch. Expected ${this.dimensions}, received ${embedding.length}.`,
      );
    }

    return {
      model: this.model,
      dimensions: embedding.length,
      embedding,
    };
  }
}
