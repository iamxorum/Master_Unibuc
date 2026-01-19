SELECT
    m.Denumire AS NumeMedicament,
    m.FormaFarmaceutica,
    COUNT(DISTINCT r.ID) AS NumarRetete,
    SUM(rm.Cantitate) AS CantitateaTotala,
    ROUND(AVG(rm.DurataTratament), 1) AS DurataMedieTratament,
    DECODE(m.NecesitaReteta, 1, 'Da', 'Nu') AS NecesitaReteta,
    CASE
        WHEN m.StocDisponibil = 0 THEN 'Stoc epuizat'
        WHEN m.StocDisponibil < 10 THEN 'Stoc critic'
        WHEN m.StocDisponibil < 50 THEN 'Stoc redus'
        ELSE 'Stoc suficient'
    END AS StatusStoc,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT r.ID) DESC) AS RankPopularitate
FROM MEDICAMENT m
LEFT JOIN RETETA_MEDICAMENT rm ON m.ID = rm.IDMedicament
LEFT JOIN RETETA r ON rm.IDReteta = r.ID
WHERE UPPER(m.SubstantaActiva) NOT LIKE '%PENICILINA%'
GROUP BY
    m.Denumire,
    m.FormaFarmaceutica,
    m.NecesitaReteta,
    m.StocDisponibil
HAVING COUNT(DISTINCT r.ID) > 0
ORDER BY NumarRetete DESC;