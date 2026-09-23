# Controle de Integração — Ciclo de Discipulado

Portal web para acompanhar a formação de novos membros de uma igreja em Carazinho-RS.
Cada participante passa por 12 módulos após o retiro de integração; o portal registra
presença, mostra quem falta em cada aula, convoca pelo WhatsApp e gera relatórios.

Usuário principal: Viní (líder, não é programador). Explique mudanças em português,
em linguagem simples, e sempre diga o que ele precisa fazer do lado dele.

## Stack

- **Um único arquivo:** `index.html` (~2.750 linhas: HTML + CSS + JS, sem build)
- **Backend:** Supabase (Postgres + Auth), projeto "Integração", região sa-east-1
  URL: `https://kectvdncelzrfquhrqrh.supabase.co`
- **Hospedagem:** GitHub Pages, branch `main` → https://canuto035.github.io/ciclo-discipulado/
- **Biblioteca:** supabase-js 2.45.4 via CDN, com 3 fontes de reserva (jsDelivr, unpkg, Skypack)
- Arquivo `.nojekyll` precisa continuar na raiz

A chave `sb_publishable_…` no HTML é pública por design — a proteção vem do RLS.
**Nunca** coloque chave secreta (`sb_secret_…`) ou token do GitHub no código.

## Os 12 módulos (ordem oficial — não altere)

1 Aliança de Sangue · 2 Relacionando-me com o Pai · 3 Cinco Ministérios ·
4 Autoridade Espiritual · 5 Panorama da Obra Divina · 6 Mente Renova ·
7 Batalha Espiritual · 8 Perdão · 9 Dízimo · 10 Espírito Santo ·
11 Grupo Familiar · 12 Batismo nas Águas

Os módulos 6 a 12 costumam ser dados no próprio retiro.

## Banco de dados

Tabelas: `profiles` (usuários e papel), `participantes`, `historico`.
Esquema completo em `sql/schema.sql`.

`participantes.modulos` é **jsonb** no formato `{"Perdão": "2026-09-13", ...}`
(datas ISO no banco; o front converte para DD/MM/AAAA).

Colunas opcionais, detectadas em tempo de execução — se não existirem no banco,
o recurso some da tela sem quebrar nada:

| Coluna | Flag no JS | Recurso |
|---|---|---|
| `turma` | `HAS_TURMA` (+ interruptor `TURMAS_ON`) | barra e filtro de turmas |
| `familia` | `HAS_FAM` | marca de grupo familiar |
| `obs` | `HAS_OBS` | observações na ficha |
| `nascimento` | `HAS_NASC` | idade e aniversários |

Papéis: `admin` (tudo), `editor` (cadastra e edita), `viewer` (só consulta).
Função `can()` diz se o usuário pode escrever.

## Regras que não são óbvias — leia antes de mexer

**Telefone / DDD 54.** O DDD de Carazinho é 54, que é o código de país da Argentina.
Número sem +55 abriria o WhatsApp no país errado. Todo link passa por `telIntl()` e
toda gravação por `fmtTel()`. Nunca monte `wa.me/` concatenando o celular cru.

**Duas validações de data.** `br2iso()` aceita só anos 2000–2100 (protege datas de aula
contra erro de digitação tipo "3026"). `nasc2iso()` aceita 1900 até hoje, sem futuro.
Nascimento usa `nasc2iso` — já houve bug por usar `br2iso` e rejeitar quem nasceu antes de 2000.

**Gravação com fusão.** Vários editores usam ao mesmo tempo. Módulos são gravados por
`gravarModulos(id, alteracoes)`, que relê o registro no banco e funde antes de salvar.
Nunca faça `update({modulos: ...})` com o objeto montado a partir da tela.
A mesclagem (`doMerge`) também relê as duas fichas antes de juntar.

**Numeração.** `numero` tem índice único. Use `inserirParticipante()`, que busca o
último número no banco e tenta o próximo em caso de colisão.

**Parados.** `estaParado()` conta 30 dias desde o último módulo; sem módulo, conta
desde o retiro. Sem nenhuma das duas datas, não é considerado parado.

**Sincronização.** Ao voltar para a aba depois de 30s, `sincronizar()` recarrega os dados —
mas nunca com um modal aberto.

**Abertura.** Com mais de uma turma, o portal abre filtrado na mais recente, não em "Todas".

## Estrutura do painel (decisões de produto já tomadas)

- Hero em 3 colunas: **como estamos** (% e média de módulos) · **situação do grupo**
  (4 faixas que somam o total + alerta de parados) · **o que fazer** (cartão da próxima aula)
- Um único botão de chamada, no cartão. "Novo participante" fica no menu do avatar.
- Números em zero ficam acinzentados; painel mostra exceção, não censo.
- Foram removidos de propósito: previsão de término e contagem de ritmo
  (davam números enganosos com turmas misturadas). Não recoloque sem discutir.

Paleta: fundo `#071018`, verde `#2EE58C`, azul `#35A7FF`, amarelo `#F2C14E`,
laranja `#FF9F43`, dourado da logo `#C5A238`. Fontes: Syne (títulos) e Inter.

## Publicar

1. Validar o JS: `node -e "new Function(require('fs').readFileSync('index.html','utf8').match(/<script>([\s\S]*?)<\/script>\s*<\/body>/)[1])"`
2. Testar no navegador (celular 320–430px e desktop), sem estouro horizontal
3. `git commit` e `git push origin main`
4. GitHub Pages publica em ~1 minuto

## Testes

Não há suíte automatizada ainda. O método usado até aqui: Playwright abrindo o
`index.html` com um stub de `window.supabase` injetado antes do script, alimentado
com dados de exemplo (inclusive nomes com apóstrofo, HTML e telefones em vários formatos).
Transformar isso em testes versionados é uma boa próxima tarefa.

## Operação

- Supabase gratuito **pausa após 7 dias sem acesso**. Se o login der "Failed to fetch",
  o projeto está pausado: painel do Supabase → Restore project.
- O tradutor do Chrome quebra comandos colados no SQL Editor — desligar antes.

## Pendências do usuário

- Mesclar duplicatas: Eduarda Dettner ↔ Eduarda Dettner Soares, Norton Pellizzari ↔
  Norton Pelisari, Leonardo ↔ Leonardo Schneider, Ana Maria Tozzi ↔ Ana Tozzi,
  Polyanna ↔ Pollyana
- Apagar o cadastro "teste"
- Turmas atuais: Jun/2026 (59) e Set/2026 (29, 3ª edição, retiro 13/09/2026)
