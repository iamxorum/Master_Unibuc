# 🏥 Diagrama Logica (LDM) - CareConnect

## 👨‍🦲 Enitatea Pacient 

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- Nume - VARCHAR2(50) - NOT NULL
- Prenume - VARCHAR2(50) - NOT NULL
- CNP - VARCHAR2(13) - NOT NULL - CHECK (CNP LIKE '[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') - UNIQUE
- Adresa - VARCHAR2(200) - NOT NULL 
- Telefon - VARCHAR2(15) - NOT NULL - CHECK (Telefon LIKE '07%') - UNIQUE
- Email - VARCHAR2(100) - NOT NULL - CHECK (Email LIKE '%_@__%.__%') - UNIQUE
- DataNasterii - DATE - NOT NULL - CHECK (DataNasterii < GETDATE())
- Sex - CHAR(1) - NOT NULL - CHECK (Sex IN ('M', 'F'))
- GrupaSanguina - VARCHAR2(3) - NOT NULL - CHECK (GrupaSanguina IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))
- DataInregistrarii - TIMESTAMP - NOT NULL - DEFAULT CURRENT_TIMESTAMP

### 🔗 Relații
- Pacient poate avea 0 sau mai multe alergii
- Pacient poate avea 0 sau mai multe programari

### Constraințe
- CNP este unic pentru fiecare pacient
- Telefonul este unic pentru fiecare pacient
- Emailul este unic pentru fiecare pacient
- DataNasterii trebuie sa fie mai mica decat data curenta
- Sexul trebuie sa fie M sau F
- GrupaSanguina trebuie sa fie A+ sau A- sau B+ sau B- sau AB+ sau AB- sau O+ sau O-
- DataInregistrarii este data curenta
---
## 📅 Enitatea Programare

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- IDPacient - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Pacient(ID)
- IDMedic - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Medic(ID)
- DataProgramare - DATE - NOT NULL - CHECK (DataProgramare >= GETDATE())
- OraProgramare - VARCHAR2(5) - NOT NULL - CHECK (OraProgramare LIKE '[0-9][0-9]:[0-9][0-9]')
- Status - VARCHAR2(20) - NOT NULL - CHECK (Status IN ('Programata', 'Anulata', 'Realizata'))
- MotivPrezentare - VARCHAR2(500) - NOT NULL
- Observatii - VARCHAR2(500)

### Relații
- Programare poate avea 0 sau 1 consultație
- Programare poate fi gestionata de 1 singur medic

### 🔗 Constraințe
- DataProgramare trebuie sa fie mai mare sau egala cu data curenta
- OraProgramare trebuie sa fie in formatul HH:MM
- Statusul trebuie sa fie Programata, Anulata sau Realizata
- MotivPrezentare trebuie sa fie o descriere a motivului pentru care pacientul vine la programare
---
## 🧑‍⚕️ Enitatea Medic

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- Nume - VARCHAR2(50) - NOT NULL
- Prenume - VARCHAR2(50) - NOT NULL
- CNP - VARCHAR2(13) - NOT NULL - CHECK (CNP LIKE '[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]') - UNIQUE
- Telefon - VARCHAR2(15) - NOT NULL - CHECK (Telefon LIKE '07%') - UNIQUE
- Email - VARCHAR2(100) - NOT NULL - CHECK (Email LIKE '%_@__%.__%') - UNIQUE
- DataAngajare - DATE - NOT NULL - CHECK (DataAngajare <= GETDATE())
- GradProfesional - VARCHAR2(50) - NOT NULL
- NrLicenta - VARCHAR2(20) - NOT NULL - UNIQUE
- IdDepartament - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Departament(ID)

### 🔗 Relații
- Medic poate avea 0 sau mai multe programari
- Medic poate avea 0 sau mai multe specializari
- Medic poate fi in 1 singur departament
- Medic poate fi sef la 1 singur departament

