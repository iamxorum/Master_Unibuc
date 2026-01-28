ALTER SESSION SET CONTAINER = XEPDB1;

-- Tip pentru lista de pacienți
CREATE OR REPLACE TYPE careconnect.t_pacient_row AS OBJECT (
    id_pacient      NUMBER,
    nume            VARCHAR2(50),
    prenume         VARCHAR2(50),
    cnp_display     VARCHAR2(50),
    data_nasterii   DATE,
    sex             CHAR(1),
    telefon         VARCHAR2(20),
    email           VARCHAR2(100),
    adresa          VARCHAR2(200),
    grupa_sanguina  VARCHAR2(5)
);
/

CREATE OR REPLACE TYPE careconnect.t_pacient_table AS TABLE OF careconnect.t_pacient_row;
/

-- Tip pentru fișe medicale
CREATE OR REPLACE TYPE careconnect.t_fisa_row AS OBJECT (
    id_fisa                 NUMBER,
    pacient_nume            VARCHAR2(100),
    medic_nume              VARCHAR2(100),
    data_consultatie        DATE,
    diagnostic              VARCHAR2(500),
    tratament               VARCHAR2(500),
    observatii              VARCHAR2(500),
    nivel_confidentialitate NUMBER,
    nr_modificari           NUMBER
);
/

CREATE OR REPLACE TYPE careconnect.t_fisa_table AS TABLE OF careconnect.t_fisa_row;
/

-- Tip pentru personal medical
CREATE OR REPLACE TYPE careconnect.t_personal_row AS OBJECT (
    id_personal       NUMBER,
    nume              VARCHAR2(50),
    prenume           VARCHAR2(50),
    rol               VARCHAR2(30),
    grad_acces        NUMBER,
    nume_departament  VARCHAR2(50),
    telefon           VARCHAR2(20),
    email             VARCHAR2(100),
    data_angajare     DATE,
    username_db       VARCHAR2(30)
);
/

CREATE OR REPLACE TYPE careconnect.t_personal_table AS TABLE OF careconnect.t_personal_row;
/

-- Tip pentru audit log
CREATE OR REPLACE TYPE careconnect.t_audit_row AS OBJECT (
    audit_type        VARCHAR2(20),
    username          VARCHAR2(50),
    action_type       VARCHAR2(20),
    table_name        VARCHAR2(50),
    action_timestamp  TIMESTAMP,
    ip_address        VARCHAR2(50),
    details           VARCHAR2(500)
);
/

CREATE OR REPLACE TYPE careconnect.t_audit_table AS TABLE OF careconnect.t_audit_row;
/

-- Tip pentru statistici audit
CREATE OR REPLACE TYPE careconnect.t_audit_stat_row AS OBJECT (
    audit_type  VARCHAR2(20),
    total_count NUMBER
);
/

CREATE OR REPLACE TYPE careconnect.t_audit_stat_table AS TABLE OF careconnect.t_audit_stat_row;
/

-- functie pentru a obtine gradul de acces al utilizatorului curent
CREATE OR REPLACE FUNCTION careconnect.get_grad_acces
RETURN NUMBER
IS
    v_grad NUMBER;
