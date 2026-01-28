SAVEPOINT start_transaction;

-- DEPARTAMENT (fără IdSefDepartament inițial)
INSERT INTO DEPARTAMENT (NumeDepartament, Locatie, BugetAlocat, NrPaturi, TelefonContact) VALUES
('Cardiologie', 'Etaj 2, Aripa Est', 500000.00, 20, '0755123456');
INSERT INTO DEPARTAMENT (NumeDepartament, Locatie, BugetAlocat, NrPaturi, TelefonContact) VALUES
('Neurologie', 'Etaj 3, Aripa Vest', 450000.00, 15, '0755123457');
INSERT INTO DEPARTAMENT (NumeDepartament, Locatie, BugetAlocat, NrPaturi, TelefonContact) VALUES
('Pediatrie', 'Etaj 1, Aripa Sud', 400000.00, 25, '0755123458');
INSERT INTO DEPARTAMENT (NumeDepartament, Locatie, BugetAlocat, NrPaturi, TelefonContact) VALUES
('Chirurgie', 'Etaj 4, Aripa Nord', 600000.00, 30, '0755123459');
INSERT INTO DEPARTAMENT (NumeDepartament, Locatie, BugetAlocat, NrPaturi, TelefonContact) VALUES
('Ortopedie', 'Etaj 2, Aripa Vest', 350000.00, 18, '0755123460');

-- MEDIC
INSERT INTO MEDIC (Nume, Prenume, CNP, Telefon, Email, DataAngajare, GradProfesional, NrLicenta, IdDepartament) VALUES
('Popescu', 'Ion', '1780101123456', '0722123456', 'ion.popescu@spital.ro', TO_DATE('2020-01-15', 'YYYY-MM-DD'), 'Primar', 'L123456', 3000001);
INSERT INTO MEDIC (Nume, Prenume, CNP, Telefon, Email, DataAngajare, GradProfesional, NrLicenta, IdDepartament) VALUES
('Ionescu', 'Maria', '2800202123456', '0722123457', 'maria.ionescu@spital.ro', TO_DATE('2019-03-20', 'YYYY-MM-DD'), 'Specialist', 'L123457', 3000002);
INSERT INTO MEDIC (Nume, Prenume, CNP, Telefon, Email, DataAngajare, GradProfesional, NrLicenta, IdDepartament) VALUES
('Georgescu', 'Ana', '2810303123456', '0722123458', 'ana.georgescu@spital.ro', TO_DATE('2021-06-10', 'YYYY-MM-DD'), 'Primar', 'L123458', 3000003);
INSERT INTO MEDIC (Nume, Prenume, CNP, Telefon, Email, DataAngajare, GradProfesional, NrLicenta, IdDepartament) VALUES
('Vasilescu', 'Dan', '1820404123456', '0722123459', 'dan.vasilescu@spital.ro', TO_DATE('2018-09-01', 'YYYY-MM-DD'), 'Specialist', 'L123459', 3000004);
INSERT INTO MEDIC (Nume, Prenume, CNP, Telefon, Email, DataAngajare, GradProfesional, NrLicenta, IdDepartament) VALUES
('Marinescu', 'Elena', '2830505123456', '0722123460', 'elena.marinescu@spital.ro', TO_DATE('2022-01-05', 'YYYY-MM-DD'), 'Rezident', 'L123460', 3000005);

-- Update DEPARTAMENT cu IdSefDepartament
UPDATE DEPARTAMENT SET IdSefDepartament = 2000001 WHERE ID = 3000001;
UPDATE DEPARTAMENT SET IdSefDepartament = 2000002 WHERE ID = 3000002;
UPDATE DEPARTAMENT SET IdSefDepartament = 2000003 WHERE ID = 3000003;
UPDATE DEPARTAMENT SET IdSefDepartament = 2000004 WHERE ID = 3000004;
UPDATE DEPARTAMENT SET IdSefDepartament = 2000005 WHERE ID = 3000005;

