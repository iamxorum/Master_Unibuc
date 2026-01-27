create table dim_client (
   client_key         number generated always as identity primary key,
   client_id          number not null,
   email              varchar2(100),
   phone              varchar2(20),
   registration_date  date,
   client_type        char(1),
   nume               varchar2(50),
   prenume            varchar2(50),
   cnp                varchar2(13),
   denumire           varchar2(200),
   cui                varchar2(20),
   sediu_social       varchar2(200),
   reprezentant_legal varchar2(100),
   is_active          char(1) default 'Y',
   valid_from         date default sysdate,
   valid_to           date,
   is_current         char(1) default 'Y',
   load_date          date default sysdate,
   constraint uk_dim_client_id unique ( client_id,
                                        valid_from )
);

create table dim_agent (
   agent_key      number generated always as identity primary key,
   agent_id       number not null,
   nume           varchar2(50),
   prenume        varchar2(50),
   nume_complet   varchar2(101),
   email          varchar2(100),
   telefon        varchar2(20),
   hire_date      date,
   is_active      char(1),
   ani_experienta number,
   valid_from     date default sysdate,
   valid_to       date,
   is_current     char(1) default 'Y',
   load_date      date default sysdate,
   constraint uk_dim_agent_id unique ( agent_id,
                                       valid_from )
);

create table dim_departament (
   departament_key number generated always as identity primary key,
   departament_id  number not null,
   nume            varchar2(100),
   descriere       varchar2(500),
   manager_nume    varchar2(101),
   manager_email   varchar2(100),
   numar_agenti    number,
   valid_from      date default sysdate,
   valid_to        date,
   is_current      char(1) default 'Y',
   load_date       date default sysdate,
   constraint uk_dim_departament_id unique ( departament_id,
                                             valid_from )
);

create table dim_categorie (
   categorie_key          number generated always as identity primary key,
   categorie_id           number not null,
   nume                   varchar2(100),
   descriere              varchar2(500),
   categorie_parinte_id   number,
   categorie_parinte_nume varchar2(100),
   nivel_ierarhie         number,
   categorie_completa     varchar2(500),
   load_date              date default sysdate,
   constraint uk_dim_categorie_id unique ( categorie_id )
);

create table dim_topic (
   topic_key       number generated always as identity primary key,
   topic_id        number not null,
   nume            varchar2(100),
   descriere       varchar2(500),
   topic_type      char(1),
   tip_serviciu    varchar2(50),
   durata_estimata number,
   tarif           number(10,2),
   versiune        varchar2(20),
   pret            number(10,2),
   stoc            number,
   load_date       date default sysdate,
   constraint uk_dim_topic_id unique ( topic_id )
);

create table dim_tag (
   tag_key   number generated always as identity primary key,
   tag_id    number not null,
   nume      varchar2(50),
   culoare   varchar2(20),
   descriere varchar2(200),
   load_date date default sysdate,
   constraint uk_dim_tag_id unique ( tag_id )
);

create table dim_time (
   date_key          number primary key,
   data_completa     date not null,
   an                number(4) not null,
   trimestru         number(1) not null check ( trimestru between 1 and 4 ),
   luna              number(2) not null check ( luna between 1 and 12 ),
   luna_nume         varchar2(20) not null,
   luna_abrev        varchar2(3) not null,
   zi                number(2) not null check ( zi between 1 and 31 ),
   saptamana_an      number(2) check ( saptamana_an between 1 and 53 ),
   zi_saptamana      number(1) not null check ( zi_saptamana between 1 and 7 ),
   zi_saptamana_nume varchar2(20) not null,
   este_weekend      char(1) default 'N' check ( este_weekend in ( 'Y',
                                                              'N' ) ),
   este_sarbatoare   char(1) default 'N' check ( este_sarbatoare in ( 'Y',
                                                                    'N' ) ),
   nume_sarbatoare   varchar2(100),
   zi_lucratoare     char(1) default 'Y' check ( zi_lucratoare in ( 'Y',
                                                               'N' ) ),
   constraint uk_dim_time_data unique ( data_completa )
);

create table fact_ticket (
   fact_ticket_id              number generated always as identity primary key,
   ticket_id                   number not null,
   client_key                  number not null,
   agent_key                   number not null,
   departament_key             number not null,
   categorie_key               number,
   date_creare_key             number not null,
   date_rezolvare_key          number,
   date_inchidere_key          number,
   status_id                   number not null,
   status_nume                 varchar2(30) not null,
   status_este_final           char(1),
   status_ordine               number,
   prioritate_id               number not null,
   prioritate_nivel            number(1) not null,
   prioritate_nume             varchar2(20) not null,
   prioritate_timp_raspuns_ore number,
   numar_ticketuri             number default 1,
   timp_rezolvare_ore          number,
   timp_raspuns_ore            number,
   timp_rezolvare_minute       number,
   rating_feedback             number(1) check ( rating_feedback between 1 and 5 ),
   numar_comentarii            number default 0,
   numar_comentarii_client     number default 0,
   numar_comentarii_agent      number default 0,
   numar_atasamente            number default 0,
   cost_estimativ              number(10,2),
   load_date                   date default sysdate,
   constraint fk_fact_client foreign key ( client_key )
      references dim_client ( client_key ),
   constraint fk_fact_agent foreign key ( agent_key )
      references dim_agent ( agent_key ),
   constraint fk_fact_departament foreign key ( departament_key )
      references dim_departament ( departament_key ),
   constraint fk_fact_categorie foreign key ( categorie_key )
      references dim_categorie ( categorie_key ),
   constraint fk_fact_date_creare foreign key ( date_creare_key )
      references dim_time ( date_key ),
   constraint fk_fact_date_rezolvare foreign key ( date_rezolvare_key )
      references dim_time ( date_key ),
   constraint fk_fact_date_inchidere foreign key ( date_inchidere_key )
      references dim_time ( date_key ),
   constraint uk_fact_ticket_id unique ( ticket_id )
);