BEGIN
    v_grad := TO_NUMBER(SYS_CONTEXT('CARECONNECT_CTX', 'GRAD_ACCES'));
    RETURN NVL(v_grad, 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END get_grad_acces;
/


-- functie pentru a obtine lista pacienților conform gradului de acces
CREATE OR REPLACE FUNCTION careconnect.get_pacienti
RETURN careconnect.t_pacient_table PIPELINED
IS
    v_grad_acces NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces >= 4 THEN
        FOR rec IN (
            SELECT id_pacient, nume, prenume, '[CRIPTAT]' AS cnp_display,
                   data_nasterii, sex, telefon, email, adresa, grupa_sanguina
            FROM careconnect.v_pacienti_admin
        ) LOOP
            PIPE ROW(careconnect.t_pacient_row(
                rec.id_pacient, rec.nume, rec.prenume, rec.cnp_display,
                rec.data_nasterii, rec.sex, rec.telefon, rec.email, 
                rec.adresa, rec.grupa_sanguina
            ));
        END LOOP;
    ELSIF v_grad_acces >= 3 THEN
        FOR rec IN (
            SELECT id_pacient, nume, prenume, cnp_partial AS cnp_display,
                   data_nasterii, sex, telefon, email, adresa, grupa_sanguina
            FROM careconnect.v_pacienti_medic
        ) LOOP
            PIPE ROW(careconnect.t_pacient_row(
                rec.id_pacient, rec.nume, rec.prenume, rec.cnp_display,
                rec.data_nasterii, rec.sex, rec.telefon, rec.email, 
                rec.adresa, rec.grupa_sanguina
            ));
        END LOOP;
    ELSIF v_grad_acces >= 2 THEN
        FOR rec IN (
            SELECT id_pacient, nume, prenume, cnp_status AS cnp_display,
                   data_nasterii, sex, telefon, email, adresa, grupa_sanguina
            FROM careconnect.v_pacienti_asistent
        ) LOOP
            PIPE ROW(careconnect.t_pacient_row(
                rec.id_pacient, rec.nume, rec.prenume, rec.cnp_display,
                rec.data_nasterii, rec.sex, rec.telefon, rec.email, 
                rec.adresa, rec.grupa_sanguina
            ));
        END LOOP;
    ELSE
        FOR rec IN (
            SELECT id_pacient, nume, prenume, cnp_status AS cnp_display,
                   data_nasterii, sex, telefon, email, adresa, grupa_sanguina
            FROM careconnect.v_pacienti_receptie
        ) LOOP
            PIPE ROW(careconnect.t_pacient_row(
                rec.id_pacient, rec.nume, rec.prenume, rec.cnp_display,
                rec.data_nasterii, rec.sex, rec.telefon, rec.email, 
                rec.adresa, rec.grupa_sanguina
            ));
        END LOOP;
    END IF;
    
    RETURN;
END get_pacienti;
/


-- functie pentru a obtine fișele medicale conform gradului de acces
CREATE OR REPLACE FUNCTION careconnect.get_fise_medicale
RETURN careconnect.t_fisa_table PIPELINED
IS
    v_grad_acces NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces >= 4 THEN
        FOR rec IN (
            SELECT id_fisa, pacient_nume, medic_nume, data_consultatie,
                   diagnostic, tratament, observatii, nivel_confidentialitate, nr_modificari
            FROM careconnect.v_fise_admin
            ORDER BY data_consultatie DESC
        ) LOOP
            PIPE ROW(careconnect.t_fisa_row(
                rec.id_fisa, rec.pacient_nume, rec.medic_nume, rec.data_consultatie,
                rec.diagnostic, rec.tratament, rec.observatii, 
                rec.nivel_confidentialitate, rec.nr_modificari
            ));
        END LOOP;
    ELSIF v_grad_acces >= 3 THEN
        FOR rec IN (
            SELECT id_fisa, pacient_nume, medic_nume, data_consultatie,
                   diagnostic, tratament, observatii, nivel_confidentialitate
            FROM careconnect.v_fise_medic
            ORDER BY data_consultatie DESC
        ) LOOP
            PIPE ROW(careconnect.t_fisa_row(
                rec.id_fisa, rec.pacient_nume, rec.medic_nume, rec.data_consultatie,
                rec.diagnostic, rec.tratament, rec.observatii, 
                rec.nivel_confidentialitate, NULL
            ));
        END LOOP;
    ELSIF v_grad_acces >= 2 THEN
        FOR rec IN (
            SELECT id_fisa, pacient_nume, medic_nume, data_consultatie,
                   diagnostic, tratament, nivel_confidentialitate
            FROM careconnect.v_fise_asistent
            ORDER BY data_consultatie DESC
        ) LOOP
            PIPE ROW(careconnect.t_fisa_row(
                rec.id_fisa, rec.pacient_nume, rec.medic_nume, rec.data_consultatie,
                rec.diagnostic, rec.tratament, NULL, 
                rec.nivel_confidentialitate, NULL
            ));
        END LOOP;
    ELSE
        FOR rec IN (
            SELECT id_fisa, pacient_nume, medic_nume, data_consultatie,
                   diagnostic, tratament, nivel_confidentialitate
            FROM careconnect.v_fise_receptie
            ORDER BY data_consultatie DESC
        ) LOOP
            PIPE ROW(careconnect.t_fisa_row(
                rec.id_fisa, rec.pacient_nume, rec.medic_nume, rec.data_consultatie,
                rec.diagnostic, rec.tratament, NULL, 
                rec.nivel_confidentialitate, NULL
            ));
        END LOOP;
    END IF;
    
    RETURN;
END get_fise_medicale;
/


-- functie pentru a obtine personalul medical conform gradului de acces
CREATE OR REPLACE FUNCTION careconnect.get_personal
RETURN careconnect.t_personal_table PIPELINED
IS
    v_grad_acces NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces >= 4 THEN
        FOR rec IN (
            SELECT id_personal, nume, prenume, rol, grad_acces, 
                   nume_departament, telefon, email, data_angajare, username_db
            FROM careconnect.v_personal_admin
            WHERE grad_acces <= v_grad_acces
            ORDER BY grad_acces DESC, nume
        ) LOOP
            PIPE ROW(careconnect.t_personal_row(
                rec.id_personal, rec.nume, rec.prenume, rec.rol, rec.grad_acces,
                rec.nume_departament, rec.telefon, rec.email, rec.data_angajare, rec.username_db
            ));
        END LOOP;
    ELSIF v_grad_acces >= 3 THEN
        FOR rec IN (
            SELECT id_personal, nume, prenume, rol, grad_acces, 
                   nume_departament, telefon, email, data_angajare
            FROM careconnect.v_personal_medic
            WHERE grad_acces <= v_grad_acces
            ORDER BY grad_acces DESC, nume
        ) LOOP
            PIPE ROW(careconnect.t_personal_row(
                rec.id_personal, rec.nume, rec.prenume, rec.rol, rec.grad_acces,
                rec.nume_departament, rec.telefon, rec.email, rec.data_angajare, NULL
            ));
        END LOOP;
    ELSIF v_grad_acces >= 2 THEN
        FOR rec IN (
            SELECT id_personal, nume, prenume, rol, grad_acces, 
                   nume_departament, telefon, email
            FROM careconnect.v_personal_asistent
            WHERE grad_acces <= v_grad_acces
            ORDER BY grad_acces DESC, nume
        ) LOOP
            PIPE ROW(careconnect.t_personal_row(
                rec.id_personal, rec.nume, rec.prenume, rec.rol, rec.grad_acces,
                rec.nume_departament, rec.telefon, rec.email, NULL, NULL
            ));
        END LOOP;
    ELSE
        FOR rec IN (
            SELECT id_personal, nume, prenume, rol, grad_acces, nume_departament, telefon, email
            FROM careconnect.v_personal_receptie
            WHERE grad_acces <= v_grad_acces
            ORDER BY nume
        ) LOOP
            PIPE ROW(careconnect.t_personal_row(
                rec.id_personal, rec.nume, rec.prenume, rec.rol, rec.grad_acces,
                rec.nume_departament, rec.telefon, rec.email, NULL, NULL
            ));
        END LOOP;
    END IF;
    
    RETURN;
END get_personal;
/


-- functie pentru a obtine ultimele N intrări din audit
CREATE OR REPLACE FUNCTION careconnect.get_audit_log(p_limit IN NUMBER DEFAULT 20)
RETURN careconnect.t_audit_table PIPELINED
IS
    v_grad_acces NUMBER;
    v_count      NUMBER := 0;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 4 THEN
        RETURN;
    END IF;
    
    FOR rec IN (
        SELECT audit_type, username, action_type, table_name,
               action_timestamp, ip_address, details
        FROM careconnect.v_audit_all
        ORDER BY action_timestamp DESC
    ) LOOP
        EXIT WHEN v_count >= p_limit;
        
        PIPE ROW(careconnect.t_audit_row(
            rec.audit_type, rec.username, rec.action_type, rec.table_name,
            rec.action_timestamp, rec.ip_address, rec.details
        ));
        
        v_count := v_count + 1;
    END LOOP;
    
    RETURN;
END get_audit_log;
/


-- functie pentru a obtine statisticile audit
CREATE OR REPLACE FUNCTION careconnect.get_audit_stats
RETURN careconnect.t_audit_stat_table PIPELINED
IS
    v_grad_acces NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 4 THEN
        RETURN;
    END IF;
    
    FOR rec IN (
        SELECT audit_type, COUNT(*) AS total_count
        FROM careconnect.v_audit_all
        GROUP BY audit_type
    ) LOOP
        PIPE ROW(careconnect.t_audit_stat_row(rec.audit_type, rec.total_count));
    END LOOP;
    
    RETURN;
END get_audit_stats;
/


-- functie pentru a decripta CNP-ul pentru un pacient
CREATE OR REPLACE FUNCTION careconnect.get_pacient_cnp_decriptat(p_id_pacient IN NUMBER)
RETURN VARCHAR2
IS
    v_grad_acces NUMBER;
    v_cnp_decriptat VARCHAR2(20);
    v_nume VARCHAR2(50);
    v_prenume VARCHAR2(50);
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 3 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Nu ai permisiunea să decriptezi CNP-uri!');
    END IF;
    
    SELECT nume, prenume, careconnect.decrypt_cnp_audited(cnp, p_id_pacient)
    INTO v_nume, v_prenume, v_cnp_decriptat
    FROM careconnect.pacient
    WHERE id_pacient = p_id_pacient;
    
    RETURN v_cnp_decriptat;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'Pacient negăsit!');