-- SPECIALIZARE
INSERT INTO SPECIALIZARE (Denumire, Descriere, Nivel, CodSpecializare) VALUES
('Cardiologie', 'Specializare în boli cardiovasculare', 'Avansat', 'CARD001');
INSERT INTO SPECIALIZARE (Denumire, Descriere, Nivel, CodSpecializare) VALUES
('Neurologie', 'Specializare în boli neurologice', 'Avansat', 'NEUR001');
INSERT INTO SPECIALIZARE (Denumire, Descriere, Nivel, CodSpecializare) VALUES
('Pediatrie', 'Specializare în îngrijirea copiilor', 'Mediu', 'PED001');
INSERT INTO SPECIALIZARE (Denumire, Descriere, Nivel, CodSpecializare) VALUES
('Chirurgie Generală', 'Specializare în intervenții chirurgicale', 'Avansat', 'CHIR001');
INSERT INTO SPECIALIZARE (Denumire, Descriere, Nivel, CodSpecializare) VALUES
('Ortopedie', 'Specializare în afecțiuni ale sistemului osteoarticular', 'Mediu', 'ORT001');

-- PACIENT
INSERT INTO PACIENT (Nume, Prenume, CNP, Adresa, Telefon, Email, DataNasterii, Sex, GrupaSanguina) VALUES
('Popa', 'Alexandru', '1900101123456', 'Str. Primaverii 10, București', '0733123456', 'alex.popa@email.com', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 'M', 'A+');
INSERT INTO PACIENT (Nume, Prenume, CNP, Adresa, Telefon, Email, DataNasterii, Sex, GrupaSanguina) VALUES
('Dumitrescu', 'Elena', '2910202123456', 'Str. Florilor 20, București', '0733123457', 'elena.dumitrescu@email.com', TO_DATE('1991-02-02', 'YYYY-MM-DD'), 'F', 'O+');
INSERT INTO PACIENT (Nume, Prenume, CNP, Adresa, Telefon, Email, DataNasterii, Sex, GrupaSanguina) VALUES
('Stanescu', 'Mihai', '1920303123456', 'Str. Victoriei 30, București', '0733123458', 'mihai.stanescu@email.com', TO_DATE('1992-03-03', 'YYYY-MM-DD'), 'M', 'B+');
INSERT INTO PACIENT (Nume, Prenume, CNP, Adresa, Telefon, Email, DataNasterii, Sex, GrupaSanguina) VALUES
('Constantinescu', 'Maria', '2930404123456', 'Str. Unirii 40, București', '0733123459', 'maria.const@email.com', TO_DATE('1993-04-04', 'YYYY-MM-DD'), 'F', 'AB+');
INSERT INTO PACIENT (Nume, Prenume, CNP, Adresa, Telefon, Email, DataNasterii, Sex, GrupaSanguina) VALUES
('Diaconu', 'Andrei', '1940505123456', 'Str. Libertatii 50, București', '0733123460', 'andrei.diaconu@email.com', TO_DATE('1994-05-05', 'YYYY-MM-DD'), 'M', 'A-');

-- ALERGIE
INSERT INTO ALERGIE (Denumire, Descriere, TipAlergie, CodMedical) VALUES
('Penicilină', 'Alergie la antibiotice din grupa penicilinei', 'Medicamentoasă', 'AL001');
INSERT INTO ALERGIE (Denumire, Descriere, TipAlergie, CodMedical) VALUES
('Polen', 'Alergie sezonieră la polen', 'Sezonieră', 'AL002');
INSERT INTO ALERGIE (Denumire, Descriere, TipAlergie, CodMedical) VALUES
('Lactoza', 'Intoleranță la lactoză', 'Alimentară', 'AL003');
INSERT INTO ALERGIE (Denumire, Descriere, TipAlergie, CodMedical) VALUES
('Acarieni', 'Alergie la acarieni din praf', 'Respiratorie', 'AL004');
INSERT INTO ALERGIE (Denumire, Descriere, TipAlergie, CodMedical) VALUES
('Latex', 'Alergie la latex', 'Contact', 'AL005');

