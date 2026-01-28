WITH DepartamentStats AS (
    SELECT
        d.NumeDepartament,
        COUNT(DISTINCT m.ID) AS NumarMedici,
        COUNT(DISTINCT p.ID) AS NumarProgramari,
        SUM(d.BugetAlocat) AS BugetTotal,
        AVG(c.Urgenta) AS UrgentaMedie
    FROM DEPARTAMENT d
    LEFT JOIN MEDIC m ON d.ID = m.IDDepartament
    LEFT JOIN PROGRAMARE p ON m.ID = p.IDMedic
    LEFT JOIN CONSULTATIE c ON p.ID = c.IDProgramare
    GROUP BY d.NumeDepartament
)
SELECT
    ds.*,
    RANK() OVER (ORDER BY NumarProgramari DESC) AS RankActivitate,
    CASE
        WHEN BugetTotal > 500000 THEN 'Buget Mare'
        WHEN BugetTotal > 200000 THEN 'Buget Mediu'
        ELSE 'Buget Mic'
    END AS CategorieBuget
FROM DepartamentStats ds
ORDER BY NumarProgramari DESC;