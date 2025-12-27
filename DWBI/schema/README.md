# TickLy - Diagrama Conceptuală Extinsă OLTP

## 📋 ENTITĂȚI PRINCIPALE (Independente)

### 1. **CLIENT** (entitate părinte)
**PK:** `client_id`  
**Atribute:**
- `client_id` (PK, IDENTITY)
- `email` (UNIQUE, NOT NULL)
- `phone`
- `registration_date` (DEFAULT SYSDATE)
- `client_type` ('F' sau 'J')

**FK:** -  
**Relații:**
- 1:M → Ticket
- 1:M → Comment (prin client_id FK)
- 1:M → Adresa

---

### 2. **CLIENT_FIZICA** (subentitate)
**PK:** `client_id` (FK → Client)  
**Atribute:**
- `client_id` (PK, FK → Client)
- `cnp` (UNIQUE, NOT NULL)
- `nume` (NOT NULL)
- `prenume` (NOT NULL)
- `data_nasterii`

**FK:** `client_id` → Client

---

### 3. **CLIENT_JURIDICA** (subentitate)
**PK:** `client_id` (FK → Client)  
**Atribute:**
- `client_id` (PK, FK → Client)
- `cui` (UNIQUE, NOT NULL)
- `denumire` (NOT NULL)
- `sediu_social`
- `numar_inregistrare`
- `reprezentant_legal`

**FK:** `client_id` → Client

---

### 4. **ADRESA** (entitate nouă)
**PK:** `adresa_id`  
**Atribute:**
- `adresa_id` (PK, IDENTITY)
- `strada` (NOT NULL)
- `numar`
- `oras` (NOT NULL)
- `judet`
- `cod_postal`
- `tara` (DEFAULT 'Romania')
- `tip_adresa` ('FACTURARE', 'LIVRARE', 'SEDIU')
- `este_principala` ('Y'/'N')

**FK:** `client_id` → Client (M:1)

---

### 5. **AGENT**
**PK:** `agent_id`  
**Atribute:**
- `agent_id` (PK, IDENTITY)
- `nume` (NOT NULL)
- `prenume` (NOT NULL)
- `email` (UNIQUE, NOT NULL)
- `telefon`
- `hire_date` (DEFAULT SYSDATE)
- `is_active` ('Y'/'N')

**FK:** -  
**Relații:**
- 1:M → KB_Article
- 1:M → Comment (prin agent_id FK)
- 1:M → Solutie
- M:N → Departament (prin Agent_Departament)
- M:N → Ticket (prin Ticket_Agent)

---

### 6. **DEPARTAMENT**
**PK:** `departament_id`  
**Atribute:**
- `departament_id` (PK, IDENTITY)
- `nume` (UNIQUE, NOT NULL)
- `descriere`
- `manager_id` (FK → Agent, NOT NULL)

**FK:** `manager_id` → Agent (M:1, NOT NULL)  
**Relații:**
- 1:M → Ticket
- M:N → Agent (prin Agent_Departament)
- M:1 → Agent (prin manager_id)

---

### 7. **PRIORITATE**
**PK:** `prioritate_id`  
**Atribute:**
- `prioritate_id` (PK, IDENTITY)
- `nivel` (1-5, UNIQUE, NOT NULL)
- `nume` (UNIQUE, NOT NULL)
- `descriere`
- `timp_raspuns_ore`

**FK:** -  
**Relații:**
- 1:M → Ticket

---

### 8. **STATUS**
**PK:** `status_id`  
**Atribute:**
- `status_id` (PK, IDENTITY)
- `nume` (UNIQUE, NOT NULL)
- `descriere`
- `este_final` ('Y'/'N')

**FK:** -  
**Relații:**
- 1:M → Ticket

---

### 9. **TOPIC** (entitate părinte)
**PK:** `topic_id`  
**Atribute:**
- `topic_id` (PK, IDENTITY)
- `nume` (NOT NULL)
- `descriere`
- `topic_type` ('S' sau 'P')

**FK:** -  
**Relații:**
- M:N → Ticket (prin Ticket_Topic)
- 1:1 → Topic_Serviciu sau Topic_Produs

