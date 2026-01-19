WITH PrescrieriMedicament AS (
    SELECT
        m.ID,
        m.Denumire,
        m.SubstantaActiva,
        m.FormaFarmaceutica,
        COUNT(DISTINCT rm.IDReteta) AS NumarPrescrieri,
        SUM(rm.Cantitate) AS CantitatePrescrisa,
        AVG(rm.DurataTratament) AS DurataMedieTratament,
        COUNT(DISTINCT r.IDConsultatie) AS NumarConsultatii,
        COUNT(DISTINCT p.IDPacient) AS NumarPacienti
    FROM MEDICAMENT m
    LEFT JOIN RETETA_MEDICAMENT rm ON m.ID = rm.IDMedicament
    LEFT JOIN RETETA r ON rm.IDReteta = r.ID
    LEFT JOIN CONSULTATIE c ON r.IDConsultatie = c.ID
    LEFT JOIN PROGRAMARE p ON c.IDProgramare = p.ID
    GROUP BY m.ID, m.Denumire, m.SubstantaActiva, m.FormaFarmaceutica
)
SELECT
    Denumire,
    SubstantaActiva,
    FormaFarmaceutica,
    NumarPrescrieri,
    CantitatePrescrisa,
    ROUND(DurataMedieTratament, 1) AS DurataMedieTratament,
    NumarPacienti,
    DENSE_RANK() OVER (ORDER BY NumarPrescrieri DESC) AS RankPopularitate
FROM PrescrieriMedicament
WHERE NumarPrescrieri > 0
ORDER BY NumarPrescrieri DESC;