/**
 * Database and schema constants for MODBD multi-instance setup
 */

export type UserType = "B2C" | "B2B" | "AGENT";

export const DB_CONFIG = {
  // B2C instance - sv1
  SV1_B2C: {
    name: "sv1",
    type: "B2C",
    port: 1521,
    pdb: "orclpdb1",
    tables: {
      client: "TICKLY.client_fizic",
      ticket: "TICKLY.ticket_fizic",
      comment_client: "TICKLY.comment_client_fizic",
      comment_agent: "TICKLY.comment_agent_fizic",
      adresa: "TICKLY.adresa_fizic",
      ticket_tag: "TICKLY.ticket_tag_fizic",
      ticket_history: "TICKLY.ticket_history_fizic",
      feedback: "TICKLY.feedback_fizic",
    },
    clientIdField: "cnp",
  },

  // B2B instance - sv2
  SV2_B2B: {
    name: "sv2",
    type: "B2B",
    port: 1521,
    pdb: "orclpdb1",
    tables: {
      client: "TICKLY.client_juridic",
      ticket: "TICKLY.ticket_juridic",
      comment_client: "TICKLY.comment_client_juridic",
      comment_agent: "TICKLY.comment_agent_juridic",
      adresa: "TICKLY.adresa_juridic",
      ticket_tag: "TICKLY.ticket_tag_juridic",
      ticket_history: "TICKLY.ticket_history_juridic",
      feedback: "TICKLY.feedback_juridic",
    },
    clientIdField: "cui",
  },

  // Security instance - sv3
  SV3_SECURITY: {
    name: "sv3",
    type: "AGENT",
    port: 1521,
    pdb: "orclpdb1",
    tables: {
      agent_sec: "TICKLY.agent_sec",
      ticket: "TICKLY.v_ticket",
      client: "TICKLY.v_client",
      comment_client: "TICKLY.v_comment_client",
      comment_agent: "TICKLY.v_comment_agent",
      ticket_history: "TICKLY.v_ticket_history",
      ticket_agent: "TICKLY.v_ticket_agent",
    },
  },

  // Template/Reference instance - sv4
  SV4_TEMPLATE: {
    name: "sv4",
    type: "REFERENCE",
    port: 1522,
    pdb: "orclpdb1",
    tables: {
      prioritate: "TICKLY.prioritate",
      status: "TICKLY.status",
      categorie: "TICKLY.categorie",
      tag: "TICKLY.tag",
      topic: "TICKLY.topic",
      departament: "TICKLY.departament",
    },
  },
};

/**
 * Get appropriate DB config based on user type
 */
export function getDbConfigByUserType(userType: UserType) {
  switch (userType) {
    case "B2C":
      return DB_CONFIG.SV1_B2C;
    case "B2B":
      return DB_CONFIG.SV2_B2B;
    case "AGENT":
      return DB_CONFIG.SV3_SECURITY;
    default:
      return DB_CONFIG.SV1_B2C; // default to B2C
  }
}

/**
 * Get table name based on user type and table type
 */
export function getTableName(userType: UserType, tableType: string): string {
  const config = getDbConfigByUserType(userType);
  return (config.tables as Record<string, string>)[tableType] || "";
}
