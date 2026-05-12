# PROMPT CLAUDE CODE — SPRINT 1: DESTRAVAR RECEITA

> **Pré-requisito obrigatório:** o Sprint 0 (Emergência) já foi executado pelo Edy manualmente. A chave OpenAI antiga foi revogada, uma nova chave foi gerada e está guardada fora do código. O dashboard do RevenueCat foi inspecionado e o modo Production foi confirmado ou ativado.
>
> **Se Edy ainda não fez o Sprint 0, PARE e peça para ele executar primeiro.** Não há sentido em fazer este Sprint 1 com chave OpenAI ainda comprometida ou RevenueCat ainda em sandbox.

---

## REGRAS DE EXECUÇÃO

Este projeto está em produção, com usuários reais. Antes de qualquer mudança:

1. Verifique a branch atual. Se não estiver em uma branch nova, **pare e crie**: `git checkout -b sprint-1/destravar-receita`
2. Antes de tocar qualquer arquivo sensível (`AppConfig.swift`, `Info.plist`, `project.pbxproj`, qualquer coisa relacionada a auth ou pagamento), **mostre o arquivo atual para o Edy** e peça confirmação.
3. Faça commits atômicos e descritivos a cada bloco terminado. Não acumule múltiplos blocos em um único commit.
4. Após cada bloco, rode build limpo: `xcodebuild -scheme Naplet -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build`. Erro de build não fecha o bloco.
5. Smoke test obrigatório após cada bloco: abrir app no simulador, fazer login, criar registro de sono, fechar. Se quebrar, reverter.
6. Consulte as skills `naplet-safe-migration`, `naplet-design-system` e `naplet-paywall-patterns` antes de cada bloco relevante.
7. **Nunca** comite arquivos com chaves de API, mesmo de teste.

---

## BLOCO 1.1: SEGURANÇA DA OPENAI (4 a 6h)

### Objetivo
Mover a chave OpenAI do código para uma Edge Function do Supabase que atua como proxy autenticado.

### Passos

**1. Criar Edge Function no Supabase**

Edy precisa criar manualmente no painel Supabase, ou via CLI:

```bash
supabase functions new openai-proxy
```

**2. Implementar a função (sugestão de código para Edy colar)**

Crie o arquivo `supabase/functions/openai-proxy/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  const body = await req.json();

  const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  return new Response(openaiResponse.body, {
    status: openaiResponse.status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
});
```

**3. Configurar secrets**

```bash
supabase secrets set OPENAI_API_KEY=sk-proj-NOVA_CHAVE_AQUI
```

**4. Deploy**

```bash
supabase functions deploy openai-proxy
```

**5. Atualizar `OpenAIService.swift`**

Antes de editar, mostre o arquivo atual para o Edy. Sugestão de mudança:

- Trocar a URL base de `https://api.openai.com/v1` para `https://{seu-projeto}.supabase.co/functions/v1/openai-proxy`
- Trocar o header `Authorization: Bearer {OPENAI_KEY}` para `Authorization: Bearer {SUPABASE_USER_JWT}`
- Obter o JWT do usuário via `try await SupabaseManager.shared.client.auth.session.accessToken`

**6. Remover a chave do AppConfig.swift**

- Mostrar o arquivo atual
- Remover a linha 60 (a constante com a chave OpenAI)
- Remover qualquer importação ou referência órfã
- Build limpo

**7. Smoke test específico**

- Abrir o app no simulador
- Fazer login
- Abrir o Chat IA
- Enviar uma mensagem
- Validar que recebe resposta da OpenAI
- Validar que **não há nenhuma string `sk-proj-`** no binário (`strings Naplet.app/Naplet | grep "sk-proj"` deve retornar vazio)

**8. Commit**

```bash
git add .
git commit -m "feat(security): mover chave OpenAI para Edge Function proxy"
```

### Critério de saída do Bloco 1.1

- [ ] Edge Function `openai-proxy` deployada
- [ ] `OpenAIService.swift` usando o proxy
- [ ] Chave OpenAI removida de `AppConfig.swift`
- [ ] `strings` no binário não retorna chaves
- [ ] Chat IA funcionando no simulador
- [ ] Commit feito

---

## BLOCO 1.2: CONFIRMAR E BLINDAR REVENUECAT (2 a 3h)

### Objetivo
Garantir e provar que RevenueCat está em produção.

### Passos

**1. Inspecionar `AppConfig.swift:49`**

Mostrar o arquivo para o Edy. Confirmar que a chave começa com `appl_` (esperado: `appl_ZmzpzrfPorQGHpEwFEdkpkkJtvq`), não com `test_`.

Se ainda estiver `test_`, parar e pedir ao Edy a chave de produção.

**2. Adicionar log de runtime**

Em `NapletApp.swift` ou onde inicializa o RevenueCat, adicionar:

