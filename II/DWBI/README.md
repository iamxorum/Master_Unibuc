# TickLy - DW&BI Project

Data Warehouse and Business Intelligence project for TickLy support ticketing system.

## Project Structure

```
dwbi_project/
├── docker-compose.yml      # Docker Compose configuration
├── scripts/
│   ├── setup/              # Initialization scripts
│   │   └── 01_create_tickly_user.sql
│   └── startup/            # Startup scripts
├── schema/                 # Database schemas
│   ├── TickLy DW.sql       # OLTP schema
│   └── TickLy_DW_BI.sql    # Data Warehouse schema
└── oradata/                # Oracle data files
```
