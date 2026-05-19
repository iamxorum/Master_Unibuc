ALTER SESSION SET CONTAINER = PDB1;

CREATE OR REPLACE FORCE VIEW TICKLY.V_CLIENT_GLOBAL AS
SELECT c.client_id, c.prenume || ' ' || c.nume AS nume_client, s.email, 'FIZIC' AS tip
FROM TICKLY.client_fizic c
JOIN TICKLY.client_fizic_sec@LINK_SV3 s ON c.client_id = s.client_id
UNION ALL
SELECT c.client_id, c.denumire AS nume_client, s.email, 'JURIDIC' AS tip
FROM TICKLY.client_juridic@LINK_SV2 c
JOIN TICKLY.client_juridic_sec@LINK_SV3 s ON c.client_id = s.client_id;

CREATE OR REPLACE FORCE VIEW TICKLY.V_TICKET_AGENT AS
SELECT ticket_id, client_id, prioritate_id, status_id, categorie_id, titlu, descriere, data_creare, data_rezolvare, 'FIZIC' AS tip_client 
FROM TICKLY.ticket_fizic
UNION ALL
SELECT ticket_id, client_id, prioritate_id, status_id, categorie_id, titlu, descriere, data_creare, data_rezolvare, 'JURIDIC' AS tip_client 
FROM TICKLY.ticket_juridic@LINK_SV2;

CREATE OR REPLACE VIEW TICKLY.V_CLIENT_FIZIC_AUTH AS
SELECT 
    sec.client_id,
    prof.nume || ' ' || prof.prenume AS display_name,
    sec.email,
    sec.password_hash,
    sec.is_active
FROM TICKLY.CLIENT_FIZIC_SEC@LINK_SV3 sec
JOIN TICKLY.client_fizic prof ON prof.client_id = sec.client_id;

CREATE OR REPLACE VIEW TICKLY.V_AGENT_AUTH AS
SELECT p.agent_id, p.prenume || ' ' || p.nume AS display_name, s.email, s.password_hash
FROM TICKLY.agent_profil p
INNER JOIN TICKLY.agent_sec@LINK_SV3 s ON p.agent_id = s.agent_id
WHERE s.is_active = 'Y';