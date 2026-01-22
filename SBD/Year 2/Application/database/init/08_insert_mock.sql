ALTER SESSION SET CONTAINER = XEPDB1;

-- Cheie random de criptare
INSERT INTO careconnect.encryption_keys (key_id, key_name, key_value, algorithm)
VALUES (1, 'CNP_KEY', DBMS_CRYPTO.RANDOMBYTES(32), 'AES256');

-- Departamente
INSERT INTO careconnect.departament VALUES (careconnect.seq_departament.NEXTVAL, 'Cardiologie', 'Etaj 2, Aripa A', '0212345001');
INSERT INTO careconnect.departament VALUES (careconnect.seq_departament.NEXTVAL, 'Neurologie', 'Etaj 3, Aripa B', '0212345002');
INSERT INTO careconnect.departament VALUES (careconnect.seq_departament.NEXTVAL, 'Pediatrie', 'Etaj 1, Aripa C', '0212345003');

-- ANA_POPESCU - MEDIC (grad 3)
CREATE USER ANA_POPESCU IDENTIFIED BY "Medic2026!";
GRANT CREATE SESSION TO ANA_POPESCU;
GRANT ROL_MEDIC TO ANA_POPESCU;

-- MIHAI_IONESCU - ASISTENT (grad 2)
CREATE USER MIHAI_IONESCU IDENTIFIED BY "Asistent2026!";
GRANT CREATE SESSION TO MIHAI_IONESCU;
GRANT ROL_ASISTENT TO MIHAI_IONESCU;

-- ELENA_MARINESCU - RECEPTIE (grad 1)
CREATE USER ELENA_MARINESCU IDENTIFIED BY "Receptie2026!";
GRANT CREATE SESSION TO ELENA_MARINESCU;
GRANT ROL_RECEPTIE TO ELENA_MARINESCU;

-- ADMIN_SYSTEM - ADMIN (grad 4)
CREATE USER ADMIN_SYSTEM IDENTIFIED BY "Admin2026!";
GRANT CREATE SESSION TO ADMIN_SYSTEM;
GRANT ROL_ADMIN TO ADMIN_SYSTEM;

-- personal medical
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Popescu', 'Ana', '2850115123456', 'ana.popescu@careconnect.ro', '0721000001', 'MEDIC', 3, 1, 'ANA_POPESCU');
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Ionescu', 'Mihai', '1900220234567', 'mihai.ionescu@careconnect.ro', '0721000002', 'ASISTENT', 2, 1, 'MIHAI_IONESCU');
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Marinescu', 'Elena', '2880330345678', 'elena.marinescu@careconnect.ro', '0721000003', 'RECEPTIE', 1, 2, 'ELENA_MARINESCU');
INSERT INTO careconnect.personal_medical (id_personal, nume, prenume, cnp, email, telefon, rol, grad_acces, id_departament, username_db) VALUES (careconnect.seq_personal.NEXTVAL, 'Admin', 'System', '1800101000001', 'admin@careconnect.ro', '0721000000', 'ADMIN', 4, 1, 'ADMIN_SYSTEM');

-- Pacienti 
INSERT INTO careconnect.pacient (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina) VALUES (careconnect.seq_pacient.NEXTVAL, 'Georgescu', 'Ion', careconnect.encrypt_cnp('1850415123456'), DATE '1985-04-15', 'M', '0731000001', 'ion.g@email.com', 'Str. Victoriei 10, Bucuresti', 'A+');
INSERT INTO careconnect.pacient (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina) VALUES (careconnect.seq_pacient.NEXTVAL, 'Vasilescu', 'Maria', careconnect.encrypt_cnp('2900520234567'), DATE '1990-05-20', 'F', '0731000002', 'maria.v@email.com', 'Bd. Unirii 25, Cluj-Napoca', 'B-');
INSERT INTO careconnect.pacient (id_pacient, nume, prenume, cnp, data_nasterii, sex, telefon, email, adresa, grupa_sanguina) VALUES (careconnect.seq_pacient.NEXTVAL, 'Dumitrescu', 'Andrei', careconnect.encrypt_cnp('1950630345678'), DATE '1995-06-30', 'M', '0731000003', 'andrei.d@email.com', 'Str. Republicii 5, Timisoara', 'O+');

-- Fise Medicale
INSERT INTO careconnect.fisa_medicala (id_fisa, id_pacient, id_medic, diagnostic, tratament, nivel_confidentialitate) VALUES (careconnect.seq_fisa.NEXTVAL, 1, 1, 'Hipertensiune arteriala esentiala', 'Lisinopril 10mg zilnic', 1);
INSERT INTO careconnect.fisa_medicala (id_fisa, id_pacient, id_medic, diagnostic, tratament, nivel_confidentialitate) VALUES (careconnect.seq_fisa.NEXTVAL, 2, 1, 'Anxietate generalizata', 'Alprazolam 0.5mg - tratament psihiatric', 2);
INSERT INTO careconnect.fisa_medicala (id_fisa, id_pacient, id_medic, diagnostic, tratament, nivel_confidentialitate) VALUES (careconnect.seq_fisa.NEXTVAL, 3, 1, 'HIV pozitiv - monitorizare', 'Terapie antiretrovirala - CONFIDENTIAL', 3);

COMMIT;
