const express = require('express');
const bodyParser = require('body-parser');
const sql = require('mssql');
const path = require('path');
const fs = require('fs');
const appInsights = require('applicationinsights');

// Initialize Application Insights
const appInsightsKey = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING || process.env.APPINSIGHTS_INSTRUMENTATIONKEY;
if (appInsightsKey) {
  appInsights.setup(appInsightsKey)
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .start();
  console.log('Application Insights initialized');
} else {
  console.warn('Application Insights not configured. Set APPLICATIONINSIGHTS_CONNECTION_STRING or APPINSIGHTS_INSTRUMENTATIONKEY environment variable.');
}

const app = express();
const PORT = process.env.PORT || 8080;

// Get the default client
const client = appInsights.defaultClient;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static('public'));

// Request performance telemetry middleware
app.use((req, res, next) => {
  const startTime = Date.now();
  const timestamp = new Date().toISOString();
  
  // Log original end function
  const originalEnd = res.end;
  
  res.end = function(...args) {
    const duration = Date.now() - startTime;
    
    // Track request telemetry
    if (client) {
      client.trackRequest({
        name: `${req.method} ${req.path}`,
        url: req.originalUrl || req.url,
        duration: duration,
        resultCode: res.statusCode,
        success: res.statusCode < 400,
        properties: {
          method: req.method,
          path: req.path,
          timestamp: timestamp
        }
      });
    }
    
    // Log to console for debugging
    console.log(`[${timestamp}] ${req.method} ${req.path} - ${res.statusCode} - ${duration}ms`);
    
    // Call original end
    originalEnd.apply(res, args);
  };
  
  next();
});

// Database configuration
const dbConfig = {
  server: process.env.DB_SERVER || '',
  database: process.env.DB_NAME || '',
  user: process.env.DB_USER || '',
  password: process.env.DB_PASSWORD || '',
  options: {
    encrypt: true,
    trustServerCertificate: false,
    enableArithAbort: true
  }
};

let pool = null;

async function initDatabase() {
  try {
    if (!dbConfig.server || !dbConfig.database || !dbConfig.user || !dbConfig.password) {
      console.error('Database configuration is missing. Please set DB_SERVER, DB_NAME, DB_USER, and DB_PASSWORD environment variables.');
      return;
    }

    pool = await sql.connect(dbConfig);
    console.log('Connected to Azure SQL Database');

    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Items]') AND type in (N'U'))
      BEGIN
        CREATE TABLE [dbo].[Items] (
          [Id] INT IDENTITY(1,1) PRIMARY KEY,
          [Text] NVARCHAR(500) NOT NULL,
          [CreatedAt] DATETIME2 DEFAULT GETDATE()
        )
      END
    `);
    console.log('Database table ready');
  } catch (err) {
    console.error('Database connection error:', err.message);
    pool = null;
  }
}

initDatabase();

// Routes
app.get('/', (req, res) => {
  // Inject Application Insights key into HTML
  let html = fs.readFileSync(path.join(__dirname, 'public', 'index.html'), 'utf8');
  const instrumentationKey = process.env.APPLICATIONINSIGHTS_INSTRUMENTATION_KEY || '';
  html = html.replace('instrumentationKey: ""', `instrumentationKey: "${instrumentationKey}"`);
  res.send(html);
});

app.get('/api/items', async (req, res) => {
  try {
    if (!pool) {
      if (client) {
        client.trackException({ exception: new Error('Database not available') });
      }
      return res.status(503).json({ error: 'Database not available' });
    }

    const result = await pool.request().query('SELECT Id, Text, CreatedAt FROM Items ORDER BY CreatedAt DESC');
    res.json(result.recordset);
  } catch (err) {
    console.error('Error fetching items:', err);
    if (client) {
      client.trackException({ exception: err });
    }
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

app.post('/api/items', async (req, res) => {
  try {
    if (!pool) {
      const error = new Error('Database not available');
      if (client) {
        client.trackException({ exception: error });
      }
      return res.status(503).json({ error: 'Database not available' });
    }

    const { text } = req.body;
    
    if (!text || text.trim().length === 0) {
      const error = new Error('Item text is required');
      if (client) {
        client.trackException({ 
          exception: error,
          properties: { endpoint: '/api/items', method: 'POST' }
        });
      }
      return res.status(400).json({ error: 'Item text is required' });
    }

    const trimmedText = text.trim();
    
    // Check for duplicate items (case-insensitive)
    const checkResult = await pool.request()
      .input('text', sql.NVarChar, trimmedText)
      .query('SELECT Id FROM Items WHERE LOWER(Text) = LOWER(@text)');
    
    if (checkResult.recordset.length > 0) {
      const error = new Error('Duplicate item: Item with the same text already exists');
      console.error('Duplicate item error:', trimmedText);
      if (client) {
        client.trackException({ 
          exception: error,
          properties: { 
            endpoint: '/api/items', 
            method: 'POST',
            itemText: trimmedText
          }
        });
        client.trackEvent({
          name: 'DuplicateItemAttempt',
          properties: {
            itemText: trimmedText
          }
        });
      }
      return res.status(409).json({ error: 'Duplicate item: Item with the same text already exists' });
    }

    const result = await pool.request()
      .input('text', sql.NVarChar, trimmedText)
      .query('INSERT INTO Items (Text) OUTPUT INSERTED.Id, INSERTED.Text, INSERTED.CreatedAt VALUES (@text)');

    // Business logging: Item successfully added
    console.log('Item successfully added:', result.recordset[0]);
    if (client) {
      client.trackTrace({ 
        message: 'Item successfully added',
        severity: 1, // Information
        properties: {
          itemId: result.recordset[0].Id,
          itemText: trimmedText
        }
      });
      client.trackEvent({
        name: 'ItemAdded',
        properties: {
          itemId: result.recordset[0].Id,
          itemText: trimmedText
        }
      });
    }

    res.status(201).json(result.recordset[0]);
  } catch (err) {
    console.error('Error adding item:', err);
    if (client) {
      client.trackException({ 
        exception: err,
        properties: { endpoint: '/api/items', method: 'POST' }
      });
    }
    res.status(500).json({ error: 'Failed to add item' });
  }
});

app.get('/health', (req, res) => {
  // Health endpoint - automatically tracked by middleware
  res.json({ 
    status: 'ok', 
    database: pool ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


