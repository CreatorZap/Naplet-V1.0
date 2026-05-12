# 09 - Auditoria Crítica do Onboarding Naplet

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Resumo brutal

O onboarding do Naplet existe e tem 12 telas. O problema não é a quantidade, é a **ordem** e **o que cada tela faz**. Em particular: o usuário é forçado a fazer login **antes** de ver valor, paywall **nunca aparece** durante onboarding, e a copy é genérica demais para criar conexão emocional. Cada um desses três pontos é um vazamento.

---

## Mapa das 12 telas (confirmado em código)

| # | Tela | Propósito | Copy principal | CTA | Problema |
|---|---|---|---|---|---|
| 1 | Welcome | Gancho emocional + prova social | "Noites tranquilas começam aqui" + "10.000 famílias já transformaram suas noites" | "Começar agora" | Aparece **depois** do SignIn |
| 2 | Benefits | Value prop em 3 pilares | "Menos estresse, mais clareza" / "Noites melhores" / "Família sincronizada" | "Vamos lá!" | Ok |
| 3 | Differentials | Diferencial vs concorrentes | "IA 24h", "Relatórios PDF", "**3x mais barato**" | "Continuar" | "3x mais barato" sem ancoragem em R$ |
| 4 | Attribution | Rastreamento de marketing | "Como você descobriu?" (8 opções) | "Próximo" (skip OK) | Ok |
| 5 | Goals | Personalização inicial | "O que você quer conquistar?" (8 opções) | "Continuar" (skip OK) | Ok |
| 6 | Baby Name | Dado crítico 1 | "Qual é o nome?" | "Próximo" (disabled se vazio) | Ok |
| 7 | Baby Birth | Dado crítico 2 | "Quando %@ nasceu?" + toggle "ainda não nasceu" | "Próximo" | Ok |
| 8 | Baby Gender | Dado contextual | "%@ é..." (3 opções) | "Próximo" | Ok |
| 9 | Relationship | Tipo de cuidador | "E você, quem é?" (5 opções) | "Próximo" | Ok |
| 10 | Confirmation | Review antes de salvar | Resumo editável | "Confirmar e começar" | **Pico de motivação: sem paywall** |
| 11 | Loading | Feedback visual + save | "Preparando..." → "Calculando..." → "Personalizando..." | automático | **Sem narrativa: poderia vender** |
| 12 | Completion | Celebração + NPS | "Tudo pronto! Bem-vindo(a) à família Naplet" + confetti | "Começar a usar" | Sem ponte para pagar |

Tempo total estimado: ~115s (1m55s). Toques: ~50.

---

## Perguntas da auditoria, respostas diretas

### 1. O usuário entende valor antes ou depois de cadastrar?

**Depois.** [ContentView.swift:66-68](Naplet/App/ContentView.swift:66) exige `currentUser != nil` antes de mostrar `OnboardingView`. O SignInView vem ANTES — sem qualquer promessa de valor. Drop-off típico: 30-50%.

### 2. Tem prova social no onboarding?

Sim, mas fraca. Apenas o número "10.000 famílias" na tela 1, sem testemunhos, sem fotos, sem estrelas. Comparar com o Napper: 1M famílias + 30K reviews + Editors' Choice + depoimentos com foto.

### 3. Tem ancoragem de preço?

Vagamente. Tela 3 diz "3x mais barato que os concorrentes" sem citar:
- Concorrente nominal (Napper)
- Valor absoluto (R$)
- Período (mensal/anual)

Sem referência concreta, "3x mais barato" não convence.

### 4. Tem promessa emocional ou só funcional?

Mista, mas predominância funcional:

**Emocional:**
- "Noites tranquilas"
- "Bem-vindo(a) à família Naplet"

**Funcional:**
- "Janelas de sono ideais"
- "Menos despertares noturnos"
- "PDF profissional"

Falta nível 3: **dor específica** ("acordou 3 vezes às 3am", "você que olha o relógio na escuridão"). O Napper toca essa dor; Naplet fala em abstrações.

### 5. Promessa específica para a dor real (3 da manhã)?

**Não aparece.** Nenhuma menção a:
- "3 da manhã"
- "Despertares noturnos" como cenário (só como goal abstrato)
- "Insônia parental"
- "Cansaço extremo"

Copy genérico = baixa identificação.

### 6. Paywall: tela 12, antes, ou depois do onboarding?

**Nenhuma das opções.** Paywall aparece SOMENTE depois do onboarding completo, e mesmo assim apenas em 2/7 triggers (ver doc 03). Usuário pode usar 2 semanas sem nunca ver paywall.

**Ideal:** paywall na tela 11 (loading dramatizado vira pitch) ou na tela 12 (após confetti) — modelo Napper.

### 7. Tempo total tela 1 → dashboard

~115 segundos (1m55s) no caminho feliz, sem revisões, sem skip em goals/attribution. Aceitável, mas a percepção emocional é mais importante que o tempo cronológico.

### 8. Campos obrigatórios antes da 1ª ação útil

4 campos: nome, data nascimento, gênero, relação. Razoável. Skip permitido em attribution (4) e goals (5).

### 9. Skip option?

Sim, em 2 telas:
- 4 (Attribution): "Pular por enquanto"
- 5 (Goals): "Pular por enquanto"

Bom. Tela 6+ não tem skip (dados críticos), aceitável.

### 10. Animações / microinterações

Sim, presentes:
- Spring animation entre telas
- Progress bar animada
- Loading spinner rotativo
- Selection haptics em cliques
- Confetti na completion
- Button haptics em submit

**O onboarding NÃO é estático.** Os fundamentos visuais estão bem feitos. O problema é estratégia, não execução técnica.

