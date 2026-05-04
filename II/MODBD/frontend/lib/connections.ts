import oracledb, { type Connection } from "oracledb";
import { DB_CONFIG, type UserType, getDbConfigByUserType } from "./constants";

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;
oracledb.autoCommit = true;
oracledb.fetchAsString = [oracledb.CLOB, oracledb.NCLOB];

/**
 * Get connection config for a specific instance
 */
function getConnectionConfig(userType: UserType) {
  const dbConfig = getDbConfigByUserType(userType);
  
  let envConnectString = process.env.ORACLE_CONNECT_STRING;

  // Route the connection to the correct server based on user profile
  if (userType === "B2C" && process.env.ORACLE_CONNECT_STRING_SV1) {
    envConnectString = process.env.ORACLE_CONNECT_STRING_SV1;
    
  } else if (userType === "B2B" && process.env.ORACLE_CONNECT_STRING_SV2) {
    envConnectString = process.env.ORACLE_CONNECT_STRING_SV2;
  } else if (userType === "AGENT" && process.env.ORACLE_CONNECT_STRING_SV3) {
    envConnectString = process.env.ORACLE_CONNECT_STRING_SV3;
  }

  const connectString = envConnectString || `localhost:${dbConfig.port}/${dbConfig.pdb}`;

  return {
    user: process.env.ORACLE_USER || "TickLy",
    password: process.env.ORACLE_PASSWORD || "itdev123",
    connectString: connectString,
  };
}

/**
 * Get connection to a specific instance (B2C, B2B, AGENT, etc.)
 */
export async function getConnectionByUserType(userType: UserType): Promise<Connection> {
  const config = getConnectionConfig(userType);
  return oracledb.getConnection(config);
}

/**
 * Get default connection (B2C for initial login queries)
 */
export async function getDefaultConnection(): Promise<Connection> {
  const config = getConnectionConfig("B2C");
  return oracledb.getConnection(config);
}

/**
 * Run a query with a specific user type connection
 */
export async function runQueryByUserType<T>(
  userType: UserType,
  fn: (conn: Connection) => Promise<T>
): Promise<T> {
  let conn: Connection | undefined;
  try {
    conn = await getConnectionByUserType(userType);
    return await fn(conn);
  } finally {
    if (conn) await conn.close();
  }
}

/**
 * Run a query with default connection (for login and initial detection)
 */
export async function runQuery<T>(fn: (conn: Connection) => Promise<T>): Promise<T> {
  let conn: Connection | undefined;
  try {
    conn = await getDefaultConnection();
    return await fn(conn);
  } finally {
    if (conn) await conn.close();
  }
}
