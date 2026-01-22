ALTER SESSION SET CONTAINER = XEPDB1;

AUDIT CREATE USER;
AUDIT DROP USER;
AUDIT ALTER USER;

AUDIT SELECT ON careconnect.pacient;
AUDIT INSERT ON careconnect.pacient;
AUDIT UPDATE ON careconnect.pacient;
AUDIT DELETE ON careconnect.pacient;

AUDIT SELECT ON careconnect.fisa_medicala;
AUDIT INSERT ON careconnect.fisa_medicala;
AUDIT UPDATE ON careconnect.fisa_medicala;
AUDIT DELETE ON careconnect.fisa_medicala;

AUDIT SELECT ON careconnect.encryption_keys;
AUDIT UPDATE ON careconnect.encryption_keys;

AUDIT EXECUTE ON careconnect.decrypt_cnp_audited;
AUDIT EXECUTE ON careconnect.rotate_encryption_key;

-- Trigger pentru PACIENT
CREATE OR REPLACE TRIGGER careconnect.trg_audit_pacient
AFTER INSERT OR UPDATE OR DELETE ON careconnect.pacient
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_action VARCHAR2(10);
    v_old_val VARCHAR2(4000);
    v_new_val VARCHAR2(4000);
    v_details VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
        v_new_val := 'ID=' || :NEW.id_pacient || ', Nume=' || :NEW.nume || ' ' || :NEW.prenume;
        v_details := 'Pacient nou înregistrat';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        v_old_val := 'Nume=' || :OLD.nume || ' ' || :OLD.prenume || ', Tel=' || :OLD.telefon;
        v_new_val := 'Nume=' || :NEW.nume || ' ' || :NEW.prenume || ', Tel=' || :NEW.telefon;
        v_details := 'Date pacient actualizate';
    ELSIF DELETING THEN
        v_action := 'DELETE';
        v_old_val := 'ID=' || :OLD.id_pacient || ', Nume=' || :OLD.nume || ' ' || :OLD.prenume;
        v_details := 'Pacient șters din sistem';
    END IF;
    
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name, 
        record_id, old_value, new_value, ip_address, os_user, program, details
    ) VALUES (
        'TRIGGER',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_action,
        'PACIENT',
        NVL(:NEW.id_pacient, :OLD.id_pacient),
        v_old_val,
        v_new_val,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        v_details
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NULL;
END trg_audit_pacient;
/


-- Trigger pentru FISA_MEDICALA
CREATE OR REPLACE TRIGGER careconnect.trg_audit_fisa_medicala
AFTER INSERT OR UPDATE OR DELETE ON careconnect.fisa_medicala
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_action VARCHAR2(10);
    v_old_val VARCHAR2(4000);
    v_new_val VARCHAR2(4000);
    v_details VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
        v_new_val := 'ID=' || :NEW.id_fisa || ', Pacient=' || :NEW.id_pacient || 
                     ', Medic=' || :NEW.id_medic || ', Diagnostic=' || SUBSTR(:NEW.diagnostic, 1, 100);
        v_details := 'Fișă medicală nouă creată (nivel=' || :NEW.nivel_confidentialitate || ')';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        v_old_val := 'Diagnostic=' || SUBSTR(:OLD.diagnostic, 1, 100) || 
                     ', Nivel=' || :OLD.nivel_confidentialitate;
        v_new_val := 'Diagnostic=' || SUBSTR(:NEW.diagnostic, 1, 100) || 
                     ', Nivel=' || :NEW.nivel_confidentialitate;
        IF :OLD.nivel_confidentialitate != :NEW.nivel_confidentialitate THEN
            v_details := 'ALERTĂ: Schimbare nivel confidențialitate de la ' || 
                         :OLD.nivel_confidentialitate || ' la ' || :NEW.nivel_confidentialitate;
        ELSE
            v_details := 'Fișă medicală actualizată';
        END IF;
    ELSIF DELETING THEN
        v_action := 'DELETE';
        v_old_val := 'ID=' || :OLD.id_fisa || ', Pacient=' || :OLD.id_pacient;
        v_details := 'Fișă medicală ștearsă (nivel=' || :OLD.nivel_confidentialitate || ')';
    END IF;
    
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name,
        record_id, old_value, new_value, ip_address, os_user, program, details
    ) VALUES (
        'TRIGGER',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_action,
        'FISA_MEDICALA',
        NVL(:NEW.id_fisa, :OLD.id_fisa),
        v_old_val,
        v_new_val,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        v_details
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NULL;
END trg_audit_fisa_medicala;
/


-- Trigger pentru DEPARTAMENT
CREATE OR REPLACE TRIGGER careconnect.trg_audit_departament
AFTER INSERT OR UPDATE OR DELETE ON careconnect.departament
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_action VARCHAR2(10);
    v_old_val VARCHAR2(4000);
    v_new_val VARCHAR2(4000);
    v_details VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
        v_new_val := 'ID=' || :NEW.id_departament || ', Nume=' || :NEW.nume_departament || 
                     ', Locatie=' || :NEW.locatie;
        v_details := 'Departament nou creat';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        v_old_val := 'Nume=' || :OLD.nume_departament || ', Locatie=' || :OLD.locatie;
        v_new_val := 'Nume=' || :NEW.nume_departament || ', Locatie=' || :NEW.locatie;
        v_details := 'Departament actualizat';
    ELSIF DELETING THEN
        v_action := 'DELETE';
        v_old_val := 'ID=' || :OLD.id_departament || ', Nume=' || :OLD.nume_departament;
        v_details := 'Departament șters din sistem';
    END IF;
    
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name,
        record_id, old_value, new_value, ip_address, os_user, program, details
    ) VALUES (
        'TRIGGER',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_action,
        'DEPARTAMENT',
        NVL(:NEW.id_departament, :OLD.id_departament),
        v_old_val,
        v_new_val,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        v_details
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NULL;
END trg_audit_departament;
/


CREATE OR REPLACE TRIGGER careconnect.trg_audit_personal
AFTER INSERT OR UPDATE OR DELETE ON careconnect.personal_medical
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_action VARCHAR2(10);
    v_old_val VARCHAR2(4000);
    v_new_val VARCHAR2(4000);
    v_details VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_action := 'INSERT';
        v_new_val := 'ID=' || :NEW.id_personal || ', ' || :NEW.nume || ' ' || :NEW.prenume || 
                     ', Rol=' || :NEW.rol || ', Grad=' || :NEW.grad_acces;
        v_details := 'Angajat nou adăugat';
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        v_old_val := 'Rol=' || :OLD.rol || ', Grad=' || :OLD.grad_acces;
        v_new_val := 'Rol=' || :NEW.rol || ', Grad=' || :NEW.grad_acces;
        
        IF :OLD.grad_acces != :NEW.grad_acces THEN
            v_details := 'ALERTĂ: Schimbare grad acces de la ' || :OLD.grad_acces || ' la ' || :NEW.grad_acces;
        END IF;
    ELSIF DELETING THEN
        v_action := 'DELETE';
        v_old_val := 'ID=' || :OLD.id_personal || ', ' || :OLD.nume || ' ' || :OLD.prenume;
        v_details := 'Angajat șters din sistem';
    END IF;
    
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name,
        record_id, old_value, new_value, ip_address, os_user, program, details
    ) VALUES (
        'TRIGGER',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        v_action,
        'PERSONAL_MEDICAL',
        NVL(:NEW.id_personal, :OLD.id_personal),
        v_old_val,
        v_new_val,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        v_details
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        NULL;
END trg_audit_personal;
/


-- ============================================================================
-- Handler pentru FGA
CREATE OR REPLACE PROCEDURE careconnect.fga_audit_handler(
    p_schema       IN VARCHAR2,
    p_table        IN VARCHAR2,
    p_policy       IN VARCHAR2
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name,
        sql_text, ip_address, os_user, program, details
    ) VALUES (
        'FGA',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        'SELECT',
        p_table,
        SYS_CONTEXT('USERENV', 'CURRENT_SQL'),
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        'FGA Policy: ' || p_policy
    );
    COMMIT;
END fga_audit_handler;
/


-- Politică FGA: Audit pe accesarea CNP-ului din PACIENT
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'CARECONNECT',
        object_name     => 'PACIENT',
        policy_name     => 'AUDIT_CNP_ACCESS',
        audit_column    => 'CNP',
        audit_condition => NULL,
        handler_schema  => 'CARECONNECT',
        handler_module  => 'FGA_AUDIT_HANDLER',
        enable          => TRUE,
        statement_types => 'SELECT'
    );
