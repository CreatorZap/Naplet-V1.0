# 15 - Plano de Inversão 10x

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

> Cada item tem: **O quê**, **Por quê** (métrica de conversão impactada), **Esforço estimado** (horas), **Arquivos afetados**, **Risco**.
>
> Os horizontes não são rígidos — alguns Quick Wins podem ser feitos em paralelo com Médio Prazo.

---

## ANTES DE TUDO: AÇÕES DE EMERGÊNCIA (HOJE / AMANHÃ)

Estes 3 itens não são "Quick Wins de marketing". São **dívidas perigosas** que precisam ser resolvidas antes de qualquer outra coisa porque podem estar **ativamente sabotando** o app.

### E1. Confirmar status do RevenueCat (PROD vs TEST)
- **O quê:** Verificar no dashboard do RevenueCat se a key em [AppConfig.swift:49](Naplet/Core/Config/AppConfig.swift:49) é production ou sandbox/test.
- **Por quê:** Se test, 100% das compras estão sendo simuladas, **nunca** chegam à App Store. Pode ser a explicação inteira de "0 assinaturas". O `RELATORIO_APP_STORE_v2.md` já apontava isso e parece não ter sido corrigido.
- **Esforço:** 30 min.
- **Risco:** baixo (verificação).

### E2. Revogar e mover a API Key da OpenAI para um proxy
- **O quê:** Revogar [AppConfig.swift:60](Naplet/Core/Config/AppConfig.swift:60). Criar Edge Function no Supabase que recebe `messages[]` e chama a OpenAI com chave server-side. App passa a chamar o proxy.
- **Por quê:** Chave atual está no binário do app (extraível) e provavelmente também no git. Risco de abuso financeiro infinito.
- **Esforço:** 1-2 dias.
- **Arquivos:** `AppConfig.swift`, `OpenAIService.swift`, nova Edge Function `chat-proxy/index.ts`.
- **Risco:** quebrar Chat IA temporariamente. Testar bem.

### E3. Substituir App Store ID em SupportViewModel
- **O quê:** [SupportViewModel.swift:155](Naplet/Features/Support/ViewModels/SupportViewModel.swift:155) tem `id123456789` placeholder. App ID real é `id6758465410` (mencionado no contexto).
- **Por quê:** "Avaliar na App Store" abre URL inválida → usuário tem fricção, ratings não vêm.
- **Esforço:** 5 minutos.
- **Risco:** zero.

---

## QUICK WINS (24-72h) — 12 ações

Foco: **maximizar pressão de conversão** com menor esforço possível, sem refatoração grande.

### Q1. Implementar 5 triggers de paywall fantasmas
- **O quê:** Conectar `pdfReport`, `multipleBabies`, `historyLimit`, `settingsUpgrade`, `softPrompt` aos pontos de uso (ver doc 03 e 10).
- **Por quê:** Hoje só 2 dos 7 triggers disparam → 71% da pressão de paywall planejada não acontece.
- **Esforço:** 16-24h.
- **Arquivos:** `AddBabyView.swift`, `ReportView.swift`, `SleepHistoryView.swift`, `SettingsView.swift`, novo `SoftPromptScheduler`.
- **Risco:** baixo. Reverter é simples.
- **Impacto estimado:** **+15-25% em conversão.**

### Q2. Trocar copy do CTA Regular do paywall
- **O quê:** Mudar `paywall.cta.subscribe` em `Localizable.strings` de **"Assinar Agora"** para **"Desbloquear Premium"** ou **"Garantir Acesso Completo"**.
- **Por quê:** Verbo de ganho > verbo de gasto. CTA de Founders já usa "Garantir".
- **Esforço:** 10 min.
- **Arquivos:** `Localizable.strings`.
- **Risco:** zero.
- **Impacto:** +5-10% no botão.

### Q3. Reescrever copies de paywall com loss aversion
- **O quê:** Atualizar headlines/subtítulos por trigger para nomear a perda em vez da feature ganha. Ex: "Suas 5 perguntas grátis acabaram. Continue agora — ou espere 23 dias." (ver tabela no doc 10).
- **Por quê:** Loss aversion converte 2-3x melhor em paywalls reativos.
- **Esforço:** 1 dia.
- **Arquivos:** `Localizable.strings` (todas as `paywall.*`).
- **Risco:** zero.
- **Impacto:** +8-15% em CTR.