---

## Os 3 maiores erros do onboarding (em ordem de impacto em conversão)

### 🔴 ERRO #1: Autenticação obrigatória antes do value prop (IMPACTO CRÍTICO)

**Problema:**
[ContentView.swift:58-68](Naplet/App/ContentView.swift:58) mostra SignInView (Apple/Google/Email) como primeiro passo se `hasCompletedOnboarding == false` E `currentUser == nil`. A copy emotiva da tela 1 só aparece **depois** que o usuário criou conta.

**Por que custa caro:**
- Princípio universal de UX: mostre valor antes de pedir comprometimento.
- Drop-off em SignIn de apps mobile sem pre-pitch: tipicamente **30-50%**.
- Usuário entra na App Store, baixa, abre e vê: "Login com Apple". Pensa: "Mas eu nem sei o que esse app faz." Fecha.

**Fix:**
1. Mover SignIn para depois da tela 9 (Relationship) ou 11 (Loading).
2. Permitir bebê em local storage temporário até o login.
3. Tela 1 deveria ser hero + promessa SEM CTA de login — só "Começar".

**Esforço:** Médio (1-2 dias). Refatorar `AppState`, `ContentView`, criar `LocalBabyStore` para dados pré-auth.

---

### 🔴 ERRO #2: Copy genérica, sem dor visceral (IMPACTO ALTO)

**Problema:**
Telas 1-3 falam em abstrações ("noites tranquilas", "menos despertares"). Não tocam o usuário no momento concreto. Comparar com a abordagem do Napper, que **dramatiza problemas com gráficos** (Problema #1: ritmo circadiano em formação; Problema #2: pressão de sono diferente; Problema #3: necessidades em constante mudança) e só DEPOIS vende a solução.

**Por que custa caro:**
- Promessa abstrata → "interessante, vou ver depois" (não converte)
- Dor concreta → "esse app sabe o que eu vivo" (converte)

**Fix:**
Reescrever as telas 2-3 para **3 problemas reais**:

- "Você sabe quanto seu bebê dormiu ontem?" → maioria não sabe exato
- "Quando ele vai precisar dormir hoje?" → maioria não sabe
- "Como contar isso pro pediatra na próxima consulta?" → poucos têm relatório

Depois (telas 4-5), apresentar a solução do Naplet **para cada problema**:
- Tracker preciso de sono
- IA que prevê janelas
- PDF para pediatra

**Esforço:** Baixo (1 dia copy + 1 dia design). Strings localizáveis + reordenar telas.

---

### 🟠 ERRO #3: Zero monetização durante o pico de motivação (IMPACTO ALTO)

**Problema:**
O usuário completou as 12 telas, viu confetti, recebeu "Bem-vindo à família Naplet". Esse é o **maior pico de motivação da jornada**. E o que o Naplet faz? Joga ele direto no Dashboard sem mencionar plano, preço ou trial.

**Por que custa caro:**
- O Napper usa exatamente esse momento para mostrar paywall com trial de 7 dias.
- Naplet deixa o usuário ir para o Dashboard, onde ele faz 2 registros, fecha o app, e talvez nunca mais volta. Sem ter visto preço, sem ter comprado.

**Fix:**
Adicionar tela 11.5 (entre Loading e Completion) ou substituir Completion: **paywall com trial gratuito**, mesmo formato do Napper:
- Timeline (Hoje grátis → Dia 5 lembrete → Dia 7 cobrança)
- Prova social numérica
- 2 CTAs: "Experimente 7 dias grátis" (primário) + "Continuar sem trial" (secundário, fonte menor)

**Esforço:** Médio (3-4 dias). Adicionar tela ao TabView, criar variante de PaywallView com trial-timeline, integrar com RevenueCat trial.

---

## 3 erros menores (mas relevantes)

| # | Erro | Esforço | Impacto |
|---|---|---|---|
| 4 | "3x mais barato" sem ancoragem em R$ | 30 min (copy) | Médio |
| 5 | Prova social só com 1 número (10K) sem foto/depoimento | 2-4h (design + copy) | Médio |
| 6 | Tela 11 (Loading) com mensagens genéricas em vez de narrativa | 2h (strings + timing) | Baixo |

---

## Comparativo rápido vs Napper

| Aspecto | Naplet | Napper |
|---|---|---|
| SignIn no início | ✗ sim | ✓ não (vem após onboarding) |
| Quantidade de telas | 12 | ~20 |
| Personalização com nome do pai E do bebê | parcial (só bebê) | sim (Edy + Alice em mesma tela) |
| Telas educativas com gráficos | não | 3 (ciência do sono) |
| Mascote 3D próprio | não | sim (nuvem, bebê amarelo, pai roxo) |
| Loading dramatizado | parcial (4 mensagens) | sim (lego → bola de cristal) |
| Paywall no final | não | sim (trial + timeline) |
| Reforço emocional ("Uau! Time incrível!") | parcial (confetti final) | sim (tela 7095 dedicada) |
| Prova social antes do paywall | número solto | 1M + 30K reviews + Editor's Choice |

---

## Conclusão

O onboarding atual do Naplet **não está quebrado**. Ele apenas não foi pensado como **funil de conversão** — foi pensado como "cadastro com onboarding". A diferença é cara: o Napper usa cada tela para construir valor que justifica o paywall final, enquanto o Naplet usa as telas para coletar dados.

Se o Edy fizesse só 3 mudanças nessa frente — mover SignIn para o fim, reescrever copy com dor concreta, adicionar paywall com trial após Loading — o salto em conversão pode ser de 3-10x. **É o ponto de maior alavancagem do app inteiro.**
