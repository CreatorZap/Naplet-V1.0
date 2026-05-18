# Naplet - Lições do Sprint 1 (Build 22/23)

Data: 16 de maio de 2026
Autor: Edy Souza
Contexto: Após sequência de 3 builds intensas com debug do Bug 32

## Lições técnicas

1. Apple ID compartilhado em testes dá falso positivo de bug.
2. Family Sharing é hipótese número 1 quando testando IAP com 2 devices diferentes.
3. Active customers não é igual a active subscriptions no dashboard RevenueCat.
4. RevenueCat tem configuração "Restore Behavior" que pode ser ajustada para apps com login obrigatório (L1 - sprint futuro).
5. Validar dados antes de entrar em pânico.
6. Linha temporal de bugs é evidência crítica para investigação.

## Lições de processo

1. Quando 2 ou mais chats discordam, validar com dados objetivos.
2. Métricas reais valem mais que teorias plausíveis.
3. Family Sharing é a primeira coisa a checar em "bug de IAP".
4. Testes em sandbox podem mostrar comportamento diferente de produção.

## Conclusão do Bbug. O comportamento observado foi:
- Esposa do Edy criou conta nova no iPhone dela
- Apple ID dela tinha acesso à assinatura Founders via Family Sharing
- App refletiu o acesso corretamente
- Não houve vazamento de receita

Build 23 está pronta para revisão da Apple.

## Tarefas para próximo sprint

### Defesa em profundidade (RevenueCat)
- L1: Mudar Restore Behavior no dashboard de "Transfer" para "Keep with original"
- L2: Check de originalAppUserId vs supabaseUserId em PurchaseService.swift
- L3: Espelhar check em OnboardingPaywallViewModel.swift
- L4: Espelhar check em PaywallViewModel.swift
- L5: Pre-flight check antes de mostrar paywall
- L6: Edge Function Supabase para validação server-side

### Polimento (auditoria de paywall)
- P1: Envolver developer bypass em #if DEBUG (10 min)
- P2: Sequencializar StoreKit 2 fallback (15 min)
- P3: Tratar productAlreadyPurchasedError no paywall in-app (30 min)
- P4: Validação server-side de entitlement (4-8h)

### Administrativo
- Cadastrar cartão no R(antes de chegar a US$ 2500 MTR)
- Adicionar FAQ sobre Family Sharing
- Configurar Google Analytics 4 no naplet.app

## Métricas do projeto neste momento

- 240 active customers nos últimos 28 dias
- 1 active subscription paga (US$ 23 dos últimos 28 dias)
- 1 venda confirmada do México há 2 dias
- MRR atual: US$ 2
- App live na App Store BR desde 8 de março de 2026
- Build 23 pronta para revisão da Apple

## Build 23 - O que foi corrigido

1. Bug 31: safe area Settings (commit c3e3310)
2. Bug 9: teclado Alimentação Sólida (commit eab0994)
3. Bug 6: card Energia em alta com cor errada (commit 2cfd56c)
4. Bug 10b: Documentos pull-to-refresh (commit 0370642)
5. Bug 10: Vacinação race condition (commit c7a0f64)
6. Bug 32: regressão de auto-restore removida (commit b3f5ffd)
7. Bug 33: padding card WakeWindow (commit d095791)
8. Bump versão para Build 23 (commit 0e45e84)

## Reflexão pessoal

Em 3 dias, atravessei 6 bugs críticos, 1 regressão crítica caçada, 2 auditorias completas, 3 builds envht, 1 falso positivo de bug investigado e descartado por evidência.

Aprendi que validar com dados é mais importante que reagir com pressa. Aprendi que múltiplas análises conflitantes podem todas estar parcialmente certas. Aprendi que a engenharia real é sobre integrar evidências, não seguir o primeiro caminho proposto.

Build 23 vai para a Apple amanhã.
