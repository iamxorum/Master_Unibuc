CREATE TABLE pacient (
    id_pacient SERIAL PRIMARY KEY,
    nume VARCHAR(50) NOT NULL,
    prenume VARCHAR(50) NOT NULL,
    cnp VARCHAR(13) UNIQUE NOT NULL,
    telefon VARCHAR(15),
    adresa TEXT
);

CREATE TABLE personal_medical (
    id_personal SERIAL PRIMARY KEY,
    nume VARCHAR(50) NOT NULL,
    prenume VARCHAR(50) NOT NULL,
    specializare VARCHAR(50),
    username_db VARCHAR(60) UNIQUE NOT NULL, 
    grad_acreditare INT NOT NULL DEFAULT 1 
);

CREATE TABLE fisa_medicala (
    id_fisa SERIAL PRIMARY KEY,
    id_pacient INT REFERENCES pacient(id_pacient),
    id_medic INT REFERENCES personal_medical(id_personal),
    diagnostic TEXT NOT NULL,
    tratament TEXT,
    data_consultatie TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    nivel_clasificare INT NOT NULL DEFAULT 1 CHECK (nivel_clasificare IN (1, 2, 3))
);