END get_pacient_cnp_decriptat;
/


-- functie pentru a obtine info pacient pentru decriptare
CREATE OR REPLACE FUNCTION careconnect.get_pacient_info(p_id_pacient IN NUMBER)
RETURN VARCHAR2
IS
    v_result VARCHAR2(200);
BEGIN
    SELECT nume || ' ' || prenume
    INTO v_result
    FROM careconnect.pacient
    WHERE id_pacient = p_id_pacient;
    
    RETURN v_result;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_pacient_info;
/


-- procedura pentru a adauga o fișă medicală nouă
CREATE OR REPLACE PROCEDURE careconnect.add_fisa_medicala(
    p_id_pacient            IN NUMBER,
    p_diagnostic            IN VARCHAR2,
    p_tratament             IN VARCHAR2 DEFAULT NULL,
    p_observatii            IN VARCHAR2 DEFAULT NULL,
    p_nivel_confidentialitate IN NUMBER DEFAULT 1,
    p_id_fisa               OUT NUMBER
)
IS
    v_grad_acces NUMBER;
    v_id_medic   NUMBER;
    v_nivel      NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 3 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Doar medicii și adminii pot adăuga fișe medicale!');
    END IF;
    
    SELECT id_personal INTO v_id_medic
    FROM careconnect.personal_medical
    WHERE UPPER(username_db) = SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    v_nivel := CASE 
        WHEN p_nivel_confidentialitate BETWEEN 1 AND 3 THEN p_nivel_confidentialitate
        ELSE 1
    END;
    
    INSERT INTO careconnect.fisa_medicala 
    (id_fisa, id_pacient, id_medic, diagnostic, tratament, observatii, nivel_confidentialitate)
    VALUES (careconnect.seq_fisa.NEXTVAL, p_id_pacient, v_id_medic, p_diagnostic, p_tratament, p_observatii, v_nivel)
    RETURNING id_fisa INTO p_id_fisa;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20021, 'Nu s-a găsit înregistrarea ta în personal_medical!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END add_fisa_medicala;
