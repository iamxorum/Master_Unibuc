
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    tabel_nume VARCHAR(100) NOT NULL,
    operatie VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    utilizator VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_vechi JSONB,
    date_noi JSONB,
    ip_adresa INET
);

CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER 
SECURITY DEFINER
AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (tabel_nume, operatie, utilizator, date_vechi, ip_adresa)
        VALUES (TG_TABLE_NAME, TG_OP, session_user, row_to_json(OLD), inet_client_addr());
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (tabel_nume, operatie, utilizator, date_vechi, date_noi, ip_adresa)
        VALUES (TG_TABLE_NAME, TG_OP, session_user, row_to_json(OLD), row_to_json(NEW), inet_client_addr());
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (tabel_nume, operatie, utilizator, date_noi, ip_adresa)
        VALUES (TG_TABLE_NAME, TG_OP, session_user, row_to_json(NEW), inet_client_addr());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_fisa_medicala
AFTER INSERT OR UPDATE OR DELETE ON fisa_medicala
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_pacient
AFTER INSERT OR UPDATE OR DELETE ON pacient
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

CREATE TRIGGER audit_personal_medical
AFTER INSERT OR UPDATE OR DELETE ON personal_medical
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

GRANT SELECT ON audit_log TO admin;

