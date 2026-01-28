ALTER SESSION SET CONTAINER = XEPDB1;

-- ============================================================================
-- PRIVILEGII SI ROLURI
-- ============================================================================
--
-- IERARHIA DE ROLURI:
--   rol_admin (grad_acces=4)
--       └── rol_medic (grad_acces=3)
--              └── rol_asistent (grad_acces=2)
--                      └── rol_receptie (grad_acces=1)
--
-- Fiecare rol moștenește privilegiile rolului inferior.
-- Privilegiile sunt INCREMENTALE - adăugăm doar ce e NOU la fiecare nivel.
--
-- ============================================================================
-- MATRICE FINALĂ DE PRIVILEGII:
-- ============================================================================
--
-- +-------------------+----------+----------+-------+-------+
-- | Obiect            | RECEPTIE | ASISTENT | MEDIC | ADMIN |
-- +-------------------+----------+----------+-------+-------+
-- | departament       |    R     |    R     |   R   | CRUD  |
-- | personal_medical  |    R     |    R     |   R   | CRUD  |
-- | pacient           |   CR     |   CR     |  CRU  | CRUD  |
-- | fisa_medicala     | R(VPD=1) | R(VPD≤2) |  CRU  | CRUD  |
-- | encryption_keys   |    -     |    -     |   R   | CRUD  |
-- | audit_log         |    -     |    -     |   -   |   R   |
-- +-------------------+----------+----------+-------+-------+
--
-- FUNCȚII:
-- +----------------------+----------+----------+-------+-------+
-- | Funcție              | RECEPTIE | ASISTENT | MEDIC | ADMIN |
-- +----------------------+----------+----------+-------+-------+
-- | encrypt_cnp          |    X     |    X     |   X   |   X   |
-- | decrypt_cnp_audited  |    -     |    -     |   X   |   X   |
-- | rotate_encryption_key|    -     |    -     |   -   |   X   |
-- +----------------------+----------+----------+-------+-------+

-- sterge profilurile existente
BEGIN
   FOR p IN (SELECT profile FROM dba_profiles WHERE profile IN ('PROFIL_RECEPTIE','PROFIL_ASISTENT','PROFIL_MEDIC','PROFIL_ADMIN') GROUP BY profile) LOOP
      EXECUTE IMMEDIATE 'DROP PROFILE ' || p.profile || ' CASCADE';
   END LOOP;
END;
/

-- Se creeaza profilurile
CREATE PROFILE profil_receptie LIMIT
    SESSIONS_PER_USER       5
    CPU_PER_SESSION         300
    CPU_PER_CALL            60
    IDLE_TIME               10
    CONNECT_TIME            480
    FAILED_LOGIN_ATTEMPTS   3
    PASSWORD_LIFE_TIME      30
    PASSWORD_LOCK_TIME      1/24;

CREATE PROFILE profil_asistent LIMIT
    SESSIONS_PER_USER       5
    CPU_PER_SESSION         600
    CPU_PER_CALL            120
    IDLE_TIME               15
    CONNECT_TIME            480
    FAILED_LOGIN_ATTEMPTS   3
    PASSWORD_LIFE_TIME      60
    PASSWORD_LOCK_TIME      1/24;

CREATE PROFILE profil_medic LIMIT
    SESSIONS_PER_USER       10
    CPU_PER_SESSION         UNLIMITED
    CPU_PER_CALL            UNLIMITED
    IDLE_TIME               30
    CONNECT_TIME            720
    FAILED_LOGIN_ATTEMPTS   5
    PASSWORD_LIFE_TIME      90
    PASSWORD_LOCK_TIME      1/48;

CREATE PROFILE profil_admin LIMIT
    SESSIONS_PER_USER       UNLIMITED
    CPU_PER_SESSION         UNLIMITED
    CPU_PER_CALL            UNLIMITED
    IDLE_TIME               60
    CONNECT_TIME            UNLIMITED
    FAILED_LOGIN_ATTEMPTS   10
    PASSWORD_LIFE_TIME      180
    PASSWORD_LOCK_TIME      1/96;

CREATE ROLE rol_receptie;
CREATE ROLE rol_asistent;
CREATE ROLE rol_medic;
CREATE ROLE rol_admin;


-- Fiecare rol superior moștenește privilegiile celui inferior.
GRANT rol_receptie TO rol_asistent;
GRANT rol_asistent TO rol_medic;
GRANT rol_medic TO rol_admin;

-- privilegii rol_receptie
GRANT SELECT ON careconnect.departament TO rol_receptie;
GRANT SELECT ON careconnect.personal_medical TO rol_receptie;

