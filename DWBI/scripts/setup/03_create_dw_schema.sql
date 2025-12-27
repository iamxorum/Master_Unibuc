CREATE TABLE dim_client (
    client_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id NUMBER NOT NULL,
    email VARCHAR2(100),
    phone VARCHAR2(20),
    registration_date DATE,
    client_type CHAR(1),
    nume VARCHAR2(50),
    prenume VARCHAR2(50),
    cnp VARCHAR2(13),
    denumire VARCHAR2(200),
    cui VARCHAR2(20),
    sediu_social VARCHAR2(200),
    reprezentant_legal VARCHAR2(100),
    is_active CHAR(1) DEFAULT 'Y',
    valid_from DATE DEFAULT SYSDATE,
    valid_to DATE,
    is_current CHAR(1) DEFAULT 'Y',
    load_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_dim_client_id UNIQUE (client_id, valid_from)
);

CREATE TABLE dim_agent (
    agent_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id NUMBER NOT NULL,
    nume VARCHAR2(50),
    prenume VARCHAR2(50),
    nume_complet VARCHAR2(101),
    email VARCHAR2(100),
    telefon VARCHAR2(20),
    hire_date DATE,
    is_active CHAR(1),
    ani_experienta NUMBER,
    valid_from DATE DEFAULT SYSDATE,
    valid_to DATE,
    is_current CHAR(1) DEFAULT 'Y',
    load_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_dim_agent_id UNIQUE (agent_id, valid_from)
);

CREATE TABLE dim_departament (
    departament_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    departament_id NUMBER NOT NULL,
    nume VARCHAR2(100),
    descriere VARCHAR2(500),
    manager_nume VARCHAR2(101),
    manager_email VARCHAR2(100),
    numar_agenti NUMBER,
    valid_from DATE DEFAULT SYSDATE,
    valid_to DATE,
    is_current CHAR(1) DEFAULT 'Y',
    load_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_dim_departament_id UNIQUE (departament_id, valid_from)
);

CREATE TABLE dim_categorie (
    categorie_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    categorie_id NUMBER NOT NULL,
    nume VARCHAR2(100),
    descriere VARCHAR2(500),
    categorie_parinte_id NUMBER,
    categorie_parinte_nume VARCHAR2(100),
    nivel_ierarhie NUMBER,
    categorie_completa VARCHAR2(500),
    load_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_dim_categorie_id UNIQUE (categorie_id)
);

CREATE TABLE dim_topic (
    topic_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    topic_id NUMBER NOT NULL,
    nume VARCHAR2(100),
    descriere VARCHAR2(500),
    topic_type CHAR(1),
    tip_serviciu VARCHAR2(50),
    durata_estimata NUMBER,
    tarif NUMBER(10,2),
    versiune VARCHAR2(20),
    pret NUMBER(10,2),
    stoc NUMBER,
    load_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_dim_topic_id UNIQUE (topic_id)
);

CREATE TABLE dim_tag (
    tag_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tag_id NUMBER NOT NULL,
    nume VARCHAR2(50),
    culoare VARCHAR2(20),
    descriere VARCHAR2(200),
    load_date DATE DEFAULT SYSDATE,
    CONSTRAINT uk_dim_tag_id UNIQUE (tag_id)
);

CREATE TABLE dim_time (
    date_key NUMBER PRIMARY KEY,
    data_completa DATE NOT NULL,
    an NUMBER(4) NOT NULL,
    trimestru NUMBER(1) NOT NULL CHECK (trimestru BETWEEN 1 AND 4),
    luna NUMBER(2) NOT NULL CHECK (luna BETWEEN 1 AND 12),
    luna_nume VARCHAR2(20) NOT NULL,
    luna_abrev VARCHAR2(3) NOT NULL,
    zi NUMBER(2) NOT NULL CHECK (zi BETWEEN 1 AND 31),
    saptamana_an NUMBER(2) CHECK (saptamana_an BETWEEN 1 AND 53),
    zi_saptamana NUMBER(1) NOT NULL CHECK (zi_saptamana BETWEEN 1 AND 7),
    zi_saptamana_nume VARCHAR2(20) NOT NULL,
    este_weekend CHAR(1) DEFAULT 'N' CHECK (este_weekend IN ('Y', 'N')),
    este_sarbatoare CHAR(1) DEFAULT 'N' CHECK (este_sarbatoare IN ('Y', 'N')),
    nume_sarbatoare VARCHAR2(100),
    zi_lucratoare NUMBER,
    CONSTRAINT uk_dim_time_data UNIQUE (data_completa)
);

