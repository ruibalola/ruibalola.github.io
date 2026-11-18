# 📺 Gestão de Clientes TV (100% Cloud Supabase)

Aplicação web para gestão de clientes e subscrições de serviços de TV (IPTV, OTT, etc.), **conectada exclusivamente à base de dados na nuvem com Supabase**.

---

## 🔐 1. Acesso Inicial & Gestão de Utilizadores (Root)

Para garantir segurança total, **não existe registo público de utilizadores** no ecrã de login. Apenas o administrador **root** pode criar e gerir utilizadores.

### Credenciais Iniciais Padrão:
- **Utilizador:** `admin`
- **Palavra-passe:** `admin123`

*(As palavras-passe são protegidas por criptografia `bcrypt` diretamente na base de dados PostgreSQL através da extensão `pgcrypto`).*

### O que o Root pode fazer:
- **Criar novos utilizadores:** No botão **"Utilizadores"** no topo, defina o nome, login e palavra-passe do novo operador.
- **Alterar senha de qualquer utilizador:** Redefina a senha de qualquer utilizador com 1 clique (inclui gerador de senhas seguras).
- **Apagar utilizadores:** Remova o acesso de utilizadores (o utilizador root principal é protegido e não pode ser apagado).
- **Alterar a própria senha:** No botão **"Minha Senha"** no topo.

---

## 🌐 2. Como Deixar a App no GitHub Já Conectada Automaticamente?

**Sim, é possível e muito simples!** Para que ninguém precise de colar o URL ou a chave quando abrir o site no GitHub Pages:

1. Abra o ficheiro [`config.js`](./config.js) no seu editor.
2. Preencha com o seu **Project URL** e a sua **Anon Public Key** do Supabase:
   ```javascript
   window.ENV = {
       SUPABASE_URL: "https://SEU-PROJETO.supabase.co",
       SUPABASE_ANON_KEY: "SUA-CHAVE-ANON-AQUI"
   };
   ```
3. Envie para o GitHub:
   ```powershell
   git add .
   git commit -m "feat: app conectada ao supabase com login root e gestao de clientes"
   git push -u origin main
   ```

*(Nota de Segurança: No Supabase, a chave `anon` é pública e foi feita especificamente para aplicações frontend no navegador. A sua senha direta da base de dados `pass_db` permanece guardada em segurança no ficheiro `.env` e nunca é enviada para o GitHub).*

---

## 🛠️ 3. Como Aplicar o SQL no Supabase

1. Aceda ao painel do seu projeto no [Supabase](https://supabase.com/dashboard).
2. No menu lateral, clique em **SQL Editor** &rarr; **New query**.
3. Copie todo o código do ficheiro [`schema.sql`](./schema.sql), cole no editor e clique em **Run** (Executar).
   - O script cria:
     - A tabela `usuarios_sistema` com o utilizador `admin` / `admin123`.
     - As funções seguras de autenticação (`autenticar_usuario`, `salvar_usuario`, `apagar_usuario`, `alterar_minha_senha`).
     - A tabela `clientes` com índices, segurança RLS e sincronização em tempo real (Realtime).

---

## 👥 4. Gestão de Clientes de TV

- **Criar Cliente:** Nome, contacto WhatsApp, serviço, valor (€), utilizador, palavra-passe, link e vencimento.
- **Alterar Senha do Cliente:** Botão 🔑 na tabela para gerar senha segura e atualizar de imediato no Supabase.
- **Copiar Dados:** Botão de cópia rápida para utilizador e senha com 1 clique.
- **Upload CSV:** Botão para carregar um ficheiro CSV existente diretamente para a base de dados Supabase em lote.
- **Avisar por WhatsApp:** Envio automático de mensagem de lembrete de vencimento com 1 clique.
- **Exportações:** Download de cópias de segurança em CSV e relatórios em PDF.
