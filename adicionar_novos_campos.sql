-- ==============================================================================
-- ATUALIZAÇÃO DA TABELA CLIENTES (4 NOVOS CAMPOS)
-- ==============================================================================
-- Execute este comando no SQL Editor do Supabase (https://supabase.com/dashboard)
-- para adicionar as novas colunas à tabela 'clientes'.
-- ==============================================================================

-- 1. Adicionar coluna 'box' (Dispositivo / Box TV)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS box TEXT;

-- 2. Adicionar coluna 'observacao' (Notas / Observações sobre o cliente)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS observacao TEXT;

-- 3. Adicionar coluna 'ficheiros' (Histórico de anexos, fotos, comprovativos em JSON)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS ficheiros JSONB DEFAULT '[]'::jsonb;

-- 4. Reafirmar permissões para as roles do Supabase
GRANT ALL ON TABLE public.clientes TO anon, authenticated, service_role;

-- 5. Atualizar comentários
COMMENT ON COLUMN public.clientes.box IS 'Modelo ou tipo de dispositivo/box TV (ex: Formuler, FireStick, SmartTV)';
COMMENT ON COLUMN public.clientes.observacao IS 'Observações, MAC address ou notas históricas sobre o cliente';
COMMENT ON COLUMN public.clientes.ficheiros IS 'Histórico de ficheiros e comprovativos anexados em formato JSON';
