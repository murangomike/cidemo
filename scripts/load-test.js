#!/usr/bin/env node

/**
 * Simple Load Testing Script
 * 
 * This script generates HTTP requests to test the application's
 * performance and trigger auto-scaling in Kubernetes.
 * 
 * Usage:
 *   node scripts/load-test.js [URL] [CONCURRENT_REQUESTS] [DURATION_SECONDS]
 * 
 * Example:
 *   node scripts/load-test.js http://localhost:3000 10 60
 */

const http = require('http');
const https = require('https');
const { performance } = require('perf_hooks');

// Configuration
const DEFAULT_URL = 'http://localhost:3000';
const DEFAULT_CONCURRENT = 5;
const DEFAULT_DURATION = 30; // seconds

// Parse command line arguments
const args = process.argv.slice(2);
const targetUrl = args[0] || DEFAULT_URL;
const concurrentRequests = parseInt(args[1]) || DEFAULT_CONCURRENT;
const testDuration = parseInt(args[2]) || DEFAULT_DURATION;

// Parse URL
let parsedUrl;
let httpClient;

try {
  parsedUrl = new URL(targetUrl);
  httpClient = parsedUrl.protocol === 'https:' ? https : http;
} catch (error) {
  console.error('❌ Invalid URL:', targetUrl);
  process.exit(1);
}

// Test statistics
const stats = {
  totalRequests: 0,
  successfulRequests: 0,
  failedRequests: 0,
  totalResponseTime: 0,
  minResponseTime: Infinity,
  maxResponseTime: 0,
  responseCodes: {},
  errors: {},
  startTime: 0,
  endTime: 0
};

// Test endpoints to hit
const endpoints = [
  { path: '/healthz', method: 'GET', weight: 30 },
  { path: '/users', method: 'GET', weight: 50 },
  { 
    path: '/users', 
    method: 'POST', 
    weight: 20,
    data: JSON.stringify({ name: `LoadTest-${Date.now()}` }),
    headers: { 'Content-Type': 'application/json' }
  }
];

// Create weighted endpoint selector
const weightedEndpoints = [];
endpoints.forEach(endpoint => {
  for (let i = 0; i < endpoint.weight; i++) {
    weightedEndpoints.push(endpoint);
  }
});

/**
 * Make a single HTTP request
 */
function makeRequest() {
  return new Promise((resolve) => {
    const endpoint = weightedEndpoints[Math.floor(Math.random() * weightedEndpoints.length)];
    const startTime = performance.now();
    
    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
      path: endpoint.path,
      method: endpoint.method,
      headers: endpoint.headers || {}
    };

    const req = httpClient.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        const endTime = performance.now();
        const responseTime = endTime - startTime;
        
        stats.totalRequests++;
        stats.totalResponseTime += responseTime;
        stats.minResponseTime = Math.min(stats.minResponseTime, responseTime);
        stats.maxResponseTime = Math.max(stats.maxResponseTime, responseTime);
        
        const statusCode = res.statusCode;
        stats.responseCodes[statusCode] = (stats.responseCodes[statusCode] || 0) + 1;
        
        if (statusCode >= 200 && statusCode < 300) {
          stats.successfulRequests++;
        } else {
          stats.failedRequests++;
        }
        
        resolve({ statusCode, responseTime, endpoint: endpoint.path });
      });
    });
    
    req.on('error', (error) => {
      const endTime = performance.now();
      const responseTime = endTime - startTime;
      
      stats.totalRequests++;
      stats.failedRequests++;
      stats.totalResponseTime += responseTime;
      
      const errorType = error.code || 'UNKNOWN_ERROR';
      stats.errors[errorType] = (stats.errors[errorType] || 0) + 1;
      
      resolve({ error: errorType, responseTime, endpoint: endpoint.path });
    });
    
    // Write request data if POST
    if (endpoint.data) {
      req.write(endpoint.data);
    }
    
    req.end();
  });
}

/**
 * Run concurrent requests
 */
async function runConcurrentRequests() {
  const promises = [];
  
  for (let i = 0; i < concurrentRequests; i++) {
    promises.push(makeRequest());
  }
  
  return Promise.all(promises);
}

/**
 * Display progress
 */
function displayProgress() {
  const elapsed = (performance.now() - stats.startTime) / 1000;
  const rps = stats.totalRequests / elapsed;
  const avgResponseTime = stats.totalRequests > 0 ? stats.totalResponseTime / stats.totalRequests : 0;
  
  process.stdout.write(`\r🚀 Requests: ${stats.totalRequests} | RPS: ${rps.toFixed(2)} | Avg: ${avgResponseTime.toFixed(2)}ms | Success: ${stats.successfulRequests} | Failed: ${stats.failedRequests}`);
}

