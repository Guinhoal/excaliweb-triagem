-- Cria schema dedicado para a Evolution API se não existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'evolution_api'
    ) THEN
        EXECUTE 'CREATE SCHEMA evolution_api AUTHORIZATION triagem_user';
    END IF;
END $$;