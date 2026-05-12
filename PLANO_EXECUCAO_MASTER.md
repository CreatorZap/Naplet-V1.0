# PLANO MESTRE DE EXECUÇÃO NAPLET
## Da auditoria à conversão real | Versão 1.0

---

## FILOSOFIA DESTE PLANO

Existem 10 problemas críticos. Não dá para atacar todos juntos. A ordem foi desenhada para que cada sprint **destrave o seguinte**:

- Sprint 0 e 1 destravam a possibilidade matemática de gerar receita
- Sprint 2 destrava a medição (sem medir, todo plano vira chute)
- Sprint 3 destrava a percepção de valor real do app
- Sprint 4 nivela com o concorrente em table stakes

Pular ordens, fazer Sprint 3 antes do 1, é polir lataria de carro sem motor.

---

## SPRINT 0: EMERGÊNCIA (HOJE, 1 a 3 horas)

**Risco se ignorado:** prejuízo financeiro infinito por chave OpenAI exposta, zero receita perpétua por RevenueCat em sandbox.

### Ações

| Ordem | Ação | Tempo | Onde |
|---|---|---|---|
| 1 | Acessar painel OpenAI, revogar a chave atual | 5 min | platform.openai.com |
| 2 | Gerar nova chave OpenAI, copiar para gerenciador de senhas, **não colocar no código** | 5 min | platform.openai.com |
| 3 | Verificar limite de gasto da nova chave (recomendado: 50 USD/mês) | 5 min | platform.openai.com |
| 4 | Acessar dashboard RevenueCat, conferir se está em Production ou Sandbox | 5 min | app.revenuecat.com |
| 5 | Se estiver em Sandbox, ir em Project Settings, alternar para Production | 10 min | RevenueCat |
| 6 | Confirmar Bundle ID `app.naplet.ios` e chave que começa com `appl_` (não `test_`) | 5 min | RevenueCat |
| 7 | Verificar logs do RevenueCat das últimas semanas: alguma compra real apareceu como transaction sandbox? | 15 min | RevenueCat |
| 8 | Documentar tudo no arquivo `EMERGENCIA_LOG.md` na raiz do projeto | 15 min | Projeto |

### Critério de saída do Sprint 0

- [ ] Chave OpenAI antiga revogada e confirmada inativa
- [ ] Nova chave OpenAI guardada fora do código
- [ ] RevenueCat confirmado em modo Production
- [ ] Chave de API do RevenueCat começa com `appl_`, não `test_`
- [ ] Bundle ID confirmado em produção
- [ ] Documentação salva em `EMERGENCIA_LOG.md`

**Atenção:** **NÃO** ainda removeu a chave do `AppConfig.swift` neste sprint. Essa remoção segura, com proxy via Edge Function, vem no Sprint 1.

---

## SPRINT 1: DESTRAVAR RECEITA (2 a 3 dias)

**Hipótese de impacto:** apenas mover o paywall para o fim do onboarding pode dobrar conversão. Mover o SignIn para depois pode reduzir drop-off em 30%.

### Bloco 1.1: Segurança da OpenAI (4 a 6h)

1. Criar Edge Function no Supabase chamada `openai-proxy`
2. Armazenar a nova chave OpenAI como secret na Edge Function
3. Edge Function valida `Authorization` do usuário Supabase antes de chamar OpenAI
4. Atualizar `OpenAIService.swift` para chamar a Edge Function, não a OpenAI direta
5. Remover a chave do `AppConfig.swift`
6. Build de teste, validar Chat IA funcionando
7. Commit em branch `sprint-1/openai-proxy`

### Bloco 1.2: Confirmar e blindar RevenueCat (2 a 3h)

1. Confirmar `AppConfig.swift:49` usando chave `appl_` (não `test_`)
2. Adicionar verificação de runtime: app loga `[RC] modo: \(Purchases.shared.isSandbox ? "SANDBOX" : "PROD")` no console
3. Fazer compra teste em ambiente sandbox com conta de teste Apple
4. Validar evento no RevenueCat dashboard
5. Commit em branch `sprint-1/revenuecat-validation`

### Bloco 1.3: Paywall pós-onboarding (8 a 12h)

A maior alavanca isolada do plano.

1. Criar nova tela `OnboardingPaywallView.swift` em `Features/Onboarding/Views/`
2. Inserir entre tela 11 (Confirmation/Loading) e tela 12 (Completion)
3. Estrutura visual obrigatória:
   - Topo: nome do bebê + foto avatar gerado
   - Headline: "O sono da {nome do bebê} começa agora"
   - 4 benefícios concretos com ícones SF Symbols
   - Card de oferta Founders com preço, riscado, badge "EXCLUSIVO LANÇAMENTO"
   - Trial timeline visual (3 etapas: Hoje grátis → Dia 12 lembrete → Dia 14 cobrança)
   - CTA principal: "Começar 14 dias grátis"
   - CTA secundário discreto: "Continuar com plano gratuito"
4. Skip permitido, mas registra evento `onboarding_paywall_skipped` para analytics
5. Se aceitar trial: dispara compra via RevenueCat, segue para Completion
6. Se pular: segue para Completion normal
7. Commit em branch `sprint-1/onboarding-paywall`

