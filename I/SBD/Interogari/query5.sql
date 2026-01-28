WITH MediciDepartament AS (
    SELECT 
        d.NumeDepartament,
        d.BugetAlocat,
        m.Nume || ' ' || m.Prenume AS NumeMedic,
        m.GradProfesional,
        COUNT(p.ID) AS NumarProgramari,
        ROW_NUMBER() OVER (PARTITION BY d.ID ORDER BY COUNT(p.ID) DESC) AS RankInDepartament
    FROM DEPARTAMENT d
    LEFT JOIN MEDIC m ON d.ID = m.IDDepartament
    LEFT JOIN PROGRAMARE p ON m.ID = p.IDMedic
    GROUP BY d.NumeDepartament, d.BugetAlocat, m.Nume, m.Prenume, m.GradProfesional, d.ID
)
SELECT 
    NumeDepartament,
    BugetAlocat,
    LISTAGG(NumeMedic || ' (' || GradProfesional || ')', '; ') 
    WITHIN GROUP (ORDER BY RankInDepartament) AS MediciOrdonatiDupaProgramari
FROM MediciDepartament
GROUP BY NumeDepartament, BugetAlocat
ORDER BY BugetAlocat DESC;
