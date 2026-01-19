SELECT
    m.Nume || ' ' || m.Prenume AS NumeComplet,
    LISTAGG(s.Denumire, ', ') WITHIN GROUP (ORDER BY s.Denumire) AS Specializari,
    COUNT(DISTINCT p.ID) AS NumarProgramari,
    TO_CHAR(MIN(m.DataAngajare), 'DD-MON-YYYY') AS DataAngajare,
    MONTHS_BETWEEN(SYSDATE, m.DataAngajare)/12 AS AniVechime
FROM MEDIC m
LEFT JOIN MEDIC_SPECIALIZARE ms ON m.ID = ms.IDMedic
LEFT JOIN SPECIALIZARE s ON ms.IDSpecializare = s.ID
LEFT JOIN PROGRAMARE p ON m.ID = p.IDMedic
GROUP BY m.ID, m.Nume, m.Prenume, m.DataAngajare
HAVING COUNT(DISTINCT s.ID) >= 2
ORDER BY AniVechime DESC;
