# 11 - Auditoria Crítica do Chat IA

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Por que esse documento importa

O Chat IA é o **único diferencial real** do Naplet contra o Napper. Napper tem artigos; Naplet tem conversa. Mas se o Chat IA não entrega valor, esse diferencial vira marketing oco. Esta auditoria diz o que está acontecendo de fato — com brutalidade.

---

## 1. Primeira mensagem do bot

**O que o usuário vê:**

> "Olá! Sou o assistente de sono do Naplet. Estou aqui para ajudar com dicas sobre o sono do seu bebê. Como posso ajudar?"

Fonte: [ChatViewModel.swift:95](Naplet/Features/Chat/ViewModels/ChatViewModel.swift:95).

**Veredito: FRACO.**

- Genérica. Funciona em qualquer chatbot do mundo.
- Não diferencia vs Napper (que nem tem chat, então qualquer pergunta provocativa daria vantagem).
- Não menciona o **nome do bebê** (que já está no contexto).
- Não menciona o **último dado registrado** (que também está disponível).
- Não cria curiosidade nem provoca pergunta.

**Versão melhorada proposta:**

> "Oi! Sou a assistente de sono da Alice 👶
>
> Vi aqui que ela dormiu 4h32 ontem à noite, com 2 acordadas. Quer que eu olhe esse padrão com você?
>
> Ou me pergunta o que quiser:"
> (chips de sugestões abaixo)

Esse formato:
- usa nome do bebê na primeira frase
- referencia dado real (último sono)
- propõe diagnóstico antes de o usuário pedir
- mantém "Como posso ajudar" como fallback via chips

---

## 2. Personalidade, nome, avatar, system prompt

- **Nome:** "Naplet AI" ✅
- **Avatar:** círculo roxo com sparkles ⚠️ (genérico). Não tem mascote.
- **System prompt:** **existe e está OK**.

Trecho do prompt (fonte: [OpenAIService.swift:204-221](Naplet/Data/Services/OpenAIService.swift:204)):

```
Você é uma consultora de sono infantil experiente conversando com pais pelo chat.
Seu nome é Naplet AI.

COMO RESPONDER:
- Converse naturalmente, como uma amiga especialista falaria pelo WhatsApp
- Seja direta e prática, sem enrolação
- Use português brasileiro coloquial
- Personalize usando o nome do bebê quando fizer sentido

FORMATAÇÃO:
- Sem markdown, sem bold, sem listas numeradas
- Máximo 2-3 parágrafos curtos
- Máximo 1 emoji por resposta
```

**Análise:**

✅ Coerente, bem estruturado.
⚠️ "Personalize usando o nome do bebê **quando fizer sentido**" — o "quando fizer sentido" é vago. GPT-4o-mini interpreta livremente e às vezes esquece o nome.
❌ Falta instrução para citar **dados específicos** ("últimas X horas de sono", "padrão da semana").
❌ Falta tom emocional ("seja acolhedora, mas com autoridade").

**Correção sugerida no prompt:**

```
COMO RESPONDER:
- Use SEMPRE o nome do bebê (Alice) na primeira frase de cada resposta.
- Referencie dados específicos quando disponíveis (ex: "vi que dormiu X horas ontem").
- Tom: amiga especialista com autoridade. Acolhedora, mas confiante.
- ...
```

---

## 3. Uso do nome do bebê

**Como funciona hoje:**
- Nome PASSADO no contexto (`BabyContext.name = baby.name`)
- System prompt **sugere** uso, não obriga.
- Resultado: GPT-4o-mini às vezes usa, às vezes não.

**Veredito: INCOMPLETO.** Sem garantia. Para uma feature vendida como "personalizada", isso quebra a promessa.

**Fix:** instrução explícita no prompt (ver acima).

---

## 4. Referência a dados registrados

**Dados ATUALMENTE passados para a OpenAI** ([OpenAIService.swift:14-37](Naplet/Data/Services/OpenAIService.swift:14)):

✅ Nome do bebê
✅ Idade / descrição etária
✅ Janela de sono recomendada
✅ Sonecas recomendadas/dia
✅ Horas de sono ideal
✅ Sono total **de HOJE** (em minutos)
✅ Número de sonecas hoje
✅ Último sono registrado

**Dados NÃO passados:**

