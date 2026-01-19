ALTER SESSION SET CONTAINER = XEPDB1;

GRANT CREATE TABLE TO careconnect;
GRANT CREATE SEQUENCE TO careconnect;
GRANT CREATE TRIGGER TO careconnect;
GRANT CREATE VIEW TO careconnect;
GRANT CREATE PROCEDURE TO careconnect;
GRANT UNLIMITED TABLESPACE TO careconnect;

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
    grad_acces NUMBER(1) DEFAULT 1 CHECK (grad_acces IN (1, 2, 3)),
    id_departament NUMBER(10) REFERENCES careconnect.departament(id_departament),
    data_angajare DATE DEFAULT SYSDATE,
    username_db VARCHAR2(30)
);

CREATE TABLE careconnect.pacient (
    id_pacient NUMBER(10) PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    cnp VARCHAR2(13) NOT NULL UNIQUE,
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

-- Departamente
INSERT INTO careconnect.departament VALUES (careconnect.seq_departament.NEXTVAL, 'Cardiologie', 'Etaj 2, Aripa A', '0212345001');
INSERT INTO careconnect.departament VALUES (careconnect.seq_departament.NEXTVAL, 'Neurologie', 'Etaj 3, Aripa B', '0212345002');
INSERT INTO careconnect.departament VALUES (careconnect.seq_departament.NEXTVAL, 'Pediatrie', 'Etaj 1, Aripa C', '0212345003');

-- Personal Medical
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Popescu', 'Ana', '2850115123456', 'ana.popescu@careconnect.ro', '0721000001', 'MEDIC', 3, 1, 'ANA_POPESCU');
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Ionescu', 'Mihai', '1900220234567', 'mihai.ionescu@careconnect.ro', '0721000002', 'ASISTENT', 2, 1, 'MIHAI_IONESCU');
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Marinescu', 'Elena', '2880330345678', 'elena.marinescu@careconnect.ro', '0721000003', 'RECEPTIE', 1, 2, 'ELENA_MARINESCU');
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Admin', 'System', '1800101000001', 'admin@careconnect.ro', '0721000000', 'ADMIN', 3, 1, 'ADMIN_SYSTEM');

-- Pacienti
INSERT INTO careconnect.pacient (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina) VALUES (careconnect.seq_pacient.NEXTVAL, 'Georgescu', 'Ion', '1850415123456', DATE '1985-04-15', 'M', '0731000001', 'ion.g@email.com', 'Str. Victoriei 10, Bucuresti', 'A+');
INSERT INTO careconnect.pacient (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina) VALUES (careconnect.seq_pacient.NEXTVAL, 'Vasilescu', 'Maria', '2900520234567', DATE '1990-05-20', 'F', '0731000002', 'maria.v@email.com', 'Bd. Unirii 25, Cluj-Napoca', 'B-');
INSERT INTO careconnect.pacient (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina) VALUES (careconnect.seq_pacient.NEXTVAL, 'Dumitrescu', 'Andrei', '1950630345678', DATE '1995-06-30', 'M', '0731000003', 'andrei.d@email.com', 'Str. Republicii 5, Timisoara', 'O+');

-- Fise Medicale
INSERT INTO careconnect.fisa_medicala (id_fisa, id_pacient, id_medic, diagnostic, tratament, nivel_confidentialitate) VALUES (careconnect.seq_fisa.NEXTVAL, 1, 1, 'Hipertensiune arteriala esentiala', 'Lisinopril 10mg zilnic', 1);
INSERT INTO careconnect.fisa_medicala (id_fisa, id_pacient, id_medic, diagnostic, tratament, nivel_confidentialitate) VALUES (careconnect.seq_fisa.NEXTVAL, 2, 1, 'Anxietate generalizata', 'Alprazolam 0.5mg - tratament psihiatric', 2);
INSERT INTO careconnect.fisa_medicala (id_fisa, id_pacient, id_medic, diagnostic, tratament, nivel_confidentialitate) VALUES (careconnect.seq_fisa.NEXTVAL, 3, 1, 'HIV pozitiv - monitorizare', 'Terapie antiretrovirala - CONFIDENTIAL', 3);

COMMIT;
