const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;

// Azure OpenAI Configuration
const AZURE_OPENAI_ENDPOINT = process.env.AZURE_OPENAI_ENDPOINT;
const AZURE_OPENAI_API_KEY = process.env.AZURE_OPENAI_API_KEY;
const AZURE_OPENAI_DEPLOYMENT_NAME = process.env.AZURE_OPENAI_DEPLOYMENT_NAME || 'gpt-4o-mini';

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Plugin info endpoint
app.get('/info', (req, res) => {
  res.json({
    name: 'Grammar & Style Checker Plugin',
    description: 'This plugin checks and corrects grammar and style issues in the text received through the prompt. It uses Azure OpenAI to analyze the input text and returns a corrected/improved version along with explanations of the changes made.',
    version: '1.0.0',
    endpoints: {
      info: {
        method: 'GET',
        path: '/info',
        description: 'Returns information about this plugin'
      },
      prompt: {
        method: 'POST',
        path: '/prompt',
        description: 'Accepts text and returns grammar/style corrections',
        body: {
          prompt: 'string (required) - The text to check for grammar and style issues'
        }
      }
    },
    model: AZURE_OPENAI_DEPLOYMENT_NAME,
    author: 'CC Homework 4'
  });
});

// Main prompt endpoint
app.post('/prompt', async (req, res) => {
  try {
    const { prompt } = req.body;

    // Validate input
    if (!prompt) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'The "prompt" field is required in the request body',
        example: { prompt: 'I has went to the store yesterday.' }
      });
    }

    if (typeof prompt !== 'string') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'The "prompt" field must be a string',
        received: typeof prompt
      });
    }

    if (prompt.trim().length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'The "prompt" field cannot be empty'
      });
    }

    if (prompt.length > 10000) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'The "prompt" field exceeds the maximum length of 10000 characters',
        received: prompt.length
      });
    }

    // Check Azure OpenAI configuration
    if (!AZURE_OPENAI_ENDPOINT || !AZURE_OPENAI_API_KEY) {
      console.error('Azure OpenAI configuration missing');
      return res.status(500).json({
        error: 'Internal Server Error',
        message: 'Azure OpenAI is not properly configured. Please contact the administrator.'
      });
    }

    // Build the system prompt for grammar checking
    const systemPrompt = `You are a professional grammar and style checker. Your task is to:
1. Analyze the provided text for grammar, spelling, punctuation, and style issues
2. Provide a corrected version of the text
3. List the specific corrections made with brief explanations

Format your response as JSON with the following structure:
{
  "original": "the original text",
  "corrected": "the corrected text",
  "corrections": [
    {
      "original": "incorrect phrase",
      "corrected": "corrected phrase",
      "explanation": "brief explanation of the correction"
    }
  ],
  "summary": "brief summary of the overall quality and main issues found"
}

If the text has no errors, return the same text as corrected and an empty corrections array.
Always respond with valid JSON only, no additional text.`;

    // Call Azure OpenAI
    const apiUrl = `${AZURE_OPENAI_ENDPOINT}openai/deployments/${AZURE_OPENAI_DEPLOYMENT_NAME}/chat/completions?api-version=2024-08-01-preview`;

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': AZURE_OPENAI_API_KEY
      },
      body: JSON.stringify({
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: prompt }
        ],
        temperature: 0.3,
        max_tokens: 2000
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Azure OpenAI API error:', response.status, errorText);
      
      if (response.status === 401) {
        return res.status(500).json({
          error: 'Internal Server Error',
          message: 'Azure OpenAI authentication failed. Please contact the administrator.'
        });
      }
      
      if (response.status === 429) {
        return res.status(503).json({
          error: 'Service Unavailable',
          message: 'Azure OpenAI rate limit exceeded. Please try again later.'
        });
      }
      
      if (response.status === 404) {
        return res.status(500).json({
          error: 'Internal Server Error',
          message: 'Azure OpenAI deployment not found. Please contact the administrator.'
        });
      }
      
      return res.status(502).json({
        error: 'Bad Gateway',
        message: 'Failed to communicate with Azure OpenAI service',
        details: `Status: ${response.status}`
      });
    }

    const data = await response.json();
    
    if (!data.choices || data.choices.length === 0) {
      console.error('Azure OpenAI returned no choices:', data);
      return res.status(502).json({
        error: 'Bad Gateway',
        message: 'Azure OpenAI returned an unexpected response'
      });
    }

    const aiResponse = data.choices[0].message.content;

    // Try to parse the response as JSON
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(aiResponse);
    } catch (parseError) {
      // If parsing fails, return the raw response
      console.warn('Could not parse AI response as JSON:', parseError.message);
      parsedResponse = {
        original: prompt,
        corrected: aiResponse,
        corrections: [],
        summary: 'Response could not be parsed as structured JSON'
      };
    }

    // Return the result
    res.json({
      success: true,
      result: parsedResponse,
      usage: data.usage || null
    });

  } catch (error) {
    console.error('Error processing prompt:', error);
    
    if (error.code === 'ENOTFOUND' || error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        error: 'Service Unavailable',
        message: 'Could not connect to Azure OpenAI service. Please try again later.'
      });
    }
    
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'An unexpected error occurred while processing your request'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    configuration: {
      openaiEndpoint: AZURE_OPENAI_ENDPOINT ? 'configured' : 'missing',
      openaiApiKey: AZURE_OPENAI_API_KEY ? 'configured' : 'missing',
      openaiDeployment: AZURE_OPENAI_DEPLOYMENT_NAME
    }
  });
});

// Serve the frontend
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `The endpoint ${req.method} ${req.path} does not exist`,
    availableEndpoints: [
      'GET /info',
      'POST /prompt',
      'GET /health'
    ]
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: 'An unexpected error occurred'
  });
});

app.listen(PORT, () => {
  console.log(`Grammar & Style Checker Plugin running on port ${PORT}`);
  console.log(`Azure OpenAI Endpoint: ${AZURE_OPENAI_ENDPOINT || 'NOT CONFIGURED'}`);
  console.log(`Azure OpenAI Deployment: ${AZURE_OPENAI_DEPLOYMENT_NAME}`);
});
