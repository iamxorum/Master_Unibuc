CREATE TABLE client (
    client_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR2(100) NOT NULL UNIQUE,
    phone VARCHAR2(20),
    registration_date DATE DEFAULT SYSDATE NOT NULL,
    client_type CHAR(1) NOT NULL CHECK (client_type IN ('F', 'J')),
    CONSTRAINT chk_client_type CHECK (client_type IN ('F', 'J'))
);

CREATE TABLE client_fizica (
    client_id NUMBER PRIMARY KEY,
    cnp VARCHAR2(13) NOT NULL UNIQUE,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    data_nasterii DATE,
    CONSTRAINT fk_client_fizica FOREIGN KEY (client_id) REFERENCES client(client_id) ON DELETE CASCADE
);

CREATE TABLE client_juridica (
    client_id NUMBER PRIMARY KEY,
    cui VARCHAR2(20) NOT NULL UNIQUE,
    denumire VARCHAR2(200) NOT NULL,
    sediu_social VARCHAR2(200),
    numar_inregistrare VARCHAR2(50),
    reprezentant_legal VARCHAR2(100),
    CONSTRAINT fk_client_juridica FOREIGN KEY (client_id) REFERENCES client(client_id) ON DELETE CASCADE
);

CREATE TABLE adresa (
    adresa_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id NUMBER NOT NULL,
    tip_adresa VARCHAR2(20) CHECK (tip_adresa IN ('FACTURARE', 'LIVRARE', 'SEDIU')),
    strada VARCHAR2(100) NOT NULL,
    numar VARCHAR2(10),
    oras VARCHAR2(50) NOT NULL,
    judet VARCHAR2(50),
    cod_postal VARCHAR2(10),
    tara VARCHAR2(50) DEFAULT 'Romania',
    este_principala CHAR(1) DEFAULT 'N' CHECK (este_principala IN ('Y', 'N')),
    CONSTRAINT fk_adresa_client FOREIGN KEY (client_id) REFERENCES client(client_id) ON DELETE CASCADE
);

CREATE TABLE agent (
    agent_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) NOT NULL UNIQUE,
    telefon VARCHAR2(20),
    hire_date DATE DEFAULT SYSDATE NOT NULL,
    is_active CHAR(1) DEFAULT 'Y' CHECK (is_active IN ('Y', 'N'))
);

CREATE TABLE departament (
    departament_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL UNIQUE,
    descriere VARCHAR2(500),
    manager_id NUMBER NOT NULL,
    CONSTRAINT fk_departament_manager FOREIGN KEY (manager_id) REFERENCES agent(agent_id)
);

CREATE TABLE prioritate (
    prioritate_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nivel NUMBER(1) NOT NULL UNIQUE CHECK (nivel BETWEEN 1 AND 5),
    nume VARCHAR2(20) NOT NULL UNIQUE,
    descriere VARCHAR2(200),
    timp_raspuns_ore NUMBER
);

CREATE TABLE status (
    status_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nume VARCHAR2(30) NOT NULL UNIQUE,
    descriere VARCHAR2(200),
    este_final CHAR(1) DEFAULT 'N' CHECK (este_final IN ('Y', 'N'))
);

CREATE TABLE topic (
    topic_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL,
    descriere VARCHAR2(500),
    topic_type CHAR(1) NOT NULL CHECK (topic_type IN ('S', 'P')),
    CONSTRAINT chk_topic_type CHECK (topic_type IN ('S', 'P'))
);

CREATE TABLE topic_serviciu (
    topic_id NUMBER PRIMARY KEY,
    tip_serviciu VARCHAR2(50) NOT NULL,
    durata_estimata NUMBER,
    tarif NUMBER(10,2),
    CONSTRAINT fk_topic_serviciu FOREIGN KEY (topic_id) REFERENCES topic(topic_id) ON DELETE CASCADE
);

CREATE TABLE topic_produs (
    topic_id NUMBER PRIMARY KEY,
    versiune VARCHAR2(20),
    categorie VARCHAR2(50),
    pret NUMBER(10,2),
    stoc NUMBER,
    CONSTRAINT fk_topic_produs FOREIGN KEY (topic_id) REFERENCES topic(topic_id) ON DELETE CASCADE
);

