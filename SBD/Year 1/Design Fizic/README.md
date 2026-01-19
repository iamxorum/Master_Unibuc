

# 🔍 Analiza Normalizării - CareConnect

## 1️⃣ Atribut Multivaloare (Repetitiv)

### Exemplu: Specializările unui Medic
În modelul inițial, un medic ar putea avea mai multe specializări stocate într-un singur câmp, ceea ce încalcă principiul atomicității (FN1):

**Tabel MEDIC (neformal, înainte de normalizare):**
| id_medic | nume    | specializari                    |
|----------|---------|--------------------------------|
| 1        | Dr. Pop | cardiologie, pediatrie         |
| 2        | Dr. Ion | neurologie, psihiatrie, geriatrie |

**Probleme identificate:**
- Câmpul 'specializari' conține multiple valori
- Nu se pot face căutări eficiente după o specializare specifică
- Dificultate în adăugarea sau eliminarea unei specializări
- Imposibilitatea stocării informațiilor adiționale despre specializare

**Soluția (FN1):**

## 1. Crearea tabelei SPECIALIZARE:
| id_specializare | denumire    | descriere | nivel  |
|----------------|-------------|-----------|--------|
| 1              | cardiologie | ...       | senior |
| 2              | pediatrie   | ...       | primar |

## 2. Crearea tabelei de joncțiune MEDIC_SPECIALIZARE:
| id_medic | id_specializare | data_obtinere | nr_certificat  |
|----------|----------------|---------------|----------------|
| 1        | 1              | 2020-01-01    | CARD2020/001  |
| 1        | 2              | 2018-06-15    | PED2018/123   |

Această soluție:
- Elimină atributul multivaloare (specializări) din tabela MEDIC
- Creează o tabelă separată pentru SPECIALIZARE cu propriile atribute
- Folosește o tabelă de joncțiune pentru a gestiona relația many-to-many
- Permite stocarea informațiilor adiționale despre fiecare specializare a medicului (data_obtinere, nr_certificat)


## 2️⃣ Tabel în FN1 dar nu în FN2

### Exemplu: Consultație 
**Tabel inițial (în FN1 dar nu în FN2):**

CONSULTATIE(id_consultatie, id_programare, nume_medic, specializare_medic, grad_medic, diagnostic, observatii)

**Probleme identificate:**
1. Dependențe parțiale:
   - nume_medic → id_medic (vine din programare)
   - specializare_medic → id_medic
   - grad_medic → id_medic
2. Informațiile despre medic sunt redundante și pot deveni inconsistente

**Soluția (FN2):**

1. Tabel CONSULTATIE:
CONSULTATIE(id_consultatie, id_programare, diagnostic, observatii)

2. Informațiile despre medic sunt păstrate în tabelul MEDIC și accesate prin id_medic din PROGRAMARE:
MEDIC(id_medic, nume_medic, specializare_medic, grad_medic)

## 3️⃣ Tabel în FN2 dar nu în FN3

### Exemplu: Departament 
**Tabel inițial (în FN2 dar nu în FN3):**

DEPARTAMENT(id_departament, nume_departament, id_sef_departament, nume_sef, grad_sef, telefon_sef, email_sef, data_numire_sef)

**Probleme identificate - Dependențe tranzitive:**
1. id_departament → id_sef_departament → nume_sef
2. id_departament → id_sef_departament → grad_sef
3. id_departament → id_sef_departament → telefon_sef
4. id_departament → id_sef_departament → email_sef

Această structură creează:
- Redundanță în date
- Risc de inconsistență
- Dificultăți la actualizare

**Soluția (FN3):**

1. Tabel DEPARTAMENT (informații de bază):
DEPARTAMENT(id_departament, nume_departament, id_sef_departament)

2. Informațiile despre șef sunt păstrate în tabelul MEDIC:
MEDIC(id_medic, nume, grad, telefon, email)