/


-- procedura pentru a modifica o fișă medicală existentă
CREATE OR REPLACE PROCEDURE careconnect.update_fisa_medicala(
    p_id_fisa               IN NUMBER,
    p_diagnostic            IN VARCHAR2 DEFAULT NULL,
    p_tratament             IN VARCHAR2 DEFAULT NULL,
    p_observatii            IN VARCHAR2 DEFAULT NULL,
    p_nivel_confidentialitate IN NUMBER DEFAULT NULL
)
IS
    v_grad_acces NUMBER;
    v_id_medic_fisa NUMBER;
    v_id_medic_curent NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 3 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Doar medicii și adminii pot modifica fișe medicale!');
    END IF;
    
    SELECT id_medic INTO v_id_medic_fisa
    FROM careconnect.fisa_medicala
    WHERE id_fisa = p_id_fisa;
    
    SELECT id_personal INTO v_id_medic_curent
    FROM careconnect.personal_medical
    WHERE UPPER(username_db) = SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    IF v_grad_acces < 4 AND v_id_medic_fisa != v_id_medic_curent THEN
        RAISE_APPLICATION_ERROR(-20031, 'Poți modifica doar fișele create de tine!');
    END IF;
    
    UPDATE careconnect.fisa_medicala
    SET diagnostic = NVL(p_diagnostic, diagnostic),
        tratament = NVL(p_tratament, tratament),
        observatii = NVL(p_observatii, observatii),
        nivel_confidentialitate = NVL(p_nivel_confidentialitate, nivel_confidentialitate)
    WHERE id_fisa = p_id_fisa;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20032, 'Fișă medicală negăsită!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_fisa_medicala;
