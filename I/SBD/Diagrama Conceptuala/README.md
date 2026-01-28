# 🏥 Diagrama Conceptuală (CDM) - CareConnect

## 📝 Scop și Viziune
Această diagramă conceptuală reprezintă o vedere de ansamblu a sistemului medical CareConnect, concentrându-se pe conceptele cheie și relațiile dintre ele.

## 🎯 Entități și Relații Principale

### 👤 PACIENT
- Poate cere PROGRAMARE
- Poate avea ALERGII
- Istoricul medical este reflectat prin consultațiile și rețetele asociate

### 📅 PROGRAMARE 
- Este cerută de PACIENT
- Este gestionată de MEDIC
- Devine CONSULTAȚIE daca programarea nu este anulata

### 👨‍⚕️ MEDIC
- Gestionează PROGRAMĂRI
- Are SPECIALIZĂRI
- Aparține unui DEPARTAMENT

### 🏢 DEPARTAMENT
- Organizează MEDICI pe specialități
- Gestionează resurse și capacități

### 🩺 CONSULTAȚIE
- Rezultă din PROGRAMARE
- Poate genera REȚETĂ

### 📋 REȚETĂ
- Este generată din CONSULTAȚIE
- Conține MEDICAMENTE

### 💊 MEDICAMENT
- Este inclus în REȚETĂ
- Are specificații și instrucțiuni

### ⚠️ ALERGII
- Sunt asociate PACIENTULUI
- Importante pentru siguranța tratamentului

### 🎓 SPECIALIZARE
- Este deținută de MEDIC
- Definește aria de expertiză

## 🔄 Fluxul Principal de Lucru

### 👤 Relații PACIENT
- 🏥 PACIENT ➡️ PROGRAMARE (0..N)
  - Un pacient poate avea zero sau mai multe programări
- 🚨 PACIENT ➡️ ALERGII (0..N)
  - Un pacient poate avea zero sau mai multe alergii înregistrate

### 👨‍⚕️ Relații MEDIC
- 📅 MEDIC ➡️ PROGRAMARE (0..N)
  - Un medic poate gestiona zero sau mai multe programări
- 🎓 MEDIC ➡️ SPECIALIZARE (0..N) | SPECIALIZARE ➡️ MEDIC (1..N)
  - Un medic poate avea zero sau mai multe specializări
  - O specializare trebuie să fie deținută de cel puțin un medic
- 🏢 MEDIC ➡️ DEPARTAMENT (1..1) | DEPARTAMENT ➡️ MEDIC (1..N)
  - Un medic aparține exact unui departament
  - Un departament are cel puțin un medic
- 👑 DEPARTAMENT ➡️ MEDIC ȘEF (1..1)
  - Un departament are exact un medic șef

### 🩺 Lanțul Consultației
- 📋 PROGRAMARE ➡️ CONSULTAȚIE (0..1)
  - O programare poate rezulta în zero sau o consultație
- 💊 CONSULTAȚIE ➡️ REȚETĂ (0..1)
  - O consultație poate genera zero sau o rețetă
- 💊 REȚETĂ ➡️ MEDICAMENTE (1..N)
  - O rețetă conține cel puțin un medicament