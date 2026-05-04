# DWBI & MODBD Configuration Summary

## 1. DWBI Frontend Database Configuration

### Connection Details
- **Type**: Direct Oracle Database Connection
- **Default Host**: `10.80.0.40`
- **Default Port**: `1515` (mapped from Oracle's 1521)
- **Database PDB**: `orclpdb1`
- **Default Schema User**: `TickLy`
- **Default Password**: `itdev123`

### Connection String Format
```
ORACLE_CONNECT_STRING=10.80.0.40:1515/orclpdb1
```

### Environment Variables (from `.env.local.example`)
```
# Oracle DB (OLTP/DW same host)
ORACLE_USER=username
ORACLE_PASSWORD=password
ORACLE_CONNECT_STRING=xx.xx.xx.xx:xxxx/xxxx
```

### Connection Implementation
**File**: `frontend/lib/db.ts`
```typescript
const config = {
  user: process.env.ORACLE_USER || "TickLy",
  password: process.env.ORACLE_PASSWORD || "itdev123",
  connectString: process.env.ORACLE_CONNECT_STRING || "10.80.0.40:1515/orclpdb1",
};

export async function getConnection() {
  return oracledb.getConnection(config);
}
```

### Database Modules
- **OLTP Schema**: `TickLy` - Contains operational data (clients, agents, tickets, statuses)
- **Data Warehouse Schema**: `TickLy_DW` - Contains materialized views and dimension/fact tables

---

## 2. DWBI API Endpoints Structure

### Authentication Endpoints

#### POST `/api/auth/login`
- **Purpose**: User authentication (clients and agents)
- **Queries**: 
  - Checks `TickLy.client` table for client login
  - Checks `TickLy.agent` table for agent login
  - Verifies password hash using `bcryptjs`
- **Response**: Session cookie with user data
  - `tickly_session` (httpOnly, 24-hour max age)
  - Returns: `{ role, id, email, name }`

#### POST `/api/auth/logout`
- **Purpose**: Clear user session
- **Action**: Deletes session cookie

#### GET `/api/auth/me`
- **Purpose**: Get current authenticated user session
- **Response**: Current session data or 401 if not authenticated

### Tickets Endpoints

#### GET `/api/tickets`
- **Query Parameters**:
  - `page` (int): Page number for pagination (default: 1)
  - `limit` (int): Items per page (default: 20, max: 100)
  - `stats` (bool): Include status statistics if true
  - `statusFilter` (string): "open" or "closed" (clients only)
  - `status` (string): Comma-separated status names (agents only)
  
- **Database Queries**:
  - Joins: `ticket`, `status`, `prioritate`, `departament`, `client`, `client_fizica`, `client_juridica`
  - **For Clients**: Only shows their own tickets
  - **For Agents**: Shows all tickets (can filter by status)

- **Response Structure**:
```json
{
  "tickets": [
    {
      "ticket_id": number,
      "titlu": string,
      "data_creare": timestamp,
      "data_ultima_actualizare": timestamp,
      "data_rezolvare": timestamp|null,
      "status_nume": string,
      "prioritate_nume": string,
      "departament_nume": string,
      "client_email": string,
      "client_nume": string|null
    }
  ],
  "total": number,
  "stats": {
    "total": number,
    "statuses": [
      {
        "status_id": number,
        "nume": string,
        "este_final": boolean,
        "count": number
      }
    ]
  }
}
```

#### POST `/api/tickets`
- **Purpose**: Create new ticket
- **Body Parameters**:
  ```json
  {
    "titlu": "Ticket Title",
    "descriere": "Description (optional)",
    "departament_id": number,
    "prioritate_id": number,
    "categorie_id": number (optional)
  }
  ```
- **Database Action**:
  - Inserts into `TickLy.ticket` with client_id from session
  - Auto-assigns default status (first non-final status)
  - Returns: `{ new_ticket_id }`

### Reports Endpoints

#### GET `/api/reports`
- **Purpose**: Fetch Data Warehouse analytics dashboards
- **Access**: Agents only (role === "agent")
- **Database Queries**: Reads from multiple materialized views:
  
  1. **SLA Gauge**: `TickLy_DW.mv_report_sla`
     - `respectat_sla`, `total_critice`
  
  2. **Trend Chart**: `TickLy_DW.mv_report_trend` (last 12 months)
     - `luna_nume`, `an`, `tichete_deschise`, `tichete_rezolvate`
  
  3. **Top Topics Bar Chart**: `TickLy_DW.mv_report_top_topics` (top 5)
     - `topic_nume`, `topic_type`, `total_tichete`
  
  4. **Agents Scatter Plot**: `TickLy_DW.mv_report_agents` (top 5)
     - `nume_complet`, `departament`, `tichete_rezolvate`, `medie_ore`
  
  5. **Department Yearly Stats**: `TickLy_DW.mv_dept_yearly_stats`
     - `departament_nume`, `an`, `mv_total_tichete`, `mv_venit_total`, `mv_sum_timp`, `mv_count_timp`
  
  6. **Department Performance**: `TickLy_DW.mv_report_dept_perf` (last 10 records)
     - `departament`, `luna_nume`, `an`, `timp_mediu_ore`, `volum_tichete`

- **Response**:
```json
{
  "total_facts": number,
  "sla": { "RESPECTAT_SLA": number, "TOTAL_CRITICE": number },
  "trend": [...],
  "topics": [...],
  "agents": [...],
  "dept_stats": [...],
  "dept_perf": [...]
}
```

#### POST `/api/reports`
- **Purpose**: Trigger Data Warehouse synchronization
- **Access**: Agents only
- **Database Action**: Executes stored procedure
  ```sql
  BEGIN TickLy_DW.SYNC_DATA_WAREHOUSE; END;
  ```
- **Response**: `{ "success": true }`

---

## 3. DWBI Docker Compose Configuration

### Service: `oracle-db`
**File**: `docker-compose.yml`

```yaml
ports:
  - "1515:1521"   # Oracle Listener (mapped from 1521)
  - "1516:5500"   # OEM Express (mapped from 5500)

environment:
  ORACLE_SID: "${ORACLE_SID}"
  ORACLE_PDB: "${ORACLE_PDB}"
  ORACLE_PWD: "${ORACLE_PWD}"
  ORACLE_EDITION: enterprise
  ORACLE_CHARACTERSET: "AL32UTF8"
  ENABLE_ARCHIVELOG: "true"
  INIT_SGA_SIZE: "2048"
  INIT_PGA_SIZE: "1024"

volumes:
  - ./oradata:/opt/oracle/oradata:rw
  - ./scripts/startup:/opt/oracle/scripts/startup:rw
  - ./scripts/setup:/opt/oracle/scripts/setup:rw
  - ./scripts/etl:/opt/oracle/scripts/etl:ro

network:
  dwbi-net: 172.20.0.10/16
```

### Container
- **Name**: `DW_BI`
- **Image**: `container-registry.oracle.com/database/enterprise:19.3.0.0`
- **Memory**: 8GB limit
- **Character Set**: AL32UTF8
- **Archive Logging**: Enabled

### Setup Scripts Location
```
scripts/setup/
  ├── 01_create_tickly_oltp_user.sql
  ├── 02_create_oltp_schema.sql
  ├── 03_create_oltp_indexes.sql
  ├── 04_insert_mock_records.sql
  ├── 05_mass_insertion.sql
  ├── 06_create_tickly_olap_user.sql
  ├── 07_create_olap_schema.sql
  ├── 08_create_olap_indexes.sql
  ├── 09_create_olap_dimension.sql
  ├── 10_run_etl_full_load.sql
  ├── 11_create_sync_olap_procedure.sql
  └── 12_mw_olap_reports.sql
```

---

## 4. MODBD Oracle Database Configuration

### Multi-Server Setup
**File**: `docker-compose.yml`

MODBD runs 4 independent Oracle database servers (sv1, sv2, sv3, sv4), each selectable via Docker Compose profiles.

#### Environment Variables
```
COMPOSE_PROFILES=sv1,sv2,sv3,sv4
ORACLE_PWD=""
ORACLE_PDB=""
ORACLE_SID=""
```

### Database Instances

#### Server 1 (sv1)
- **Container Name**: `oracle-sv1`
- **Profile**: `sv1`
- **Ports**: 
  - `1521:1521` (Oracle Listener)
  - `5500:5500` (OEM Express)
- **Default SID**: `DB1`
- **Default PDB**: `PDB1`

#### Server 2 (sv2)
- **Container Name**: `oracle-sv2`
- **Profile**: `sv2`
- **Ports**: Same as sv1 (1521:1521)
- **Default SID**: `DB2`
- **Default PDB**: `PDB2`

#### Server 3 (sv3)
- **Container Name**: `oracle-sv3`
- **Profile**: `sv3`
- **Ports**: Same as sv1 (1521:1521)
- **Default SID**: `DB3`
- **Default PDB**: `PDB3`

#### Server 4 (sv4)
- **Container Name**: `oracle-sv4`
- **Profile**: `sv4`
- **Ports**: 
  - `1522:1521` (Oracle Listener)
  - `5501:5500` (OEM Express)
- **Default SID**: `DB4`
- **Default PDB**: `PDB4`

### Common Configuration (All Servers)
```yaml
Image: container-registry.oracle.com/database/enterprise:19.3.0.0
Edition: enterprise
Character Set: AL32UTF8
Archive Logging: Enabled
SGA Size: 2048 MB
PGA Size: 1024 MB
Memory Limit: 6GB
Shared Memory: 2GB
Network: modbd-net (bridge driver)
```

### Startup Scripts Location
```
sv{1-4}/scripts/setup/
```

### Usage

To start specific server:
```bash
docker-compose --profile sv1 up -d    # Start sv1 only
docker-compose --profile sv1,sv2 up -d # Start sv1 and sv2
docker-compose up -d                  # Start all (if all profiles enabled)
```

---

## 5. Connection Flow

### Current Architecture
```
DWBI Frontend (Next.js @ localhost:3000)
           ↓
    [API Routes - TypeScript]
           ↓
    [oracledb Driver]
           ↓
    Oracle Database (10.80.0.40:1515/orclpdb1)
           ├── TickLy OLTP Schema (operational data)
           └── TickLy_DW OLAP Schema (materialized views)
```

### Component Summary

| Component | Type | Purpose |
|-----------|------|---------|
| **DWBI** | Complete Application | Ticket system + DW/BI dashboards |
| **MODBD** | Database Infrastructure | Multi-server Oracle database setup for distributed learning/testing |
| **Frontend** | Next.js 16.1.6 | React 18 with TypeScript, Tailwind CSS |
| **Backend** | Built-in API Routes | Server-side database queries via oracledb |
| **Database** | Oracle 19c Enterprise | Single instance in DWBI, 4 selectable instances in MODBD |

---

## 6. Technology Stack

### DWBI Frontend
- **Runtime**: Node.js (Next.js)
- **Framework**: Next.js 16.1.6
- **UI**: React 18.2.0 + Tailwind CSS 3.4.0
- **Database Driver**: oracledb 6.6.0
- **Security**: bcryptjs 2.4.3 (password hashing)
- **Charts**: Recharts 3.7.0
- **Language**: TypeScript 5.0.0

### MODBD
- **Database**: Oracle Enterprise Edition 19.3.0.0
- **Containerization**: Docker + Docker Compose
- **Network**: Custom bridge network (172.20.0.0/16)

---

## 7. Key Database Schemas

### DWBI - TickLy OLTP Schema Tables
- `ticket` - Main ticket records
- `client` - Client/customer data
- `client_fizica` - Individual client details
- `client_juridica` - Company client details
- `agent` - Support agent records
- `status` - Ticket status definitions
- `prioritate` - Priority levels
- `departament` - Department categories
- `categorie` - Ticket categories

### DWBI - TickLy_DW OLAP Schema
**Materialized Views** (for reporting):
- `mv_report_sla` - SLA compliance metrics
- `mv_report_trend` - Monthly trend analysis
- `mv_report_top_topics` - Top ticket topics
- `mv_report_agents` - Agent performance
- `mv_dept_yearly_stats` - Department yearly statistics
- `mv_report_dept_perf` - Department monthly performance

**Procedures**:
- `SYNC_DATA_WAREHOUSE` - Refresh DW materialized views and aggregate data

---

## 8. Port Mappings Summary

### DWBI
| Service | Internal Port | External Port | Purpose |
|---------|---------------|---------------|---------|
| Oracle | 1521 | 1515 | Database Listener |
| OEM Express | 5500 | 1516 | Oracle Enterprise Manager |

### MODBD sv1-sv3
| Service | Internal Port | External Port |
|---------|---------------|---------------|
| Oracle | 1521 | 1521 |
| OEM Express | 5500 | 5500 |

### MODBD sv4
| Service | Internal Port | External Port |
|---------|---------------|---------------|
| Oracle | 1521 | 1522 |
| OEM Express | 5500 | 5501 |

---

## 9. Authentication & Authorization

### Session Management
- **Cookie Name**: `tickly_session`
- **Type**: httpOnly, secure (in production)
- **Max Age**: 24 hours
- **Storage**: User JSON encoded in cookie

### User Roles
1. **Client**
   - Can view only own tickets
   - Can create tickets
   - Cannot access `/reports` endpoint
   - Sees tickets filtered by `client_id`

2. **Agent**
   - Can view all tickets
   - Can filter tickets by status
   - Full access to `/reports` endpoint
   - Can trigger DW synchronization

---

## 10. Summary of Connection Dependencies

**DWBI Frontend depends on:**
1. Oracle Database at `10.80.0.40:1515`
2. Credentials from environment variables (or defaults)
3. Network access to Oracle listener on port 1515
4. No separate backend service - API routes are embedded in Next.js

**MODBD is:**
1. Independent infrastructure for testing/learning
2. Not actively used by DWBI in current configuration
3. Can be used as alternate Oracle databases if connection string changes
4. Multiple instances for distributed database scenarios
