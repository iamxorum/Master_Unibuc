-- Verificare membri ai rolurilor
SELECT r.rolname AS role_name, m.rolname AS member_name
FROM pg_roles r
JOIN pg_auth_members am ON r.oid = am.roleid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname LIKE 'rol_%'
ORDER BY r.rolname, m.rolname;

-- Verificare permisiuni pe tabele pentru fiecare rol
SELECT 
    grantee AS role_name,
    table_name,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE grantee LIKE 'rol_%'
    AND table_schema = 'public'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;