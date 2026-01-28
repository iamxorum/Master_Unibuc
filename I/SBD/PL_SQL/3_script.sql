CREATE OR REPLACE FUNCTION calculeaza_programari_medic(
    p_id_medic NUMBER
) RETURN NUMBER IS
    v_numar_programari NUMBER := 0;
    v_exista_medic NUMBER;

    -- Definire excepții
    e_medic_inexistent EXCEPTION;
    e_prea_multe_programari EXCEPTION;
BEGIN
    -- Verifică dacă medicul există
    SELECT COUNT(*) INTO v_exista_medic
    FROM Medic
    WHERE ID = p_id_medic;

    IF v_exista_medic = 0 THEN
        -- Logging și raise pentru medic inexistent
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Medicul nu există', 'E', USER, SYSDATE);
        RAISE e_medic_inexistent;
    END IF;

    -- Numără programările medicului
    SELECT COUNT(*) INTO v_numar_programari
    FROM Programare
    WHERE IDMedic = p_id_medic
    AND DataProgramare >= SYSDATE - 30;

    IF v_numar_programari > 100 THEN
        -- Logging și raise pentru prea multe programări
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Prea multe programări', 'W', USER, SYSDATE);
        RAISE e_prea_multe_programari;
    END IF;

    -- Logging succes
    INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
    VALUES (seq_mesaje.NEXTVAL, 'Calcul reușit', 'I', USER, SYSDATE);

    RETURN v_numar_programari;

EXCEPTION
    WHEN e_medic_inexistent THEN
        RAISE_APPLICATION_ERROR(-20001, 'Medicul nu există în baza de date');
    WHEN e_prea_multe_programari THEN
        RAISE_APPLICATION_ERROR(-20002, 'Prea multe programări');
    WHEN OTHERS THEN
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Eroare neașteptată', 'E', USER, SYSDATE);
        RAISE;
END;
/

-- Apelare pentru testare
DECLARE
    v_rezultat NUMBER;
BEGIN
    v_rezultat := calculeaza_programari_medic(1);
    DBMS_OUTPUT.PUT_LINE('Număr programări: ' || v_rezultat);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
END;
/