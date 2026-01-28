WITH StatisticiMedic AS (
    SELECT
        m.ID,
        m.Nume || ' ' || m.Prenume AS NumeMedic,
        d.NumeDepartament,
        COUNT(DISTINCT p.ID) AS TotalProgramari,
        COUNT(DISTINCT c.ID) AS TotalConsultatii,
        COUNT(DISTINCT r.ID) AS TotalRetete,
        ROUND(AVG(c.Urgenta), 2) AS MedieUrgenta,
        COUNT(DISTINCT ms.IDSpecializare) AS NumarSpecializari
    FROM MEDIC m
    JOIN DEPARTAMENT d ON m.IDDepartament = d.ID
    LEFT JOIN PROGRAMARE p ON m.ID = p.IDMedic
    LEFT JOIN CONSULTATIE c ON p.ID = c.IDProgramare
    LEFT JOIN RETETA r ON c.ID = r.IDConsultatie
    LEFT JOIN MEDIC_SPECIALIZARE ms ON m.ID = ms.IDMedic
    WHERE p.DataProgramare >= ADD_MONTHS(SYSDATE, -6)
    GROUP BY m.ID, m.Nume, m.Prenume, d.NumeDepartament
)
SELECT
    NumeMedic,
    NumeDepartament,
    TotalProgramari,
    TotalConsultatii,
    ROUND(TotalConsultatii * 100.0 / NULLIF(TotalProgramari, 0), 1) AS RataFinalizare,
    TotalRetete,
    MedieUrgenta,
    NumarSpecializari,
    RANK() OVER (PARTITION BY NumeDepartament ORDER BY TotalConsultatii DESC) AS RankInDepartament
FROM StatisticiMedic
WHERE TotalProgramari > 0
ORDER BY TotalConsultatii DESC;