/**
 * Display final results
 */
function displayResults() {
  console.log('\n\n📊 Load Test Results');
  console.log('='.repeat(50));
  
  const duration = (stats.endTime - stats.startTime) / 1000;
  const rps = stats.totalRequests / duration;
  const avgResponseTime = stats.totalRequests > 0 ? stats.totalResponseTime / stats.totalRequests : 0;
  const successRate = stats.totalRequests > 0 ? (stats.successfulRequests / stats.totalRequests) * 100 : 0;
  
  console.log(`📋 Test Configuration:`);
  console.log(`   Target URL: ${targetUrl}`);
  console.log(`   Concurrent Requests: ${concurrentRequests}`);
  console.log(`   Test Duration: ${testDuration}s (actual: ${duration.toFixed(2)}s)`);
  console.log();
  
  console.log(`📈 Performance Metrics:`);
  console.log(`   Total Requests: ${stats.totalRequests}`);
  console.log(`   Requests/Second: ${rps.toFixed(2)}`);
  console.log(`   Success Rate: ${successRate.toFixed(2)}%`);
  console.log(`   Successful Requests: ${stats.successfulRequests}`);
  console.log(`   Failed Requests: ${stats.failedRequests}`);
  console.log();
  
  console.log(`⏱️  Response Times:`);
  console.log(`   Average: ${avgResponseTime.toFixed(2)}ms`);
  console.log(`   Minimum: ${stats.minResponseTime === Infinity ? 'N/A' : stats.minResponseTime.toFixed(2) + 'ms'}`);
  console.log(`   Maximum: ${stats.maxResponseTime.toFixed(2)}ms`);
  console.log();
  
  if (Object.keys(stats.responseCodes).length > 0) {
    console.log(`📊 Response Codes:`);
    Object.entries(stats.responseCodes)
      .sort(([a], [b]) => parseInt(a) - parseInt(b))
      .forEach(([code, count]) => {
        const percentage = (count / stats.totalRequests) * 100;
        console.log(`   ${code}: ${count} (${percentage.toFixed(1)}%)`);
      });
    console.log();
  }
  
  if (Object.keys(stats.errors).length > 0) {
    console.log(`❌ Errors:`);
    Object.entries(stats.errors).forEach(([error, count]) => {
      const percentage = (count / stats.totalRequests) * 100;
      console.log(`   ${error}: ${count} (${percentage.toFixed(1)}%)`);
    });
    console.log();
  }
  
  console.log(`💡 Tips for Kubernetes Auto-scaling:`);
  console.log(`   - Monitor with: kubectl get hpa -n crud-app -w`);
  console.log(`   - Check pods: kubectl get pods -n crud-app -w`);
  console.log(`   - View metrics: kubectl top pods -n crud-app`);
}

/**
 * Main test execution
 */
async function runLoadTest() {
  console.log('🚀 Starting Load Test');
  console.log(`📊 Target: ${targetUrl}`);
  console.log(`⚡ Concurrent Requests: ${concurrentRequests}`);
  console.log(`⏱️  Duration: ${testDuration} seconds`);
  console.log(`🎯 Endpoints: ${endpoints.map(e => `${e.method} ${e.path}`).join(', ')}`);
  console.log();
  
  stats.startTime = performance.now();
  
  // Initial connection test
  console.log('🔍 Testing connection...');
  try {
    await makeRequest();
    console.log('✅ Connection successful!\n');
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    process.exit(1);
  }
  
  // Reset stats after connection test
  Object.assign(stats, {
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    totalResponseTime: 0,
    minResponseTime: Infinity,
    maxResponseTime: 0,
    responseCodes: {},
    errors: {}
  });
  
  stats.startTime = performance.now();
  const endTime = stats.startTime + (testDuration * 1000);
  
  // Progress display interval
  const progressInterval = setInterval(displayProgress, 1000);
  
  console.log('🏃 Running load test...\n');
  
  // Main test loop
  while (performance.now() < endTime) {
    await runConcurrentRequests();
  }
  
  stats.endTime = performance.now();
  
  // Clean up
  clearInterval(progressInterval);
  
  // Display final results
  displayResults();
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n\n🛑 Test interrupted by user');
  stats.endTime = performance.now();
  displayResults();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n\n🛑 Test terminated');
  stats.endTime = performance.now();
  displayResults();
  process.exit(0);
});

// Run the test
runLoadTest().catch((error) => {
  console.error('❌ Load test failed:', error);
  process.exit(1);
});