### Q4. Adicionar prova social numérica + FAQ inline no paywall
- **O quê:** Bloco com 3 stats reais ("27K+ sonos rastreados", "4.8⭐ no BR", "1.200+ PDFs entregues") + accordion FAQ com 4 perguntas (cancelar, compartilhar, money-back, dados).
- **Por quê:** Reduz objeções inline (Napper faz isso, ver doc 05).
- **Esforço:** 12-16h.
- **Arquivos:** `PaywallView.swift`, novos `NapletStatRow.swift`, `NapletFAQAccordion.swift`, strings.
- **Risco:** baixo.
- **Impacto:** +5-10%.

### Q5. Adicionar paywall com trial-timeline ao final do onboarding
- **O quê:** Inserir tela 11.5 (entre Loading e Completion) com formato Napper: timeline Hoje/Dia 5/Dia 7 + CTA "Experimente 7 dias grátis" + secundário "Continuar gratuito".
- **Por quê:** Pico de motivação após onboarding está sendo desperdiçado. **Maior alavanca isolada do app.**
- **Esforço:** 24-32h (variant de PaywallView + integração com RevenueCat trial + lógica de skip).
- **Arquivos:** `OnboardingView.swift`, novo `OnboardingPaywallView.swift`, `PaywallViewModel.swift`.
- **Risco:** médio. Testar exaustivamente o trial.
- **Impacto:** **+30-100%** (este é o item de maior impacto).

### Q6. Mover SignIn para depois do onboarding
- **O quê:** Refatorar `ContentView` para mostrar onboarding pré-auth (com bebê em local storage), pedir SignIn entre tela 9 e 10.
- **Por quê:** Hoje 30-50% dos usuários abandonam antes de ver valor.
- **Esforço:** 16-24h.
- **Arquivos:** `ContentView.swift`, `AppState.swift`, novo `LocalBabyStore.swift`, `OnboardingViewModel.swift`.
- **Risco:** médio. Auth é fluxo crítico.
- **Impacto:** **+20-50%** retention da fase de cadastro.

### Q7. Adicionar prova social numérica na tela 1 do onboarding
- **O quê:** Substituir "10.000 famílias já transformaram suas noites" por bloco com 3 stats + 1 depoimento curto com foto (mesmo que do círculo próximo).
- **Por quê:** Prova social no momento de maior atenção converte SignUp.
- **Esforço:** 4h.
- **Arquivos:** `OnboardingComponents.swift` (`SocialProofBanner`).
- **Risco:** zero.
- **Impacto:** +5-10%.

### Q8. Implementar primeira mensagem do Chat IA personalizada
- **O quê:** Reescrever a primeira mensagem para citar nome do bebê + último dado registrado (ver doc 11). Ex: "Oi! Sou a assistente de Alice. Vi aqui que ela dormiu 4h32 ontem com 2 acordadas. Quer que eu olhe esse padrão com você?"
- **Por quê:** Primeira impressão do diferencial. Hoje é genérica.
- **Esforço:** 4-6h.
- **Arquivos:** `ChatViewModel.swift` (`initialMessage()`), `OpenAIService.swift` (montagem do contexto), strings.
- **Risco:** baixo.
- **Impacto:** retention do Chat IA + percepção de valor.

### Q9. Adicionar contador de mensagens do Chat desde a 1ª (não só na 3ª)
- **O quê:** Badge no header do ChatView mostrando "X/5". Cores escalonadas: verde→amarelo→laranja→vermelho.
- **Por quê:** Cria consciência de escassez antes de bater o limite. Aumenta upgrade na hora certa.
- **Esforço:** 3-4h.
- **Arquivos:** `ChatView.swift`, `ChatViewModel.swift`.
- **Risco:** zero.
- **Impacto:** +5-10% conversão pelo trigger `aiChatLimit`.

### Q10. Adicionar logo + cabeçalho institucional ao PDF
- **O quê:** Inserir logo do Naplet + cabeçalho com nome do paciente, idade, sexo, período (ver doc 12).
- **Por quê:** Transforma PDF amador em documento profissional. Diferencial vs Napper.
- **Esforço:** 3-4h.
- **Arquivos:** `PDFReportService.swift`.
- **Risco:** zero.
- **Impacto:** percepção de valor; potencial aumento de share orgânico.

### Q11. ASO da App Store: novo título, subtítulo, categoria, descrição
- **O quê:**
  - Título → **"Naplet: Sono e Diário do Bebê"**
  - Subtítulo → **"Com IA e relatório para pediatra"**
  - Categoria → **Saúde e Fitness**
  - Descrição → reescrever no padrão Napper (ver doc 07)
