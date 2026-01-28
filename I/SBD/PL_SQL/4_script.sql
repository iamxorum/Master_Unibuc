CREATE OR REPLACE TRIGGER trg_verificare_programari
BEFORE INSERT OR UPDATE ON Programare
BEGIN
    -- Verifică dacă se încearcă programări în weekend
    IF TO_CHAR(SYSDATE, 'DY') IN ('SAT', 'SUN') THEN
        -- Logging avertisment
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL,
                'Nu se pot face programări în weekend',
                'W',
                USER,
                SYSDATE);

        RAISE_APPLICATION_ERROR(-20003, 'Nu se pot face programări în weekend');
    END IF;

    -- Logging succes
    INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
    VALUES (seq_mesaje.NEXTVAL,
            'Verificare programări efectuată cu succes',
            'I',
            USER,
            SYSDATE);
END;
/

-- Test trigger
BEGIN
    -- Încercare de inserare programare
    INSERT INTO Programare (ID, IDPacient, IDMedic, DataProgramare)
    VALUES (SEQ_PROGRAMARE_ID.NEXTVAL, 1, 1, SYSDATE);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
        ROLLBACK;
END;
/