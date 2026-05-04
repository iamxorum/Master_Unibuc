// Re-export all connection functions from connections.ts for backward compatibility
export { runQuery, getDefaultConnection, getConnectionByUserType, runQueryByUserType } from "./connections";
export { DB_CONFIG, getDbConfigByUserType, getTableName, type UserType } from "./constants";
