CREATE OR REPLACE PACKAGE management_spital AS
    -- Excepții
    e_medic_inexistent EXCEPTION;
    e_prea_multe_programari EXCEPTION;
    
    -- Procedura cu colecții
    PROCEDURE gestionare_pacienti;
    
    -- Procedura cu cursoare
    PROCEDURE vizualizare_departamente_medici;
    
    -- Funcția cu 3 tabele
    FUNCTION calculeaza_programari_medic(p_id_medic NUMBER) RETURN NUMBER;
    
    -- Proceduri pentru testarea trigger-urilor
    PROCEDURE test_inserare_programare(
        p_id_pacient NUMBER,
        p_id_medic NUMBER,
        p_data DATE
    );
    
    PROCEDURE test_inserare_medic(
        p_nume VARCHAR2,
        p_prenume VARCHAR2,
        p_grad VARCHAR2,
        p_id_dept NUMBER
    );
END management_spital;
/

CREATE OR REPLACE PACKAGE BODY management_spital AS
    -- Implementare procedură cu colecții
    PROCEDURE gestionare_pacienti IS
        TYPE t_pacienti IS TABLE OF Pacient%ROWTYPE INDEX BY PLS_INTEGER;
        v_pacienti t_pacienti;
    BEGIN
        SELECT * BULK COLLECT INTO v_pacienti 
        FROM Pacient 
        WHERE ROWNUM <= 5;
        
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Gestionare pacienți executată', 'I', USER, SYSDATE);
    END gestionare_pacienti;
    
    -- Implementare procedură cu cursoare
    PROCEDURE vizualizare_departamente_medici IS
        CURSOR c_departamente IS 
            SELECT id, NumeDepartament FROM Departament;
            
        CURSOR c_medici (p_id_dept NUMBER) IS 
            SELECT Nume, Prenume FROM Medic WHERE IDDepartament = p_id_dept;
    BEGIN
        FOR dep IN c_departamente LOOP
            FOR med IN c_medici(dep.id) LOOP
                NULL; -- Aici doar pentru demonstrație
            END LOOP;
        END LOOP;
        
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Vizualizare departamente executată', 'I', USER, SYSDATE);
    END vizualizare_departamente_medici;
    
    -- Implementare funcție
    FUNCTION calculeaza_programari_medic(p_id_medic NUMBER) RETURN NUMBER IS
        v_numar_programari NUMBER := 0;
        v_exista_medic NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exista_medic FROM Medic WHERE ID = p_id_medic;
        
        IF v_exista_medic = 0 THEN
            RAISE e_medic_inexistent;
        END IF;
        
        SELECT COUNT(*) INTO v_numar_programari
        FROM Programare
        WHERE IDMedic = p_id_medic;
        
        RETURN v_numar_programari;
    END calculeaza_programari_medic;
    
    -- Implementare procedură test programare
    PROCEDURE test_inserare_programare(
        p_id_pacient NUMBER,
        p_id_medic NUMBER,
        p_data DATE
    ) IS
    BEGIN
        INSERT INTO Programare (ID, IDPacient, IDMedic, DataProgramare)
        VALUES (SEQ_PROGRAMARE_ID.NEXTVAL, p_id_pacient, p_id_medic, p_data);
        
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Programare inserată', 'I', USER, SYSDATE);
    END test_inserare_programare;
    
    -- Implementare procedură test medic
    PROCEDURE test_inserare_medic(
        p_nume VARCHAR2,
        p_prenume VARCHAR2,
        p_grad VARCHAR2,
        p_id_dept NUMBER
    ) IS
    BEGIN
        INSERT INTO Medic (ID, Nume, Prenume, GradProfesional, IDDepartament)
        VALUES (SEQ_MEDIC_ID.NEXTVAL, p_nume, p_prenume, p_grad, p_id_dept);
        
        INSERT INTO MESAJE (cod_mesaj, mesaj, tip_mesaj, creat_de, creat_la)
        VALUES (seq_mesaje.NEXTVAL, 'Medic inserat', 'I', USER, SYSDATE);
    END test_inserare_medic;
    
END management_spital;
/

-- Test pachet
BEGIN
    -- Test procedură cu colecții
    management_spital.gestionare_pacienti;
    
    -- Test procedură cu cursoare
    management_spital.vizualizare_departamente_medici;
    
    -- Test funcție
    DBMS_OUTPUT.PUT_LINE('Număr programări: ' || 
        management_spital.calculeaza_programari_medic(1));
    
    -- Test inserare programare
    management_spital.test_inserare_programare(1, 1, SYSDATE);
    
    -- Test inserare medic
    management_spital.test_inserare_medic('Test', 'Test', 'Specialist', 1);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
END;
/