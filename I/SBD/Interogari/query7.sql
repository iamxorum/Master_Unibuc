SELECT
    p.Nume || ' ' || p.Prenume AS NumePacient,
    TO_CHAR(p.DataNasterii, 'YYYY-MM-DD') AS DataNastere,
    NVL(LISTAGG(DISTINCT a.Denumire, ', ') WITHIN GROUP (ORDER BY a.Denumire), 'Fără alergii') AS ListaAlergii,
    COUNT(DISTINCT c.ID) AS NumarConsultatii,
    MAX(c.DataConsultatie) AS UltimaConsultatie,
    CASE
        WHEN COUNT(DISTINCT c.ID) = 0 THEN 'Fără consultații'
        WHEN MAX(c.DataConsultatie) < ADD_MONTHS(SYSDATE, -6) THEN 'Inactiv'
        ELSE 'Activ'
    END AS StatusPacient
FROM PACIENT p
LEFT JOIN PACIENT_ALERGIE pa ON p.ID = pa.IDPacient
LEFT JOIN ALERGIE a ON pa.IDAlergie = a.ID
LEFT JOIN PROGRAMARE pr ON p.ID = pr.IDPacient
LEFT JOIN CONSULTATIE c ON pr.ID = c.IDProgramare
GROUP BY p.ID, p.Nume, p.Prenume, p.DataNasterii
HAVING COUNT(DISTINCT a.ID) >= 2 OR COUNT(DISTINCT c.ID) >= 3
ORDER BY COUNT(DISTINCT c.ID) DESC;