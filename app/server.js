const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;
const START_TIME = Date.now();
let REQUEST_COUNT = 0;

app.use((req, res, next) => {
  REQUEST_COUNT += 1;
  next();
});

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from ECS Fargate 🚀',
    hostname: require('os').hostname(),
    uptimeSeconds: Math.floor((Date.now() - START_TIME) / 1000),
  });
});

// Used by the ALB target group + ECS task health check.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Basic Prometheus-style metrics for Grafana/Container Insights scraping.
app.get('/metrics', (req, res) => {
  const uptime = Math.floor((Date.now() - START_TIME) / 1000);
  res.set('Content-Type', 'text/plain');
  res.send(
    [
      '# HELP app_uptime_seconds Time since process start',
      '# TYPE app_uptime_seconds counter',
      `app_uptime_seconds ${uptime}`,
      '# HELP app_requests_total Total HTTP requests received',
      '# TYPE app_requests_total counter',
      `app_requests_total ${REQUEST_COUNT}`,
      '',
    ].join('\n')
  );
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
  });
}

module.exports = app;