### Constraințe
- DataAngajare trebuie sa fie mai mica sau egala cu data curenta
- CNP trebuie sa fie un numar unic pentru fiecare medic
- Telefonul trebuie sa fie un numar unic pentru fiecare medic
- Emailul trebuie sa fie un numar unic pentru fiecare medic
- NrLicenta trebuie sa fie un numar unic pentru fiecare medic
- IdDepartament trebuie sa fie un id valid pentru un departament
- GradProfesional trebuie sa fie o descriere a gradului profesional al medicului
---
## 🔍 Enitatea Specializare

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- Denumire - VARCHAR2(100) - NOT NULL
- Descriere - VARCHAR2(500) - NOT NULL
- Nivel - VARCHAR2(50) - NOT NULL
- CodSpecializare - VARCHAR2(20) - NOT NULL - UNIQUE

### Relații
- Specializare poate avea 0 sau mai multi medici

### 🔗 Constraințe
- Denumirea trebuie sa fie o descriere a specializarii
- Codul specializarii trebuie sa fie un numar unic pentru fiecare specializare
---
## 📚 Enitatea Departament

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- NumeDepartament - VARCHAR2(100) - NOT NULL
- Locatie - VARCHAR2(100) - NOT NULL
- IdSefDepartament - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Medic(ID)
- BugetAlocat - NUMBER(12, 2) - NOT NULL - CHECK (BugetAlocat > 0)
- NrPaturi - NUMBER(4) - NOT NULL - CHECK (NrPaturi > 0)
- TelefonContact - VARCHAR2(15) - NOT NULL - CHECK (TelefonContact LIKE '07%') - UNIQUE

### 🔗 Relații
- Departament poate avea 0 sau mai multi medici

### 🔗 Constraințe
- NumeDepartament trebuie sa fie o descriere a departamentului
- Locatie trebuie sa fie o descriere a locatiei departamentului
- IdSefDepartament trebuie sa fie un id valid pentru un medic
- BugetAlocat trebuie sa fie un numar pozitiv
- NrPaturi trebuie sa fie un numar pozitiv
- TelefonContact trebuie sa fie un numar unic pentru fiecare departament
---
## 🤒 Enitatea Alergie

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- Denumire - VARCHAR2(100) - NOT NULL
- Descriere - VARCHAR2(500) - NOT NULL
- TipAlergie - VARCHAR2(50) - NOT NULL
- CodMedical - VARCHAR2(20) - NOT NULL - UNIQUE

### 🔗 Relații
- Alergie poate avea 0 sau mai multi pacienti

### Constraințe
- Denumirea trebuie sa fie o descriere a alergiei
- Tipul alergiei trebuie sa fie o descriere a tipului alergiei
- Codul medical trebuie sa fie un numar unic pentru fiecare alergie
---
## 🧑‍⚕️ Tabelul Asociere Medic - Specializare

### 📝 Descrierea Atributelor

- IDMedic - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Medic(ID)
- IDSpecializare - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Specializare(ID)
- DataObtinere - DATE - NOT NULL - CHECK (DataObtinere <= GETDATE())
- CertificatNr - VARCHAR2(20) - NOT NULL - UNIQUE

### Constraințe
- DataObtinerii trebuie sa fie mai mica sau egala cu data curenta
- Certificatul trebuie sa fie un numar unic pentru fiecare medic si specializare
---
## 🤒 Tabelul Asociere Pacient - Alergie

### 📝 Descrierea Atributelor

- IDPacient - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Pacient(ID)
- IDAlergie - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Alergie(ID)
- DataDiagnostic - DATE - NOT NULL - CHECK (DataDiagnostic <= GETDATE())
- Observatii - VARCHAR2(500)
- Severitate - NUMBER(1) - NOT NULL - CHECK (Severitate IN (1, 2, 3, 4, 5))

