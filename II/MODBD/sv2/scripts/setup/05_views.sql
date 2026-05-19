ALTER SESSION SET CONTAINER = PDB2;

CREATE OR REPLACE VIEW TICKLY.V_CLIENT_JURIDIC_AUTH AS
SELECT 
    sec.client_id,
    prof.denumire AS display_name,
    sec.email,
    sec.password_hash,
    sec.is_active
FROM TICKLY.CLIENT_JURIDIC_SEC@LINK_SV3 sec
JOIN TICKLY.client_juridic prof ON prof.client_id = sec.client_id;

CREATE OR REPLACE VIEW TICKLY.V_TICKET_B2B AS
SELECT ticket_id, client_id, prioritate_id, status_id, categorie_id, titlu, descriere, data_creare, data_rezolvare
FROM TICKLY.ticket_juridic;