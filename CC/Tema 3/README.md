Application URL:
  https://todo-app-f5b688.azurewebsites.net

## Features

✅ **Request Tracking** - Every HTTP request is tracked with timing and status  
✅ **Business Logging** - Logs when items are successfully added  
✅ **Error Handling** - Tracks errors and invalid inputs  
✅ **Health Monitoring** - Health endpoint to check if the app is running  

## Setup

### Quick Setup (Automatic)

Created this automatic deploy.sh to create the web app with telemetry via azure cli

```bash
./deploy.sh
```

### KQL Queries

#### See last 20 requests
```kql
requests
| order by timestamp desc
| take 20
```

#### View Custom Events
```kql
customEvents
| order by timestamp desc
| take 10
```

#### Check Health Endpoint
```kql
requests
| where name contains "health"
| order by timestamp desc
```

## Application Endpoints

- `GET /` - Main page
- `GET /api/items` - Get all items
- `POST /api/items` - Add a new item
- `GET /health` - Health check

## Example Usage

### Add an Item
```bash
curl -X POST http://app-url/api/items \
  -H "Content-Type: application/json" \
  -d '{"text": "Portocala12"}'
```

### Get All Items
```bash
curl http://app-url/api/items
```

### Check Health
```bash
curl http://app-url/health
```


## Trigger error

Configured errors for duplicated items and empty items.

1: Empty item
![Item Empty](./assets/Item%20Empty.png)

2: Duplicated Item
![Duplicated Item](./assets/Item%20Exists.png)

## Screenshots from Azure Portal

1: Dashboard App Insight
![Dashboard](./assets/Dashboard.png)

2: KQL Last 20 Reqiuests
![KQL Last 20 Reqiuests](./assets/Last%20Requests.png)

3: KQL Custom events
![KQL Custom events](./assets/Custom%20Events.png)