### 🔗 Constraințe
- DataDiagnostic trebuie sa fie mai mica sau egala cu data curenta
- Severitatea trebuie sa fie un numar intre 1 si 5
---
## 🤒 Enitatea Consultatie

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- IDProgramare - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Programare(ID)
- DataConsultatie - TIMESTAMP - NOT NULL - DEFAULT CURRENT_TIMESTAMP
- Diagnostic - VARCHAR2(500) - NOT NULL
- Observatii - VARCHAR2(500)
- Recomandari - VARCHAR2(500)
- Urgenta - NUMBER(1) - NOT NULL - CHECK (Urgenta IN (1, 2, 3, 4, 5))

### 🔗 Relații
- Consultatie poate avea 0 sau o singura reteta

### 🔗 Constraințe
- DataConsultatie trebuie sa fie data curenta
- Urgenta trebuie sa fie un numar intre 1 si 5
---
## 📝 Enitatea Reteta

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- IDConsultatie - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Consultatie(ID)
- DataPrescriere - TIMESTAMP - NOT NULL - DEFAULT CURRENT_TIMESTAMP
- DataExpirare - TIMESTAMP - NOT NULL - CHECK (DataExpirare > DataPrescriere)
- Observatii - VARCHAR2(500)
- Status - VARCHAR2(20) - NOT NULL - CHECK (Status IN ('In asteptare', 'In curs', 'Finalizata'))
- CodUnic - VARCHAR2(20) - NOT NULL - UNIQUE

### 🔗 Relații
- Reteta poate avea 0 sau mai multe medicamente

### 🔗 Constraințe
- DataExpirare trebuie sa fie mai mare decat data prescrierii
- Statusul trebuie sa fie In asteptare, In curs sau Finalizata
- Codul unic trebuie sa fie un numar unic pentru fiecare reteta
---
## 💊 Enitatea Medicament

### 📝 Descrierea Atributelor

- ID - NUMBER(10) - PRIMARY KEY - NOT NULL - AUTOINCREMENT
- Denumire - VARCHAR2(100) - NOT NULL
- SubstantaActiva - VARCHAR2(200) - NOT NULL
- Concentratie - VARCHAR2(50) - NOT NULL - CHECK (Concentratie LIKE '[0-9][0-9]%')
- FormaFarmaceutica - VARCHAR2(50) - NOT NULL
- Producator - VARCHAR2(100) - NOT NULL
- PretUnitar - NUMBER(10, 2) - NOT NULL - CHECK (PretUnitar > 0)
- StocDisponibil - NUMBER(10) - NOT NULL - CHECK (StocDisponibil >= 0) 
- NecesitaReteta - NUMBER(1) - NOT NULL - CHECK (NecesitaReteta IN (0, 1))

### 🔗 Relații
- Medicament poate avea 0 sau mai multe retete

### 🔗 Constraințe
- Pretul unitar trebuie sa fie un numar pozitiv
- Stocul disponibil trebuie sa fie un numar pozitiv
- NecesitaReteta trebuie sa fie 0 sau 1
---
## 📝 Tabelul Asociere Reteta - Medicament

### 📝 Descrierea Atributelor

- IDReteta - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Reteta(ID)
- IDMedicament - NUMBER(10) - FOREIGN KEY - NOT NULL - REFERENCES Medicament(ID)
- Cantitate - NUMBER(10) - NOT NULL - CHECK (Cantitate > 0)
- Dozaj - VARCHAR2(50) - NOT NULL
- DurataTratament - NUMBER(10) - NOT NULL - CHECK (DurataTratament > 0)
- InstructiuniAdministrare - VARCHAR2(500) - NOT NULL

### 🔗 Constraințe
- Cantitatea trebuie sa fie un numar pozitiv
- Dozajul trebuie sa fie o descriere a dozajului medicamentului
- Durata tratamentului trebuie sa fie un numar pozitiv
- Modul de administrare trebuie sa fie o descriere a modului de administrare medicamentului
---
