CREATE ROLE rol_medic;
CREATE ROLE rol_asistent;
CREATE ROLE rol_rezident;

GRANT ALL ON fisa_medicala TO rol_medic;
GRANT ALL ON pacient TO rol_medic;
GRANT ALL ON personal_medical TO rol_medic;

GRANT SELECT ON pacient TO rol_asistent;
GRANT SELECT ON fisa_medicala TO rol_asistent;
GRANT SELECT ON personal_medical TO rol_asistent;

GRANT SELECT ON fisa_medicala TO rol_rezident;

CREATE USER "ana.popescu" WITH PASSWORD 'parola123';
GRANT rol_medic TO "ana.popescu";

CREATE USER "mihai.marinescu" WITH PASSWORD 'parola123';
GRANT rol_asistent TO "mihai.marinescu";

CREATE USER "elena.constantinescu" WITH PASSWORD 'parola123';
GRANT rol_rezident TO "elena.constantinescu";