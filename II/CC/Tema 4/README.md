# Grammar & Style Checker - Azure OpenAI Plugin

A web API plugin that uses Azure OpenAI to check and correct grammar and style issues in text.

## Public API URL

After deployment, the application will be available at:
```
https://<app-service-name>.azurewebsites.net
```

## Plugin Functionality

This plugin accepts text input and uses Azure OpenAI to:
- Analyze the text for grammar, spelling, punctuation, and style issues
- Return a corrected version of the text
- Provide detailed explanations of each correction made
- Give an overall summary of the text quality

## API Endpoints

### GET /info

Returns a description of what the plugin does.

**Example Request:**
```bash
curl https://<app-service-name>.azurewebsites.net/info
```

**Example Response:**
```json
{
  "name": "Grammar & Style Checker Plugin",
  "description": "This plugin checks and corrects grammar and style issues in the text received through the prompt. It uses Azure OpenAI to analyze the input text and returns a corrected/improved version along with explanations of the changes made.",
  "version": "1.0.0",
  "endpoints": {
    "info": {
      "method": "GET",
      "path": "/info",
      "description": "Returns information about this plugin"
    },
    "prompt": {
      "method": "POST",
      "path": "/prompt",
      "description": "Accepts text and returns grammar/style corrections",
      "body": {
        "prompt": "string (required) - The text to check for grammar and style issues"
      }
    }
  },
  "model": "gpt-4o-mini",
  "author": "CC Homework 4"
}
```

### POST /prompt

Accepts text and returns grammar/style corrections.

**Example Request:**
```bash
curl -X POST https://<app-service-name>.azurewebsites.net/prompt \
  -H "Content-Type: application/json" \
  -d '{"prompt": "I has went to the store yesterday and buyed some grocerys."}'
```

**Example Response:**
```json
{
  "success": true,
  "result": {
    "original": "I has went to the store yesterday and buyed some grocerys.",
    "corrected": "I went to the store yesterday and bought some groceries.",
    "corrections": [
      {
        "original": "I has went",
        "corrected": "I went",
        "explanation": "Incorrect verb conjugation. 'Has went' should be 'went' (simple past) or 'have gone' (present perfect)."
      },
      {
        "original": "buyed",
        "corrected": "bought",
        "explanation": "'Buyed' is not a word. The past tense of 'buy' is 'bought'."
      },
      {
        "original": "grocerys",
        "corrected": "groceries",
        "explanation": "Spelling error. The correct plural of 'grocery' is 'groceries'."
      }
    ],
    "summary": "The text contained several grammatical errors including incorrect verb conjugation and spelling mistakes. The corrected version uses proper past tense forms and correct spelling."
  },
  "usage": {
    "prompt_tokens": 150,
    "completion_tokens": 200,
    "total_tokens": 350
  }
}
```

## Azure OpenAI Configuration

- **Model**: gpt-4o-mini
- **Deployment Name**: gpt-4o-mini
- **Region**: swedencentral
- **API Version**: 2024-08-01-preview

## Error Handling

The API handles the following error cases:

### 1. Invalid or Empty Prompt (400 Bad Request)

**Trigger:** Send a request without a prompt or with an empty prompt.

```bash
curl -X POST https://<app-service-name>.azurewebsites.net/prompt \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Response:**
```json
{
  "error": "Bad Request",
  "message": "The \"prompt\" field is required in the request body",
  "example": { "prompt": "I has went to the store yesterday." }
}
```

### 2. Prompt Too Long (400 Bad Request)

**Trigger:** Send a prompt exceeding 10,000 characters.

**Response:**
```json
{
  "error": "Bad Request",
  "message": "The \"prompt\" field exceeds the maximum length of 10000 characters",
  "received": 10500
}
```

### 3. Azure OpenAI Rate Limit (503 Service Unavailable)

**Trigger:** Exceeding Azure OpenAI rate limits.

**Response:**
```json
{
  "error": "Service Unavailable",
  "message": "Azure OpenAI rate limit exceeded. Please try again later."
}
```

### 4. Azure OpenAI Service Error (502 Bad Gateway)

**Trigger:** Azure OpenAI service is unavailable or returns an error.

**Response:**
```json
{
  "error": "Bad Gateway",
  "message": "Failed to communicate with Azure OpenAI service",
  "details": "Status: 500"
}
```

### 5. Internal Server Error (500)

**Trigger:** Unexpected server errors or misconfiguration.

**Response:**
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred while processing your request"
}
```

## Deployment

The application is deployed to **Azure App Service** (Linux, Node.js 20 LTS).

### Architecture

```
┌─────────────────┐       ┌──────────────────┐       ┌─────────────────────┐
│     Client      │──────▶│   App Service    │──────▶│   Azure OpenAI      │
│  (HTTP Request) │       │   (Node.js API)  │       │   (gpt-4o-mini)     │
└─────────────────┘       └──────────────────┘       └─────────────────────┘
```

### Resources Created

- **Resource Group**: rg-openai-plugin
- **App Service Plan**: asp-grammar-plugin (B1 tier, Linux)
- **App Service**: grammar-plugin-{random}
- **Azure OpenAI Account**: openai-grammar-{random}
- **OpenAI Model Deployment**: gpt-4o-mini

### Configuration

All secrets and configuration are stored in Azure App Service Application Settings:

| Setting | Description |
|---------|-------------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint URL |
| `AZURE_OPENAI_API_KEY` | Azure OpenAI API key |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | Model deployment name (gpt-4o-mini) |
| `PORT` | Server port (8080) |

No secrets are hardcoded in the source code.

### Deploy Script

Run the deployment script:

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. Create a resource group
2. Create an Azure OpenAI account
3. Deploy the gpt-4o-mini model
4. Create an App Service Plan and App Service
5. Configure application settings with OpenAI credentials
6. Deploy the application code

### Cleanup

To delete all resources:

```bash
chmod +x cleanup.sh
./cleanup.sh
```
