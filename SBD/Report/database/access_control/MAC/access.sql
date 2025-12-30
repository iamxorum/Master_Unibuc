GRANT SELECT ON personal_medical TO "ana.popescu";
GRANT SELECT ON personal_medical TO "mihai.marinescu";
GRANT SELECT ON personal_medical TO "elena.constantinescu";

GRANT SELECT ON fisa_medicala TO "ana.popescu";
GRANT SELECT ON fisa_medicala TO "mihai.marinescu";
GRANT SELECT ON fisa_medicala TO "elena.constantinescu";

ALTER TABLE fisa_medicala ENABLE ROW LEVEL SECURITY;

CREATE POLICY politica_mac_fise ON fisa_medicala
FOR SELECT
USING (
    (SELECT grad_acreditare 
     FROM personal_medical 
     WHERE username_db = current_user) >= nivel_clasificare
);

ALTER TABLE fisa_medicala FORCE ROW LEVEL SECURITY; 