/


-- procedura pentru a sterge o fișă medicală
CREATE OR REPLACE PROCEDURE careconnect.delete_fisa_medicala(p_id_fisa IN NUMBER)
IS
    v_grad_acces NUMBER;
    v_id_medic_fisa NUMBER;
    v_id_medic_curent NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 3 THEN
        RAISE_APPLICATION_ERROR(-20033, 'Doar medicii și adminii pot șterge fișe medicale!');
    END IF;
    
    SELECT id_medic INTO v_id_medic_fisa
    FROM careconnect.fisa_medicala
    WHERE id_fisa = p_id_fisa;
    
    SELECT id_personal INTO v_id_medic_curent
    FROM careconnect.personal_medical
    WHERE UPPER(username_db) = SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    IF v_grad_acces < 4 AND v_id_medic_fisa != v_id_medic_curent THEN
        RAISE_APPLICATION_ERROR(-20034, 'Poți șterge doar fișele create de tine!');
    END IF;
    
    DELETE FROM careconnect.fisa_medicala WHERE id_fisa = p_id_fisa;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20035, 'Fișă medicală negăsită!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END delete_fisa_medicala;
/


-- procedura pentru a adauga un pacient nou
CREATE OR REPLACE PROCEDURE careconnect.add_pacient(
    p_nume            IN VARCHAR2,
    p_prenume         IN VARCHAR2,
    p_cnp             IN VARCHAR2,
    p_data_nasterii   IN DATE DEFAULT NULL,
    p_sex             IN CHAR DEFAULT NULL,
    p_telefon         IN VARCHAR2 DEFAULT NULL,
    p_email           IN VARCHAR2 DEFAULT NULL,
    p_adresa          IN VARCHAR2 DEFAULT NULL,
    p_grupa_sanguina  IN VARCHAR2 DEFAULT NULL,
    p_id_pacient      OUT NUMBER
)
IS
    v_grad_acces NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 1 THEN
        RAISE_APPLICATION_ERROR(-20040, 'Nu ai permisiunea să adaugi pacienți!');
    END IF;
    
    INSERT INTO careconnect.pacient 
    (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina)
    VALUES (
        careconnect.seq_pacient.NEXTVAL, 
        p_nume, 
        p_prenume, 
        careconnect.encrypt_cnp(p_cnp),
        p_data_nasterii, 
        p_sex, 
        p_telefon, 
        p_email, 
        p_adresa, 
        p_grupa_sanguina
    )
    RETURNING id_pacient INTO p_id_pacient;
    
    COMMIT;
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20041, 'CNP-ul există deja în sistem!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END add_pacient;
/


