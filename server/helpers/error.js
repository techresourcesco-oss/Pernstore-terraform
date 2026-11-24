const { logger } = require("../utils/logger");
class ErrorHandler extends Error {
  constructor(statusCode, message) {
    super();
    this.status = "error";
    this.statusCode = statusCode;
    this.message = message;
  }
}

const handleError = (err, req, res, next) => {
  const { statusCode, message } = err;
  logger.error("Request failed", {
    method: req.method,
    path: req.path,
    statusCode: statusCode || 500,
    errorName: err.name,
    errorMessage: message,
    stack: err.stack,
  });
  res.status(statusCode || 500).json({
    status: "error",
    statusCode: statusCode || 500,
    message: statusCode === 500 ? "An error occurred" : message,
  });
  next();
};
module.exports = {
  ErrorHandler,
  handleError,
};