### Bloco 1.4: Mover SignIn para depois do valor (6 a 8h)

1. Refatorar `ContentView.swift:66-68` removendo SignIn obrigatório
2. Permitir uso anônimo do onboarding até a tela 9 (Confirmation)
3. SignIn obrigatório aparece **na tela 10**, após o usuário já ter investido no fluxo
4. Persistir dados de onboarding em UserDefaults temporariamente
5. Migrar para Supabase Auth após SignIn bem-sucedido
6. Suporte a Sign in with Apple obrigatório
7. Commit em branch `sprint-1/deferred-signin`

### Bloco 1.5: Reativar oferta Founders (2 a 3h)

O período original expirou em 22/04/2026. Duas opções:

**Opção A (recomendada):** estender o período Founders por mais 90 dias, justificado pela "fase de lançamento expandida".
- Atualizar `foundersEndDate` em PaywallViewModel para 22/07/2026
- Manter R$59,90/ano

**Opção B:** criar novo offering "Early Access" com preço diferente.

Decidir antes de executar.

### Critério de saída do Sprint 1

- [ ] Chave OpenAI fora do código, via Edge Function
- [ ] RevenueCat confirmado em produção, com log de runtime ativo
- [ ] Compra de teste validada em sandbox
- [ ] Paywall aparece ao final do onboarding
- [ ] SignIn movido para depois do valor
- [ ] Oferta Founders reativada e visível
- [ ] Smoke test completo passa: instalar, onboarding, paywall, skip, dashboard
- [ ] Build submetido como v1.2 build 20 para TestFlight

---

## SPRINT 2: MEDIR E WIRING COMPLETO DE PAYWALL (3 a 5 dias)

Sem analytics, qualquer mudança vira chute. Sem os 5 triggers, 71% da pressão de pagamento planejada não acontece.

### Bloco 2.1: Integrar PostHog (4 a 6h)

1. Adicionar PostHog SDK via SPM
2. Inicializar no `NapletApp.swift` com chave de projeto
3. Identificar usuário com `posthog.identify(userId)` após SignIn
4. Eventos mínimos obrigatórios:
   - `app_opened`
   - `onboarding_started`
   - `onboarding_step_completed` (com parâmetro `step_number`)
   - `onboarding_paywall_shown`
   - `onboarding_paywall_accepted`
   - `onboarding_paywall_skipped`
   - `paywall_shown` (com parâmetro `trigger`)
   - `paywall_purchase_completed`
   - `paywall_purchase_failed`
   - `sleep_record_created`
   - `chat_message_sent`
   - `pdf_generated`
5. Commit em branch `sprint-2/posthog-analytics`

### Bloco 2.2: Implementar 5 triggers de paywall mortos (10 a 14h)

Para cada um, código + analytics:

1. **pdfReport**: dispara quando usuário tenta gerar PDF e é free. Modal: "Relatórios para o pediatra são Premium."
2. **multipleBabies**: dispara ao tentar adicionar 2º bebê. Modal: "Acompanhe quantos bebês quiser com Premium."
3. **historyLimit**: dispara ao tentar ver histórico anterior a 7 dias. Modal: "Veja todo o histórico de {nome do bebê} com Premium."
4. **settingsUpgrade**: card permanente em Settings com countdown da oferta Founders.
5. **softPrompt**: aparece após 5º registro de sono no mesmo dia, modal não-bloqueante com "Está usando bastante o Naplet, conheça o Premium."

### Bloco 2.3: Refinar paywall principal (6 a 8h)

1. Adicionar countdown visual da oferta Founders (dias restantes)
2. Adicionar ancoragem direta: "Napper cobra R$114,90/ano, Naplet cobra R$59,90"
3. Adicionar 3 depoimentos curtos (pode usar os fictícios da descrição da App Store, depois substituir por reais)
4. Botão "Restaurar compra" visível e funcional
5. Links para Termos e Privacidade obrigatórios

### Bloco 2.4: Tela de downgrade após recusa (4 a 6h)

Após primeira recusa de paywall, próxima tentativa mostra:
- "Que tal experimentar grátis primeiro?"
- Reforça trial de 14 dias
- Adiciona opção mensal R$12,90 como entrada mais barata
- Se recusar novamente, espera 48h antes de mostrar paywall de novo

### Critério de saída do Sprint 2

- [ ] PostHog recebendo eventos em produção
- [ ] Dashboard de funil mínimo criado no PostHog
- [ ] Os 7 triggers de paywall disparam corretamente
- [ ] Cada trigger tem evento de analytics
- [ ] Tela de downgrade implementada
- [ ] Smoke test passa

---

## SPRINT 3: REFINAR PROPOSTA DE VALOR (1 a 2 semanas)

Agora que tem fluxo de receita e medição, vale investir nos diferenciais reais.

### Bloco 3.1: Chat IA personalizado (12 a 16h)

