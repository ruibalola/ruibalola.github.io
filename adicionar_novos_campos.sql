-- ==============================================================================
-- ATUALIZAÇÃO DA TABELA CLIENTES (NOVOS CAMPOS)
-- ==============================================================================
-- Execute este comando no SQL Editor do Supabase (https://supabase.com/dashboard)
-- para adicionar as novas colunas à tabela 'clientes'.
-- ==============================================================================

-- 1. Adicionar coluna 'marca_equipamento' (Marca do Equipamento TV)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS marca_equipamento TEXT;

-- 2. Adicionar coluna 'box' (Dispositivo / Box TV)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS box TEXT;

-- 3. Adicionar coluna 'observacao' (Notas / Observações sobre o cliente)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS observacao TEXT;

-- 4. Adicionar coluna 'ficheiros' (Histórico de anexos, fotos, comprovativos em JSON)
ALTER TABLE public.clientes ADD COLUMN IF NOT EXISTS ficheiros JSONB DEFAULT '[]'::jsonb;

-- 5. Reafirmar permissões para as roles do Supabase
GRANT ALL ON TABLE public.clientes TO anon, authenticated, service_role;

-- 6. Atualizar comentários das colunas
COMMENT ON COLUMN public.clientes.marca_equipamento IS 'Marca do equipamento do cliente (ex: Xiaomi, Apple, Amazon, Formuler, LG, Samsung)';
COMMENT ON COLUMN public.clientes.box IS 'Modelo ou tipo de dispositivo/box TV (ex: Formuler, FireStick, Mag, SmartTV)';
COMMENT ON COLUMN public.clientes.observacao IS 'Observações, MAC address ou notas históricas sobre o cliente';
COMMENT ON COLUMN public.clientes.ficheiros IS 'Histórico de ficheiros e comprovativos anexados em formato JSON';
