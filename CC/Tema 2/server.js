const express = require('express');
const bodyParser = require('body-parser');
const sql = require('mssql');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static('public'));

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
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/items', async (req, res) => {
  try {
    if (!pool) {
      return res.status(503).json({ error: 'Database not available' });
    }

    const result = await pool.request().query('SELECT Id, Text, CreatedAt FROM Items ORDER BY CreatedAt DESC');
    res.json(result.recordset);
  } catch (err) {
    console.error('Error fetching items:', err);
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

app.post('/api/items', async (req, res) => {
  try {
    if (!pool) {
      return res.status(503).json({ error: 'Database not available' });
    }

    const { text } = req.body;
    
    if (!text || text.trim().length === 0) {
      return res.status(400).json({ error: 'Item text is required' });
    }

    const result = await pool.request()
      .input('text', sql.NVarChar, text.trim())
      .query('INSERT INTO Items (Text) OUTPUT INSERTED.Id, INSERTED.Text, INSERTED.CreatedAt VALUES (@text)');

    res.status(201).json(result.recordset[0]);
  } catch (err) {
    console.error('Error adding item:', err);
    res.status(500).json({ error: 'Failed to add item' });
  }
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    database: pool ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


