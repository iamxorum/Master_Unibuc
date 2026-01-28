ALTER SESSION SET CONTAINER = XEPDB1;

-- Mascare parțială telefon: 07XX XXX X23 -> 07** *** *23
CREATE OR REPLACE FUNCTION careconnect.mask_telefon(p_telefon IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
    IF p_telefon IS NULL OR LENGTH(p_telefon) < 4 THEN
        RETURN '[ASCUNS]';
    END IF;
    RETURN SUBSTR(p_telefon, 1, 2) || '******' || SUBSTR(p_telefon, -2);
END mask_telefon;
/

-- Mascare parțială email: ana.popescu@email.com -> a****u@e****.com
CREATE OR REPLACE FUNCTION careconnect.mask_email(p_email IN VARCHAR2)
RETURN VARCHAR2
IS
    v_at_pos    NUMBER;
    v_dot_pos   NUMBER;
    v_local     VARCHAR2(100);
    v_domain    VARCHAR2(100);
BEGIN
    IF p_email IS NULL THEN
        RETURN '[ASCUNS]';
    END IF;
    
    v_at_pos := INSTR(p_email, '@');
    IF v_at_pos = 0 THEN
        RETURN '[INVALID]';
    END IF;
    
    v_local := SUBSTR(p_email, 1, v_at_pos - 1);
    v_domain := SUBSTR(p_email, v_at_pos + 1);
    v_dot_pos := INSTR(v_domain, '.');
    
    RETURN SUBSTR(v_local, 1, 1) || '****' || SUBSTR(v_local, -1) || 
           '@' || SUBSTR(v_domain, 1, 1) || '****' || SUBSTR(v_domain, v_dot_pos);
END mask_email;
/

-- Mascare adresă: Str. Victoriei 10, București -> [ADRESĂ ASCUNSĂ], București
CREATE OR REPLACE FUNCTION careconnect.mask_adresa(p_adresa IN VARCHAR2)
RETURN VARCHAR2
IS
    v_virgula_pos NUMBER;
BEGIN
    IF p_adresa IS NULL THEN
        RETURN '[ASCUNS]';
    END IF;
    
    v_virgula_pos := INSTR(p_adresa, ',');
    IF v_virgula_pos > 0 THEN
        RETURN '[ADRESĂ ASCUNSĂ],' || SUBSTR(p_adresa, v_virgula_pos + 1);
    ELSE
        RETURN '[ADRESĂ ASCUNSĂ]';
    END IF;
END mask_adresa;
/

-- Mascare parțială CNP decriptat: 1850415123456 -> 185****123456
CREATE OR REPLACE FUNCTION careconnect.mask_cnp_partial(p_cnp IN VARCHAR2)
RETURN VARCHAR2
IS
BEGIN
    IF p_cnp IS NULL OR (LENGTH(p_cnp) < 13 OR LENGTH(p_cnp) > 13) THEN
        RETURN '[INVALID]';
    END IF;
    RETURN SUBSTR(p_cnp, 1, 3) || '****' || SUBSTR(p_cnp, 8);
END mask_cnp_partial;
/


-- funcție combinată: decriptează CNP și apoi îl mascează parțial cu funcția de mai sus
CREATE OR REPLACE FUNCTION careconnect.decrypt_and_mask_cnp(p_cnp_encrypted IN RAW)
RETURN VARCHAR2
IS
    v_cnp_decrypted VARCHAR2(20);
BEGIN
    IF p_cnp_encrypted IS NULL THEN
        RETURN '[FĂRĂ CNP]';
    END IF;
    
    v_cnp_decrypted := careconnect.decrypt_cnp_audited(p_cnp_encrypted);
    
    RETURN careconnect.mask_cnp_partial(v_cnp_decrypted);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN '[EROARE DECRIPTARE]';
END decrypt_and_mask_cnp;
/

-- view pacienti receptie
CREATE OR REPLACE VIEW careconnect.v_pacienti_receptie AS
SELECT 
    id_pacient,
    nume,
    prenume,
    '[CNP PROTEJAT]' AS cnp_status,
    data_nasterii,
    sex,
    telefon,
    email,
    adresa,
    grupa_sanguina,
    data_inregistrare
FROM careconnect.pacient;

-- view pacienti asistent
CREATE OR REPLACE VIEW careconnect.v_pacienti_asistent AS
SELECT 
    id_pacient,
    nume,
    prenume,
    '[CNP PROTEJAT]' AS cnp_status,
    data_nasterii,
    sex,
    telefon,
    careconnect.mask_email(email) AS email,
    careconnect.mask_adresa(adresa) AS adresa,
    grupa_sanguina,
    data_inregistrare
FROM careconnect.pacient;

-- view pacienti medic
CREATE OR REPLACE VIEW careconnect.v_pacienti_medic AS
SELECT 
    id_pacient,
    nume,
    prenume,
    careconnect.decrypt_and_mask_cnp(cnp) AS cnp_partial,
    data_nasterii,
    sex,
    careconnect.mask_telefon(telefon) AS telefon,
    careconnect.mask_email(email) AS email,
    careconnect.mask_adresa(adresa) AS adresa,
    grupa_sanguina,
    data_inregistrare
FROM careconnect.pacient;

-- view pacienti admin
CREATE OR REPLACE VIEW careconnect.v_pacienti_admin AS
SELECT 
    id_pacient,
    nume,
    prenume,
    cnp AS cnp_criptat,
    data_nasterii,
    sex,
    telefon,
    email,
    adresa,
    grupa_sanguina,
    data_inregistrare,
    (SELECT COUNT(*) FROM careconnect.fisa_medicala f WHERE f.id_pacient = p.id_pacient) AS nr_fise
FROM careconnect.pacient p;


-- view fise receptie
CREATE OR REPLACE VIEW careconnect.v_fise_receptie AS
SELECT 
    f.id_fisa,
    f.id_pacient,
    p.nume || ' ' || p.prenume AS pacient_nume,
    f.id_medic,
    m.nume || ' ' || m.prenume AS medic_nume,
    f.data_consultatie,
    'Consultație medicală' AS diagnostic,
    '*** INFORMAȚIE MEDICALĂ ***' AS tratament,
    f.nivel_confidentialitate
FROM careconnect.fisa_medicala f
JOIN careconnect.pacient p ON f.id_pacient = p.id_pacient
JOIN careconnect.personal_medical m ON f.id_medic = m.id_personal
WHERE f.nivel_confidentialitate = 1;

-- view fise asistent
CREATE OR REPLACE VIEW careconnect.v_fise_asistent AS
SELECT 
    f.id_fisa,
    f.id_pacient,
    p.nume || ' ' || p.prenume AS pacient_nume,
    f.id_medic,
    m.nume || ' ' || m.prenume AS medic_nume,
    f.data_consultatie,
    f.diagnostic,
    CASE 
        WHEN f.nivel_confidentialitate >= 2 THEN '*** TRATAMENT SENSIBIL ***'
        ELSE f.tratament 
    END AS tratament,
    f.nivel_confidentialitate
FROM careconnect.fisa_medicala f
JOIN careconnect.pacient p ON f.id_pacient = p.id_pacient
JOIN careconnect.personal_medical m ON f.id_medic = m.id_personal
WHERE f.nivel_confidentialitate <= 2;

-- view fise medic
CREATE OR REPLACE VIEW careconnect.v_fise_medic AS
SELECT 
    f.id_fisa,
    f.id_pacient,
    p.nume || ' ' || p.prenume AS pacient_nume,
    f.id_medic,
    m.nume || ' ' || m.prenume AS medic_nume,
    f.data_consultatie,
    f.diagnostic,
    f.tratament,
    f.observatii,
    f.nivel_confidentialitate
FROM careconnect.fisa_medicala f
JOIN careconnect.pacient p ON f.id_pacient = p.id_pacient
JOIN careconnect.personal_medical m ON f.id_medic = m.id_personal;

-- view fise admin
CREATE OR REPLACE VIEW careconnect.v_fise_admin AS
SELECT 
    f.id_fisa,
    f.id_pacient,
    p.nume || ' ' || p.prenume AS pacient_nume,
    f.id_medic,
    m.nume || ' ' || m.prenume AS medic_nume,
    m.username_db AS medic_username,
    f.data_consultatie,
    f.diagnostic,
    f.tratament,
    f.observatii,
    f.nivel_confidentialitate,
    (SELECT COUNT(*) FROM careconnect.audit_log a 
     WHERE a.table_name = 'FISA_MEDICALA' AND a.record_id = f.id_fisa) AS nr_modificari
FROM careconnect.fisa_medicala f
JOIN careconnect.pacient p ON f.id_pacient = p.id_pacient
JOIN careconnect.personal_medical m ON f.id_medic = m.id_personal;


-- view personal receptie
CREATE OR REPLACE VIEW careconnect.v_personal_receptie AS
SELECT 
    pm.id_personal,
    pm.nume,
    pm.prenume,
    pm.rol,
    pm.grad_acces,
    d.nume_departament,
    pm.telefon,
    pm.email
FROM careconnect.personal_medical pm
LEFT JOIN careconnect.departament d ON pm.id_departament = d.id_departament;

-- view personal asistent
CREATE OR REPLACE VIEW careconnect.v_personal_asistent AS
SELECT 
    pm.id_personal,
    pm.nume,
    pm.prenume,
    pm.rol,
    pm.grad_acces,
    d.nume_departament,
    pm.telefon,
    pm.email
FROM careconnect.personal_medical pm
LEFT JOIN careconnect.departament d ON pm.id_departament = d.id_departament;

-- view personal medic
CREATE OR REPLACE VIEW careconnect.v_personal_medic AS
SELECT 
    pm.id_personal,
    pm.nume,
    pm.prenume,
    pm.cnp,
    pm.rol,
    pm.grad_acces,
    d.nume_departament,
    pm.telefon,
    pm.email,
    pm.data_angajare
FROM careconnect.personal_medical pm
LEFT JOIN careconnect.departament d ON pm.id_departament = d.id_departament;

-- view personal admin
CREATE OR REPLACE VIEW careconnect.v_personal_admin AS
SELECT 
    pm.id_personal,
    pm.nume,
    pm.prenume,
    pm.cnp,
    pm.rol,
    pm.grad_acces,
    d.nume_departament,
    pm.telefon,
    pm.email,
    pm.data_angajare,
    pm.username_db
FROM careconnect.personal_medical pm
LEFT JOIN careconnect.departament d ON pm.id_departament = d.id_departament;

-- view audit complet
CREATE OR REPLACE VIEW careconnect.v_audit_all AS
SELECT 
    audit_id,
    audit_type,
    username,
    action_type,
    table_name,
    record_id,
    action_timestamp,
    ip_address,
    os_user,
    details
FROM careconnect.audit_log
ORDER BY action_timestamp DESC;

-- grants pe functii de mascare
GRANT EXECUTE ON careconnect.mask_telefon TO PUBLIC;
GRANT EXECUTE ON careconnect.mask_email TO PUBLIC;
GRANT EXECUTE ON careconnect.mask_adresa TO PUBLIC;
GRANT EXECUTE ON careconnect.mask_cnp_partial TO PUBLIC;
GRANT EXECUTE ON careconnect.decrypt_and_mask_cnp TO PUBLIC;

COMMIT;
