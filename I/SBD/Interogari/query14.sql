WITH EficientaDepartament AS (
    SELECT
        d.ID,
        d.NumeDepartament,
        d.BugetAlocat,
        COUNT(DISTINCT m.ID) AS NumarMedici,
        COUNT(DISTINCT p.ID) AS NumarProgramari,
        COUNT(DISTINCT c.ID) AS NumarConsultatii,
        COUNT(DISTINCT r.ID) AS NumarRetete,
        SUM(rm.Cantitate * med.PretUnitar) AS CostMedicamente
    FROM DEPARTAMENT d
    LEFT JOIN MEDIC m ON d.ID = m.IDDepartament
    LEFT JOIN PROGRAMARE p ON m.ID = p.IDMedic
    LEFT JOIN CONSULTATIE c ON p.ID = c.IDProgramare
    LEFT JOIN RETETA r ON c.ID = r.IDConsultatie
    LEFT JOIN RETETA_MEDICAMENT rm ON r.ID = rm.IDReteta
    LEFT JOIN MEDICAMENT med ON rm.IDMedicament = med.ID
    GROUP BY d.ID, d.NumeDepartament, d.BugetAlocat
)
SELECT
    NumeDepartament,
    NumarMedici,
    NumarProgramari,
    NumarConsultatii,
    ROUND(NumarConsultatii * 100.0 / NULLIF(NumarProgramari, 0), 1) AS RataFinalizare,
    NumarRetete,
    ROUND(BugetAlocat / NULLIF(NumarConsultatii, 0), 2) AS CostPerConsultatie,
    ROUND(CostMedicamente / NULLIF(NumarRetete, 0), 2) AS CostMediuReteta,
    RANK() OVER (ORDER BY NumarConsultatii DESC) AS RankActivitate,
    RANK() OVER (ORDER BY (NumarConsultatii * 100.0 / NULLIF(NumarProgramari, 0)) DESC) AS RankEficienta
FROM EficientaDepartament
WHERE NumarMedici > 0
ORDER BY RataFinalizare DESC;