1. Estender `BabyContext` em OpenAIService para incluir:
   - Nome, idade exata em meses, gênero
   - Padrão de sono dos últimos 7 dias (média, variância, melhor horário)
   - Padrão de alimentação dos últimos 7 dias
   - Última fralda, último banho, última temperatura
   - Marcos de desenvolvimento recentes
   - Vacinas pendentes
2. Reescrever system prompt:
   - Persona definida (consultora de sono, calorosa, baseada em evidência)
   - Sempre usa o nome do bebê
   - Sempre referencia dados reais quando relevante
   - Respostas em 3 a 5 frases, evita textão
3. Adicionar perguntas sugeridas na primeira sessão:
   - "Por que ela acorda de madrugada?"
   - "Como melhorar a soneca da tarde?"
   - "Está na hora de tirar a mamada noturna?"
4. Persistir histórico de conversa por bebê

### Bloco 3.2: PDF para pediatra premium (10 a 14h)

1. Redesenhar layout com identidade institucional:
   - Cabeçalho com logo Naplet
   - Bloco de dados do bebê (nome, idade, peso, altura, foto)
   - Seção de sono com gráfico de 7, 14 e 30 dias
   - Seção de alimentação com gráfico de barras
   - Seção de fraldas e saúde
   - Marcos de desenvolvimento
   - Vacinas aplicadas e pendentes
   - Campo para anotações do pediatra
   - Rodapé com data, versão do app e QR Code para validação
2. Usar `SwiftUI` + `PDFKit` para layout vetorial
3. Salvar PDF localmente e oferecer compartilhamento via WhatsApp, Mail, AirDrop

### Bloco 3.3: Realtime multi-cuidador (8 a 12h)

1. Ativar Supabase Realtime em `sleep_records`, `feeding_records`, `diaper_records`, `bath_records`, `health_records`
2. Implementar listener em cada repository
3. Adicionar indicador visual "cuidador X registrou agora há pouco"
4. Validar performance com 5 cuidadores ativos

### Bloco 3.4: Revisão completa de RLS (6 a 8h)

1. Auditar policies de cada tabela
2. Garantir que cuidador aceito **não vê** registros anteriores ao aceite
3. Adicionar coluna `caregiver_accepted_at` se necessário
4. Filtrar histórico por essa data nos repositories
5. Testar com 2 contas distintas

### Critério de saída do Sprint 3

- [ ] Chat IA usando nome do bebê e contexto real em 100% das mensagens
- [ ] PDF redesenhado, aprovado visualmente pelo Edy
- [ ] Realtime funcionando entre 2 dispositivos
- [ ] RLS validado sem vazamento retroativo
- [ ] Smoke test ampliado passa

---

## SPRINT 4: TABLE STAKES E DIFERENCIAIS (2 a 3 semanas)

### Bloco 4.1: Dream Engine, sons offline (16 a 24h)

1. Estruturar pasta `Resources/Sounds/` com os 12 MP3 (white, pink, brown, blue, violet, grey noises + heartbeat já gerados; resto do Pixabay)
2. Player com `AVAudioEngine`
3. Background audio configurado em Info.plist
4. Timer de desligamento automático
5. Favoritos por bebê
6. Mix simples (até 2 sons sobrepostos)

### Bloco 4.2: Live Activity e Dynamic Island (8 a 12h)

1. ActivityKit para sono em andamento
2. Compact, Expanded e Minimal states
3. Atualização via Push tokens

### Bloco 4.3: Notificações inteligentes (6 a 10h)

1. Notificação dia 3: "Como foram os primeiros dias com {nome do bebê}?"
2. Notificação dia 7: "1 semana de Naplet! Veja seu primeiro gráfico."
3. Notificação dia 14: "Fim do trial. Veja o que você descobriu sobre o sono de {nome do bebê}."
4. Predictive nap notification (já em desenvolvimento)

### Bloco 4.4: Microinterações e polimento visual (8 a 12h)

1. Haptic feedback em todos os toques principais
2. Loading skeletons em fetches longos
3. Empty states ilustrados
4. Confetti em momentos de celebração (primeiro registro, primeiro trial, etc)
5. Transições suaves entre telas

---

## MÉTRICAS DE SUCESSO

| Métrica | Baseline atual | Meta Sprint 1 | Meta Sprint 2 | Meta Sprint 4 |
|---|---|---|---|---|
| Trial iniciado / instalações | 0% | 5% | 10% | 15% |
| Trial → pago | N/A | 30% | 40% | 50% |
| Receita mensal | R$0 | R$200 | R$800 | R$2.500 |
| Avaliações App Store | 2 | 5 | 15 | 50 |
| Avaliação média | 5.0 | 4.8+ | 4.8+ | 4.7+ |

---

## SE TUDO DER CERTO

Em 30 dias após o início do Sprint 1, com 46 ativos atuais e supondo continuidade de instalações orgânicas:

- Conservador: 1 a 3 assinantes pagantes, R$150 a R$200 de receita mensal
- Realista: 5 a 8 assinantes, R$400 a R$700
- Otimista: 12 a 20 assinantes, R$1.000 a R$1.800

O valor real não é o número absoluto. É **provar que o produto converte**. Uma vez provado, marketing pago faz sentido.

---

*Documento operacional. Atualize após cada sprint concluído.*
