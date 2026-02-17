import http from "http";
import { Pool } from "pg";

const port = Number(process.env.PORT || 3000);
const { DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME } = process.env;

// Minimal env validation (patterns vars)
if (!DB_HOST || !DB_USER || !DB_PASSWORD || !DB_NAME) {
  console.error("[config] Missing DB env vars (DB_HOST/DB_USER/DB_PASSWORD/DB_NAME)");
  process.exit(1);
}

const pool = new Pool({
  host: DB_HOST,
  port: Number(DB_PORT || 5432),
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  connectionTimeoutMillis: 2000,
  idleTimeoutMillis: 10000,
  max: 5,
});

function sendJson(res, status, payload) {
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json");
  res.end(JSON.stringify(payload));
}

function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error("db_timeout")), ms)),
  ]);
}

http
  .createServer(async (req, res) => {
    if (req.url === "/api" || req.url === "/api/") {
      try {
        const q = await withTimeout(
          pool.query("SELECT * FROM users LIMIT 1"),
          1500
        );
        const first = q.rows?.[0];

        return sendJson(res, 200, {
          database: true,
          userAdmin: first?.role === "admin",
        });
      } catch (err) {
        // Keep response predictable (no internal error leak)
        console.error("[db] unavailable:", err?.message);
        return sendJson(res, 503, {
          database: false,
          userAdmin: false,
          error: "db_unavailable",
        });
      }
    }

    return sendJson(res, 404, { error: "Not Found" });
  })
  .listen(port, "0.0.0.0", () => {
    console.log(`Server is listening on port ${port}`);
  });