WITH RetetaCosturi AS (
    SELECT
        d.NumeDepartament,
        r.ID,
        SUM(rm.Cantitate * m.PretUnitar) AS CostTotal,
        COUNT(DISTINCT m.ID) AS NumarMedicamente
    FROM DEPARTAMENT d
    JOIN MEDIC med ON d.ID = med.IDDepartament
    JOIN PROGRAMARE p ON med.ID = p.IDMedic
    JOIN CONSULTATIE c ON p.ID = c.IDProgramare
    JOIN RETETA r ON c.ID = r.IDConsultatie
    JOIN RETETA_MEDICAMENT rm ON r.ID = rm.IDReteta
    JOIN MEDICAMENT m ON rm.IDMedicament = m.ID
    GROUP BY d.NumeDepartament, r.ID
)
SELECT
    NumeDepartament,
    COUNT(ID) AS NumarRetete,
    ROUND(AVG(CostTotal), 2) AS CostMediuReteta,
    MAX(CostTotal) AS CostMaximReteta,
    ROUND(AVG(NumarMedicamente), 1) AS MedieMedicamentePerReteta,
    SUM(CostTotal) AS CostTotalDepartament
FROM RetetaCosturi
GROUP BY NumeDepartament
HAVING AVG(CostTotal) > (
    SELECT AVG(CostTotal) FROM RetetaCosturi
)
ORDER BY CostTotalDepartament DESC;
