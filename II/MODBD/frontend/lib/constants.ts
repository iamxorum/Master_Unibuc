/**
 * Database and schema constants for MODBD multi-instance setup
 */

export type UserType = "B2C" | "B2B" | "AGENT";

export const DB_CONFIG = {
  
  SV1_B2C: {
    name: "SV1",
    type: "B2C",
    port: 1521,
    pdb: "PDB1",
    tables: {
      
      client: "TICKLY.V_CLIENT_FIZIC_AUTH", 
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

  
  SV2_B2B: {
    name: "SV2",
    type: "B2B",
    port: 1523,
    pdb: "PDB2",
    tables: {
      
      client: "TICKLY.V_CLIENT_JURIDIC_AUTH",
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

  
  SV3_SECURITY: { 
    name: "SV1_AGENT_HUB",
    type: "AGENT",
    port: 1521,
    pdb: "PDB1", 
    tables: {
      agent_sec: "TICKLY.V_AGENT_AUTH", 
      ticket: "TICKLY.V_TICKET_AGENT", 
      client: "TICKLY.V_CLIENT_GLOBAL",
      comment_client: "TICKLY.comment_client_fizic",
      comment_agent: "TICKLY.comment_agent_fizic",
      ticket_history: "TICKLY.ticket_history_fizic",
      ticket_agent: "TICKLY.ticket_agent_fizic",
    },
  },

  
  SV4_TEMPLATE: {
    name: "SV4",
    type: "REFERENCE",
    port: 1522,
    pdb: "PDB4",
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

export function getDbConfigByUserType(userType: UserType) {
  switch (userType) {
    case "B2C": return DB_CONFIG.SV1_B2C;
    case "B2B": return DB_CONFIG.SV2_B2B;
    case "AGENT": return DB_CONFIG.SV3_SECURITY;
    default: return DB_CONFIG.SV1_B2C;
  }
}

export function getTableName(userType: UserType, tableType: string): string {
  const config = getDbConfigByUserType(userType);
  return (config.tables as Record<string, string>)[tableType] || "";
}