```swift
#if DEBUG
print("[RC] modo: \(Purchases.shared.isSandbox ? "SANDBOX" : "PRODUCTION")")
print("[RC] App Store country: \(Purchases.shared.storeFront?.countryCode ?? "unknown")")
#endif
```

**3. Validar Offerings**

Forçar busca de offerings ao abrir o app e logar:

```swift
#if DEBUG
Task {
    do {
        let offerings = try await Purchases.shared.offerings()
        print("[RC] Offerings disponíveis: \(offerings.all.keys)")
        if let current = offerings.current {
            print("[RC] Offering atual: \(current.identifier)")
            for package in current.availablePackages {
                print("[RC] Package: \(package.identifier), preço: \(package.localizedPriceString)")
            }
        }
    } catch {
        print("[RC] Erro ao buscar offerings: \(error)")
    }
}
#endif
```

**4. Compra de teste em sandbox**

Pedir para o Edy fazer:
- Sair da Apple ID atual no simulador (Settings, App Store)
- Logar com conta sandbox (criar uma em App Store Connect, Users and Access, Sandbox Testers)
- Abrir o app, tentar comprar
- Validar que a compra aparece no RevenueCat dashboard

**5. Commit**

```bash
git add .
git commit -m "chore(revenuecat): adicionar logs de runtime e validar produção"
```

### Critério de saída do Bloco 1.2

- [ ] Chave RevenueCat confirmada começando com `appl_`
- [ ] Logs de runtime mostram `PRODUCTION` no console
- [ ] Offerings carregados corretamente
- [ ] Compra de teste em sandbox apareceu no dashboard
- [ ] Commit feito

---

## BLOCO 1.3: PAYWALL PÓS-ONBOARDING (8 a 12h)

### Objetivo
Inserir paywall no momento de pico de motivação, ao final do onboarding.

### Passos

**1. Consultar skill `naplet-paywall-patterns`** antes de começar.

**2. Criar `OnboardingPaywallView.swift`**

Local: `Features/Onboarding/Views/OnboardingPaywallView.swift`

Estrutura visual obrigatória (do topo para baixo):

```
┌────────────────────────────────────────┐
│  [Avatar do bebê]   {Nome do bebê}    │
│                                        │
│  O sono da {Nome} começa agora        │
│  (headline grande, peso bold)          │
│                                        │
│  ✓ Chat IA 24h sobre o sono           │
│  ✓ Relatórios PDF para o pediatra     │
│  ✓ Toda a família sincronizada        │
│  ✓ Histórico completo e ilimitado     │
│                                        │
│  ┌──────────────────────────────────┐ │
│  │  EXCLUSIVO LANÇAMENTO             │ │
│  │  Naplet Founders                  │ │
│  │                                   │ │
│  │  R$59,90/ano                      │ │
│  │  ~~R$89,90~~  economize R$30      │ │
│  │  apenas R$4,99/mês                │ │
│  │                                   │ │
│  │  Comparado ao Napper: 48% menos   │ │
│  └──────────────────────────────────┘ │
│                                        │
│  Trial de 14 dias grátis:             │
│                                        │
│  Hoje • • • • • • • • • • • • • Dia 14│
│   ↓                       ↓        ↓  │
│  Acesso total          Lembrete   Cobra│
│                                        │
│  [Começar 14 dias grátis]             │
│                                        │
│  Continuar com plano gratuito         │
│  (link discreto)                       │
└────────────────────────────────────────┘
```

**3. Integrar no fluxo de onboarding**

- Localizar onde a tela 11 (Confirmation ou Loading) navega para tela 12 (Completion)
- Interceptar e mostrar `OnboardingPaywallView` antes
- Após dismiss da paywall (comprou ou pulou), seguir para tela 12

**4. Disparar compra via RevenueCat**

Reusar a lógica de `PaywallViewModel.swift` existente. Se aceitar, chama `Purchases.shared.purchase(package:)` com a Founders Annual package.

**5. Skip permitido, com analytics**

Botão "Continuar com plano gratuito" loga evento `onboarding_paywall_skipped` no PostHog (que vem no Sprint 2, por ora só `print` em DEBUG).

**6. Localização**

Adicionar strings em PT-BR, EN e ES.

**7. Commit**

```bash
git add .
git commit -m "feat(onboarding): adicionar paywall ao final do onboarding"
```

### Critério de saída do Bloco 1.3

- [ ] `OnboardingPaywallView.swift` criada e funcional
- [ ] Integrada entre tela 11 e tela 12
- [ ] Visual confere com a estrutura especificada
- [ ] Compra dispara via RevenueCat
- [ ] Skip funciona e leva para tela 12
- [ ] Strings localizadas nos 3 idiomas
- [ ] Smoke test passa
- [ ] Commit feito

---

## BLOCO 1.4: MOVER SIGNIN PARA DEPOIS DO VALOR (6 a 8h)

### Objetivo
Reduzir drop-off ao não pedir cadastro antes de o usuário entender o que ganha.

