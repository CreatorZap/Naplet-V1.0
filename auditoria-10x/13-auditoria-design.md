# 13 - Auditoria de Design e Sensação Premium

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Premissa

"Premium" não é um decorativo — é a soma de dezenas de microdecisões: tipografia, espaçamento, ilustração, animação, haptic, transição. Cada uma sozinha é invisível; juntas, criam a sensação que faz o usuário pensar "vale o que pago". Esta auditoria compara o Naplet ao Napper nesses pontos.

Como o Naplet está sendo executado no simulador é difícil cobrir aqui sem screen capture, uso evidências de código (cores hardcoded, fontes, modificadores) e os prints do Napper para inferir gaps.

---

## Tipografia

### Naplet
- Fonte do sistema (`UIFont.system`).
- Tamanhos variados: 26pt bold para títulos, 11-12pt para corpo (no PDF).
- Em SwiftUI: `.font(.system(size:weight:))` — sem variant family própria.
- **Sem fonte custom**.

### Napper
- Logo em **serif minúsculo** (provavelmente Tiempos ou similar): assinatura única.
- Corpo em sans-serif limpa, possivelmente system rounded.
- Headlines em 28-36pt bold, hierarquia clara.

### Veredito
**Napper vence.** A logo serif vira reconhecimento visual instantâneo.

### Recomendação para o Naplet
- Adotar 1 fonte custom para títulos (Fraunces, Playfair, ou Tiempos — gratuitas no Google Fonts).
- Manter SF Pro para corpo (já é boa).
- Padronizar 5 tamanhos no app: 32 / 22 / 17 / 15 / 13. Nunca mais que 5.

---

## Espaçamento

### Naplet (evidências de código)
- `.padding(.horizontal, 24)` em vários lugares
- Mas no PDF: 30-40pt entre seções, **inconsistente** (auditoria técnica confirmou)
- Em SwiftUI: muitos `Spacer()` soltos sem grid

### Napper (prints)
- Espaçamento generoso entre cards (16-24pt)
- Sempre safe-area respeitada
- CTAs flutuantes com 32pt do bottom

### Veredito
**Empate técnico, mas Napper transmite mais "respiro".**

### Recomendação
Definir um `NapletSpacing` enum: `xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`. Usar em **todo lugar**, banir spacing arbitrário.

---

## Cores

### Naplet
- Roxo primário (variantes não documentadas)
- Em código: cores via `NapletColors` enum mas com variações ad hoc
- No PDF: roxo forte 0.4,0.2,0.6 (intenso, quase pesado)

### Napper
- Roxo-noite suave + azul-marinho com gradiente
- Pontos brancos (estrelas) e nebulosa sutil de background
- Cores **sempre dark**, sem alternância

### Veredito
**Napper vence em coesão visual.** O Naplet tem boas cores mas não estabeleceu uma paleta canônica.

### Recomendação
1. Escolher 1 paleta primária (5 cores) e 1 secundária (3 cores). Documentar em [NapletColors.swift](Naplet/Core/Design/NapletColors.swift).
2. Validar que o roxo do paywall = roxo do dashboard = roxo do PDF.
3. Adotar background gradient consistente em telas hero (onboarding, paywall).

---

## Ícones

### Naplet
- SF Symbols (provavelmente). Multi-color e SF Symbols 5.

### Napper
- 100% mascotes 3D + ícones custom em cards
- **Não usa SF Symbols** em destaques (só em barras/funcionais)

### Veredito
**Napper vence.** Mascotes 3D são assinatura inalcançável.

### Recomendação
- Não tentar mascote 3D no curto prazo (custo alto).
- Investir em **ilustrações flat** próprias para 8 telas-chave: 12 telas de onboarding (já tem componentes), paywall hero, dashboard greeting, empty states.
- Custo: 1 designer freelancer × 2 semanas = R$ 4-8k. ROI alto.

---

## Microinterações & haptic

### Naplet
- Haptic em selection ([OnboardingViewModel.swift:257-259](Naplet/Features/Onboarding/ViewModels/OnboardingViewModel.swift:257)) ✅
- Haptic em submit ([OnboardingComponents.swift:244-246](Naplet/Features/Onboarding/Components/OnboardingComponents.swift:244)) ✅
- Confetti em onboarding final ✅
- Spring animation em transições ✅

### Napper
- Loading dramatizado (lego → bola de cristal)
- Progress bar fluida no topo
- Animações 3D em mascotes

