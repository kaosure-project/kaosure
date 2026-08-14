import "dotenv/config";

import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

import { pool } from "./postgres.js";

async function main(): Promise<void> {
  const currentFile = fileURLToPath(import.meta.url);
  const currentDirectory = path.dirname(currentFile);

  const migrationPath = path.resolve(
    currentDirectory,
    "../../migrations/002_create_pudtan_memory.sql",
  );

  const sql = await readFile(migrationPath, "utf8");

  if (!sql.trim()) {
    throw new Error(
      "Pudtan Memory migration file is empty.",
    );
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(sql);

    await client.query("COMMIT");

    console.log(
      "Pudtan Memory migration applied successfully.",
    );
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((error) => {
  console.error(
    "Failed to apply Pudtan Memory migration.",
    error,
  );

  process.exit(1);
});