- **Por quê:** Sobe rank em busca por "sono", comunica diferenciais únicos.
- **Esforço:** 4h (copy + submeter via App Store Connect).
- **Arquivos:** App Store Connect (não código).
- **Risco:** zero.
- **Impacto:** **+30-100% em downloads orgânicos** ao longo de 30 dias (compounding).

### Q12. Implementar PostHog para analytics no paywall
- **O quê:** Integrar PostHog SDK + trackear eventos: paywall_shown, paywall_cta_tap, paywall_dismissed, purchase_started, purchase_succeeded, purchase_failed. Trigger e plan no payload.
- **Por quê:** **Sem analytics, todos os outros itens são chutes.** Impossível otimizar sem medir.
- **Esforço:** 6-8h.
- **Arquivos:** `PaywallTrigger.swift`, `PaywallView.swift`, `PaywallViewModel.swift`, `PurchaseService.swift`, novo `AnalyticsService.swift`.
- **Risco:** baixo.
- **Impacto:** indireto mas **multiplicador**.

---

## Total Quick Wins:
- ~110-130h de trabalho concentrado (~2-3 semanas full-time, 5-7 semanas part-time)
- Cobertura de impacto: **conversão pode subir 3-10x se a base hoje é 0% real e mover para 1-3% é viável**

---

## MÉDIO PRAZO (1-2 semanas) — 8 ações

Foco: **construir base** para conversão sustentável e diferenciar contra Napper.

### M1. Redesign completo do paywall (visual + copy + estrutura)
- **O quê:** Aplicar template Napper-style: hero com timeline → prova social → FAQ → preço → CTA fixo. Remover Founders countdown estático e usar timer real do trial.
- **Por quê:** Hoje paywall parece "design indie premium"; Napper parece "produto de série A".
- **Esforço:** 32-40h (design + Swift).
- **Arquivos:** `PaywallView.swift` (refatorar inteiro), novos componentes.
- **Risco:** médio (mudar paywall em produção).
- **Impacto:** +10-20% se Quick Wins já feitos.

### M2. Implementar paywall em 2 passos (oferta + downgrade pós-recuso)
- **O quê:** Após recusa do paywall principal, mostrar sheet menor com oferta secundária (trial estendido OU 50% off no 1º mês).
- **Por quê:** Recupera 10-18% dos que recusaram.
- **Esforço:** 16-24h.
- **Arquivos:** `PaywallPresentationManager.swift`, novo `SecondaryOfferView.swift`.
- **Risco:** baixo.
- **Impacto:** +10-18% sobre quem recusou.

### M3. Refatorar onboarding para vender antes de cadastrar (estrutura completa Napper-style)
- **O quê:** Implementar telas educativas com gráficos (ritmo circadiano, pressão de sono, horas por idade), reorganizar fluxo conforme doc 09. Loading dramatizado narrado.
- **Por quê:** Onboarding como funil de venda, não como cadastro.
- **Esforço:** 40-60h (design + Swift).
- **Arquivos:** `OnboardingView.swift`, todos os step components, novos componentes de gráfico.
- **Risco:** médio.
- **Impacto:** +20-50% retention pós-instalação.

### M4. Implementar Dream Engine v1.2 (sons offline)
- **O quê:** Adicionar 12 sons offline do Pixabay (já planejado), com player nativo, controles de timer, mix.
- **Por quê:** **Table stakes ausente.** Napper tem 30+ sons. Sem isso, comparativo direto perde.
- **Esforço:** 32-40h (player + UI + assets).
- **Arquivos:** novos arquivos em `Naplet/Features/Sounds/`, `AppConfig.swift` (`enableSounds = true`).
- **Risco:** baixo.
- **Impacto:** retention + paridade competitiva.

### M5. Implementar Supabase Realtime para multi-cuidador
- **O quê:** Subscribe channels para `sleep_records`, `feeding_records`, `diaper_records` filtrados por `baby_id`. Quando outro cuidador insere/atualiza, view atualiza automaticamente.
- **Por quê:** Multi-cuidador hoje é "cuidador read-only após reabrir app". Realtime vira história contável e diferencial.
- **Esforço:** 16-24h.
- **Arquivos:** Repositories (Sleep/Feeding/Diaper), `DashboardViewModel.swift`.
- **Risco:** médio (Supabase Realtime tem nuances).
- **Impacto:** percepção de valor + retention.

