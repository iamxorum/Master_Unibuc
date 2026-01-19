# CareConnect Security

Proiect SBD Year 2 - Securitatea Bazelor de Date Oracle

## Descriere

Aplicație bazată pe schema CareConnect (Year 1) adaptată pentru demonstrarea conceptelor de securitate în Oracle Database.

## Structura Proiectului

```
Application/
├── docker-compose.yml          # Oracle XE 21c container
├── database/
│   ├── init/
│   │   └── 01_schema.sql       # Schema de bază (4 tabele)
│   ├── 02_encryption.sql       # TODO: Criptare CNP cu DBMS_CRYPTO
│   ├── 03_audit.sql            # TODO: Trigger-i și politici de audit
│   ├── 04_roles.sql            # TODO: RBAC - roluri și privilegii
│   ├── 05_masking.sql          # TODO: Views pentru mascare date
│   └── 06_app_security.sql     # TODO: Context aplicație + anti-injection
├── frontend/                   # TODO: React mini-app
└── README.md
```

## Schema Bazei de Date

### Entități (simplificat din CareConnect Year 1)

```
┌─────────────────┐     ┌─────────────────────┐
│   DEPARTAMENT   │     │   PERSONAL_MEDICAL  │
├─────────────────┤     ├─────────────────────┤
│ id_departament  │◄────│ id_departament (FK) │
│ nume_departament│     │ id_personal         │
│ locatie         │     │ nume, prenume, cnp  │
│ telefon_contact │     │ rol (RBAC)          │
└─────────────────┘     │ grad_acces (MAC)    │
                        │ username_db         │
                        └──────────┬──────────┘
                                   │
                                   │ 1:N
                                   ▼
┌─────────────────┐     ┌─────────────────────┐
│     PACIENT     │     │    FISA_MEDICALA    │
├─────────────────┤     ├─────────────────────┤
│ id_pacient      │◄────│ id_pacient (FK)     │
│ nume, prenume   │     │ id_medic (FK)       │
│ cnp (CRIPTAT)   │     │ diagnostic          │
│ adresa (MASCAT) │     │ tratament           │
│ data_nasterii   │     │ nivel_confident.    │
└─────────────────┘     └─────────────────────┘
```

## Quick Start

### 1. Pornire Oracle

```bash
docker-compose up -d
```

Așteaptă ~2-3 minute pentru inițializare. Verifică:

```bash
docker logs -f careconnect-oracle
```

### 2. Conectare

**DataGrip / SQL Developer:**
- Host: `localhost`
- Port: `1521`
- Service: `XEPDB1`
- User: `careconnect`
- Password: `CareConnect123!`

**SQLPlus (din container):**
```bash
docker exec -it careconnect-oracle sqlplus careconnect/CareConnect123!@XEPDB1
```

## Cerințe de Securitate Implementate

| # | Cerință | Status | Fișier |
|---|---------|--------|--------|
| 2 | Criptarea datelor | ⏳ TODO | `02_encryption.sql` |
| 3 | Auditarea activităților | ⏳ TODO | `03_audit.sql` |
| 4 | Gestiunea utilizatorilor | ⏳ TODO | `04_roles.sql` |
| 5 | Privilegii și roluri | ⏳ TODO | `04_roles.sql` |
| 6 | SQL Injection | ⏳ TODO | `06_app_security.sql` |
| 7 | Mascarea datelor | ⏳ TODO | `05_masking.sql` |

## Pași Următori

1. [ ] Pornește containerul și verifică schema
2. [ ] Implementează criptarea CNP-ului (DBMS_CRYPTO)
3. [ ] Adaugă trigger-i de audit
4. [ ] Creează roluri și privilegii (RBAC)
5. [ ] Implementează views pentru mascare
6. [ ] Creează aplicația React
7. [ ] Adaugă protecție SQL Injection

## Comenzi Utile

```bash
# Pornire
docker-compose up -d

# Oprire
docker-compose down

# Oprire + ștergere volume (reset complet)
docker-compose down -v

# Logs
docker logs -f careconnect-oracle

# Shell în container
docker exec -it careconnect-oracle bash
```
