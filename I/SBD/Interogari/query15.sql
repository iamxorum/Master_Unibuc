WITH IerarhieMedici AS (
    SELECT DISTINCT 
        GradProfesional,
        CASE 
            WHEN GradProfesional = 'Primar' THEN NULL
            WHEN GradProfesional = 'Specialist' THEN 'Primar'
            WHEN GradProfesional = 'Rezident' THEN 'Specialist'
        END AS GradSuperior
    FROM MEDIC
)
SELECT 
    LEVEL as Nivel,
    LPAD(' ', 2 * (LEVEL - 1)) || GradProfesional as Structura,
    (
        SELECT COUNT(*) 
        FROM MEDIC m 
        WHERE m.GradProfesional = i.GradProfesional
    ) as NumarMedici,
    CONNECT_BY_ISLEAF as EsteFrunza
FROM IerarhieMedici i
START WITH GradSuperior IS NULL
CONNECT BY PRIOR GradProfesional = GradSuperior
ORDER SIBLINGS BY GradProfesional;