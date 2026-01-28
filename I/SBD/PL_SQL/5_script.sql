CREATE OR REPLACE TRIGGER trg_verificare_medic
BEFORE INSERT OR UPDATE ON Medic
FOR EACH ROW
BEGIN
    -- Verifică dacă gradul profesional este valid
    IF :NEW.GradProfesional NOT IN ('Rezident', 'Specialist', 'Primar') THEN
        -- Logging eroare
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (
            seq_mesaje.NEXTVAL,
            'Grad profesional invalid: ' || :NEW.GradProfesional,
            'E',
            USER,
            SYSDATE
        );

        RAISE_APPLICATION_ERROR(-20004, 'Grad profesional invalid');
    END IF;

    -- Logging modificare
    INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
    VALUES (
        seq_mesaje.NEXTVAL,
        'Modificare medic: ' || :NEW.Nume,
        'I',
        USER,
        SYSDATE
    );
END;
/

-- Test trigger
BEGIN
    -- Încercare de inserare medic cu grad invalid
    INSERT INTO Medic (ID, Nume, Prenume, GradProfesional, IDDepartament)
    VALUES (SEQ_MEDIC_ID.NEXTVAL, 'Test', 'Test', 'Invalid', 1);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
        ROLLBACK;
END;
/