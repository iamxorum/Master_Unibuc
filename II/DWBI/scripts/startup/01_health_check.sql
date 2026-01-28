ALTER SESSION SET CONTAINER = orclpdb1;

SELECT 'OK' AS health_status FROM v$instance WHERE status = 'OPEN';