-- procedura pentru a modifica datele unui pacient
CREATE OR REPLACE PROCEDURE careconnect.update_pacient(
    p_id_pacient      IN NUMBER,
    p_nume            IN VARCHAR2 DEFAULT NULL,
    p_prenume         IN VARCHAR2 DEFAULT NULL,
    p_cnp             IN VARCHAR2 DEFAULT NULL,
    p_data_nasterii   IN DATE DEFAULT NULL,
    p_sex             IN CHAR DEFAULT NULL,
    p_telefon         IN VARCHAR2 DEFAULT NULL,
    p_email           IN VARCHAR2 DEFAULT NULL,
    p_adresa          IN VARCHAR2 DEFAULT NULL,
    p_grupa_sanguina  IN VARCHAR2 DEFAULT NULL
)
IS
    v_grad_acces NUMBER;
    v_exists NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 2 THEN
        RAISE_APPLICATION_ERROR(-20042, 'Nu ai permisiunea să modifici pacienți!');
    END IF;
    
    SELECT COUNT(*) INTO v_exists
    FROM careconnect.pacient
    WHERE id_pacient = p_id_pacient;
    
    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20043, 'Pacient negăsit!');
    END IF;
    
    UPDATE careconnect.pacient
    SET nume = NVL(p_nume, nume),
        prenume = NVL(p_prenume, prenume),
        cnp = CASE WHEN p_cnp IS NOT NULL THEN careconnect.encrypt_cnp(p_cnp) ELSE cnp END,
        data_nasterii = NVL(p_data_nasterii, data_nasterii),
        sex = NVL(p_sex, sex),
        telefon = NVL(p_telefon, telefon),
        email = NVL(p_email, email),
        adresa = NVL(p_adresa, adresa),
        grupa_sanguina = NVL(p_grupa_sanguina, grupa_sanguina)
    WHERE id_pacient = p_id_pacient;
    
    COMMIT;
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20044, 'CNP-ul există deja în sistem!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_pacient;
/


-- procedura pentru a sterge un pacient
CREATE OR REPLACE PROCEDURE careconnect.delete_pacient(p_id_pacient IN NUMBER)
IS
    v_grad_acces NUMBER;
    v_fise_count NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 4 THEN
        RAISE_APPLICATION_ERROR(-20045, 'Doar administratorii pot șterge pacienți!');
    END IF;
    
    SELECT COUNT(*) INTO v_fise_count
    FROM careconnect.fisa_medicala
    WHERE id_pacient = p_id_pacient;
    
    IF v_fise_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20046, 'Nu poți șterge un pacient cu fișe medicale! Șterge mai întâi fișele.');
    END IF;
    
    DELETE FROM careconnect.pacient WHERE id_pacient = p_id_pacient;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20047, 'Pacient negăsit!');
    END IF;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END delete_pacient;
/


