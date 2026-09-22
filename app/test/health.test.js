const test = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const app = require('../server');

test('GET /health returns 200 and status ok', async () => {
  const server = app.listen(0);
  const { port } = server.address();

  await new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}/health`, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        assert.strictEqual(res.statusCode, 200);
        assert.deepStrictEqual(JSON.parse(data), { status: 'ok' });
        server.close();
        resolve();
      });
    }).on('error', reject);
  });
});
