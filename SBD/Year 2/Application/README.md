# CareConnect Security

## Structura Proiectului

```
Application/
├── docker-compose.yml              # Oracle XE 21c container
├── cli.py                          # Aplicație CLI Python
├── requirements.txt                # Dependențe Python
├── database/init/
│   ├── 01_schema.sql              # Tabele, secvențe
│   ├── 02_encryption.sql           # Criptare AES-256 (CNP)
│   ├── 03_views.sql                # Views cu mascare date
│   ├── 04_privileges.sql          # RBAC - roluri, profile
│   ├── 05_rls_policies.sql        # VPD (Row-Level Security)
│   ├── 06_audit.sql               # Audit (standard, trigger, FGA)
│   ├── 07_app_procedures.sql      # Funcții/proceduri PL/SQL
│   └── 08_insert_mock.sql         # Date demo
└── README.md
```

## Schema Bazei de Date

```
DEPARTAMENT (1) ──< PERSONAL_MEDICAL (N)
                        │
                        │ (1:N)
                        ▼
PACIENT (1) ──< FISA_MEDICALA (N)
```

**Tabele principale:**
- `departament` - Departamente medicale
- `personal_medical` - Personal cu roluri (RECEPȚIE/ASISTENT/MEDIC/ADMIN)
- `pacient` - CNP criptat (RAW), date personale
- `fisa_medicala` - Fișe cu nivel_confidentialitate (1-3)
- `encryption_keys` - Chei AES-256 pentru CNP
- `audit_log` - Loguri de audit

## Matrice de Privilegii

| Obiect | RECEPȚIE (1) | ASISTENT (2) | MEDIC (3) | ADMIN (4) |
|--------|--------------|-------------|-----------|-----------|
| `departament` | R | R | R | CRUD |
| `personal_medical` | R | R | R | CRUD |
| `pacient` | CR | CR | CRU | CRUD |
| `fisa_medicala` | R (VPD=1) | R (VPD≤2) | CRU | CRUD |
| `encryption_keys` | - | - | R | CRUD |
| `audit_log` | - | - | - | R |
| `encrypt_cnp` | ✓ | ✓ | ✓ | ✓ |
| `decrypt_cnp_audited` | - | - | ✓ | ✓ |

## Quick Start

```bash
# 1. Pornire Oracle
docker-compose up -d
# Așteaptă ~2-3 minute

# 2. Instalare dependențe
pip install -r requirements.txt

# 3. Rulare CLI
python cli.py
```

## Utilizatori Demo

| User | Parolă | Rol | Grad |
|------|--------|-----|------|
| ANA_POPESCU | Medic2026! | MEDIC | 3 |
| MIHAI_IONESCU | Asistent2026! | ASISTENT | 2 |
| ELENA_MARINESCU | Receptie2026! | RECEPȚIE | 1 |
| ADMIN_SYSTEM | Admin2026! | ADMIN | 4 |

**Conectare DB:**
- Host: `localhost:1521`
- Service: `XEPDB1`
- User: `careconnect` / Password: `CareConnect123!`

## Funcționalități de Securitate

### 1. Criptare (AES-256)
- CNP-ul pacienților criptat cu `DBMS_CRYPTO`
- Funcții: `encrypt_cnp()`, `decrypt_cnp_audited()`
- Rotire chei: `rotate_encryption_key()`

### 2. RBAC (Role-Based Access Control)
- 4 roluri ierarhice: `ROL_RECEPTIE` → `ROL_ASISTENT` → `ROL_MEDIC` → `ROL_ADMIN`
- Profile Oracle cu limite (sessions, CPU, idle_time, password)
- Privilegii incrementale pe obiecte

### 3. VPD (Virtual Private Database)
- Policy pe `FISA_MEDICALA`: filtrează după `nivel_confidentialitate <= grad_acces`
- Context aplicație: `CARECONNECT_CTX` setat la logon
- Trigger logon: `trg_set_context_on_logon`

### 4. Mascare Date
- Views per rol cu date mascate (telefon, email, adresă, CNP parțial)
- Funcții: `mask_telefon()`, `mask_email()`, `mask_adresa()`, `mask_cnp_partial()`

### 5. Auditare
- **Standard**: `AUDIT` pe tabele/funcții
- **Trigger**: `trg_audit_*` pe INSERT/UPDATE/DELETE
- **FGA**: Politici pe acces CNP, fișe confidențiale, chei criptare
- Tabel: `audit_log` cu tipuri (TRIGGER, FGA, DECRYPT, GRANT)

### 6. PL/SQL API
- Funcții pipelined: `get_pacienti()`, `get_fise_medicale()`, `get_personal()`, `get_audit_log()`
- Proceduri CRUD: `add_/update_/delete_pacient`, `add_/update_/delete_fisa_medicala`, `add_/update_/delete_personal`
- Helper: `get_grad_acces()`, `get_role_name()`, `get_pacient_cnp_decriptat()`

## Comenzi Utile

```bash
docker-compose up -d          # Pornire
docker-compose down           # Oprire
docker-compose down -v        # Reset complet
docker logs -f careconnect-oracle
docker exec -it careconnect-oracle sqlplus careconnect/CareConnect123!@XEPDB1
```