CREATE TABLE fact_ticket (
    fact_ticket_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER NOT NULL,
    
    client_key NUMBER NOT NULL,
    agent_key NUMBER NOT NULL,
    departament_key NUMBER NOT NULL,
    categorie_key NUMBER,
    date_creare_key NUMBER NOT NULL,
    date_rezolvare_key NUMBER,
    date_inchidere_key NUMBER,
    
    status_id NUMBER NOT NULL,
    status_nume VARCHAR2(30) NOT NULL,
    status_este_final CHAR(1),
    status_ordine NUMBER,
    prioritate_id NUMBER NOT NULL,
    prioritate_nivel NUMBER(1) NOT NULL,
    prioritate_nume VARCHAR2(20) NOT NULL,
    prioritate_timp_raspuns_ore NUMBER,
    
    numar_ticketuri NUMBER DEFAULT 1,
    timp_rezolvare_ore NUMBER,
    timp_raspuns_ore NUMBER,
    timp_rezolvare_minute NUMBER,
    rating_feedback NUMBER(1) CHECK (rating_feedback BETWEEN 1 AND 5),
    numar_comentarii NUMBER DEFAULT 0,
    numar_comentarii_client NUMBER DEFAULT 0,
    numar_comentarii_agent NUMBER DEFAULT 0,
    numar_atasamente NUMBER DEFAULT 0,
    cost_estimativ NUMBER(10,2),
    
    load_date DATE DEFAULT SYSDATE,
    
    CONSTRAINT fk_fact_client FOREIGN KEY (client_key) REFERENCES dim_client(client_key),
    CONSTRAINT fk_fact_agent FOREIGN KEY (agent_key) REFERENCES dim_agent(agent_key),
    CONSTRAINT fk_fact_departament FOREIGN KEY (departament_key) REFERENCES dim_departament(departament_key),
    CONSTRAINT fk_fact_categorie FOREIGN KEY (categorie_key) REFERENCES dim_categorie(categorie_key),
    CONSTRAINT fk_fact_date_creare FOREIGN KEY (date_creare_key) REFERENCES dim_time(date_key),
    CONSTRAINT fk_fact_date_rezolvare FOREIGN KEY (date_rezolvare_key) REFERENCES dim_time(date_key),
    CONSTRAINT fk_fact_date_inchidere FOREIGN KEY (date_inchidere_key) REFERENCES dim_time(date_key),
    CONSTRAINT uk_fact_ticket_id UNIQUE (ticket_id)
);

CREATE INDEX idx_fact_client ON fact_ticket(client_key);
CREATE INDEX idx_fact_agent ON fact_ticket(agent_key);
CREATE INDEX idx_fact_departament ON fact_ticket(departament_key);
CREATE INDEX idx_fact_categorie ON fact_ticket(categorie_key);
CREATE INDEX idx_fact_date_creare ON fact_ticket(date_creare_key);
CREATE INDEX idx_fact_date_rezolvare ON fact_ticket(date_rezolvare_key);
CREATE INDEX idx_fact_status ON fact_ticket(status_id);
CREATE INDEX idx_fact_prioritate ON fact_ticket(prioritate_id);
CREATE INDEX idx_fact_ticket_id ON fact_ticket(ticket_id);

CREATE INDEX idx_dim_client_id ON dim_client(client_id);
CREATE INDEX idx_dim_client_current ON dim_client(is_current);
CREATE INDEX idx_dim_agent_id ON dim_agent(agent_id);
CREATE INDEX idx_dim_agent_current ON dim_agent(is_current);
CREATE INDEX idx_dim_departament_id ON dim_departament(departament_id);
CREATE INDEX idx_dim_departament_current ON dim_departament(is_current);
CREATE INDEX idx_dim_time_an ON dim_time(an);
CREATE INDEX idx_dim_time_luna ON dim_time(an, luna);
CREATE INDEX idx_dim_time_trimestru ON dim_time(an, trimestru);

CREATE BITMAP INDEX bmp_fact_status_nume ON fact_ticket(status_nume);
CREATE BITMAP INDEX bmp_fact_status_final ON fact_ticket(status_este_final);
CREATE BITMAP INDEX bmp_fact_prioritate_nivel ON fact_ticket(prioritate_nivel);
CREATE BITMAP INDEX bmp_fact_prioritate_nume ON fact_ticket(prioritate_nume);
CREATE BITMAP INDEX bmp_fact_rating ON fact_ticket(rating_feedback);

CREATE BITMAP INDEX bmp_dim_client_type ON dim_client(client_type);
CREATE BITMAP INDEX bmp_dim_client_active ON dim_client(is_active);
CREATE BITMAP INDEX bmp_dim_client_current ON dim_client(is_current);

CREATE BITMAP INDEX bmp_dim_agent_active ON dim_agent(is_active);
CREATE BITMAP INDEX bmp_dim_agent_current ON dim_agent(is_current);

CREATE BITMAP INDEX bmp_dim_departament_current ON dim_departament(is_current);

CREATE BITMAP INDEX bmp_dim_topic_type ON dim_topic(topic_type);

CREATE BITMAP INDEX bmp_dim_time_weekend ON dim_time(este_weekend);
CREATE BITMAP INDEX bmp_dim_time_sarbatoare ON dim_time(este_sarbatoare);
CREATE BITMAP INDEX bmp_dim_time_trimestru ON dim_time(trimestru);
CREATE BITMAP INDEX bmp_dim_time_luna ON dim_time(luna);
CREATE BITMAP INDEX bmp_dim_time_zi_saptamana ON dim_time(zi_saptamana);
