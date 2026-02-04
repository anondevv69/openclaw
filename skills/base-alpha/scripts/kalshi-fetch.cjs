#!/usr/bin/env node
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const https = require('https');

const CONFIG_DIR = path.join(__dirname, '..');
const API_KEY = '2bc739f7-1c05-4d93-b5cc-12be471a4382';
const BASE_URL = 'https://api.elections.kalshi.com';

function loadPrivateKey() {
  const keyPath = path.join(CONFIG_DIR, 'kalshi-key.pem');
  return fs.readFileSync(keyPath, 'utf8');
}

function signRequest(privateKeyPem, timestamp, method, path) {
  const pathWithoutQuery = path.split('?')[0];
  const message = timestamp + method + pathWithoutQuery;
  
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(message);
  sign.end();
  
  const signature = sign.sign({
    key: privateKeyPem,
    padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
    saltLength: crypto.constants.RSA_PSS_SALTLEN_DIGEST,
  });
  
  return signature.toString('base64');
}

function kalshiRequest(method, apiPath) {
  return new Promise((resolve, reject) => {
    const privateKey = loadPrivateKey();
    const timestamp = Date.now().toString();
    const signature = signRequest(privateKey, timestamp, method, apiPath);
    
    const url = new URL(BASE_URL + apiPath);
    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'KALSHI-ACCESS-KEY': API_KEY,
        'KALSHI-ACCESS-SIGNATURE': signature,
        'KALSHI-ACCESS-TIMESTAMP': timestamp,
        'Content-Type': 'application/json'
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ raw: data });
        }
      });
    });
    
    req.on('error', reject);
    req.end();
  });
}

async function main() {
  const action = process.argv[2] || 'markets';
  
  try {
    if (action === 'balance') {
      const result = await kalshiRequest('GET', '/trade-api/v2/portfolio/balance');
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'markets') {
      const result = await kalshiRequest('GET', '/trade-api/v2/markets?status=open&limit=50');
      // Filter to show high volume markets
      if (result.markets) {
        const filtered = result.markets
          .filter(m => m.volume_24h > 0)
          .sort((a, b) => b.volume_24h - a.volume_24h)
          .slice(0, 20);
        console.log(JSON.stringify({ markets: filtered }, null, 2));
      } else {
        console.log(JSON.stringify(result, null, 2));
      }
    } else if (action === 'events') {
      const result = await kalshiRequest('GET', '/trade-api/v2/events?status=open&limit=50&with_nested_markets=true');
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'series') {
      const ticker = process.argv[3] || 'KXFEDRATE';
      const result = await kalshiRequest('GET', `/trade-api/v2/series/${ticker}`);
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'shutdown') {
      // Gov shutdown market
      const result = await kalshiRequest('GET', '/trade-api/v2/markets?status=open&series_ticker=GOVSHUT&limit=10');
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'fed') {
      // Fed rate markets
      const result = await kalshiRequest('GET', '/trade-api/v2/markets?status=open&series_ticker=KXFEDRATE&limit=10');
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'btc') {
      // Bitcoin markets
      const result = await kalshiRequest('GET', '/trade-api/v2/markets?status=open&limit=100');
      if (result.markets) {
        const btc = result.markets.filter(m => 
          m.title?.toLowerCase().includes('bitcoin') || 
          m.ticker?.toLowerCase().includes('btc') ||
          m.title?.toLowerCase().includes('btc')
        );
        console.log(JSON.stringify({ markets: btc }, null, 2));
      }
    } else {
      console.log('Usage: kalshi-fetch.cjs [balance|markets|events|series <ticker>|shutdown|fed|btc]');
    }
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

main();
