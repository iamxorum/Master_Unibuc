-- Oracle docker - sysdba
CREATE USER ddsys IDENTIFIED BY 'password';

GRANT CONNECT, RESOURCE TO ddsys;

SELECT username FROM all_users WHERE username = 'DDSYS';

GRANT CREATE USER TO ddsys;
GRANT CREATE TABLESPACE TO ddsys;
GRANT UNLIMITED TABLESPACE TO ddsys;
GRANT CREATE SESSION TO ddsys;
GRANT CREATE TABLE TO ddsys;
GRANT CREATE SEQUENCE TO ddsys;

-- =======================================
-- DataGrip

SELECT USER FROM DUAL;

CREATE TABLESPACE careconnect_data
DATAFILE 'careconnect_data.dbf'
SIZE 100M
AUTOEXTEND ON NEXT 50M;

CREATE TABLESPACE careconnect_index
DATAFILE 'careconnect_index.dbf'
SIZE 50M
AUTOEXTEND ON NEXT 25M;