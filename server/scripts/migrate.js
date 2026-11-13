const { spawnSync } = require("child_process");
const path = require("path");
const dotenv = require("dotenv");

dotenv.config({ path: path.resolve(__dirname, "../.env") });

const args = process.argv.slice(2);
const isHelpRequest = args.includes("--help") || args.includes("-h");

if (!isHelpRequest) {
  const {
    POSTGRES_HOST,
    POSTGRES_PORT,
    POSTGRES_USER,
    POSTGRES_PASSWORD,
    POSTGRES_DB,
    NODE_ENV,
  } = process.env;

  if (
    !POSTGRES_HOST ||
    !POSTGRES_PORT ||
    !POSTGRES_USER ||
    !POSTGRES_PASSWORD ||
    !POSTGRES_DB
  ) {
    console.error(
      "Missing required PostgreSQL environment variables: POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB"
    );
    process.exit(1);
  }

  const protocol = "postgresql";
  const credentials = `${encodeURIComponent(POSTGRES_USER)}:${encodeURIComponent(POSTGRES_PASSWORD)}`;
  const hostname = POSTGRES_HOST;
  const port = Number(POSTGRES_PORT);
  const database = POSTGRES_DB;
  const sslSuffix = "?sslmode=no-verify";

  process.env.DATABASE_URL = `${protocol}://${credentials}@${hostname}:${port}/${database}${sslSuffix}`;
}

const migrateBin = require.resolve("node-pg-migrate/bin/node-pg-migrate");

const result = spawnSync(process.execPath, [migrateBin, ...args], {
  stdio: "inherit",
  env: process.env,
});

if (result.error) {
  console.error(result.error);
  process.exit(1);
}

process.exit(result.status ?? 1);