-- MEDICAMENT
INSERT INTO MEDICAMENT (Denumire, SubstantaActiva, Concentratie, FormaFarmaceutica, Producator, PretUnitar, StocDisponibil, NecesitaReteta) VALUES
('Augmentin', 'Amoxicilină', '875mg', 'Comprimate', 'GSK', 35.50, 100, 1);
INSERT INTO MEDICAMENT (Denumire, SubstantaActiva, Concentratie, FormaFarmaceutica, Producator, PretUnitar, StocDisponibil, NecesitaReteta) VALUES
('Nurofen', 'Ibuprofen', '400mg', 'Comprimate', 'Reckitt', 15.75, 200, 0);
INSERT INTO MEDICAMENT (Denumire, SubstantaActiva, Concentratie, FormaFarmaceutica, Producator, PretUnitar, StocDisponibil, NecesitaReteta) VALUES
('Paracetamol', 'Paracetamol', '500mg', 'Comprimate', 'Zentiva', 12.30, 300, 0);
INSERT INTO MEDICAMENT (Denumire, SubstantaActiva, Concentratie, FormaFarmaceutica, Producator, PretUnitar, StocDisponibil, NecesitaReteta) VALUES
('Ventolin', 'Salbutamol', '100mcg', 'Inhaler', 'GSK', 45.00, 50, 1);
INSERT INTO MEDICAMENT (Denumire, SubstantaActiva, Concentratie, FormaFarmaceutica, Producator, PretUnitar, StocDisponibil, NecesitaReteta) VALUES
('Omeprazol', 'Omeprazol', '20mg', 'Capsule', 'Terapia', 25.80, 150, 1);

-- PROGRAMARE
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000001, 2000001, TRUNC(SYSDATE), '09:00', 'Programata', 'Consult cardiologic', 'Prima vizită');
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000002, 2000002, TRUNC(SYSDATE), '10:30', 'Programata', 'Dureri de cap', 'Pacient cu antecedente');
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000003, 2000003, TRUNC(SYSDATE), '11:45', 'Programata', 'Control periodic', NULL);
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000004, 2000004, TRUNC(SYSDATE), '13:15', 'Programata', 'Evaluare preoperatorie', 'Urgent');
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000005, 2000005, TRUNC(SYSDATE), '14:30', 'Programata', 'Dureri articulare', NULL);
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000001, 2000002, TRUNC(SYSDATE+1), '09:15', 'Programata', 'Second opinion', NULL);
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000002, 2000003, TRUNC(SYSDATE+1), '10:45', 'Programata', 'Evaluare rezultate', NULL);
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000003, 2000004, TRUNC(SYSDATE+1), '12:00', 'Programata', 'Control postoperator', 'Follow-up');
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000004, 2000005, TRUNC(SYSDATE+1), '13:30', 'Programata', 'Consultație control', NULL);
INSERT INTO PROGRAMARE (IDPacient, IDMedic, DataProgramare, OraProgramare, Status, MotivPrezentare, Observatii) VALUES
(1000005, 2000001, TRUNC(SYSDATE+1), '15:00', 'Programata', 'Evaluare periodică', NULL);

-- CONSULTATIE (pentru programările din ziua curentă)
INSERT INTO CONSULTATIE (IDProgramare, Diagnostic, Observatii, Recomandari, Urgenta) VALUES
(4000001, 'Hipertensiune arterială', 'Tensiune 150/90', 'Regim alimentar strict', 3);
INSERT INTO CONSULTATIE (IDProgramare, Diagnostic, Observatii, Recomandari, Urgenta) VALUES
(4000002, 'Migrenă cronică', 'Dureri frecvente', 'Evitarea factorilor declanșatori', 2);
INSERT INTO CONSULTATIE (IDProgramare, Diagnostic, Observatii, Recomandari, Urgenta) VALUES
(4000003, 'Stare generală bună', 'Control de rutină', 'Menținerea stilului de viață actual', 1);
INSERT INTO CONSULTATIE (IDProgramare, Diagnostic, Observatii, Recomandari, Urgenta) VALUES
(4000004, 'Hernie de disc', 'Necesită intervenție', 'Pregătire preoperatorie', 4);
INSERT INTO CONSULTATIE (IDProgramare, Diagnostic, Observatii, Recomandari, Urgenta) VALUES
(4000005, 'Artroză genunchi', 'Dureri la mers', 'Fizioterapie', 2);

-- RETETA (pentru consultațiile efectuate)
INSERT INTO RETETA (IDConsultatie, DataExpirare, Observatii, Status, CodUnic) VALUES
(5000001, SYSDATE + 30, 'A se administra dimineața', 'In asteptare', 'RX001');
INSERT INTO RETETA (IDConsultatie, DataExpirare, Observatii, Status, CodUnic) VALUES
(5000002, SYSDATE + 30, 'A se administra la nevoie', 'In asteptare', 'RX002');
INSERT INTO RETETA (IDConsultatie, DataExpirare, Observatii, Status, CodUnic) VALUES
(5000003, SYSDATE + 30, NULL, 'In asteptare', 'RX003');
INSERT INTO RETETA (IDConsultatie, DataExpirare, Observatii, Status, CodUnic) VALUES
(5000004, SYSDATE + 30, 'Tratament preoperator', 'In asteptare', 'RX004');
INSERT INTO RETETA (IDConsultatie, DataExpirare, Observatii, Status, CodUnic) VALUES
(5000005, SYSDATE + 30, 'Tratament antiinflamator', 'In asteptare', 'RX005');