create index idx_fact_client on
   fact_ticket (
      client_key
   );
create index idx_fact_agent on
   fact_ticket (
      agent_key
   );
create index idx_fact_departament on
   fact_ticket (
      departament_key
   );
create index idx_fact_categorie on
   fact_ticket (
      categorie_key
   );
create index idx_fact_date_creare on
   fact_ticket (
      date_creare_key
   );
create index idx_fact_date_rezolvare on
   fact_ticket (
      date_rezolvare_key
   );
create index idx_fact_status on
   fact_ticket (
      status_id
   );
create index idx_fact_prioritate on
   fact_ticket (
      prioritate_id
   );

-- this will fail because we already have an index on ticket_id because it's UNIQUE (CONSTRAINT)
-- CREATE INDEX idx_fact_ticket_id ON fact_ticket(ticket_id);

create index idx_dim_client_id on
   dim_client (
      client_id
   );
create index idx_dim_client_current on
   dim_client (
      is_current
   );
create index idx_dim_agent_id on
   dim_agent (
      agent_id
   );
create index idx_dim_agent_current on
   dim_agent (
      is_current
   );
create index idx_dim_departament_id on
   dim_departament (
      departament_id
   );
create index idx_dim_departament_current on
   dim_departament (
      is_current
   );
create index idx_dim_time_an on
   dim_time (
      an
   );
create index idx_dim_time_luna on
   dim_time (
      an,
      luna
   );
create index idx_dim_time_trimestru on
   dim_time (
      an,
      trimestru
   );

create bitmap index bmp_fact_status_nume on
   fact_ticket (
      status_nume
   );
create bitmap index bmp_fact_status_final on
   fact_ticket (
      status_este_final
   );
create bitmap index bmp_fact_prioritate_nivel on
   fact_ticket (
      prioritate_nivel
   );
create bitmap index bmp_fact_prioritate_nume on
   fact_ticket (
      prioritate_nume
   );
create bitmap index bmp_fact_rating on
   fact_ticket (
      rating_feedback
   );

create bitmap index bmp_dim_client_type on
   dim_client (
      client_type
   );
create bitmap index bmp_dim_client_active on
   dim_client (
      is_active
   );

-- this will throw an error because you already created an index for the same table, for the same column
create bitmap index bmp_dim_client_current on
   dim_client (
      is_current
   );

-- execute the following to get the index name, drop it and then create the bitmap index

-- SELECT i.index_name, i.index_type, i.uniqueness
-- FROM user_indexes i
-- JOIN user_ind_columns c ON c.index_name = i.index_name
-- WHERE c.table_name = 'DIM_CLIENT'
--   AND c.column_name = 'IS_CURRENT'
-- ORDER BY i.index_name;

-- drop index IDX_DIM_CLIENT_CURRENT;

-- this will produce the same error as before:
create bitmap index bmp_dim_agent_active on
   dim_agent (
      is_active
   );

-- execute this: 

-- SELECT i.index_name, i.index_type, i.uniqueness
-- FROM user_indexes i
-- JOIN user_ind_columns c
--   ON c.index_name = i.index_name
-- WHERE c.table_name = 'DIM_AGENT'
--   AND c.column_name = 'IS_CURRENT';

-- drop index IDX_DIM_AGENT_CURRENT;

-- and then create the index

-- same here too:
create bitmap index bmp_dim_agent_current on
   dim_agent (
      is_current
   );

-- SELECT i.index_name,
--        i.index_type,
--        i.uniqueness
-- FROM user_indexes i
-- JOIN user_ind_columns c
--   ON c.index_name = i.index_name
-- WHERE c.table_name = 'DIM_DEPARTAMENT'
--   AND c.column_name = 'IS_CURRENT';  

-- drop index IDX_DIM_DEPARTAMENT_CURRENT;
-- and don't forget to create the index again

create bitmap index bmp_dim_departament_current on
   dim_departament (
      is_current
   );

create bitmap index bmp_dim_topic_type on
   dim_topic (
      topic_type
   );

create bitmap index bmp_dim_time_weekend on
   dim_time (
      este_weekend
   );
create bitmap index bmp_dim_time_sarbatoare on
   dim_time (
      este_sarbatoare
   );
create bitmap index bmp_dim_time_trimestru on
   dim_time (
      trimestru
   );
create bitmap index bmp_dim_time_luna on
   dim_time (
      luna
   );
create bitmap index bmp_dim_time_zi_saptamana on
   dim_time (
      zi_saptamana
   );