CREATE OR REPLACE PROCEDURE vizualizare_departamente_medici AS
    -- Primul cursor - pentru departamente
    CURSOR c_departamente IS
        SELECT id, NumeDepartament
        FROM Departament;

    -- Al doilea cursor - parametrizat, pentru medicii din departament
    CURSOR c_medici (p_id_departament NUMBER) IS
        SELECT Nume, Prenume, GradProfesional
        FROM Medic
        WHERE IDDepartament = p_id_departament;

    v_mesaj VARCHAR2(255);
BEGIN
    -- Pentru fiecare departament
    FOR dep IN c_departamente LOOP
        DBMS_OUTPUT.PUT_LINE('Departament: ' || dep.NumeDepartament);

        -- Pentru fiecare medic din departamentul curent
        FOR med IN c_medici(dep.id) LOOP
            DBMS_OUTPUT.PUT_LINE('   - ' || med.Nume || ' ' || med.Prenume ||
                                ' (' || med.GradProfesional || ')');
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('-------------------');
    END LOOP;

    -- Logging succes
    v_mesaj := 'Procedura vizualizare_departamente_medici executată cu succes';
    INSERT INTO MESAJE
    VALUES (seq_mesaje.NEXTVAL, v_mesaj, 'I', USER, SYSDATE);

EXCEPTION
    WHEN OTHERS THEN
        -- Logging eroare
        v_mesaj := 'Eroare în procedura vizualizare_departamente_medici: ' || SQLERRM;
        INSERT INTO MESAJE
        VALUES (seq_mesaje.NEXTVAL, v_mesaj, 'E', USER, SYSDATE);
        RAISE;
END;
/

-- Apelare
BEGIN
    vizualizare_departamente_medici;
END;
/