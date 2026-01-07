const https = require('https');

module.exports = async (req, res) => {
  // 1. 处理 CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // 2. 转发 DeepSeek 请求
  if (req.method === 'POST') {
    const options = {
      hostname: 'api.deepseek.com',
      path: '/chat/completions',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': req.headers.authorization || ''
      }
    };

    const proxyReq = https.request(options, (proxyRes) => {
      res.status(proxyRes.statusCode);
      // 转发响应头
      Object.keys(proxyRes.headers).forEach(key => {
        res.setHeader(key, proxyRes.headers[key]);
      });
      proxyRes.pipe(res);
    });

    proxyReq.on('error', (e) => {
      console.error(e);
      res.status(500).json({ error: e.message });
    });

    // 将请求体写入转发请求
    if (req.body) {
        // Vercel 会自动解析 JSON body，所以我们需要重新 stringify
        // 如果是 raw body，可能需要不同处理，但通常 Vercel 处理得很好
        proxyReq.write(JSON.stringify(req.body));
    }
    proxyReq.end();
  } else {
    res.status(405).json({ error: 'Method not allowed' });
  }
};
