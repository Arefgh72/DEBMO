const http = require('http');
const { ProxyAgent, fetch } = require('undici');

const PORT = 8080;
const XRAY_PROXY = 'http://127.0.0.1:10809';
const dispatcher = new ProxyAgent(XRAY_PROXY);

const server = http.createServer(async (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-relay-hop, x-fwd-hop');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ e: "Relay is Active." }));
    return;
  }

  if (req.method !== 'POST') {
    res.writeHead(405, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ e: "Method not allowed." }));
    return;
  }

  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', async () => {
    try {
      const data = JSON.parse(body);

      if (!data.u) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ e: "missing url" }));
        return;
      }

      const hop = req.headers['x-relay-hop'];
      const fwdHop = req.headers['x-fwd-hop'];
      if (hop === '1' || fwdHop === '1') {
        res.writeHead(508, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ e: "loop detected" }));
        return;
      }

      const headers = { ...data.h };
      headers['x-relay-hop'] = '1';

      const fetchOptions = {
        method: (data.m || 'GET').toUpperCase(),
        headers: headers,
        dispatcher: dispatcher,
        redirect: data.r === false ? 'manual' : 'follow'
      };

      if (data.b) {
        fetchOptions.body = Buffer.from(data.b, 'base64');
      }

      const response = await fetch(data.u, fetchOptions);

      const responseHeaders = {};
      response.headers.forEach((v, k) => {
        responseHeaders[k] = v;
      });

      const arrayBuffer = await response.arrayBuffer();
      const base64Body = Buffer.from(arrayBuffer).toString('base64');

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        s: response.status,
        h: responseHeaders,
        b: base64Body
      }));

    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ e: String(err) }));
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Relay server running on port ${PORT}`);
  console.log(`Using Xray proxy: ${XRAY_PROXY}`);
});
