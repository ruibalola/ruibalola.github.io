-- ==============================================================================
-- GESTÃO DE CLIENTES TV - SCHEMA COMPLETO SUPABASE (POSTGRESQL)
-- ==============================================================================
-- Instruções:
-- 1. Aceda ao painel do seu projeto Supabase: https://supabase.com/dashboard
-- 2. No menu lateral esquerdo, clique no ícone "SQL Editor"
-- 3. Clique em "New query", cole todo este código e clique em "Run" (Executar)
-- ==============================================================================

-- 1. Habilitar extensões necessárias para UUID e Hashing seguro (bcrypt)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==============================================================================
-- 2. TABELA DE UTILIZADORES DO SISTEMA (LOGIN & ACESSO ROOT)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.usuarios_sistema (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    nome TEXT NOT NULL DEFAULT 'Administrador',
    role TEXT NOT NULL DEFAULT 'admin', -- 'root' ou 'admin'
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.usuarios_sistema IS 'Contas de utilizadores autorizados a aceder ao painel';

-- Inserir utilizador ROOT inicial (admin / admin123) se ainda não existir
INSERT INTO public.usuarios_sistema (username, password_hash, nome, role)
VALUES (
    'admin',
    crypt('admin123', gen_salt('bf')),
    'Administrador Root',
    'root'
)
ON CONFLICT (username) DO NOTHING;

-- Habilitar RLS para usuarios_sistema
ALTER TABLE public.usuarios_sistema ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Acesso total usuarios_sistema" ON public.usuarios_sistema;
CREATE POLICY "Acesso total usuarios_sistema"
    ON public.usuarios_sistema
    FOR ALL
    TO anon, authenticated, service_role
    USING (true)
    WITH CHECK (true);

-- ==============================================================================
-- 3. TABELA DE CLIENTES DE SERVIÇO TV
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.clientes (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    name TEXT NOT NULL,
    phone TEXT,
    service TEXT NOT NULL,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    "user" TEXT,
    pass TEXT,
    link TEXT,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

COMMENT ON TABLE public.clientes IS 'Tabela principal de clientes e assinaturas de TV';

-- Índices para otimização de pesquisas
CREATE INDEX IF NOT EXISTS idx_clientes_date ON public.clientes (date ASC);
CREATE INDEX IF NOT EXISTS idx_clientes_name ON public.clientes (name ASC);
CREATE INDEX IF NOT EXISTS idx_clientes_service ON public.clientes (service);

-- Trigger para atualizar automaticamente o campo updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_clientes_updated_at ON public.clientes;
CREATE TRIGGER tr_clientes_updated_at
    BEFORE UPDATE ON public.clientes
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- PERMISSÕES DE ACESSO (GRANTS) & ROW LEVEL SECURITY (RLS)
-- ==============================================================================
-- 1. Permissões de uso do schema public
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Conceder permissões totais nas tabelas para as roles do Supabase
GRANT ALL ON TABLE public.clientes TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.usuarios_sistema TO anon, authenticated, service_role;

-- 3. Conceder permissões em sequências e funções
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- 4. Garantir privilégios padrão para futuras tabelas/sequências
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;

-- Habilitar RLS para clientes
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Acesso total clientes" ON public.clientes;
CREATE POLICY "Acesso total clientes"
    ON public.clientes
    FOR ALL
    TO anon, authenticated, service_role
    USING (true)
    WITH CHECK (true);

-- Habilitar Supabase Realtime para a tabela clientes
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
          AND schemaname = 'public' 
          AND tablename = 'clientes'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.clientes;
    END IF;
END $$;

-- ==============================================================================
-- 4. FUNÇÕES RPC (AUTENTICAÇÃO & GESTÃO DE UTILIZADORES PELO ROOT)
-- ==============================================================================

-- 4.1 Autenticar utilizador (Verifica username e password com bcrypt)
CREATE OR REPLACE FUNCTION public.autenticar_usuario(p_username TEXT, p_password TEXT)
RETURNS TABLE (
    id UUID,
    username TEXT,
    nome TEXT,
    role TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.nome, u.role
    FROM public.usuarios_sistema u
    WHERE LOWER(u.username) = LOWER(p_username)
      AND u.password_hash = crypt(p_password, u.password_hash);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.2 Listar todos os utilizadores (Apenas root e admins)
CREATE OR REPLACE FUNCTION public.listar_usuarios()
RETURNS TABLE (
    id UUID,
    username TEXT,
    nome TEXT,
    role TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.nome, u.role, u.created_at
    FROM public.usuarios_sistema u
    ORDER BY (u.role = 'root') DESC, u.username ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.3 Criar ou Editar utilizador do sistema
CREATE OR REPLACE FUNCTION public.salvar_usuario(
    p_id UUID,
    p_username TEXT,
    p_password TEXT,
    p_nome TEXT,
    p_role TEXT
)
RETURNS JSON AS $$
DECLARE
    v_id UUID;
BEGIN
    IF p_id IS NOT NULL THEN
        -- Atualizar utilizador existente
        IF p_password IS NOT NULL AND trim(p_password) <> '' THEN
            UPDATE public.usuarios_sistema
            SET username = p_username,
                nome = p_nome,
                role = p_role,
                password_hash = crypt(p_password, gen_salt('bf')),
                updated_at = timezone('utc'::text, now())
            WHERE id = p_id;
        ELSE
            UPDATE public.usuarios_sistema
            SET username = p_username,
                nome = p_nome,
                role = p_role,
                updated_at = timezone('utc'::text, now())
            WHERE id = p_id;
        END IF;
        v_id := p_id;
    ELSE
        -- Criar novo utilizador
        IF p_password IS NULL OR trim(p_password) = '' THEN
            RETURN json_build_object('success', false, 'error', 'A palavra-passe é obrigatória para novos utilizadores.');
        END IF;
        INSERT INTO public.usuarios_sistema (username, password_hash, nome, role)
        VALUES (p_username, crypt(p_password, gen_salt('bf')), p_nome, p_role)
        RETURNING id INTO v_id;
    END IF;

    RETURN json_build_object('success', true, 'id', v_id);
EXCEPTION WHEN unique_violation THEN
    RETURN json_build_object('success', false, 'error', 'Já existe um utilizador com esse nome de utilizador.');
WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.4 Apagar utilizador do sistema (Protege o utilizador root)
CREATE OR REPLACE FUNCTION public.apagar_usuario(p_id UUID)
RETURNS JSON AS $$
DECLARE
    v_role TEXT;
BEGIN
    SELECT role INTO v_role FROM public.usuarios_sistema WHERE id = p_id;
    IF v_role = 'root' THEN
        RETURN json_build_object('success', false, 'error', 'Não é permitido apagar o utilizador root principal do sistema.');
    END IF;

    DELETE FROM public.usuarios_sistema WHERE id = p_id;
    RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4.5 Alterar a própria palavra-passe
CREATE OR REPLACE FUNCTION public.alterar_minha_senha(p_user_id UUID, p_old_pass TEXT, p_new_pass TEXT)
RETURNS JSON AS $$
DECLARE
    v_valid BOOLEAN;
BEGIN
    SELECT (password_hash = crypt(p_old_pass, password_hash))
    INTO v_valid
    FROM public.usuarios_sistema
    WHERE id = p_user_id;

    IF v_valid IS NOT TRUE THEN
        RETURN json_build_object('success', false, 'error', 'A palavra-passe atual está incorreta.');
    END IF;

    UPDATE public.usuarios_sistema
    SET password_hash = crypt(p_new_pass, gen_salt('bf')),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_user_id;

    RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