CREATE TABLE categorie (
    categorie_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nume VARCHAR2(100) NOT NULL UNIQUE,
    descriere VARCHAR2(500),
    categorie_parinte_id NUMBER,
    CONSTRAINT fk_categorie_parinte FOREIGN KEY (categorie_parinte_id) REFERENCES categorie(categorie_id)
);

CREATE TABLE ticket (
    ticket_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id NUMBER NOT NULL,
    departament_id NUMBER NOT NULL,
    prioritate_id NUMBER NOT NULL,
    status_id NUMBER NOT NULL,
    categorie_id NUMBER,
    titlu VARCHAR2(200) NOT NULL,
    descriere CLOB,
    data_creare DATE DEFAULT SYSDATE NOT NULL,
    data_rezolvare DATE,
    data_inchidere DATE,
    timp_rezolvare_ore NUMBER,
    CONSTRAINT fk_ticket_client FOREIGN KEY (client_id) REFERENCES client(client_id),
    CONSTRAINT fk_ticket_departament FOREIGN KEY (departament_id) REFERENCES departament(departament_id),
    CONSTRAINT fk_ticket_prioritate FOREIGN KEY (prioritate_id) REFERENCES prioritate(prioritate_id),
    CONSTRAINT fk_ticket_status FOREIGN KEY (status_id) REFERENCES status(status_id),
    CONSTRAINT fk_ticket_categorie FOREIGN KEY (categorie_id) REFERENCES categorie(categorie_id)
);

CREATE TABLE comment_client (
    comment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER NOT NULL,
    client_id NUMBER NOT NULL,
    content CLOB NOT NULL,
    created_date DATE DEFAULT SYSDATE NOT NULL,
    is_internal CHAR(1) DEFAULT 'N' CHECK (is_internal IN ('Y', 'N')),
    CONSTRAINT fk_comment_client_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_client_client FOREIGN KEY (client_id) REFERENCES client(client_id) ON DELETE CASCADE
);

CREATE TABLE comment_agent (
    comment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER NOT NULL,
    agent_id NUMBER NOT NULL,
    content CLOB NOT NULL,
    created_date DATE DEFAULT SYSDATE NOT NULL,
    is_internal CHAR(1) DEFAULT 'N' CHECK (is_internal IN ('Y', 'N')),
    CONSTRAINT fk_comment_agent_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_agent_agent FOREIGN KEY (agent_id) REFERENCES agent(agent_id) ON DELETE CASCADE
);

CREATE TABLE kb_article (
    kb_article_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id NUMBER NOT NULL,
    categorie_id NUMBER,
    titlu VARCHAR2(200) NOT NULL,
    content CLOB NOT NULL,
    keywords VARCHAR2(500),
    vizualizari NUMBER DEFAULT 0,
    rating_mediu NUMBER(3,2),
    data_creare DATE DEFAULT SYSDATE NOT NULL,
    data_actualizare DATE,
    este_public CHAR(1) DEFAULT 'Y' CHECK (este_public IN ('Y', 'N')),
    CONSTRAINT fk_kb_agent FOREIGN KEY (agent_id) REFERENCES agent(agent_id),
    CONSTRAINT fk_kb_categorie FOREIGN KEY (categorie_id) REFERENCES categorie(categorie_id)
);

CREATE TABLE atasament (
    atasament_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER,
    kb_article_id NUMBER,
    file_name VARCHAR2(255) NOT NULL,
    file_path VARCHAR2(500) NOT NULL,
    file_size NUMBER,
    file_type VARCHAR2(50),
    upload_date DATE DEFAULT SYSDATE NOT NULL,
    uploader_id NUMBER NOT NULL,
    uploader_type CHAR(1) NOT NULL CHECK (uploader_type IN ('C', 'A')),
    CONSTRAINT fk_atasament_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_atasament_kb FOREIGN KEY (kb_article_id) REFERENCES kb_article(kb_article_id) ON DELETE CASCADE,
    CONSTRAINT chk_atasament_source CHECK (
        (ticket_id IS NOT NULL AND kb_article_id IS NULL) OR
        (ticket_id IS NULL AND kb_article_id IS NOT NULL)
    )
);


