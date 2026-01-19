# 🏥 CareConnect

## 📊 Entități Principale

### 👤 PACIENT
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_pacient (PK) | NUMBER(10) | Identificator unic |
| 📝 cnp | VARCHAR2(13) | Cod numeric personal |
| 📋 nume | VARCHAR2(50) | Numele pacientului |
| 📋 prenume | VARCHAR2(50) | Prenumele pacientului |
| 📅 data_nasterii | DATE | Data nașterii |
| ⚧ sex | CHAR(1) | Sexul pacientului (M/F) |
| 📍 adresa | VARCHAR2(200) | Adresa completă |
| 📱 telefon | VARCHAR2(15) | Număr de contact |
| 📧 email | VARCHAR2(100) | Adresa de email |
| 🩸 grupa_sanguina | VARCHAR2(3) | Grupa de sânge |
| 📅 data_inregistrare | TIMESTAMP | Data înregistrării în sistem |

### 👨‍⚕️ MEDIC
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_medic (PK) | NUMBER(10) | Identificator unic |
| 📝 cnp | VARCHAR2(13) | Cod numeric personal |
| 📋 nume | VARCHAR2(50) | Numele medicului |
| 📋 prenume | VARCHAR2(50) | Prenumele medicului |
| 📊 grad_profesional | VARCHAR2(50) | Gradul profesional |
| 📅 data_angajare | DATE | Data angajării |
| 📱 telefon | VARCHAR2(15) | Număr de contact |
| 📧 email | VARCHAR2(100) | Adresa de email |
| 📜 nr_licenta | VARCHAR2(20) | Numărul licenței |
| 🔗 id_departament (FK) | NUMBER(10) | Legătura cu departamentul |

### 🏢 DEPARTAMENT
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_departament (PK) | NUMBER(10) | Identificator unic |
| 📋 nume_departament | VARCHAR2(100) | Denumirea departamentului |
| 📍 locatie | VARCHAR2(100) | Locația în spital |
| 🔗 id_sef_departament (FK) | NUMBER(10) | Șeful departamentului |
| 💰 buget_alocat | NUMBER(12,2) | Bugetul alocat |
| 🛏️ nr_paturi | NUMBER(4) | Număr de paturi |
| 📱 telefon_contact | VARCHAR2(15) | Telefon departament |

### 🩺 PROGRAMARE
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_programare (PK) | NUMBER(10) | Identificator unic |
| 🔗 id_pacient (FK) | NUMBER(10) | Pacientul programat |
| 🔗 id_medic (FK) | NUMBER(10) | Medicul programat |
| 📅 data_programare | DATE | Data programării |
| ⏰ ora_programare | VARCHAR2(5) | Ora programării |
| 📝 motiv_prezentare | VARCHAR2(500) | Motivul programării |
| 📊 status | VARCHAR2(20) | Status (Programat/Anulat/Finalizat) |
| 📝 observatii | VARCHAR2(500) | Observații adiționale |

### 🩺 CONSULTATIE
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_consultatie (PK) | NUMBER(10) | Identificator unic |
| 🔗 id_programare (FK) | NUMBER(10) | Programarea asociată |
| 🔗 data_consultatie | TIMESTAMP | Data și ora consultației |
| 📋 diagnostic_principal | VARCHAR2(500) | Diagnosticul principal |
| 📝 observatii | CLOB | Observații medicale |
| 📋 recomandari | CLOB | Recomandări |
| 🚨 urgenta | NUMBER(1) | Nivel de urgență (1-5) |

### 💊 RETETA
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_reteta (PK) | NUMBER(10) | Identificator unic |
| 🔗 id_consultatie (FK) | NUMBER(10) | Consultația asociată |
| 📅 data_prescriere | TIMESTAMP | Data și ora prescrierii |
| 📅 data_expirare | DATE | Data expirării rețetei |
| 📝 observatii | VARCHAR2(500) | Observații speciale |
| 📊 status | VARCHAR2(20) | Status rețetă (Activă/Expirată/Anulată) |
| 🔢 cod_unic | VARCHAR2(20) | Cod unic de identificare |

### 💊 MEDICAMENT
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_medicament (PK) | NUMBER(10) | Identificator unic |
| 📋 denumire | VARCHAR2(100) | Denumirea medicamentului |
| 🧪 substanta_activa | VARCHAR2(200) | Substanța activă |
| 📊 concentratie | VARCHAR2(50) | Concentrația |
| 💊 forma_farmaceutica | VARCHAR2(50) | Forma farmaceutică |
| 🏭 producator | VARCHAR2(100) | Producătorul |
| 💰 pret_unitar | NUMBER(10,2) | Preț per unitate |
| 📦 stoc_disponibil | NUMBER(10) | Stoc curent |
| ⚕️ necesita_reteta | NUMBER(1) | Necesită rețetă (0/1) |

### ⚠️ ALERGIE
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_alergie (PK) | NUMBER(10) | Identificator unic |
| 📋 denumire | VARCHAR2(100) | Denumirea alergiei |
| 📝 descriere | VARCHAR2(500) | Descriere detaliată |
| 📊 tip_alergie | VARCHAR2(50) | Tipul alergiei |
| 🏥 cod_medical | VARCHAR2(20) | Cod medical standardizat |

### 🎓 SPECIALIZARE
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_specializare (PK) | NUMBER(10) | Identificator unic |
| 📋 denumire | VARCHAR2(100) | Denumirea specializării |
| 📝 descriere | VARCHAR2(500) | Descriere detaliată |
| 📊 nivel | VARCHAR2(50) | Nivelul specializării |
| 📜 cod_specializare | VARCHAR2(20) | Cod standardizat |