-- procedura pentru a adauga un personal medical nou
CREATE OR REPLACE PROCEDURE careconnect.add_personal(
    p_nume            IN VARCHAR2,
    p_prenume         IN VARCHAR2,
    p_cnp             IN VARCHAR2,
    p_rol             IN VARCHAR2,
    p_grad_acces      IN NUMBER,
    p_id_departament  IN NUMBER DEFAULT NULL,
    p_telefon         IN VARCHAR2 DEFAULT NULL,
    p_email           IN VARCHAR2 DEFAULT NULL,
    p_username_db     IN VARCHAR2,
    p_password        IN VARCHAR2,
    p_id_personal     OUT NUMBER
)
IS
    v_grad_acces NUMBER;
    v_role_name  VARCHAR2(30);
    v_sql        VARCHAR2(500);
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 4 THEN
        RAISE_APPLICATION_ERROR(-20050, 'Doar administratorii pot adăuga personal medical!');
    END IF;
    
    IF p_username_db IS NULL OR p_password IS NULL THEN
        RAISE_APPLICATION_ERROR(-20059, 'Username și parola sunt obligatorii!');
    END IF;
    
    IF LENGTH(p_password) < 8 THEN
        RAISE_APPLICATION_ERROR(-20060, 'Parola trebuie să aibă minim 8 caractere!');
    END IF;
    
    v_sql := 'CREATE USER ' || p_username_db || ' IDENTIFIED BY "' || p_password || '"';
    EXECUTE IMMEDIATE v_sql;
    
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ' || p_username_db;
    
    v_role_name := CASE p_grad_acces
        WHEN 1 THEN 'ROL_RECEPTIE'
        WHEN 2 THEN 'ROL_ASISTENT'
        WHEN 3 THEN 'ROL_MEDIC'
        WHEN 4 THEN 'ROL_ADMIN'
        ELSE 'ROL_RECEPTIE'
    END;
    
    EXECUTE IMMEDIATE 'GRANT ' || v_role_name || ' TO ' || p_username_db;
    
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name, details
    ) VALUES (
        'GRANT',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        'CREATE_USER',
        'DBA_USERS',
        'User creat: ' || UPPER(p_username_db) || ', Rol: ' || v_role_name || ', Grad: ' || p_grad_acces
    );
    
    INSERT INTO careconnect.personal_medical 
    (id_personal, nume, prenume, cnp, rol, grad_acces, id_departament, telefon, email, username_db)
    VALUES (
        careconnect.seq_personal.NEXTVAL,
        p_nume,
        p_prenume,
        p_cnp,
        p_rol,
        p_grad_acces,
        p_id_departament,
        p_telefon,
        p_email,
        UPPER(p_username_db)
    )
    RETURNING id_personal INTO p_id_personal;
    
    COMMIT;
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        BEGIN
            EXECUTE IMMEDIATE 'DROP USER ' || p_username_db || ' CASCADE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        RAISE_APPLICATION_ERROR(-20051, 'CNP-ul sau username-ul există deja!');
    WHEN OTHERS THEN
        BEGIN
            EXECUTE IMMEDIATE 'DROP USER ' || p_username_db || ' CASCADE';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        ROLLBACK;
        RAISE;
END add_personal;
/


-- procedura pentru a modifica datele unui personal medical
CREATE OR REPLACE PROCEDURE careconnect.update_personal(
    p_id_personal     IN NUMBER,
    p_nume            IN VARCHAR2 DEFAULT NULL,
    p_prenume         IN VARCHAR2 DEFAULT NULL,
    p_cnp             IN VARCHAR2 DEFAULT NULL,
    p_rol             IN VARCHAR2 DEFAULT NULL,
    p_grad_acces      IN NUMBER DEFAULT NULL,
    p_id_departament  IN NUMBER DEFAULT NULL,
    p_telefon         IN VARCHAR2 DEFAULT NULL,
    p_email           IN VARCHAR2 DEFAULT NULL,
    p_username_db     IN VARCHAR2 DEFAULT NULL
)
IS
    v_grad_acces NUMBER;
    v_exists NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 4 THEN
        RAISE_APPLICATION_ERROR(-20052, 'Doar administratorii pot modifica personal medical!');
    END IF;
    
    SELECT COUNT(*) INTO v_exists
    FROM careconnect.personal_medical
    WHERE id_personal = p_id_personal;
    
    IF v_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20053, 'Personal negăsit!');
    END IF;
    
    UPDATE careconnect.personal_medical
    SET nume = NVL(p_nume, nume),
        prenume = NVL(p_prenume, prenume),
        cnp = NVL(p_cnp, cnp),
        rol = NVL(p_rol, rol),
        grad_acces = NVL(p_grad_acces, grad_acces),
        id_departament = NVL(p_id_departament, id_departament),
        telefon = NVL(p_telefon, telefon),
        email = NVL(p_email, email),
        username_db = NVL(p_username_db, username_db)
    WHERE id_personal = p_id_personal;
    
    COMMIT;
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20054, 'CNP-ul sau username-ul există deja!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END update_personal;
/


