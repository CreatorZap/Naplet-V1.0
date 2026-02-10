# REGRAS OBRIGATORIAS — LEIA ANTES DE QUALQUER MODIFICACAO

## [!] REGRA #1: NAO QUEBRAR FUNCIONALIDADES EXISTENTES

Antes de modificar QUALQUER arquivo:
1. **PERGUNTE** o que o codigo atual faz
2. **ENTENDA** o fluxo completo
3. **PRESERVE** toda logica que ja funciona
4. **ADICIONE** codigo novo sem remover o existente
5. **TESTE** mentalmente se sua mudanca pode afetar outras partes

### [X] NUNCA faca isso:
- Remover codigo "que parece nao usado"
- Substituir funcoes inteiras sem entender o contexto
- Refatorar codigo que ja funciona
- Mudar nomes de variaveis/funcoes existentes
- Alterar ordem de execucao de codigo assincrono

### [OK] SEMPRE faca isso:
- Adicionar codigo NOVO sem mexer no existente
- Comentar codigo antigo em vez de deletar (se necessario)
- Perguntar antes de modificacoes grandes
- Mostrar o diff antes de aplicar

---

## [!] REGRA #2: ORDEM DE MODIFICACAO

Quando precisar modificar algo:

1. **PRIMEIRO:** Me mostre o codigo ATUAL
2. **SEGUNDO:** Explique o que vai mudar e POR QUE
3. **TERCEIRO:** Me mostre o codigo NOVO (diff)
4. **QUARTO:** Pergunte "Posso aplicar essa mudanca?"
5. **QUINTO:** So entao aplique

---

## [!] REGRA #3: ARQUIVOS CRITICOS — NAO MODIFICAR SEM PERMISSAO

Estes arquivos sao CRITICOS e qualquer modificacao pode quebrar o app:

### Core (NUNCA modificar sem pedir):
- `AppDelegate.swift`
- `ContentView.swift`
- `NapletApp.swift`
- `SupabaseService.swift`
- `AppConfig.swift`

### ViewModels (CUIDADO MAXIMO):
- `DashboardViewModel.swift`
- `SleepViewModel.swift`
- `OnboardingViewModel.swift`
- `AuthViewModel.swift`

### Repositories (CUIDADO MAXIMO):
- `SleepRepository.swift`
- `BabyRepository.swift`
- `FeedingRepository.swift`
- `*Repository.swift` (qualquer um)

### Services (CUIDADO MAXIMO):
- `PDFReportService.swift`
- `PurchaseService.swift`
- `OpenAIService.swift`

---

## [!] REGRA #4: FLUXOS QUE FUNCIONAM — NAO TOCAR

Estas funcionalidades estao 100% funcionando. NAO MODIFIQUE:

- [OK] Autenticacao (Sign in with Apple + Email)
- [OK] Cadastro de bebe
- [OK] Registro de sono (iniciar/parar timer)
- [OK] Registro de alimentacao
- [OK] Registro de fralda
- [OK] Registro de banho
- [OK] Registro de temperatura
- [OK] Registro de medicamento
- [OK] Chat IA
- [OK] Historico com graficos
- [OK] Sincronizacao Supabase
- [OK] Onboarding completo
- [OK] Paywall
- [OK] Settings
- [OK] Multi-cuidador

Se precisar ADICIONAR algo a essas features, faca de forma ADITIVA, sem modificar o codigo existente.

---

## [!] REGRA #5: ANTES DE CADA TAREFA

Responda estas perguntas ANTES de comecar:

1. Quais arquivos vou modificar?
2. Algum deles esta na lista de "arquivos criticos"?
3. Minha mudanca pode afetar algum fluxo que ja funciona?
4. Estou ADICIONANDO codigo ou MODIFICANDO codigo existente?
5. Preciso perguntar ao usuario antes de prosseguir?

---

## [!] REGRA #6: SE ALGO DER ERRADO

Se voce causar um erro de compilacao ou quebrar algo:

1. **PARE** imediatamente
2. **MOSTRE** exatamente o que voce mudou
3. **REVERTA** a mudanca se possivel
4. **PERGUNTE** como proceder

NAO tente "consertar" fazendo mais mudancas sem perguntar.

---

## [!] REGRA #7: CODIGO ASSINCRONO (async/await)

O app usa muito codigo assincrono. CUIDADO com:

- Ordem de execucao (await A antes de await B)
- Nao mover chamadas await para lugares diferentes
- Nao remover await de funcoes existentes
- Nao adicionar await onde nao tinha

Se precisar modificar codigo async:
1. Me mostre o fluxo ATUAL
2. Me mostre o fluxo NOVO
3. Explique por que a ordem e importante

---

## [!] REGRA #8: TESTES MENTAIS

Antes de finalizar qualquer modificacao, faca estes testes mentais:

- [ ] O app vai compilar?
- [ ] O fluxo principal (Dashboard) vai funcionar?
- [ ] O registro de sono vai funcionar?
- [ ] O onboarding vai funcionar?
- [ ] Alguma View vai quebrar por falta de dados?

---

## [!] REGRA #9: ICONES E EMOJIS

O app Naplet usa APENAS SF Symbols (icones do sistema iOS) para representar elementos visuais.

### [X] NUNCA use:
- Emojis em nenhum lugar do codigo
- Emojis em strings de interface
- Emojis em comentarios de codigo
- Emojis em arquivos de documentacao dentro do projeto

### [OK] SEMPRE use:
- SF Symbols para icones (ex: "heart.fill", "moon.zzz.fill")
- Bullets simples (•) para listas em PDFs
- Texto puro para labels e titulos

### Exemplos de substituicao:
| Emoji | SF Symbol |
|-------|-----------|
| Coracao/Amor | heart.fill |
| Triste/Chorou | cloud.rain.fill |
| OK/Normal | hand.thumbsup.fill |
| Sono | moon.zzz.fill |
| Alerta | exclamationmark.triangle.fill |
| Relogio | clock.fill |
| Sol | sunrise.fill |
| Sino | bell.fill |

---

## TEMPLATE PARA CADA TAREFA

Use este formato para QUALQUER tarefa:

```
TAREFA: [Descricao curta]

ARQUIVOS A MODIFICAR:
- arquivo1.swift (adicionar funcao X)
- arquivo2.swift (modificar linha Y)

VERIFICACAO PRE-MODIFICACAO:
- [ ] Nenhum arquivo critico sera modificado sem permissao
- [ ] Nenhum fluxo existente sera quebrado
- [ ] Estou apenas ADICIONANDO, nao removendo

MUDANCAS PROPOSTAS:
[Mostrar codigo antes e depois]

POSSO PROSSEGUIR? (Aguardar confirmacao)
```

---

## LEMBRETE FINAL

O app Naplet esta 95% pronto para lancamento.
Cada mudanca errada pode atrasar o lancamento em DIAS.
Na duvida, PERGUNTE antes de modificar.
Melhor perguntar demais do que quebrar algo.

---

**CONFIRME QUE LERAM ESTAS REGRAS RESPONDENDO:**
"Li e entendi as regras. Vou seguir o protocolo de seguranca."
