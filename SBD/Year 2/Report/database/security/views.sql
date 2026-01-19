CREATE OR REPLACE VIEW pacient_public AS
SELECT 
    id_pacient,
    nume,
    prenume,
    telefon
FROM pacient;

CREATE OR REPLACE VIEW personal_public AS
SELECT 
    id_personal,
    nume,
    prenume,
    specializare
FROM personal_medical;

CREATE OR REPLACE VIEW fisa_medicala_personal AS
SELECT 
    f.id_fisa,
    f.id_pacient,
    p.nume AS nume_pacient,
    p.prenume AS prenume_pacient,
    f.diagnostic,
    f.tratament,
    f.data_consultatie
FROM fisa_medicala f
JOIN pacient p ON f.id_pacient = p.id_pacient
JOIN personal_medical pm ON f.id_medic = pm.id_personal
WHERE pm.username_db = current_user;

GRANT SELECT ON pacient_public TO rol_asistent;
GRANT SELECT ON personal_public TO rol_asistent;
GRANT SELECT ON fisa_medicala_personal TO rol_medic;

