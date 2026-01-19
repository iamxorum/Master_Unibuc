SELECT p.Nume, p.Prenume
FROM PACIENT p
WHERE NOT EXISTS (
    SELECT a.ID
    FROM ALERGIE a
    WHERE a.TipAlergie = 'Alimentară'
    AND NOT EXISTS (
        SELECT 1
        FROM PACIENT_ALERGIE pa
        WHERE pa.IDPacient = p.ID
        AND pa.IDAlergie = a.ID
    )
);