END;
/


-- Politică FGA: Audit pe fișe cu nivel confidențialitate 3
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'CARECONNECT',
        object_name     => 'FISA_MEDICALA',
        policy_name     => 'AUDIT_FISE_CONFIDENTIALE',
        audit_column    => 'DIAGNOSTIC, TRATAMENT',
        audit_condition => 'nivel_confidentialitate = 3',
        handler_schema  => 'CARECONNECT',
        handler_module  => 'FGA_AUDIT_HANDLER',
        enable          => TRUE,
        statement_types => 'SELECT'
    );
END;
/


-- Politică FGA: Audit pe accesarea cheilor de criptare
BEGIN
    DBMS_FGA.ADD_POLICY(
        object_schema   => 'CARECONNECT',
        object_name     => 'ENCRYPTION_KEYS',
        policy_name     => 'AUDIT_KEY_ACCESS',
        audit_column    => 'KEY_VALUE',
        audit_condition => NULL,
        handler_schema  => 'CARECONNECT',
        handler_module  => 'FGA_AUDIT_HANDLER',
        enable          => TRUE,
        statement_types => 'SELECT'
    );
END;
/


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
    details
FROM careconnect.audit_log
ORDER BY action_timestamp DESC;

GRANT SELECT ON careconnect.v_audit_all TO rol_admin;

COMMIT;