-- Tabele: CR pe pacient (înregistrare pacienți noi)
GRANT SELECT, INSERT ON careconnect.pacient TO rol_receptie;

-- Tabele: R pe fisa_medicala (VPD filtrează - vede doar nivel = 1)
GRANT SELECT ON careconnect.fisa_medicala TO rol_receptie;

-- secvente necesare pentru INSERT
GRANT SELECT ON careconnect.seq_pacient TO rol_receptie;

-- functii: encrypt_cnp pentru a cripta CNP-ul la inregistrare
GRANT EXECUTE ON careconnect.encrypt_cnp TO rol_receptie;

-- views mascate pentru recepție
GRANT SELECT ON careconnect.v_pacienti_receptie TO rol_receptie;
GRANT SELECT ON careconnect.v_fise_receptie TO rol_receptie;
GRANT SELECT ON careconnect.v_personal_receptie TO rol_receptie;


-- privilegii rol_asistent
-- views pentru asistenți (date parțial mascate)
GRANT SELECT ON careconnect.v_pacienti_asistent TO rol_asistent;
GRANT SELECT ON careconnect.v_fise_asistent TO rol_asistent;
GRANT SELECT ON careconnect.v_personal_asistent TO rol_asistent;


-- privilegii rol_medic
-- Tabele: +U pe pacient
GRANT UPDATE ON careconnect.pacient TO rol_medic;

-- Tabele: +CU pe fisa_medicala (deja are R de la rol_asistent)
GRANT INSERT, UPDATE ON careconnect.fisa_medicala TO rol_medic;

-- Tabele: R pe encryption_keys (necesar pentru decrypt_cnp_audited)
GRANT SELECT ON careconnect.encryption_keys TO rol_medic;

-- Secvente necesare pentru INSERT fisa_medicala
GRANT SELECT ON careconnect.seq_fisa TO rol_medic;

-- Functii: decrypt_cnp_audited (cu audit automat)
GRANT EXECUTE ON careconnect.decrypt_cnp_audited TO rol_medic;

-- Views complete pentru medici
GRANT SELECT ON careconnect.v_pacienti_medic TO rol_medic;
GRANT SELECT ON careconnect.v_fise_medic TO rol_medic;
GRANT SELECT ON careconnect.v_personal_medic TO rol_medic;


-- privilegii rol_admin
-- Tabele: +D pe pacient si fisa_medicala
GRANT DELETE ON careconnect.pacient TO rol_admin;
GRANT DELETE ON careconnect.fisa_medicala TO rol_admin;

-- Tabele: CRUD complet pe departament (INSERT, UPDATE, DELETE - deja are R)
GRANT INSERT, UPDATE, DELETE ON careconnect.departament TO rol_admin;

-- Tabele: CRUD complet pe personal_medical (INSERT, UPDATE, DELETE - deja are R)
GRANT INSERT, UPDATE, DELETE ON careconnect.personal_medical TO rol_admin;

-- Tabele: CRUD complet pe encryption_keys (INSERT, UPDATE, DELETE - deja are R)
GRANT INSERT, UPDATE, DELETE ON careconnect.encryption_keys TO rol_admin;

-- Tabele: R pe audit_log (doar rol_admin poate vedea audit-ul)
GRANT SELECT ON careconnect.audit_log TO rol_admin;

-- Secvente pentru departament si personal
GRANT SELECT ON careconnect.seq_departament TO rol_admin;
GRANT SELECT ON careconnect.seq_personal TO rol_admin;

-- Functii: rotire chei si logging
GRANT EXECUTE ON careconnect.rotate_encryption_key TO rol_admin;
GRANT EXECUTE ON careconnect.log_decrypt_action TO rol_admin;

-- Views complete + audit pentru admin
GRANT SELECT ON careconnect.v_pacienti_admin TO rol_admin;
GRANT SELECT ON careconnect.v_fise_admin TO rol_admin;
GRANT SELECT ON careconnect.v_personal_admin TO rol_admin;
GRANT SELECT ON careconnect.v_audit_all TO rol_admin;


-- privilegii sistem pentru schema careconnect

GRANT CREATE USER TO careconnect;
GRANT DROP USER TO careconnect;
GRANT ALTER USER TO careconnect;

GRANT rol_receptie TO careconnect WITH ADMIN OPTION;
GRANT rol_asistent TO careconnect WITH ADMIN OPTION;
GRANT rol_medic TO careconnect WITH ADMIN OPTION;
GRANT rol_admin TO careconnect WITH ADMIN OPTION;
GRANT CREATE SESSION TO careconnect WITH ADMIN OPTION;

COMMIT;
