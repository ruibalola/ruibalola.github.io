-- ==============================================================================
-- CORREÇÃO IMEDIATA DE PERMISSÕES NO SUPABASE
-- ==============================================================================
-- Execute este comando no SQL Editor do Supabase para corrigir o erro:
-- "permission denied for table clientes"
-- ==============================================================================

-- 1. Conceder permissões de acesso ao schema public
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Conceder permissões totais nas tabelas clientes e usuarios_sistema
GRANT ALL ON TABLE public.clientes TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.usuarios_sistema TO anon, authenticated, service_role;

-- 3. Conceder permissões em sequências e funções
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 4. Garantir que as políticas de RLS permitem inserção e alteração
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Acesso total clientes" ON public.clientes;
CREATE POLICY "Acesso total clientes"
    ON public.clientes
    FOR ALL
    TO anon, authenticated, service_role
    USING (true)
    WITH CHECK (true);

-- 5. Atualizar privilégios padrão para o futuro
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;
