# 🏥 CareConnect - Implementare Bază de Date Oracle

## 🔄 Ordinea de Implementare

### 1️⃣ Creare User și Tablespace (`1_creare.sql`)
- Creare user `ddsys` cu drepturi necesare
- Creare tablespace-uri separate pentru date și indexuri:
  - `careconnect_data`: 100MB pentru date
  - `careconnect_index`: 50MB pentru indexuri
- ⚠️ Important: Drepturile necesare trebuie acordate înainte de crearea obiectelor

### 2️⃣ Creare Tabele (`2_tables.sql`)
Ordinea de creare este importantă datorită dependențelor:

1. Tabele independente (fără FK):
   - PACIENT
   - DEPARTAMENT
   - SPECIALIZARE
   - ALERGIE
   - MEDICAMENT

2. Tabele cu dependențe simple:
   - MEDIC (depinde de DEPARTAMENT)
   - PROGRAMARE (depinde de PACIENT și MEDIC)
   - CONSULTATIE (depinde de PROGRAMARE)
   - RETETA (depinde de CONSULTATIE)

3. Tabele asociative (many-to-many):
   - RETETA_MEDICAMENT
   - MEDIC_SPECIALIZARE
   - PACIENT_ALERGIE

4. Constrângeri circulare:
   - Relația MEDIC-DEPARTAMENT (șef departament) necesită ALTER TABLE

### 3️⃣ Definire Secvențe (`3_secvente.sql`)
- Creare secvențe pentru generarea automată a ID-urilor
- Prefix-uri distincte pentru fiecare tip de entitate:
  - 1xxx... pentru PACIENT
  - 2xxx... pentru MEDIC
  - 3xxx... pentru DEPARTAMENT
  - etc.
- 🎯 Avantaj: Identificare ușoară a tipului de entitate după ID

### 4️⃣ Creare trigger-uri (`4_trigger.sql`)
- Creare trigger-uri pentru validare și control

### 5️⃣ Inserare Date (`5_inregistrari.sql`)
Ordinea inserării trebuie să respecte dependențele:

1. Mai întâi tabelele independente
2. Apoi tabelele dependente, în ordinea dependențelor
3. La final tabelele asociative

## 🔑 Aspecte Importante

- Toate ID-urile sunt de tip NUMBER(10)
- Se folosește SAVEPOINT pentru control tranzacțional
- Constrângeri de integritate implementate prin:
  - Chei primare (PRIMARY KEY)
  - Chei externe (FOREIGN KEY)
  - Constrângeri CHECK pentru validări
  - Constrângeri UNIQUE pentru unicitate

### 6️⃣ Drop (`6_drop.sql`)
- Drop toate obiectele create