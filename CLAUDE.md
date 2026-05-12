# CLAUDE.md — Projeto Naplet
## Versão 3.0, pós-auditoria 10x | Atualizado: 11/05/2026

---

## CONTEXTO REAL ATUAL

O Naplet está publicado na App Store brasileira (id6758465410), versão 1.1, há aproximadamente 2 meses.

**Números reais:**

| Métrica | Valor |
|---|---|
| Usuários ativos no Supabase | ~46 |
| Assinaturas convertidas | **0** |
| Avaliações na App Store | 2 (ambas 5 estrelas, círculo próximo) |
| Período Founders | Até 22/04/2026 (já expirado, revisar) |

**Diagnóstico após auditoria 10x:** o app não tem problema de marketing. O funil interno está furado em três camadas. Existe risco financeiro ativo (chave OpenAI exposta). Existe risco de monetização zerada (RevenueCat possivelmente em modo test). E existe um onboarding que pede tudo antes de entregar valor.

A auditoria completa está em `/auditoria-10x/`. Para retomar contexto, ler primeiro `auditoria-10x/00-INDEX.md`.

---

## TOP 10 PROBLEMAS DESCOBERTOS (priorizado por impacto em conversão)

| # | Severidade | Problema | Local |
|---|---|---|---|
| 1 | 🔴 Emergência | RevenueCat possivelmente em modo TEST | AppConfig.swift:49 |
| 2 | 🔴 Emergência | Chave OpenAI exposta no binário | AppConfig.swift:60 |
| 3 | 🔴 Crítico | Sem paywall após onboarding (pico de motivação desperdiçado) | OnboardingView.swift |
| 4 | 🔴 Crítico | 5 dos 7 triggers de paywall nunca disparam | PaywallTrigger.swift |
| 5 | 🔴 Crítico | SignIn obrigatório antes de qualquer valor | ContentView.swift:66 |
| 6 | 🔴 Crítico | Chat IA com primeira mensagem genérica, sem contexto do bebê | ChatViewModel.swift, OpenAIService.swift |
| 7 | 🔴 Crítico | PDF para pediatra com layout amador | PDFReportService.swift |
| 8 | 🟠 Alto | Zero analytics no paywall (impossível medir, A/B testar) | TODO em PaywallTrigger.swift:201 |
| 9 | 🟠 Alto | Multi-cuidador sem realtime e com risco de RLS retroativo | CaregiverRepository.swift, SleepRepository.swift:121 |
| 10 | 🟠 Alto | Sem sons de dormir (table stakes, Napper tem 30+) | AppConfig: enableSounds = false |

**Placar Naplet vs Napper:** 1 vitória, 15 derrotas, 3 empates em 20 dimensões.

---

## STACK TECNOLÓGICO (confirmado por leitura de código)

- Frontend: SwiftUI, iOS 16+
- Backend: Supabase (Auth, PostgreSQL, Realtime, Storage)
- Pagamentos: RevenueCat (precisa confirmar produção)
- IA: OpenAI API (precisa proxy via Edge Function)
- IDE: Cursor com Claude Code
- 258 arquivos Swift, 19 tabelas Supabase

---

## PLANO DE EXECUÇÃO ATIVO

### Sprint 0: Emergência (hoje, 1-3h)
1. Verificar dashboard RevenueCat: Production ou Sandbox?
2. Revogar chave OpenAI atual no painel da OpenAI
3. Gerar nova chave e armazenar fora do código

### Sprint 1: Destravar receita (2-3 dias)
1. Edge Function Supabase como proxy OpenAI
2. Remover chave OpenAI do AppConfig
3. Confirmar e validar RevenueCat em produção
4. Adicionar paywall ao final do onboarding (tela 12)
5. Mover SignIn para depois da tela 9 (depois do valor)
6. Reativar oferta Founders ou definir nova janela

### Sprint 2: Wiring de monetização (3-5 dias)
1. Implementar os 5 triggers de paywall mortos
2. Integrar PostHog para analytics de funil
3. Adicionar countdown e ancoragem de preço no paywall
4. Adicionar tela de "downgrade offer" após primeiro recuso

