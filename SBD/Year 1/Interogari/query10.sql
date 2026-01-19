WITH ConsultatiiDepartamente AS (
    SELECT
        d.NumeDepartament,
        d.BugetAlocat,
        COUNT(DISTINCT m.ID) AS NumarMedici,
        COUNT(DISTINCT c.ID) AS NumarConsultatii,
        COUNT(DISTINCT r.ID) AS NumarRetete,
        ROUND(AVG(c.Urgenta), 2) AS UrgentaMedie,
        COUNT(DISTINCT CASE WHEN c.Urgenta >= 4 THEN c.ID END) AS ConsultatiiUrgente
    FROM DEPARTAMENT d
    LEFT JOIN MEDIC m ON d.ID = m.IDDepartament
    LEFT JOIN PROGRAMARE p ON m.ID = p.IDMedic
    LEFT JOIN CONSULTATIE c ON p.ID = c.IDProgramare
    LEFT JOIN RETETA r ON c.ID = r.IDConsultatie
    WHERE c.DataConsultatie >= ADD_MONTHS(SYSDATE, -3)
    GROUP BY d.NumeDepartament, d.BugetAlocat
)
SELECT
    cd.NumeDepartament,
    cd.NumarMedici,
    cd.NumarConsultatii,
    cd.ConsultatiiUrgente,
    ROUND(cd.ConsultatiiUrgente * 100.0 / NULLIF(cd.NumarConsultatii, 0), 1) AS ProcentUrgente,
    cd.UrgentaMedie,
    cd.NumarRetete,
    ROUND(cd.BugetAlocat / NULLIF(cd.NumarConsultatii, 0), 2) AS CostMediuPerConsultatie,
    CASE
        WHEN cd.ConsultatiiUrgente > 10 THEN 'DEPARTAMENT CRITIC'
        WHEN cd.ConsultatiiUrgente > 5 THEN 'DEPARTAMENT SOLICITAT'
        ELSE 'DEPARTAMENT STABIL'
    END AS StatusDepartament,
    DENSE_RANK() OVER (ORDER BY cd.ConsultatiiUrgente DESC) AS RankUrgente
FROM ConsultatiiDepartamente cd
WHERE cd.NumarConsultatii > 0
ORDER BY cd.ConsultatiiUrgente DESC, cd.NumarConsultatii DESC;