CREATE TABLE tag (
    tag_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL UNIQUE,
    culoare VARCHAR2(20),
    descriere VARCHAR2(200)
);

CREATE TABLE feedback (
    feedback_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER NOT NULL UNIQUE,
    rating NUMBER(1) CHECK (rating BETWEEN 1 AND 5),
    comentariu VARCHAR2(1000),
    data_feedback DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_feedback_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE
);

CREATE TABLE solutie (
    solutie_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER NOT NULL UNIQUE,
    agent_id NUMBER NOT NULL,
    descriere_solutie CLOB NOT NULL,
    pasi_rezolvare CLOB,
    data_rezolvare DATE DEFAULT SYSDATE NOT NULL,
    timp_rezolvare_minute NUMBER,
    CONSTRAINT fk_solutie_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_solutie_agent FOREIGN KEY (agent_id) REFERENCES agent(agent_id)
);

CREATE TABLE ticket_agent (
    ticket_id NUMBER NOT NULL,
    agent_id NUMBER NOT NULL,
    rol VARCHAR2(20) DEFAULT 'PRIMARY' CHECK (rol IN ('PRIMARY', 'SECONDARY', 'OBSERVER')),
    data_asignare DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_ticket_agent PRIMARY KEY (ticket_id, agent_id),
    CONSTRAINT fk_ta_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_ta_agent FOREIGN KEY (agent_id) REFERENCES agent(agent_id) ON DELETE CASCADE
);

CREATE TABLE ticket_topic (
    ticket_id NUMBER NOT NULL,
    topic_id NUMBER NOT NULL,
    relevanta VARCHAR2(20) DEFAULT 'DIRECT' CHECK (relevanta IN ('DIRECT', 'INDIRECT')),
    CONSTRAINT pk_ticket_topic PRIMARY KEY (ticket_id, topic_id),
    CONSTRAINT fk_tt_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_tt_topic FOREIGN KEY (topic_id) REFERENCES topic(topic_id) ON DELETE CASCADE
);

CREATE TABLE agent_departament (
    agent_id NUMBER NOT NULL,
    departament_id NUMBER NOT NULL,
    este_principal CHAR(1) DEFAULT 'N' CHECK (este_principal IN ('Y', 'N')),
    data_inceput DATE DEFAULT SYSDATE NOT NULL,
    data_sfarsit DATE,
    CONSTRAINT pk_agent_departament PRIMARY KEY (agent_id, departament_id),
    CONSTRAINT fk_ad_agent FOREIGN KEY (agent_id) REFERENCES agent(agent_id) ON DELETE CASCADE,
    CONSTRAINT fk_ad_departament FOREIGN KEY (departament_id) REFERENCES departament(departament_id) ON DELETE CASCADE
);

CREATE TABLE ticket_tag (
    ticket_id NUMBER NOT NULL,
    tag_id NUMBER NOT NULL,
    CONSTRAINT pk_ticket_tag PRIMARY KEY (ticket_id, tag_id),
    CONSTRAINT fk_ttag_ticket FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    CONSTRAINT fk_ttag_tag FOREIGN KEY (tag_id) REFERENCES tag(tag_id) ON DELETE CASCADE
);

CREATE INDEX idx_ticket_client ON ticket(client_id);
CREATE INDEX idx_ticket_status ON ticket(status_id);
CREATE INDEX idx_ticket_departament ON ticket(departament_id);
CREATE INDEX idx_ticket_categorie ON ticket(categorie_id);
CREATE INDEX idx_comment_client_ticket ON comment_client(ticket_id);
CREATE INDEX idx_comment_client_client ON comment_client(client_id);
CREATE INDEX idx_comment_agent_ticket ON comment_agent(ticket_id);
CREATE INDEX idx_comment_agent_agent ON comment_agent(agent_id);
CREATE INDEX idx_atasament_ticket ON atasament(ticket_id);
CREATE INDEX idx_adresa_client ON adresa(client_id);
