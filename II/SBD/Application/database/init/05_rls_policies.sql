ALTER SESSION SET CONTAINER = XEPDB1;

-- crearea contextului (namespace pentru variabile de sesiune)
CREATE OR REPLACE CONTEXT careconnect_ctx USING careconnect.set_user_context;

-- procedura care seteaza contextul (apelata la login)
CREATE OR REPLACE PROCEDURE careconnect.set_user_context
AUTHID DEFINER
IS
    v_grad NUMBER := 0;
    v_user VARCHAR2(30);
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');
    
    -- owner-ul schemei are acces complet
    IF v_user = 'CARECONNECT' THEN
        DBMS_SESSION.SET_CONTEXT('CARECONNECT_CTX', 'GRAD_ACCES', '4');
        RETURN;
    END IF;
    
    -- in rest, pentru useri normali, cautam grad_acces in personal_medical
    BEGIN
        EXECUTE IMMEDIATE 
            'SELECT grad_acces FROM careconnect.personal_medical WHERE UPPER(username_db) = :u'
            INTO v_grad
            USING v_user;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_grad := 0;
    END;
    
    DBMS_SESSION.SET_CONTEXT('CARECONNECT_CTX', 'GRAD_ACCES', TO_CHAR(v_grad));
END set_user_context;
/

GRANT EXECUTE ON careconnect.set_user_context TO PUBLIC;


-- logon trigger - seteaza contextul automat
CREATE OR REPLACE TRIGGER careconnect.trg_set_context_on_logon
AFTER LOGON ON DATABASE
BEGIN
    careconnect.set_user_context();
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END trg_set_context_on_logon;
/


-- functii policy pentru RLS (folosesc context = rapid!)

-- Policy pentru FISA_MEDICALA: nivel_confidentialitate <= grad_acces
-- grad_acces=0 (necunoscut): NU vede fișe (1=0)
-- grad_acces=1 (RECEPTIE): vede fișe cu nivel = 1 (doar informații de bază)
-- grad_acces=2 (ASISTENT): vede fișe cu nivel <= 2
-- grad_acces=3 (MEDIC): vede fișe cu nivel <= 3 (toate)
-- grad_acces=4 (ADMIN): vede tot
CREATE OR REPLACE FUNCTION careconnect.fisa_medicala_policy(
    p_schema  IN VARCHAR2,
    p_table   IN VARCHAR2
)
RETURN VARCHAR2
IS
    v_grad NUMBER;
BEGIN
    v_grad := TO_NUMBER(NVL(SYS_CONTEXT('CARECONNECT_CTX', 'GRAD_ACCES'), '0'));
    
    IF v_grad = 4 OR SYS_CONTEXT('USERENV', 'SESSION_USER') = 'CARECONNECT' THEN
        RETURN NULL;
    END IF;
    
    IF v_grad = 0 THEN
        RETURN '1=0';
    END IF;
    
    RETURN 'nivel_confidentialitate <= ' || v_grad;
END fisa_medicala_policy;
/

BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'CARECONNECT',
        object_name     => 'FISA_MEDICALA',
        policy_name     => 'FISA_CONFIDENTIALITATE_POLICY',
        function_schema => 'CARECONNECT',
        policy_function => 'FISA_MEDICALA_POLICY',
        statement_types => 'SELECT, UPDATE, DELETE',
        update_check    => TRUE
    );
END;
/


COMMIT;