### M6. Implementar streaming de respostas do Chat IA
- **O quê:** Habilitar `stream: true` na chamada à OpenAI + parser de Server-Sent Events.
- **Por quê:** UX premium. Usuário moderno espera streaming (ChatGPT, Claude, Gemini). Acelera percepção mesmo se latência total é igual.
- **Esforço:** 12-16h.
- **Arquivos:** `OpenAIService.swift`, `ChatViewModel.swift`, `ChatView.swift`.
- **Risco:** médio (parsing SSE em Swift).
- **Impacto:** retention do Chat.

### M7. Adicionar contexto completo do bebê ao Chat IA
- **O quê:** Estender `BabyContext` para incluir: padrão da semana (sono médio + variação), última mamada, fraldas das últimas 24h, despertares noturnos da semana.
- **Por quê:** Sem contexto completo, respostas genéricas. Com, vira "parceira diagnóstica" — diferencial real vs Napper.
- **Esforço:** 12-16h.
- **Arquivos:** `OpenAIService.swift` (`BabyContext`), `Repository.weeklyAggregate()` se não existir.
- **Risco:** baixo.
- **Impacto:** valor percebido do Chat.

### M8. Redesign do PDF (peso, espaço para médico, identidade visual)
- **O quê:** Implementar todas as recomendações do doc 12: logo, cabeçalho, dados antropométricos, espaço para anotações + assinatura, tipografia serif para tom institucional.
- **Por quê:** PDF vira ativo de marketing. Único diferencial defensável vs Napper.
- **Esforço:** 24-32h.
- **Arquivos:** `PDFReportService.swift` (refatoração grande), nova tabela `growth_measurements` (Supabase).
- **Risco:** baixo.
- **Impacto:** percepção + share orgânico.

---

## Total Médio Prazo:
- ~200-250h adicionais (~4-6 semanas full-time)
- Aqui o Naplet **alcança paridade competitiva** com Napper em vários eixos

---

## REFATORAÇÃO ESTRATÉGICA (3-4 semanas) — 6 ações

Foco: **infraestrutura para crescer** — analytics, A/B testing, qualidade de código, retention engines.

### R1. Implementar A/B testing no paywall
- **O quê:** Usar PostHog ou GrowthBook para A/B test de:
  - Headline (3 variantes)
  - CTA (2 variantes)
  - Preço (Founders R$89,90 vs R$99,90 vs trial-only)
  - Estrutura (timeline-first vs prova-social-first)
- **Por quê:** Sem A/B test, otimização vira chute. Com, cada decisão é mensurada.
- **Esforço:** 24-32h (incluindo backend de variants).
- **Arquivos:** novo `ExperimentService.swift`, integração em `PaywallView.swift`.
- **Risco:** baixo.
- **Impacto:** **multiplicador** (cada A/B test bem feito = 5-15% de ganho mantido).

### R2. Implementar analytics de funil completo
- **O quê:** Eventos em todos os pontos de fricção: app_open, onboarding_step_X, signup_started, signup_completed, first_baby_added, first_record_added, paywall_shown, paywall_purchased, day_2_active, day_7_active, day_30_active.
- **Por quê:** Identificar onde o usuário desiste para iterar com precisão.
- **Esforço:** 24-32h.
- **Arquivos:** `AnalyticsService.swift`, instrumentação em todas as Views críticas.
- **Risco:** baixo.
- **Impacto:** indireto — sem isso, plano não tem feedback loop.

### R3. Implementar Live Activity / Dynamic Island para sono em andamento
- **O quê:** Quando usuário inicia sono, ativar Live Activity com timer + status do bebê. Atualiza no Dynamic Island do iPhone 14+.
- **Por quê:** Diferencial visual marcante. Top dos screenshots da App Store.
- **Esforço:** 24-32h.
- **Arquivos:** novo `NapletSleepActivity.swift` no Widget Extension, `SleepTrackingViewModel.swift`.
- **Risco:** médio (ActivityKit tem peculiaridades).
- **Impacto:** marketing + retention durante sono.

### R4. Sistema de notificações inteligentes (D3, D7, D14, D30)
- **O quê:** Backend (Supabase Edge Functions + cron) que envia push notifications baseadas no comportamento:
  - D3: "Como Alice está dormindo? Confira a janela de hoje"
  - D7: "Veja o relatório semanal de Alice"
  - D14: "Pediatra na próxima semana? Gere o PDF"
  - D30: "1 mês de Naplet! Como evoluiu o sono?"
- **Por quê:** Reativação ativa = 2-3x retention.
- **Esforço:** 40-60h (Edge Functions + push setup + content engine).
- **Arquivos:** Supabase functions, `NotificationService.swift`, novo backend de templates.
- **Risco:** médio.
- **Impacto:** retention significativa.

