WITH IntervaleOrare AS (
    SELECT 
        m.ID AS IDMedic,
        m.Nume || ' ' || m.Prenume AS NumeMedic,
        TO_CHAR(p.DataProgramare, 'DY') AS Zi,
        CASE 
            WHEN SUBSTR(p.OraProgramare, 1, 2) BETWEEN '08' AND '12' THEN 'Dimineața'
            WHEN SUBSTR(p.OraProgramare, 1, 2) BETWEEN '13' AND '16' THEN 'După-amiază'
            ELSE 'Seara'
        END AS IntervalOrar,
        COUNT(*) AS NumarProgramari
    FROM MEDIC m
    JOIN PROGRAMARE p ON m.ID = p.IDMedic
    WHERE p.DataProgramare BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 30
    GROUP BY 
        m.ID, 
        m.Nume, 
        m.Prenume, 
        TO_CHAR(p.DataProgramare, 'DY'),
        CASE 
            WHEN SUBSTR(p.OraProgramare, 1, 2) BETWEEN '08' AND '12' THEN 'Dimineața'
            WHEN SUBSTR(p.OraProgramare, 1, 2) BETWEEN '13' AND '16' THEN 'După-amiază'
            ELSE 'Seara'
        END
)
SELECT 
    NumeMedic,
    Zi,
    MAX(DECODE(IntervalOrar, 'Dimineața', NumarProgramari, 0)) AS Dimineata,
    MAX(DECODE(IntervalOrar, 'După-amiază', NumarProgramari, 0)) AS DupaAmiaza,
    MAX(DECODE(IntervalOrar, 'Seara', NumarProgramari, 0)) AS Seara,
    SUM(NumarProgramari) AS TotalPeZi
FROM IntervaleOrare
GROUP BY NumeMedic, Zi
ORDER BY 
    CASE Zi 
        WHEN 'MON' THEN 1 
        WHEN 'TUE' THEN 2 
        WHEN 'WED' THEN 3 
        WHEN 'THU' THEN 4 
        WHEN 'FRI' THEN 5 
        WHEN 'SAT' THEN 6 
        WHEN 'SUN' THEN 7 
    END,
    NumeMedic;