---

### 10. **TOPIC_SERVICIU** (subentitate)
**PK:** `topic_id` (FK → Topic)  
**Atribute:**
- `topic_id` (PK, FK → Topic)
- `tip_serviciu` (NOT NULL)
- `durata_estimata`
- `tarif`

**FK:** `topic_id` → Topic

---

### 11. **TOPIC_PRODUS** (subentitate)
**PK:** `topic_id` (FK → Topic)  
**Atribute:**
- `topic_id` (PK, FK → Topic)
- `versiune`
- `categorie`
- `pret`
- `stoc`

**FK:** `topic_id` → Topic

---

### 12. **CATEGORIE** (entitate nouă)
**PK:** `categorie_id`  
**Atribute:**
- `categorie_id` (PK, IDENTITY)
- `nume` (UNIQUE, NOT NULL)
- `descriere`
- `categorie_parinte_id` (FK → Categorie - auto-referință)

**FK:** 
- `categorie_parinte_id` → Categorie (auto-referință)  
**Relații:**
- 1:M → KB_Article

---

### 13. **TICKET**
**PK:** `ticket_id`  
**Atribute:**
- `ticket_id` (PK, IDENTITY)
- `titlu` (NOT NULL)
- `descriere` (CLOB)
- `data_creare` (DEFAULT SYSDATE, NOT NULL)
- `data_rezolvare`
- `data_inchidere`
- `timp_rezolvare_ore`

**FK:**
- `client_id` → Client (M:1)
- `departament_id` → Departament (M:1)
- `prioritate_id` → Prioritate (M:1)
- `status_id` → Status (M:1)
- `categorie_id` → Categorie (M:1, nullable)

**Relații:**
- 1:M → Comment
- 1:M → Atașament
- 1:1 → Feedback
- 1:1 → Solutie
- M:N → Agent (prin Ticket_Agent)
- M:N → Topic (prin Ticket_Topic)
- M:N → Tag (prin Ticket_Tag)
- M:1 → Categorie

---

### 14. **COMMENT**
**PK:** `comment_id`  
**Atribute:**
- `comment_id` (PK, IDENTITY)
- `content` (CLOB, NOT NULL)
- `created_date` (DEFAULT SYSDATE, NOT NULL)
- `is_internal` ('Y'/'N')
- `client_id` (nullable)
- `agent_id` (nullable)

**FK:**
- `ticket_id` → Ticket (M:1)
- `client_id` → Client (M:1, nullable)
- `agent_id` → Agent (M:1, nullable)

**Constraint:** Exact unul dintre `client_id` sau `agent_id` trebuie să fie NOT NULL

**Relații:**
- M:1 → Ticket
- M:1 → Client (când client_id IS NOT NULL)
- M:1 → Agent (când agent_id IS NOT NULL)

---

### 15. **ATASAMENT**
**PK:** `atasament_id`  
**Atribute:**
- `atasament_id` (PK, IDENTITY)
- `file_name` (NOT NULL)
- `file_path` (NOT NULL)
- `file_size`
- `file_type`
- `upload_date` (DEFAULT SYSDATE, NOT NULL)
- `uploader_id` (NOT NULL)
- `uploader_type` ('C'/'A', NOT NULL)

**FK:**
- `ticket_id` → Ticket (M:1, nullable)
- `kb_article_id` → KB_Article (M:1, nullable)

**Constraint:** Exact unul dintre ticket_id sau kb_article_id trebuie să fie NOT NULL

---

### 16. **KB_ARTICLE**
**PK:** `kb_article_id`  
**Atribute:**
- `kb_article_id` (PK, IDENTITY)
- `titlu` (NOT NULL)
- `content` (CLOB, NOT NULL)
- `keywords`
- `vizualizari` (DEFAULT 0)
- `rating_mediu`
- `data_creare` (DEFAULT SYSDATE, NOT NULL)
- `data_actualizare`
- `este_public` ('Y'/'N')

**FK:**
- `agent_id` → Agent (M:1)
- `categorie_id` → Categorie (M:1)

**Relații:**
- 1:M → Atașament

