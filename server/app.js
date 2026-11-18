const express = require("express");
require("express-async-errors");
const cors = require("cors");
const morgan = require("morgan");
const cookieParser = require("cookie-parser");
const routes = require("./routes");
const helmet = require("helmet");
const compression = require("compression");
const promClient = require("prom-client");
const unknownEndpoint = require("./middleware/unKnownEndpoint");
const { handleError } = require("./helpers/error");
const client = require('prom-client');

const app = express();

promClient.collectDefaultMetrics();

app.set("trust proxy", 1);
app.use(cors({ credentials: true, origin: true }));
app.use(express.json());
app.use(morgan("dev"));
app.use(compression());
app.use(helmet());
app.use(cookieParser());

// 1. API Response time aur status track karne ke liye Histogram banayein
const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 1, 2, 5] // Response time in seconds
});

// 2. Express Middleware jo har request ko track karega
app.use((req, res, next) => {
  // /metrics route ko track na karein taake extra data na bane
  if (req.path === '/metrics') {
    return next();
  }

  // Timer start karein
  const endTimer = httpRequestDurationMicroseconds.startTimer();
  
  // Jab response chala jaye, toh timer stop karein aur labels (status, route) record karein
  res.on('finish', () => {
    // req.route.path humein '/api/users/:id' dega na ke '/api/users/123' (is se data clean rehta hai)
    const route = req.route ? req.route.path : req.path;
    
    endTimer({ 
      method: req.method, 
      route: route, 
      status_code: res.statusCode 
    });
  });
  
  next();
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", promClient.register.contentType);
  res.end(await promClient.register.metrics());
});

app.use("/api", routes);
app.get("/loaderio-a48a4517d6cd80be8be7e3aa57e76ddb.txt", (req, res) => {
  res.type("text/plain");
  res.send("loaderio-a48a4517d6cd80be8be7e3aa57e76ddb");
});
app.get("/", (req, res) =>
  res.send("<h1 style='text-align: center'>E-COMMERCE API</h1>")
);

app.use(unknownEndpoint);
app.use(handleError);

module.exports = app;