❌ Fraldas (quantidade, padrão)
❌ Alimentação (mamadas, mamadeira, sólidos)
❌ **Padrão da semana** (últimos 7 dias)
❌ Horários específicos de acordadas noturnas
❌ Temperatura, medicamentos, peso/altura

**Por que isso importa:**

Imagine o usuário perguntando: "Por que meu filho está acordando à noite?"

- **Sem contexto completo (Naplet hoje):** resposta genérica sobre rotina, ambiente, estimulação.
- **Com contexto completo:** "Vi que ele dormiu 1h a menos essa semana que na passada, e a última mamada foi às 21h (3h antes de dormir). Pode ser fome. Tente uma mamada extra no jantar."

A diferença de valor é **enorme** e é exatamente o que diferencia o Naplet do Napper.

**Fix:** estender `BabyContext.from()` para incluir:
- `weeklyAverageSleep: Double`
- `lastFeedingTime: Date?`
- `lastDiaperChange: Date?`
- `nightWakingsCount: Int` (últimas 7 noites)

E injetar no prompt:

```
Contexto da semana:
- Sono médio: X horas/noite (Y na semana passada)
- Última mamada: HH:MM
- Despertares noturnos esta semana: N
```

---

## 5. Paywall do Chat (limite de 5 mensagens)

**Como funciona:**
- Limite: 5 msgs/mês, AppStorage com reset mensal ([ChatViewModel.swift:23](Naplet/Features/Chat/ViewModels/ChatViewModel.swift:23))
- Quando restam ≤3: banner amarelo "3 mensagens restantes"
- Quando 0: banner roxo de upgrade + input desabilitado

**Problemas:**

1. **Contador não aparece desde o início.** Usuário não sabe que tem limite até chegar ao 3.
2. **Sem urgência psicológica.** "3 restantes" é discreto. O Napper provavelmente coloca "Última mensagem grátis!" com destaque.
3. **Não há gamificação.** "Você completou 5 conversas — desbloqueie ilimitado!" funcionaria.
4. **Reset mensal mata urgência.** Se hoje é dia 28 do mês, o usuário pode pensar "espero 2 dias e reseta". Reset por sessão (cada 24h) é mais agressivo.

**Fix proposto:**

- Mostrar contador desde a primeira mensagem: badge no header "X/5"
- Cores escalonadas: verde (5-4), amarelo (3-2), laranja (1), vermelho (0)
- No chegar a 1: notificação push "Última mensagem grátis do mês!"
- Considerar reset semanal em vez de mensal

---

## 6. Onboarding do Chat (perguntas sugeridas)

**Existe ✅** e está bem feito:

- Mostra `messages.count <= 1`
- 6-8 chips por idade do bebê:
  - Newborn: "Como estabelecer rotina de sono?", "Quantas horas deve dormir por dia?"
  - Infant: "Como melhorar as sonecas?", "Por que acorda muito à noite?"
  - Older: "Transição de 2 para 1 soneca?", "Melhor horário para dormir?"

**Avaliação:** ✅ **EXCELENTE** em conceito. Contextualizado por idade. Visual claro.

**Mas:** os chips são **sempre os mesmos** para uma faixa etária. Não se adaptam ao contexto real do bebê.

**Melhoria proposta:** chips dinâmicos baseados em padrão real. Ex: se o bebê acordou 3+ vezes nas últimas noites, chip: "Por que Alice está acordando 3x à noite?" — usa o NOME e o número REAL.

---

## 7. Histórico de conversas

✅ **EXISTE E ESTÁ COMPLETO.**

- Salva em UserDefaults
- Agrupa por bebê
- Máx 50 conversas
- Pode deletar
- Botão "histórico" no header
- Preview da última mensagem
- Data/hora
- Contador de mensagens

**Única melhoria:** mover para Supabase em vez de UserDefaults, para sobreviver à reinstalação do app. UserDefaults é local; se o usuário desinstala, perde tudo.

---

## 8. Retry em falhas da OpenAI

❌ **NÃO EXISTE.**

[OpenAIService.swift:129-145](Naplet/Data/Services/OpenAIService.swift:129) não tem loop de retry. `AppConfig.API.retryAttempts = 3` está declarado mas não é usado.

