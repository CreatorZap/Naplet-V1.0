# GUIA DE INSTALAÇÃO E USO
## Como configurar tudo no Naplet

---

## ESTRUTURA RECOMENDADA NO PROJETO

Crie esta estrutura na raiz do projeto Naplet:

```
Naplet/
├── CLAUDE.md                              ← novo, raiz do projeto
├── PLANO_EXECUCAO_MASTER.md               ← novo, raiz do projeto
├── EMERGENCIA_LOG.md                      ← criar ao executar Sprint 0
├── auditoria-10x/                         ← já existe (do Claude Code)
├── concorrente-napper-prints/             ← já existe
├── sprints/                               ← criar
│   └── SPRINT_1_PROMPT.md                 ← novo
├── .claude/                               ← se não existir, criar
│   └── skills/                            ← criar
│       ├── naplet-safe-migration/
│       │   └── SKILL.md
│       ├── naplet-design-system/
│       │   └── SKILL.md
│       ├── naplet-paywall-patterns/
│       │   └── SKILL.md
│       └── naplet-supabase-rls/
│           └── SKILL.md
└── ... (resto do projeto)
```

---

## PASSO A PASSO

### 1. Copiar o CLAUDE.md novo

Substitua o `CLAUDE.md` atual do projeto (que está descolado da realidade) pelo arquivo `CLAUDE.md` deste pacote. O novo reflete a auditoria, prioriza problemas críticos, e atualiza o estado real do app.

**Importante:** o CLAUDE.md antigo dizia "95% pronto, pronto para submissão". Isso era verdade do ponto de vista de features, mas não de conversão. O novo CLAUDE.md é honesto sobre os 10 problemas críticos.

### 2. Salvar o PLANO_EXECUCAO_MASTER.md na raiz

Esse documento define a sequência dos sprints, os critérios de saída, e as métricas de sucesso. É o roadmap operacional. Use ele toda vez que precisar lembrar o que vem depois.

### 3. Criar pasta `sprints/` e colocar o SPRINT_1_PROMPT.md

Cada sprint terá seu prompt detalhado. Quando começarmos o Sprint 2, eu te entrego o SPRINT_2_PROMPT.md, e assim por diante.

### 4. Instalar as skills no Claude Code

Skills no Claude Code ficam em `.claude/skills/{nome-da-skill}/SKILL.md`. Crie essa estrutura:

```bash
cd /Volumes/ExtremeSSD/projetos/Naplet
mkdir -p .claude/skills/naplet-safe-migration
mkdir -p .claude/skills/naplet-design-system
mkdir -p .claude/skills/naplet-paywall-patterns
mkdir -p .claude/skills/naplet-supabase-rls
```

Cole cada SKILL.md na pasta correspondente.

### 5. Adicionar `.claude/` ao `.gitignore` (opcional)

Se você quer manter as skills locais (e não comitar para o GitHub), adicione ao `.gitignore`:

```
.claude/
```

Se você quer que outras pessoas (ou outras máquinas suas) também tenham as skills, **não** adicione ao gitignore e comite normalmente.

Recomendação: **comitar**. Skills são parte da documentação operacional do projeto.

---

## COMO USAR AS SKILLS NO CLAUDE CODE

Quando você abrir o Claude Code dentro da pasta Naplet, ele vai detectar automaticamente as skills em `.claude/skills/`. A descrição (`description:` no frontmatter) é o gatilho: o Claude Code lê a skill quando o contexto da tarefa bate com a descrição.

Por exemplo:
- Edita `AppConfig.swift` → dispara `naplet-safe-migration`
- Cria nova view de paywall → dispara `naplet-paywall-patterns` + `naplet-design-system`
- Mexe em policy do Supabase → dispara `naplet-supabase-rls`

Você não precisa invocar manualmente. Mas pode mencionar no prompt: "Antes de começar, leia a skill `naplet-paywall-patterns`."

---

## SEQUÊNCIA PARA EXECUTAR AGORA

### Hoje, antes de qualquer outra coisa: Sprint 0

Não precisa do Claude Code para isso. São ações manuais no painel da OpenAI e do RevenueCat. Veja o passo a passo em `PLANO_EXECUCAO_MASTER.md`, seção "Sprint 0: Emergência".

**Crítico:** revogar a chave OpenAI atual hoje. Cada hora que passa com a chave exposta é um risco financeiro real.

### Amanhã ou depois: Sprint 1

Depois do Sprint 0 completo:

1. Instale as skills (passo 4 acima)
2. Substitua o CLAUDE.md (passo 1)
3. Abra o Claude Code na raiz do projeto
4. Cole o `SPRINT_1_PROMPT.md`
5. Deixe ele executar bloco por bloco
6. Aprove cada bloco antes de avançar
7. Ao fim do Sprint 1, me envie o `sprint-1-relatorio.md` aqui no chat

### Depois disso

Eu monto o `SPRINT_2_PROMPT.md` com base no que aconteceu no Sprint 1, e seguimos.

---

## DICAS IMPORTANTES

### Sobre o ritmo

Não tente fazer tudo de uma vez. Cada sprint tem 2 a 5 dias. Respeitar esse ritmo evita bugs e cansaço. App em produção exige paciência.

### Sobre os smoke tests

Não pule. Sério. 30 minutos de smoke test salvam 8 horas de debug de produção.

### Sobre commits

Atômicos e descritivos. Se você ficar em dúvida se vale a pena um novo commit, vale.

### Sobre as branches

Cada sprint na sua branch. Merge para main só depois de TestFlight validado.

### Sobre métricas

Sem PostHog (Sprint 2), você está voando cego. Por isso o Sprint 2 é tão importante quanto o 1. Não pule a integração de analytics.

---

## CONTATO COMIGO (Claude na conversa)

Sempre que precisar:

- "Acabei o Sprint X, aqui está o relatório" → eu reviso e gero o próximo
- "Aconteceu Y" → eu diagnostico
- "Quero mudar Z" → eu avalio impacto e estruturo a mudança
- "Como funciona W?" → eu explico

Mantenha o `auditoria-10x/00-INDEX.md` e o `CLAUDE.md` sempre nas primeiras mensagens das nossas conversas para que eu retome contexto rápido.

---

## SE BATER A DÚVIDA "POR ONDE COMEÇO?"

Resposta única: **Sprint 0, hoje. Revogue a chave OpenAI e verifique o RevenueCat.** Antes de qualquer outra coisa. Tudo o mais depende disso.

---

*Boa execução.*