### Passos

**1. Mostrar `ContentView.swift` para Edy**

Antes de editar, mostrar a estrutura atual de autenticação obrigatória nas linhas 66 a 68.

**2. Refatorar fluxo**

- Permitir que o app abra direto no onboarding sem SignIn
- Persistir progresso do onboarding em UserDefaults com chaves prefixadas: `onboarding_step`, `onboarding_baby_name`, `onboarding_baby_birth`, etc
- Na tela 10 (uma antes de Confirmation), exigir SignIn
- Após SignIn bem-sucedido, migrar os dados de UserDefaults para Supabase

**3. Criar `OnboardingSignInView.swift`**

Local: `Features/Onboarding/Views/OnboardingSignInView.swift`

Estrutura:
- Headline: "Quase lá! Crie sua conta para salvar tudo"
- Sign in with Apple (botão principal, obrigatório)
- Sign in com Email (botão secundário)
- Texto explicativo: "Seus dados serão protegidos e você nunca perderá o histórico do seu bebê."
- Links para Termos e Privacidade

**4. Função de migração**

```swift
func migrateOnboardingDataToSupabase() async throws {
    guard let userId = SupabaseManager.shared.client.auth.currentUser?.id else { return }
    
    let babyName = UserDefaults.standard.string(forKey: "onboarding_baby_name") ?? ""
    let babyBirth = UserDefaults.standard.object(forKey: "onboarding_baby_birth") as? Date ?? Date()
    // ... outros campos
    
    let baby = Baby(
        id: UUID(),
        userId: userId,
        name: babyName,
        birthDate: babyBirth,
        // ...
    )
    
    try await BabyRepository.shared.create(baby)
    
    // Limpar UserDefaults
    UserDefaults.standard.removeObject(forKey: "onboarding_baby_name")
    // ...
}
```

**5. Smoke test**

- Reinstalar o app
- Passar pelo onboarding sem fazer SignIn nas primeiras telas
- Validar que SignIn aparece na tela 10
- Após SignIn, validar que o bebê foi criado corretamente no Supabase

**6. Commit**

```bash
git add .
git commit -m "feat(onboarding): mover SignIn para depois do valor entregue"
```

### Critério de saída do Bloco 1.4

- [ ] Onboarding funciona sem SignIn nas primeiras 9 telas
- [ ] SignIn aparece na tela 10
- [ ] Sign in with Apple funciona
- [ ] Dados migram corretamente para Supabase após SignIn
- [ ] Smoke test passa
- [ ] Commit feito

---

## BLOCO 1.5: REATIVAR OFERTA FOUNDERS (2 a 3h)

### Objetivo
Garantir que a oferta Founders esteja visível e ativa.

### Decisão prévia (Edy precisa decidir)

Opção A: estender até 22/07/2026 (90 dias a partir de hoje)
Opção B: criar nova janela com nome diferente

**Aguardar decisão antes de executar.**

### Passos (assumindo Opção A)

**1. Atualizar `PaywallViewModel.swift`**

Trocar `foundersEndDate` para a nova data.

**2. Validar no UI**

Confirmar que:
- Card Founders aparece no paywall principal
- Countdown calcula corretamente os dias restantes
- Quando expirar (julho), volta para offering regular automaticamente

**3. Commit**

```bash
git add .
git commit -m "feat(monetization): reativar oferta Founders até 22/07/2026"
```

---

## SUBMISSÃO PARA TESTFLIGHT

Após todos os 5 blocos concluídos:

1. Incrementar build number via `sed -i '' 's/CURRENT_PROJECT_VERSION = 19;/CURRENT_PROJECT_VERSION = 20;/g' Naplet.xcodeproj/project.pbxproj`
2. Atualizar `MARKETING_VERSION` para `1.2.0`
3. Archive no Xcode
4. Upload para TestFlight
5. Adicionar release notes:

```
Versão 1.2 - Sprint 1

✓ Segurança aprimorada (proxy de API)
✓ Onboarding mais fluido (sem cadastro obrigatório no início)
✓ Oferta Founders reativada
✓ Diversos refinamentos
```

6. Merge da branch `sprint-1/destravar-receita` para `main` somente após validação no TestFlight com pelo menos 3 dispositivos diferentes.

---

## SE ALGO DER ERRADO

1. **Não pânico.** Branch isolada, reverter é fácil.
2. `git stash` para salvar mudanças locais
3. `git checkout main` para voltar ao estado estável
4. Pedir ajuda ao Claude na conversa, descrevendo o erro exato

---

## ENTREGA FINAL

Ao fim do Sprint 1, gerar `auditoria-10x/sprint-1-relatorio.md` com:

- Bloco a bloco: o que foi feito, quanto tempo levou, problemas encontrados
- Smoke tests executados
- Build submetido ao TestFlight (link e número)
- Próximos passos sugeridos para Sprint 2

---

*Boa execução. Conversão começa aqui.*
