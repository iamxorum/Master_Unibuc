declare module "oracledb" {
  export interface Connection {
    execute(sql: string, binds?: unknown, opts?: unknown): Promise<{ rows?: unknown[]; outBinds?: unknown }>;
    close(): Promise<void>;
  }
  const oracledb: {
    outFormat: number;
    autoCommit: boolean;
    OUT_FORMAT_OBJECT: number;
    BIND_OUT: number;
    NUMBER: number;
    CLOB: unknown;
    NCLOB: unknown;
    fetchAsString: unknown[];
    getConnection(config: { user: string; password: string; connectString: string }): Promise<Connection>;
  };
  export default oracledb;
}
