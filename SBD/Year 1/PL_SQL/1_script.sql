CREATE OR REPLACE PROCEDURE gestionare_pacienti AS
    -- Tablou indexat
    TYPE t_pacienti IS TABLE OF Pacient%ROWTYPE INDEX BY PLS_INTEGER;
    v_pacienti t_pacienti;

    -- Tablou imbricat
    TYPE t_nume IS TABLE OF VARCHAR2(100);
    v_nume t_nume := t_nume();

    -- Vector
    TYPE v_cnp IS VARRAY(5) OF VARCHAR2(13);
    v_cnp_uri v_cnp := v_cnp();

    -- Pentru logging
    v_mesaj VARCHAR2(255);
BEGIN
    -- Populare tablou indexat
    SELECT * BULK COLLECT INTO v_pacienti
    FROM Pacient
    WHERE ROWNUM <= 5;

    -- Populare tablou imbricat
    FOR i IN 1..v_pacienti.COUNT LOOP
        v_nume.EXTEND;
        v_nume(i) := v_pacienti(i).nume || ' ' || v_pacienti(i).prenume;
    END LOOP;

    -- Populare vector
    v_cnp_uri.EXTEND(3);
    FOR i IN 1..3 LOOP
        v_cnp_uri(i) := v_pacienti(i).cnp;
    END LOOP;

    -- Afișare rezultate
    FOR i IN 1..v_nume.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Pacient ' || i || ': ' || v_nume(i));
    END LOOP;

    -- Logging succes
    v_mesaj := 'Procedura gestionare_pacienti executată cu succes';
    INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
    VALUES (seq_mesaje.NEXTVAL, v_mesaj, 'I', USER, SYSDATE);

EXCEPTION
    WHEN OTHERS THEN
        -- Logging eroare
        v_mesaj := 'Eroare în procedura gestionare_pacienti: ' || SQLERRM;
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, v_mesaj, 'E', USER, SYSDATE);
        RAISE;
END;
/

-- Apelare
BEGIN
    gestionare_pacienti;
END;
/