---

## 📋 ENTITĂȚI SUPLIMENTARE

### 17. **TAG**
**PK:** `tag_id`  
**Atribute:**
- `tag_id` (PK, IDENTITY)
- `nume` (UNIQUE, NOT NULL)
- `culoare`
- `descriere`

**FK:** -  
**Relații:**
- M:N → Ticket (prin Ticket_Tag)

---

### 18. **FEEDBACK**
**PK:** `feedback_id`  
**Atribute:**
- `feedback_id` (PK, IDENTITY)
- `rating` (1-5)
- `comentariu`
- `data_feedback` (DEFAULT SYSDATE, NOT NULL)

**FK:**
- `ticket_id` → Ticket (1:1, UNIQUE)

---

### 19. **SOLUTIE**
**PK:** `solutie_id`  
**Atribute:**
- `solutie_id` (PK, IDENTITY)
- `descriere_solutie` (CLOB, NOT NULL)
- `pasi_rezolvare` (CLOB)
- `data_rezolvare` (DEFAULT SYSDATE, NOT NULL)
- `timp_rezolvare_minute`

**FK:**
- `ticket_id` → Ticket (1:1, UNIQUE)
- `agent_id` → Agent (M:1)

---

## 📋 TABELE ASOCIATIVE (M:N)

### 20. **TICKET_AGENT** (M:N)
**PK:** (`ticket_id`, `agent_id`)  
**Atribute:**
- `ticket_id` (PK, FK → Ticket)
- `agent_id` (PK, FK → Agent)
- `rol` ('PRIMARY', 'SECONDARY', 'OBSERVER')
- `data_asignare` (DEFAULT SYSDATE, NOT NULL)

**FK:**
- `ticket_id` → Ticket
- `agent_id` → Agent

---

### 21. **TICKET_TOPIC** (M:N)
**PK:** (`ticket_id`, `topic_id`)  
**Atribute:**
- `ticket_id` (PK, FK → Ticket)
- `topic_id` (PK, FK → Topic)
- `relevanta` ('DIRECT', 'INDIRECT')

**FK:**
- `ticket_id` → Ticket
- `topic_id` → Topic

---

### 22. **AGENT_DEPARTAMENT** (M:N)
**PK:** (`agent_id`, `departament_id`)  
**Atribute:**
- `agent_id` (PK, FK → Agent)
- `departament_id` (PK, FK → Departament)
- `este_principal` ('Y'/'N')
- `data_inceput` (DEFAULT SYSDATE, NOT NULL)
- `data_sfarsit`

**FK:**
- `agent_id` → Agent
- `departament_id` → Departament

---

### 23. **TICKET_TAG** (M:N)
**PK:** (`ticket_id`, `tag_id`)  
**Atribute:**
- `ticket_id` (PK, FK → Ticket)
- `tag_id` (PK, FK → Tag)

**FK:**
- `ticket_id` → Ticket
- `tag_id` → Tag

---

## 🔗 REZUMAT RELAȚII

### Relații 1:M (One-to-Many):
- Client → Ticket
- Client → Comment (prin client_id FK)
- Client → Adresa
- Agent → KB_Article
- Agent → Comment (prin agent_id FK)
- Agent → Solutie
- Agent → Departament (prin manager_id FK)
- Departament → Ticket
- Prioritate → Ticket
- Status → Ticket
- Ticket → Comment
- Ticket → Atașament
- Topic → (Topic_Serviciu sau Topic_Produs)
- Categorie → KB_Article
- Categorie → Ticket
- Categorie → Categorie (auto-referință)

### Relații 1:1 (One-to-One):
- Ticket → Feedback
- Ticket → Solutie

### Relații M:N (Many-to-Many):
- Ticket ↔ Agent (prin Ticket_Agent)
- Ticket ↔ Topic (prin Ticket_Topic)
- Ticket ↔ Tag (prin Ticket_Tag)
- Agent ↔ Departament (prin Agent_Departament)

### Specializări (IS-A):
- Client → Client_Fizica / Client_Juridica
- Topic → Topic_Serviciu / Topic_Produs