### Sprint 3: Refinar proposta de valor (1-2 semanas)
1. Chat IA personalizado com nome do bebê + contexto completo
2. PDF para pediatra redesenhado (logo, gráficos, peso/altura, campo de anotações)
3. Realtime multi-cuidador via Supabase Realtime
4. Revisão completa de RLS para evitar vazamento retroativo

### Sprint 4: Table stakes e diferenciais (2-3 semanas)
1. Sons de dormir (v1.2 Dream Engine, 12 sons offline)
2. Live Activity / Dynamic Island para sono em andamento
3. Notificações inteligentes (dia 3, 7, 14)
4. Animações e microinterações premium

---

## REGRAS DE TRABALHO (NÃO QUEBRAR NADA)

App em produção, com usuários reais. Toda mudança segue protocolo:

1. **Sempre** criar branch com prefixo `sprint-N/feature-x` antes de qualquer mudança
2. **Commits pequenos e atômicos.** Um problema por commit.
3. **Build limpo obrigatório** após cada mudança. Erro de build não fecha tarefa.
4. **Smoke test obrigatório** no simulador: abrir app, fazer login, criar registro de sono, fechar.
5. **Nunca tocar** em AppConfig.swift, Info.plist, project.pbxproj, Supabase RLS, ou produtos RevenueCat sem dupla verificação e backup.
6. **Validar Supabase RLS** sempre via `information_schema.columns` antes de qualquer policy nova.
7. **Builds incrementais** de número de build via sed conforme já estabelecido.

Skills permanentes para apoiar:

- `naplet-safe-migration`: protocolo de mudança segura
- `naplet-design-system`: cores, tipografia, componentes autorizados
- `naplet-paywall-patterns`: timing e copy do paywall
- `naplet-supabase-rls`: validação de policies

---

## COMO O EDY TRABALHA

1. Prefere prompts completos e detalhados para colar no Cursor
2. Decisão por sprints, com confirmação antes de cada bloco grande
3. Quer código profissional, organizado, comentado quando necessário
4. Fala português brasileiro, **sem travessões**, com acentuação correta
5. Dark theme com roxo `#8B5CF6` e magenta `#EC4899`, SF Symbols
6. MVVM, Swift Charts, StoreKit 2
7. Workflow: Claude orquestra, Claude Code executa, Edy aprova

---

## DECISÕES JÁ TOMADAS (não mudar sem nova conversa)

- Trial: 14 dias
- Preço Founders: R$59,90/ano (período original encerrado em 22/04/2026)
- Preço Regular: R$89,90/ano, R$12,90/mês
- Chat IA Free: 5 mensagens/mês
- Idiomas: PT-BR, EN, ES
- Bundle: app.naplet.ios

---

## ARQUIVOS DE REFERÊNCIA

| Arquivo | Conteúdo |
|---|---|
| `auditoria-10x/00-INDEX.md` | Sumário executivo da auditoria |
| `auditoria-10x/15-plano-inversao-10x.md` | Plano completo com horas estimadas |
| `auditoria-10x/08-comparativo-naplet-vs-napper.md` | Tabela de 20 dimensões vs Napper |
| `concorrente-napper-prints/` | 30 prints do Napper analisados |

---

## CONCORRENTE: NAPPER

Referência principal de mercado, brasileiro.

| Item | Napper | Naplet |
|---|---|---|
| Preço anual | R$114,90 | R$89,90 |
| Chat IA | Não | Sim, único diferencial real |
| PDF pediatra | Não | Sim, mas precisa redesenho |
| Vacinação | Não | Sim |
| Documentos | Não | Sim |
| Sons | 30+ | 0 |
| Realtime sync | Sim | Não funcional |

Onde o Napper vence: onboarding, paywall, sons, polimento visual. Onde podemos vencer: Chat IA personalizado, PDF profissional, suíte de vacinação e documentos, preço.

---

## COMO RESPONDER NESTE PROJETO

1. Seja direto, sem enrolação
2. Use tabelas para comparações e checklists
3. Use emojis 🔴 🟠 🟢 só para status binário
4. Sem travessões, vírgulas e dois-pontos resolvem
5. Crie prompts completos quando pedir código
6. Foco em conversão antes de qualquer outra métrica
7. Antes de propor mudança, verifique a auditoria
8. Não confie no PRD antigo, ele está descolado da realidade

---

*Última atualização: 11/05/2026, após auditoria 10x*
