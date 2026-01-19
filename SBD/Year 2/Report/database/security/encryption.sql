CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS pacient_encrypted (
    id_pacient SERIAL PRIMARY KEY,
    nume VARCHAR(50) NOT NULL,
    prenume VARCHAR(50) NOT NULL,
    cnp_encrypted BYTEA,  -- CNP criptat
    telefon VARCHAR(15),
    adresa TEXT
);

CREATE OR REPLACE FUNCTION encrypt_cnp(cnp_plain VARCHAR, encryption_key TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(cnp_plain, encryption_key);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrypt_cnp(cnp_encrypted BYTEA, encryption_key TEXT)
RETURNS VARCHAR AS $$
BEGIN
    RETURN pgp_sym_decrypt(cnp_encrypted, encryption_key);
END;
$$ LANGUAGE plpgsql;

INSERT INTO pacient_encrypted (nume, prenume, cnp_encrypted, telefon, adresa)
VALUES (
    'Popescu',
    'Ion',
    encrypt_cnp('1980123456789', 'portocal12'),
    '0712345678',
    'Strada Mihai Eminescu, Nr. 10, București'
);

SELECT 
    id_pacient,
    nume,
    prenume,
    decrypt_cnp(cnp_encrypted, 'portocal12') AS cnp_decriptat,
    telefon,
    adresa
FROM pacient_encrypted
WHERE nume = 'Popescu';

ALTER TABLE pacient
ALTER COLUMN cnp TYPE BYTEA
USING encrypt_cnp(cnp, 'portocal12');
