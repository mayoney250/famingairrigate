const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 8000;
const DIRECTORY = __dirname;
const AI_API_BASE = 'famingaaimodal.onrender.com';

const mimeTypes = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
    // Add CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    const parsedUrl = url.parse(req.url, true);

    // Proxy for AI API health check
    if (parsedUrl.pathname === '/api/ai/health') {
        const options = {
            hostname: AI_API_BASE,
            path: '/health',
            method: 'GET',
            headers: {
                'Accept': 'application/json'
            }
        };

        const proxyReq = https.request(options, (proxyRes) => {
            let data = '';
            proxyRes.on('data', (chunk) => { data += chunk; });
            proxyRes.on('end', () => {
                res.writeHead(proxyRes.statusCode, {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                });
                res.end(data);
            });
        });

        proxyReq.on('error', (error) => {
            res.writeHead(500, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: error.message }));
        });

        proxyReq.end();
        return;
    }

    // Proxy for AI API advice endpoint
    if (parsedUrl.pathname === '/api/ai/advice' && req.method === 'POST') {
        let body = '';
        req.on('data', (chunk) => { body += chunk; });
        req.on('end', () => {
            console.log('\n📤 Forwarding to AI API:');
            console.log('Request Body:', body);

            const options = {
                hostname: AI_API_BASE,
                path: '/api/v1/irrigation/advice',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Content-Length': Buffer.byteLength(body)
                }
            };

            const proxyReq = https.request(options, (proxyRes) => {
                let data = '';
                proxyRes.on('data', (chunk) => { data += chunk; });
                proxyRes.on('end', () => {
                    console.log('📥 AI API Response:', data.substring(0, 200) + '...');
                    res.writeHead(proxyRes.statusCode, {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    });
                    res.end(data);
                });
            });

            proxyReq.on('error', (error) => {
                console.error('❌ Proxy Error:', error.message);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: error.message }));
            });

            proxyReq.write(body);
            proxyReq.end();
        });
        return;
    }

    // Serve static files
    let filePath = path.join(DIRECTORY, parsedUrl.pathname === '/' ? 'sensor_test.html' : parsedUrl.pathname);
    const extname = String(path.extname(filePath)).toLowerCase();
    const contentType = mimeTypes[extname] || 'application/octet-stream';

    fs.readFile(filePath, (error, content) => {
        if (error) {
            if (error.code == 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('<h1>404 Not Found</h1>', 'utf-8');
            } else {
                res.writeHead(500);
                res.end('Server Error: ' + error.code);
            }
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content, 'utf-8');
        }
    });
});

server.listen(PORT, () => {
    console.log('========================================');
    console.log('   Sensor Test Interface Server');
    console.log('========================================');
    console.log('');
    console.log(`🌐 Server running at http://localhost:${PORT}`);
    console.log(`📂 Serving files from: ${DIRECTORY}`);
    console.log(`🔄 Proxying AI API requests to: ${AI_API_BASE}`);
    console.log('');
    console.log('✅ Open this URL in your browser:');
    console.log(`   http://localhost:${PORT}/sensor_test.html`);
    console.log('');
    console.log('⏹️  Press Ctrl+C to stop the server');
    console.log('');
});

