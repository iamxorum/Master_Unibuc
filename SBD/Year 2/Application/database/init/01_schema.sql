ALTER SESSION SET CONTAINER = XEPDB1;

GRANT CREATE TABLE TO careconnect;
GRANT CREATE SEQUENCE TO careconnect;
GRANT CREATE TRIGGER TO careconnect;
GRANT CREATE VIEW TO careconnect;
GRANT CREATE PROCEDURE TO careconnect;
GRANT UNLIMITED TABLESPACE TO careconnect;
-- grant pentru a putea cripta CNP-ul
GRANT EXECUTE ON DBMS_CRYPTO TO careconnect;

-- grant pentru a putea folosi Row level security
GRANT EXECUTE ON DBMS_RLS TO careconnect;

-- grant pentru a putea folosi FGA (Fine-grained auditing)
GRANT EXECUTE ON DBMS_FGA TO careconnect;

-- grant pentru a putea crea contexturi
GRANT CREATE ANY CONTEXT TO careconnect;

-- grant pentru a putea crea trigger de logare
GRANT ADMINISTER DATABASE TRIGGER TO careconnect;

CREATE TABLE careconnect.departament (
    id_departament NUMBER(10) PRIMARY KEY,
    nume_departament VARCHAR2(100) NOT NULL,
    locatie VARCHAR2(100) NOT NULL,
    telefon_contact VARCHAR2(15) NOT NULL UNIQUE
);

CREATE TABLE careconnect.personal_medical (
    id_personal NUMBER(10) PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    cnp VARCHAR2(13) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL UNIQUE,
    telefon VARCHAR2(15) NOT NULL,
    rol VARCHAR2(20) NOT NULL CHECK (rol IN ('MEDIC', 'ASISTENT', 'ADMIN', 'RECEPTIE')),
    grad_acces NUMBER(1) DEFAULT 1 CHECK (grad_acces IN (0, 1, 2, 3, 4)),
    id_departament NUMBER(10) REFERENCES careconnect.departament(id_departament),
    data_angajare DATE DEFAULT SYSDATE,
    username_db VARCHAR2(30)
);

CREATE TABLE careconnect.pacient (
    id_pacient NUMBER(10) PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    cnp RAW(100) NOT NULL,
    data_nasterii DATE NOT NULL,
    sex CHAR(1) NOT NULL CHECK (sex IN ('M', 'F')),
    telefon VARCHAR2(15) NOT NULL,
    email VARCHAR2(100),
    adresa VARCHAR2(200) NOT NULL,
    grupa_sanguina VARCHAR2(3) CHECK (grupa_sanguina IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    data_inregistrare TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE TABLE careconnect.fisa_medicala (
    id_fisa NUMBER(10) PRIMARY KEY,
    id_pacient NUMBER(10) NOT NULL REFERENCES careconnect.pacient(id_pacient),
    id_medic NUMBER(10) NOT NULL REFERENCES careconnect.personal_medical(id_personal),
    data_consultatie TIMESTAMP DEFAULT SYSTIMESTAMP,
    diagnostic VARCHAR2(500) NOT NULL,
    tratament VARCHAR2(500),
    observatii CLOB,
    nivel_confidentialitate NUMBER(1) DEFAULT 1 CHECK (nivel_confidentialitate IN (1, 2, 3))
);

CREATE SEQUENCE careconnect.seq_departament START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE careconnect.seq_personal START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE careconnect.seq_pacient START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE careconnect.seq_fisa START WITH 1 INCREMENT BY 1;

CREATE TABLE careconnect.encryption_keys (
    key_id          NUMBER(10) PRIMARY KEY,
    key_name        VARCHAR2(50) NOT NULL UNIQUE,
    key_value       RAW(32) NOT NULL,
    algorithm       VARCHAR2(20) DEFAULT 'AES256',
    created_date    TIMESTAMP DEFAULT SYSTIMESTAMP,
    is_active       NUMBER(1) DEFAULT 1
);

COMMIT;