## 🔄 Tabele Asociative

### 📋 RETETA_MEDICAMENT
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_reteta (PK, FK) | NUMBER(10) | ID Rețetă |
| 🔑 id_medicament (PK, FK) | NUMBER(10) | ID Medicament |
| 📊 cantitate | NUMBER(5) | Cantitatea prescrisă |
| 💊 dozaj | VARCHAR2(50) | Dozajul recomandat |
| ⏱️ durata_tratament | NUMBER(3) | Durata tratamentului (zile) |
| 📝 instructiuni_administrare | VARCHAR2(500) | Instrucțiuni |

### 👨‍⚕️ MEDIC_SPECIALIZARE
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_medic (PK, FK) | NUMBER(10) | ID Medic |
| 🔑 id_specializare (PK, FK) | NUMBER(10) | ID Specializare |
| 📅 data_obtinere | DATE | Data obținerii |
| 📜 certificat_nr | VARCHAR2(20) | Număr certificat |

### 🤒 PACIENT_ALERGIE
| Atribut | Tip | Descriere |
|---------|-----|-----------|
| 🔑 id_pacient (PK, FK) | NUMBER(10) | ID Pacient |
| 🔑 id_alergie (PK, FK) | NUMBER(10) | ID Alergie |
| 📅 data_diagnosticare | DATE | Data diagnosticării |
| 📊 severitate | NUMBER(1) | Nivel severitate (1-5) |
| 📝 observatii | VARCHAR2(500) | Observații |

## 🔗 Relații între Entități

1. PACIENT --(1:N)-- PROGRAMARE --(N:1)-- MEDIC
2. PROGRAMARE --(1:1)-- CONSULTATIE
3. MEDIC --(N:1)-- DEPARTAMENT
4. CONSULTATIE --(1:1)-- RETETA
5. RETETA --(1:N)-- RETETA_MEDICAMENT --(N:1)-- MEDICAMENT
6. MEDIC --(1:N)-- MEDIC_SPECIALIZARE --(N:1)-- SPECIALIZARE
7. PACIENT --(1:N)-- PACIENT_ALERGIE --(N:1)-- ALERGIE

## ⚡ Constrângeri și Observații

1. ✅ PACIENT → PROGRAMARE → MEDIC
   - Un pacient poate avea multiple programări
   - Un medic poate avea multiple programări
   - Fiecare programare trebuie să aibă exact un pacient și un medic

2. ✅ PROGRAMARE → CONSULTATIE
   - O programare poate avea maxim o consultație
   - O consultație trebuie să aparțină exact unei programări

3. ✅ MEDIC → DEPARTAMENT
   - Un medic aparține exact unui departament
   - Un departament poate avea mai mulți medici

4. ✅ CONSULTATIE → RETETA
   - O consultație poate genera maxim o rețetă
   - O rețetă aparține exact unei consultații

5. ✅ RETETA → RETETA_MEDICAMENT → MEDICAMENT
   - O rețetă poate conține multiple medicamente
   - Un medicament poate apărea pe multiple rețete
   - Fiecare asociere rețetă-medicament are propriile specificații (cantitate, dozaj)

6. ✅ MEDIC → MEDIC_SPECIALIZARE → SPECIALIZARE
   - Un medic poate avea multiple specializări
   - O specializare poate fi deținută de mai mulți medici
   - Fiecare asociere medic-specializare are data obținerii și număr certificat

7. ✅ PACIENT → PACIENT_ALERGIE → ALERGIE
   - Un pacient poate avea multiple alergii
   - O alergie poate fi asociată mai multor pacienți
   - Fiecare asociere pacient-alergie are propriul nivel de severitate

8. ✅ Constrângeri Generale
   - Toate cheile externe trebuie să respecte integritatea referențială
   - Datele temporale trebuie să fie valide și consistente
   - Codurile unice (CNP, nr_licenta, etc.) trebuie să fie unice în tabelele respective

## 🎯 Beneficii Structură

- ✨ Normalizarea completă a datelor (3NF)
- 🔒 Integritate referențială strictă
- 🔄 Flexibilitate în gestionarea relațiilor complexe
- 🎯 Eliminarea redundanței datelor
- 📊 Trasabilitate completă a activităților medicale

## 🔢 Codificarea ID-urilor

### Structura ID-urilor
Toate ID-urile sunt de tip NUMBER(10) și urmează următoarea structură de codificare:

| Prefix | Entitate | Exemplu | Descriere |
|--------|----------|---------|-----------|
| 1xxx... | PACIENT | 1000001 | ID-uri pentru pacienți |
| 2xxx... | MEDIC | 2000001 | ID-uri pentru medici |
| 3xxx... | DEPARTAMENT | 3000001 | ID-uri pentru departamente |
| 4xxx... | PROGRAMARE | 4000001 | ID-uri pentru programări |
| 5xxx... | CONSULTATIE | 5000001 | ID-uri pentru consultații |
| 6xxx... | RETETA | 6000001 | ID-uri pentru rețete |
| 7xxx... | MEDICAMENT | 7000001 | ID-uri pentru medicamente |
| 8xxx... | ALERGIE | 8000001 | ID-uri pentru alergii |
| 9xxx... | SPECIALIZARE | 9000001 | ID-uri pentru specializări |

### Observații despre Codificare
- ✅ Fiecare entitate are propriul prefix pentru identificare rapidă
- ✅ Numerotarea începe de la xxx001 pentru fiecare categorie
- ✅ Permite până la 999,999 înregistrări per entitate
- ✅ Facilitează identificarea rapidă a tipului de entitate
- ✅ Ajută la depanare și urmărirea relațiilor între tabele
