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

INSERT INTO pacient (nume, prenume, cnp, telefon, adresa) VALUES
('Popescu', 'Ion', '1980123456789', '0712345678', 'Strada Mihai Eminescu, Nr. 10, București'),
('Ionescu', 'Maria', '1990567890123', '0723456789', 'Bulevardul Unirii, Nr. 25, Cluj-Napoca'),
('Georgescu', 'Andrei', '1985123456789', '0734567890', 'Strada Republicii, Nr. 5, Timișoara');

INSERT INTO personal_medical (nume, prenume, specializare, username_db, grad_acreditare) VALUES
('Dr. Popescu', 'Ana', 'Cardiologie', 'ana.popescu', 3),
('Dr. Marinescu', 'Mihai', 'Neurologie', 'mihai.marinescu', 2),
('Dr. Constantinescu', 'Elena', 'Pediatrie', 'elena.constantinescu', 1);

INSERT INTO fisa_medicala (id_pacient, id_medic, diagnostic, tratament, data_consultatie, nivel_clasificare) VALUES
(1, 1, 'Hipertensiune arterială', 'Lisinopril 10mg zilnic, monitorizare tensiune', '2024-01-15 10:30:00', 3),
(2, 2, 'Cefalee tensională', 'Ibuprofen 400mg la nevoie, tehnici de relaxare', '2024-01-20 14:15:00', 2),
(3, 3, 'Infecție respiratorie superioară', 'Amoxicilină 500mg de 3 ori pe zi timp de 7 zile', '2024-01-25 09:00:00', 1);