### R5. Refatoração das 5 mega-Views (DashboardView, etc.)
- **O quê:** Quebrar DashboardView (1954 linhas), OnboardingView (925), SettingsView (819), SignInView (807), PaywallView (717) em sub-views por responsabilidade.
- **Por quê:** Build time, FPS, manutenção, testabilidade. Cada nova feature está ficando mais cara.
- **Esforço:** 40-80h (refatoração contínua, low-risk em pequenos PRs).
- **Arquivos:** as 5 mega-Views + dezenas de novos arquivos.
- **Risco:** médio (regression visual).
- **Impacto:** velocidade de desenvolvimento futuro.

### R6. Sistema de referral viral (com QR code visual de verdade)
- **O quê:** Gerar QR code visual no `ReferralView` (usar `CIQRCodeGenerator`). Adicionar deep link `naplet://invite/{code}` que abre direto no AcceptInviteView. Bônus: ambos ganham 1 mês grátis.
- **Por quê:** Hoje a feature de referral é apenas URL texto — nem QR. Perdendo viralidade orgânica.
- **Esforço:** 16-24h.
- **Arquivos:** `ReferralView.swift`, `ReferralViewModel.swift`, deep link handler em `AppDelegate.swift`.
- **Risco:** baixo.
- **Impacto:** aquisição orgânica sem custo.

---

## Resumo agregado

| Horizonte | # ações | Esforço total | Impacto principal |
|---|---|---|---|
| Emergência | 3 | 1-3 dias | Para o sangramento (RevenueCat, OpenAI) |
| Quick Wins | 12 | 110-130h (~2-3 semanas FT) | **Conversão 0→3% viável** |
| Médio Prazo | 8 | 200-250h (~4-6 semanas) | Paridade vs Napper + retention |
| Refatoração Estratégica | 6 | 168-260h (~4-6 semanas) | Infra para crescer + retention motorizada |

**Total:** ~6-7 meses de trabalho focado de 1 dev full-time. Realisticamente, com part-time + outras responsabilidades, **9-12 meses** para executar tudo.

---

## Sequência recomendada (3 meses concretos)

### Mês 1
- E1, E2, E3 (semana 1, urgente)
- Q1, Q2, Q3, Q11, Q12 (semanas 2-3) — pressão de paywall + ASO + analytics
- Q5 (semana 4) — paywall no fim do onboarding

### Mês 2
- Q6, Q7, Q8, Q9, Q10 (semanas 5-6)
- M3 (refatoração de onboarding, semanas 6-8)

### Mês 3
- M1, M2 (paywall redesign + downgrade)
- M5, M6, M7 (Supabase Realtime + Chat IA streaming + contexto)
- M4 (Dream Engine sons) em paralelo

Após o mês 3, decidir baseado em dados:
- Se conversão estabilizou em 1-3%: investir em R3 (Live Activity), R4 (notificações), R6 (referral)
- Se ainda <1%: voltar e iterar paywall + onboarding com A/B test (R1)

---

## Métricas para perseguir

| Métrica | Hoje | 30 dias | 90 dias | 180 dias |
|---|---|---|---|---|
| Conversão paywall | 0% | 1% | 2-3% | 4-6% |
| Retention D7 | ? (medir) | +20% | +50% | +100% |
| Onboarding completion | ? | 70% | 80% | 85% |
| Chat IA usage rate | ? | 30% MAU | 45% | 60% |
| App Store rating count | 2 | 20 | 100 | 500 |
| MRR | 0 | R$ 500 | R$ 5K | R$ 30K |

Esses números pressupõem que tráfego se mantém ou cresce. Sem analytics, são metas — não medições.

---

## Conclusão do plano

O Naplet **não está condenado**. Está **mal-conectado**. Tem features prontas (Chat IA, PDF, multi-cuidador, vacinas, documentos) que individualmente são tão boas ou melhores que o Napper. O problema é que não se conectam em um funil de conversão competitivo.

Os 3 itens de emergência podem **literalmente** desbloquear receita amanhã (se RevenueCat estiver em test mode).

Os 12 Quick Wins reorganizam a pressão de paywall e a arquitetura do funil — é onde está o maior ganho por hora.

Médio Prazo e Refatoração Estratégica são para sustentar o salto e construir vantagens defensáveis no nicho brasileiro de cuidado infantil.

**Se eu tivesse que apostar em UMA coisa:** Q5 (paywall com trial-timeline ao final do onboarding). Sozinho, pode dobrar conversão. É a maior alavanca isolada que existe no app hoje.