-- procedura pentru a sterge un personal medical
CREATE OR REPLACE PROCEDURE careconnect.delete_personal(p_id_personal IN NUMBER)
IS
    v_grad_acces NUMBER;
    v_fise_count NUMBER;
    v_is_current_user NUMBER;
    v_username VARCHAR2(30);
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    IF v_grad_acces < 4 THEN
        RAISE_APPLICATION_ERROR(-20055, 'Doar administratorii pot șterge personal medical!');
    END IF;
    
    SELECT username_db INTO v_username
    FROM careconnect.personal_medical
    WHERE id_personal = p_id_personal;
    
    IF UPPER(v_username) = SYS_CONTEXT('USERENV', 'SESSION_USER') THEN
        RAISE_APPLICATION_ERROR(-20056, 'Nu te poți șterge pe tine însuți!');
    END IF;
    
    SELECT COUNT(*) INTO v_fise_count
    FROM careconnect.fisa_medicala
    WHERE id_medic = p_id_personal;
    
    IF v_fise_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20057, 'Nu poți șterge personal cu fișe medicale create! Reasignează mai întâi fișele.');
    END IF;
    
    DELETE FROM careconnect.personal_medical WHERE id_personal = p_id_personal;
    
    IF v_username IS NOT NULL THEN
        BEGIN
            EXECUTE IMMEDIATE 'DROP USER ' || v_username || ' CASCADE';
        EXCEPTION
            WHEN OTHERS THEN 
                NULL;
        END;
    END IF;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20058, 'Personal negăsit!');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END delete_personal;
/


-- functie pentru a obtine numele rolului
CREATE OR REPLACE FUNCTION careconnect.get_role_name
RETURN VARCHAR2
IS
    v_grad_acces NUMBER;
BEGIN
    v_grad_acces := careconnect.get_grad_acces();
    
    RETURN CASE v_grad_acces
        WHEN 4 THEN 'ADMIN'
        WHEN 3 THEN 'MEDIC'
        WHEN 2 THEN 'ASISTENT'
        WHEN 1 THEN 'RECEPȚIE'
        ELSE 'NECUNOSCUT'
    END;
END get_role_name;
/


-- Grant pe tipuri
GRANT EXECUTE ON careconnect.t_pacient_row TO PUBLIC;
GRANT EXECUTE ON careconnect.t_pacient_table TO PUBLIC;
GRANT EXECUTE ON careconnect.t_fisa_row TO PUBLIC;
GRANT EXECUTE ON careconnect.t_fisa_table TO PUBLIC;
GRANT EXECUTE ON careconnect.t_personal_row TO PUBLIC;
GRANT EXECUTE ON careconnect.t_personal_table TO PUBLIC;
GRANT EXECUTE ON careconnect.t_audit_row TO PUBLIC;
GRANT EXECUTE ON careconnect.t_audit_table TO PUBLIC;
GRANT EXECUTE ON careconnect.t_audit_stat_row TO PUBLIC;
GRANT EXECUTE ON careconnect.t_audit_stat_table TO PUBLIC;

-- Grant pe funcții și proceduri
GRANT EXECUTE ON careconnect.get_grad_acces TO PUBLIC;
GRANT EXECUTE ON careconnect.get_pacienti TO PUBLIC;
GRANT EXECUTE ON careconnect.get_fise_medicale TO PUBLIC;
GRANT EXECUTE ON careconnect.get_personal TO PUBLIC;
GRANT EXECUTE ON careconnect.get_audit_log TO PUBLIC;
GRANT EXECUTE ON careconnect.get_audit_stats TO PUBLIC;
GRANT EXECUTE ON careconnect.get_pacient_cnp_decriptat TO PUBLIC;
GRANT EXECUTE ON careconnect.get_pacient_info TO PUBLIC;
GRANT EXECUTE ON careconnect.get_role_name TO PUBLIC;

-- CRUD Fișe medicale
GRANT EXECUTE ON careconnect.add_fisa_medicala TO PUBLIC;
GRANT EXECUTE ON careconnect.update_fisa_medicala TO PUBLIC;
GRANT EXECUTE ON careconnect.delete_fisa_medicala TO PUBLIC;

-- CRUD Pacienți
GRANT EXECUTE ON careconnect.add_pacient TO PUBLIC;
GRANT EXECUTE ON careconnect.update_pacient TO PUBLIC;
GRANT EXECUTE ON careconnect.delete_pacient TO PUBLIC;

-- CRUD Personal
GRANT EXECUTE ON careconnect.add_personal TO PUBLIC;
GRANT EXECUTE ON careconnect.update_personal TO PUBLIC;
GRANT EXECUTE ON careconnect.delete_personal TO PUBLIC;


COMMIT;
