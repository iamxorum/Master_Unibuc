PREPARE get_pacient (VARCHAR, VARCHAR) AS
SELECT * FROM pacient WHERE nume = $1 AND cnp = $2;

EXECUTE get_pacient('Popescu', '1980123456789');

CREATE OR REPLACE FUNCTION get_pacient_by_cnp(cnp_param VARCHAR)
RETURNS TABLE (
    id_pacient INT,
    nume VARCHAR,
    prenume VARCHAR,
    cnp VARCHAR,
    telefon VARCHAR,
    adresa TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id_pacient, p.nume, p.prenume, p.cnp, p.telefon, p.adresa
    FROM pacient p
    WHERE p.cnp = cnp_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT * FROM get_pacient_by_cnp('1980123456789');