### Veredito
**Naplet TEM microinterações boas.** Napper tem MAIS visualmente, mas é menos do que parece à primeira vista.

### Recomendação
- Adicionar haptic em **mais cliques chave**: salvar sono, salvar fralda, dispensar paywall, completar tarefa.
- Adicionar `.symbolEffect(.bounce)` ou `.symbolEffect(.pulse)` em ícones que indicam ação concluída.
- Na tela de Loading do onboarding (tela 11), substituir spinner por animação narrada ("Calculando ritmo de Alice... ✨" → "Ajustando recomendações... 🌙" → "Quase pronto...").

---

## Empty states

### Naplet
- Confirmar visualmente (a auditar). Provavelmente: telas brancas com texto.

### Napper
- Provavelmente bem desenhado (todo app premium investe nisso)

### Recomendação para Naplet
Cada feature precisa ter empty state desenhado:
- Sleep history vazia: "Você ainda não registrou sono. Que tal iniciar?" + botão grande
- Vacinação: "Adicione a primeira vacina de Alice" + ilustração
- Documentos: "Sem documentos. Adicione CPF, certidão..." + ilustração

Hoje provavelmente algumas telas mostram só uma tabela vazia. Trocar para empty states caprichados.

---

## Dark mode

### Naplet
- Suporta? (a confirmar) Provavelmente sim, mas sem polish específico.

### Napper
- **Dark mode é obrigatório, é a identidade**. Light mode talvez nem exista.

### Recomendação
- Auditar dark mode no Naplet. Se existir, garantir que cores roxas mantêm contraste WCAG AA.
- Considerar dark-mode-first design (luz das telas é menor à noite, quando o app é mais usado).

---

## Transições e navegação

### Naplet
- `.fullScreenCover`, `.sheet` padrão iOS.
- Transições spring em onboarding.

### Napper
- Bottom sheets para confirmações em vez de full-screen
- Página inteira escorregando para a direita (parece NavigationStack tradicional)

### Recomendação
- Usar bottom sheets para confirmações curtas (ex: "Salvar sono?") em vez de modais full-screen.
- Padronizar transições: hero (slide), modais (fade-and-scale), forms (slide up).

---

## Os 7 ajustes de design que mais elevariam a percepção premium

### 1. Adotar 1 fonte custom para títulos (Fraunces ou similar)
**Esforço:** 2h.
**Impacto:** percepção premium imediata.

### 2. Definir e aplicar uma paleta canônica em todo o código
**Esforço:** 6-8h (refatorar `NapletColors` + grep por hex).
**Impacto:** coesão visual.

### 3. Investir em 8 ilustrações flat custom (1 designer × 2 semanas)
**Esforço:** orçamento R$ 4-8k.
**Impacto:** identidade visual reconhecível.

### 4. Refatorar Loading do onboarding (tela 11) em narrativa
**Esforço:** 1 dia.
**Impacto:** sensação de "plano único" antes do paywall.

### 5. Empty states caprichados para 6 features principais
**Esforço:** 2 dias.
**Impacto:** primeira impressão de cada feature.

### 6. Bottom sheets em vez de modais full-screen
**Esforço:** 1 dia (refatorar 4-5 sheets).
**Impacto:** sensação leve, não-burocrática.

### 7. Mais haptics e symbol effects em ações finalizadas
**Esforço:** 4-6h.
**Impacto:** sensação de "qualidade no detalhe".

---

## Prioridade

Se o Edy puder fazer **apenas 2** desses 7:

- **#1 (fonte custom para títulos)** — maior salto perceptivo por hora investida
- **#3 (ilustrações flat custom)** — único item que constrói **moat visual** que ninguém copia em 2 semanas

Os outros 5 são polish acumulativo. Sem eles o Naplet sente como "app indie bem feito"; com eles, sente como "produto sério".

---

## Conclusão

Naplet **não é feio**. É anonímo. A maioria das microdecisões está OK, mas nenhuma é assinada — você não consegue identificar o app de relance. Napper você identifica em 1 segundo (mascote nuvem 3D + dark estrelado).

A boa notícia: investir em design custom é o tipo de melhoria que **não quebra com refatoração futura**. Uma fonte custom dura anos. Uma paleta documentada dura anos. Ilustrações próprias duram anos.

Investimento total estimado para subir 2 níveis de "premium feel": R$ 5-12k em design + 5-7 dias de Swift. Vale.