-- Tabele asociative (10 înregistrări pentru fiecare)

-- MEDIC_SPECIALIZARE
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000001, 9000001, TO_DATE('2019-01-15', 'YYYY-MM-DD'), 'CERT001');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000001, 9000002, TO_DATE('2019-06-20', 'YYYY-MM-DD'), 'CERT002');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000002, 9000002, TO_DATE('2018-03-10', 'YYYY-MM-DD'), 'CERT003');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000002, 9000003, TO_DATE('2018-09-15', 'YYYY-MM-DD'), 'CERT004');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000003, 9000003, TO_DATE('2020-02-28', 'YYYY-MM-DD'), 'CERT005');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000003, 9000004, TO_DATE('2020-08-15', 'YYYY-MM-DD'), 'CERT006');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000004, 9000004, TO_DATE('2017-11-20', 'YYYY-MM-DD'), 'CERT007');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000004, 9000005, TO_DATE('2018-04-25', 'YYYY-MM-DD'), 'CERT008');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000005, 9000005, TO_DATE('2021-07-30', 'YYYY-MM-DD'), 'CERT009');
INSERT INTO MEDIC_SPECIALIZARE (IDMedic, IDSpecializare, DataObtinere, CertificatNr) VALUES
(2000005, 9000001, TO_DATE('2021-12-15', 'YYYY-MM-DD'), 'CERT010');

-- PACIENT_ALERGIE
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000001, 8000001, TO_DATE('2020-01-15', 'YYYY-MM-DD'), 'Reacție severă la penicilină', 5);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000001, 8000002, TO_DATE('2020-03-20', 'YYYY-MM-DD'), 'Rinită alergică sezonieră', 3);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000002, 8000002, TO_DATE('2019-05-10', 'YYYY-MM-DD'), 'Manifestări moderate', 2);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000002, 8000003, TO_DATE('2019-08-15', 'YYYY-MM-DD'), 'Intoleranță confirmată', 4);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000003, 8000003, TO_DATE('2021-02-28', 'YYYY-MM-DD'), 'Simptome ușoare', 1);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000003, 8000004, TO_DATE('2021-06-15', 'YYYY-MM-DD'), 'Necesită tratament continuu', 3);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000004, 8000004, TO_DATE('2018-11-20', 'YYYY-MM-DD'), 'Agravare în sezonul rece', 4);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000004, 8000005, TO_DATE('2019-04-25', 'YYYY-MM-DD'), 'Reacție moderată', 2);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000005, 8000005, TO_DATE('2022-07-30', 'YYYY-MM-DD'), 'Sub observație', 3);
INSERT INTO PACIENT_ALERGIE (IDPacient, IDAlergie, DataDiagnostic, Observatii, Severitate) VALUES
(1000005, 8000001, TO_DATE('2022-12-15', 'YYYY-MM-DD'), 'Necesită atenție sporită', 4);

-- RETETA_MEDICAMENT
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000001, 7000001, 1, '1cp x 2/zi', 10, 'Dimineața și seara, după masă');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000001, 7000002, 2, '1cp la 8 ore', 7, 'La nevoie, maxim 3 pe zi');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000002, 7000003, 3, '1cp la 6 ore', 5, 'În caz de durere');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000002, 7000004, 1, '2 pufuri la nevoie', 30, 'În caz de criză');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000003, 7000005, 2, '1cp/zi', 14, 'Dimineața, înainte de masă');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000003, 7000001, 1, '1cp x 2/zi', 7, 'Dimineața și seara');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000004, 7000002, 3, '1cp la 12 ore', 10, 'La durere');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000004, 7000003, 2, '1cp la 8 ore', 5, 'După masă');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000005, 7000004, 1, '2 pufuri de 3 ori/zi', 30, 'La nevoie');
INSERT INTO RETETA_MEDICAMENT (IDReteta, IDMedicament, Cantitate, Dozaj, DurataTratament, InstructiuniAdministrare) VALUES
(6000005, 7000005, 1, '1cp seara', 14, 'Înainte de culcare');

COMMIT;