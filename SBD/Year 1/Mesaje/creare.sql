CREATE TABLE MESAJE (
    cod_mesaj NUMBER PRIMARY KEY,
    mesaj VARCHAR2(255),
    tip_mesaj VARCHAR2(1) CHECK (tip_mesaj IN ('E', 'W', 'I')),
    creat_de VARCHAR2(40) NOT NULL,
    creat_la DATE NOT NULL
);

-- Creare secvență pentru cod_mesaj
CREATE SEQUENCE seq_mesaje START WITH 1 INCREMENT BY 1;

-- Comentarii pentru documentare
COMMENT ON TABLE MESAJE IS 'Tabel pentru stocarea mesajelor sistemului';
COMMENT ON COLUMN MESAJE.cod_mesaj IS 'Cheie primară';
COMMENT ON COLUMN MESAJE.mesaj IS 'Conținutul mesajului';
COMMENT ON COLUMN MESAJE.tip_mesaj IS 'Valori valide: E - Eroare, W - Avertisment, I - Informație';
COMMENT ON COLUMN MESAJE.creat_de IS 'Utilizatorul care a creat mesajul';
COMMENT ON COLUMN MESAJE.creat_la IS 'Data și ora creării mesajului';