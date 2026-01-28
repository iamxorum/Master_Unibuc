SELECT
    TO_CHAR(p.DataProgramare, 'DY') AS ZiSaptamana,
    TO_CHAR(p.DataProgramare, 'HH24:MI') AS Ora,
    COUNT(*) AS TotalProgramari,
    COUNT(c.ID) AS ProgramariOnorate,
    ROUND(COUNT(c.ID) * 100.0 / COUNT(*), 1) AS RataPrezenta,
    AVG(c.Urgenta) AS UrgentaMedie,
    COUNT(DISTINCT m.ID) AS NumarMedici,
    COUNT(DISTINCT d.ID) AS NumarDepartamente
FROM PROGRAMARE p
LEFT JOIN CONSULTATIE c ON p.ID = c.IDProgramare
JOIN MEDIC m ON p.IDMedic = m.ID
JOIN DEPARTAMENT d ON m.IDDepartament = d.ID
WHERE p.DataProgramare BETWEEN ADD_MONTHS(SYSDATE, -1) AND SYSDATE
GROUP BY TO_CHAR(p.DataProgramare, 'DY'), TO_CHAR(p.DataProgramare, 'HH24:MI')
HAVING COUNT(*) >= 5
ORDER BY
    CASE TO_CHAR(p.DataProgramare, 'DY')
        WHEN 'MON' THEN 1 WHEN 'TUE' THEN 2
        WHEN 'WED' THEN 3 WHEN 'THU' THEN 4
        WHEN 'FRI' THEN 5 WHEN 'SAT' THEN 6
        WHEN 'SUN' THEN 7
    END,
    TO_CHAR(p.DataProgramare, 'HH24:MI');