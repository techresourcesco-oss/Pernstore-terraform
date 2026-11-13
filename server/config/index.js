require("dotenv").config();
const { Pool } = require("pg");

const isProduction = process.env.NODE_ENV === "production";
const database =
  process.env.NODE_ENV === "test"
    ? process.env.POSTGRES_DB_TEST
    : process.env.POSTGRES_DB;

const pool = new Pool({
  host: process.env.POSTGRES_HOST,
  port: Number(process.env.POSTGRES_PORT),
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database,
  ssl: isProduction ? { rejectUnauthorized: false } : false,
});

console.log('db pool is',pool)

module.exports = {
  query: (text, params) => pool.query(text, params),
  end: () => pool.end(),
}
;