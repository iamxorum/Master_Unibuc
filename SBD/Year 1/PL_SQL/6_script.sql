CREATE OR REPLACE TRIGGER trg_monitorizare_schema
AFTER DDL ON SCHEMA
BEGIN
    -- Logging modificare structură
    INSERT INTO MESAJE (
        cod_mesaj,
        mesaj,
        tip_mesaj,
        creat_de,
        creat_la
    )
    VALUES (
        seq_mesaje.NEXTVAL,
        'Operație DDL executată: ' || ora_sysevent,
        'I',
        user,
        SYSDATE
    );
END;
/

-- Test trigger
CREATE TABLE test_table (
    id NUMBER PRIMARY KEY,
    nume VARCHAR2(100)
);

DROP TABLE test_table;