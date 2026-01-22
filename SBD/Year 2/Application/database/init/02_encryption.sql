ALTER SESSION SET CONTAINER = XEPDB1;

-- funcție de criptare CNP
CREATE OR REPLACE FUNCTION careconnect.encrypt_cnp(p_cnp IN VARCHAR2) 
RETURN RAW
IS
    v_key           RAW(32);
    v_encrypted     RAW(100);
    v_encryption_type PLS_INTEGER;
BEGIN
    SELECT key_value INTO v_key
    FROM careconnect.encryption_keys
    WHERE key_name = 'CNP_KEY' AND is_active = 1;
    
    v_encryption_type := DBMS_CRYPTO.ENCRYPT_AES256 
                       + DBMS_CRYPTO.CHAIN_CBC 
                       + DBMS_CRYPTO.PAD_PKCS5;
    
    v_encrypted := DBMS_CRYPTO.ENCRYPT(
        src => UTL_I18N.STRING_TO_RAW(p_cnp, 'AL32UTF8'),
        typ => v_encryption_type,
        key => v_key
    );
    
    RETURN v_encrypted;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cheia de criptare CNP_KEY nu exista sau nu este activa');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Eroare la criptare: ' || SQLERRM);
END encrypt_cnp;
/


-- tabel de audit
CREATE TABLE careconnect.audit_log (
    audit_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    audit_type        VARCHAR2(20) NOT NULL,              -- 'DECRYPT', 'TRIGGER', 'FGA', 'KEY_ROTATION'
    username          VARCHAR2(30) NOT NULL,
    action_type       VARCHAR2(30) NOT NULL,              -- SELECT, INSERT, UPDATE, DELETE, DECRYPT, etc.
    table_name        VARCHAR2(50),
    record_id         NUMBER,
    old_value         VARCHAR2(4000),                     -- Valoare veche (la UPDATE/DELETE)
    new_value         VARCHAR2(4000),                     -- Valoare noua (la INSERT/UPDATE)
    sql_text          VARCHAR2(4000),                     -- Query-ul executat (FGA)
    ip_address        VARCHAR2(50),
    os_user           VARCHAR2(100),
    program           VARCHAR2(100),                      -- Aplicatia client
    action_timestamp  TIMESTAMP DEFAULT SYSTIMESTAMP,
    details           VARCHAR2(500)
);

CREATE INDEX careconnect.idx_audit_username ON careconnect.audit_log(username);
CREATE INDEX careconnect.idx_audit_timestamp ON careconnect.audit_log(action_timestamp);
CREATE INDEX careconnect.idx_audit_table ON careconnect.audit_log(table_name);
CREATE INDEX careconnect.idx_audit_type ON careconnect.audit_log(audit_type);

-- procedura de audit pentru decriptari
CREATE OR REPLACE PROCEDURE careconnect.log_decrypt_action(
    p_table_name  IN VARCHAR2 DEFAULT NULL,
    p_record_id   IN NUMBER DEFAULT NULL,
    p_details     IN VARCHAR2 DEFAULT NULL
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO careconnect.audit_log (
        audit_type, username, action_type, table_name, 
        record_id, ip_address, os_user, program, details
    ) VALUES (
        'DECRYPT',
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        'DECRYPT',
        p_table_name,
        p_record_id,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        p_details
    );
    COMMIT;
END log_decrypt_action;
/

-- funcție de decriptare CNP cu audit automat
CREATE OR REPLACE FUNCTION careconnect.decrypt_cnp_audited(
    p_encrypted IN RAW,
    p_record_id IN NUMBER DEFAULT NULL
) 
RETURN VARCHAR2
IS
    v_key           RAW(32);
    v_decrypted     RAW(100);
    v_encryption_type PLS_INTEGER;
    v_result        VARCHAR2(13);
BEGIN
    SELECT key_value INTO v_key
    FROM careconnect.encryption_keys
    WHERE key_name = 'CNP_KEY' AND is_active = 1;
    
    v_encryption_type := DBMS_CRYPTO.ENCRYPT_AES256 
                       + DBMS_CRYPTO.CHAIN_CBC 
                       + DBMS_CRYPTO.PAD_PKCS5;
    
    v_decrypted := DBMS_CRYPTO.DECRYPT(
        src => p_encrypted,
        typ => v_encryption_type,
        key => v_key
    );
    
    v_result := UTL_I18N.RAW_TO_CHAR(v_decrypted, 'AL32UTF8');
    
    careconnect.log_decrypt_action('PACIENT', p_record_id, 'CNP decriptat');
    
    RETURN v_result;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        careconnect.log_decrypt_action('PACIENT', p_record_id, 'EROARE: Cheie inexistenta');
        RAISE_APPLICATION_ERROR(-20001, 'Cheia de criptare nu exista');
    WHEN OTHERS THEN
        careconnect.log_decrypt_action('PACIENT', p_record_id, 'EROARE: ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20003, 'Eroare la decriptare: ' || SQLERRM);
END decrypt_cnp_audited;
/

-- procedura de rotire a cheilor de criptare
CREATE OR REPLACE PROCEDURE careconnect.rotate_encryption_key
IS
    v_old_key       RAW(32);
    v_new_key       RAW(32);
    v_old_key_id    NUMBER;
    v_new_key_id    NUMBER;
    v_encryption_type PLS_INTEGER;
    v_decrypted     RAW(100);
    v_new_encrypted RAW(100);
    
    CURSOR c_pacienti IS
        SELECT id_pacient, cnp FROM careconnect.pacient WHERE cnp IS NOT NULL FOR UPDATE;
    
BEGIN
    SELECT key_value, key_id INTO v_old_key, v_old_key_id
    FROM careconnect.encryption_keys
    WHERE key_name = 'CNP_KEY' AND is_active = 1;
    
    v_encryption_type := DBMS_CRYPTO.ENCRYPT_AES256 
                       + DBMS_CRYPTO.CHAIN_CBC 
                       + DBMS_CRYPTO.PAD_PKCS5;
    
    v_new_key := DBMS_CRYPTO.RANDOMBYTES(32);
    v_new_key_id := v_old_key_id + 1;
    
    FOR rec IN c_pacienti LOOP
        v_decrypted := DBMS_CRYPTO.DECRYPT(rec.cnp, v_encryption_type, v_old_key);
        
        v_new_encrypted := DBMS_CRYPTO.ENCRYPT(v_decrypted, v_encryption_type, v_new_key);
        
        UPDATE careconnect.pacient SET cnp = v_new_encrypted WHERE CURRENT OF c_pacienti;
    END LOOP;
    
    UPDATE careconnect.encryption_keys 
    SET is_active = 0, key_name = 'CNP_KEY_OLD_' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS')
    WHERE key_id = v_old_key_id;
    
    INSERT INTO careconnect.encryption_keys (key_id, key_name, key_value, algorithm)
    VALUES (v_new_key_id, 'CNP_KEY', v_new_key, 'AES256');
    
    careconnect.log_decrypt_action('ENCRYPTION_KEYS', v_new_key_id, 'Cheie rotita cu succes');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cheia a fost rotita cu succes. Noua cheie: ID=' || v_new_key_id);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        careconnect.log_decrypt_action('ENCRYPTION_KEYS', NULL, 'EROARE rotire: ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20004, 'Eroare la rotirea cheii: ' || SQLERRM);
END rotate_encryption_key;
/

COMMIT;
