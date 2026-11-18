const supertest = require("supertest");
const app = require("../app");

describe("GET /metrics", () => {
  it("returns Prometheus default metrics", async () => {
    const response = await supertest(app).get("/metrics").expect(200);

    expect(response.headers["content-type"]).toContain("text/plain");
    expect(response.text).toContain("process_cpu_user_seconds_total");
  });
});
