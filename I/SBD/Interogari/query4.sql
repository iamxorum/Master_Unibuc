SELECT 
    TO_CHAR(DataProgramare, 'DY') AS ZiSaptamana,
    CASE 
        WHEN TO_NUMBER(SUBSTR(OraProgramare, 1, 2)) BETWEEN 8 AND 12 THEN 'Dimineața'
        WHEN TO_NUMBER(SUBSTR(OraProgramare, 1, 2)) BETWEEN 13 AND 16 THEN 'După-amiază'
        ELSE 'Seara'
    END AS IntervalOrar,
    COUNT(*) AS NumarProgramari,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS ProcentDinTotal
FROM PROGRAMARE
GROUP BY 
    TO_CHAR(DataProgramare, 'DY'),
    CASE 
        WHEN TO_NUMBER(SUBSTR(OraProgramare, 1, 2)) BETWEEN 8 AND 12 THEN 'Dimineața'
        WHEN TO_NUMBER(SUBSTR(OraProgramare, 1, 2)) BETWEEN 13 AND 16 THEN 'După-amiază'
        ELSE 'Seara'
    END;