**Cenário ruim típico:** usuário no metrô, rede oscila, envia pergunta, falha, erro genérico, mensagem do usuário **some**. Frustração + churn.

**Fix:** envolver a chamada em `withRetry(attempts: 3, delay: 1.0)`:

```swift
func sendMessage(_ text: String) async throws -> String {
    return try await withRetry(attempts: 3, delay: 1.0) {
        try await openAI.complete(messages: ...)
    }
}
```

**Esforço:** 2 horas.

---

## 9. Modelo e custo

- **Modelo:** `gpt-4o-mini` ✅
- **Temp:** 0.7
- **Max tokens:** 500
- **Custo por mensagem:** ~$0.00012 (~0.012 centavos USD)

Para 5 msgs/mês free × 10K usuários: ~$6/mês total. **Sustentável.**

**Veredito:** ✅ boas escolhas técnicas. GPT-4o-mini é o sweet spot custo/qualidade. Não trocar.

---

## 10. Streaming

⚠️ **PARCIAL.**

- TypingIndicator (bolinhas animadas) — ✅
- Stream real palavra-por-palavra — ❌

A resposta chega em bloco após 2-5s. Usuário fica olhando bolinhas no escuro.

**Impacto:**
- Pesa na percepção de velocidade (mesmo que o tempo seja igual, percepção é diferente).
- ChatGPT, Claude, Gemini todos usam streaming. Usuário moderno espera isso.

**Fix:** habilitar `stream: true` na chamada à OpenAI + processar SSE (Server-Sent Events) palavra-a-palavra. Esforço: 1-2 dias.

---

## 11. Tratamento de erros

⚠️ **FUNCIONAL, GENÉRICO.**

Erros mapeados:
- `.notConfigured` → "O chat AI ainda não está configurado"
- `.rateLimited` → "Muitas requisições..."
- `.unauthorized` → "Erro de autenticação da API"
- `.apiError(message)` → "Não foi possível obter resposta. Tente novamente"
- `.connection` → "Erro de conexão. Verifique sua internet"

**Visual:** alert modal padrão iOS com [OK].

**Problemas:**
- Mensagens técnicas demais ("Erro de autenticação da API" → usuário pensa "meu login está errado?")
- Sem botão Retry inline
- Sem indicador visual de "tentando novamente"

**Fix:**
- Reescrever copies em linguagem humana
- Adicionar botão `[Tentar novamente]` no próprio bubble que falhou
- Inline error em vez de modal

---

## Os 5 maiores problemas (em ordem de impacto)

### 🔴 #1: Primeira mensagem genérica
**Impacto:** crítico (primeira impressão).
**Esforço:** 1h (copy + injeção de contexto).
**Fix:** reescrever com nome do bebê + último dado registrado.

### 🔴 #2: Contexto incompleto (sem fraldas, alimentação, semana)
**Impacto:** crítico (diferencial vs Napper).
**Esforço:** 1-2 dias (estender BabyContext + queries Supabase).
**Fix:** adicionar weekly average, last feeding, night wakings ao contexto.

### 🔴 #3: Sem retry automático
**Impacto:** alto (UX em rede instável).
**Esforço:** 2h.
**Fix:** wrapper withRetry.

### 🔴 #4: Paywall fraco (sem urgência psicológica)
**Impacto:** alto (LTV).
**Esforço:** 4-6h.
**Fix:** contador visível desde msg 1, cores escalonadas, push na última msg.

### 🟠 #5: Sem streaming de resposta
**Impacto:** médio-alto (UX premium).
**Esforço:** 1-2 dias.
**Fix:** stream: true + SSE parser.

---

## Conclusão

O Chat IA do Naplet **funciona**. Mas funcionar não é diferencial.

**Hoje:** chatbot genérico com limite freemium → usuário usa, não vê valor único, fecha, esquece.

**Possível:** parceira diagnóstica que cita o bebê pelo nome, conhece a semana inteira de dados, responde rápido com streaming, retoma onde parou após queda de rede. Aí vira a feature pela qual vale pagar.

A diferença não é trabalho gigante. São **5 ajustes em ~3-5 dias** que transformam o Chat IA do Naplet de "uma feature como outra" para "o motivo de eu ficar".

Esse é o segundo maior ponto de alavancagem do app inteiro, depois do onboarding (doc 09).
