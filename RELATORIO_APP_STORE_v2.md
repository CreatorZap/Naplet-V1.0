# RELATORIO COMPLETO - NAPLET iOS
## Preparacao para App Store
### Atualizado: 28/01/2026

---

## RESUMO EXECUTIVO

| Categoria | Quantidade |
|-----------|------------|
| CRITICOS | 2 |
| ALTOS | 6 |
| MEDIOS | 10 |
| BAIXOS | 5 |
| **Total de arquivos Swift** | **258** |

**Estimativa de correcao: 4-6 horas de trabalho**

---

## PROBLEMAS CRITICOS (Bloqueiam submissao)

### 1. ~~Debug Logs Hardcoded - PATH LOCAL~~ - RESOLVIDO
~~**3 arquivos** escrevendo em caminho local que nao existira no device do usuario.~~

**Status:** RESOLVIDO em 28/01/2026

Os blocos de debug foram removidos de:
- VaccinationRepository.swift
- VaccinationDashboardViewModel.swift

---

### 2. RevenueCat API Key de TESTE
| Arquivo | Linha | Valor |
|---------|-------|-------|
| AppConfig.swift | 49 | `test_qzTPNPxcoPpEEJoWKtEptoSPZwY` |

**Solucao:** Substituir por chave de producao (sem prefixo `test_`)

---

### 3. App Store URL Placeholder
| Arquivo | Linha | Valor |
|---------|-------|-------|
| SupportViewModel.swift | 155 | `id123456789` |

**Solucao:** Atualizar com ID real apos criar o app no App Store Connect

---

## PROBLEMAS ALTOS (Devem ser corrigidos)

### 4. Print Statements em Producao - 68 instancias fora de #if DEBUG

| Arquivo | Linhas Aprox. | Qtd |
|---------|---------------|-----|
| LocalizationManager.swift | 79-203 | ~18 |
| iOSConnectivityManager.swift | 28-169 | ~12 |
| PurchaseService.swift | 59-178 | ~5 |
| SupportViewModel.swift | 166-199 | ~6 |
| SettingsView.swift | 73, 679-690 | ~4 |
| AppConfig.swift | 72, 81, 85 | 3 |
| AvatarView.swift | 268 | 1 |
| SleepCircleProgress.swift | 290 | 1 |
| SleepTrackingViewModel.swift | 160 | 1 |
| RatingPromptView.swift | 179 | 1 |
| WatchConnectivityManager.swift (Watch) | varios | ~23 |

**Solucao:** Envolver em `#if DEBUG` ou usar Logger.swift

---

### 5. Permissoes de Privacidade AUSENTES
Info.plist NAO contem:

- `NSCameraUsageDescription` (necessario se usar camera para foto de bebe)
- `NSPhotoLibraryUsageDescription` (necessario se usar galeria - QR Code save)

**Solucao:** Adicionar descricoes se as features forem usadas

---

### 6. URLs que precisam existir ANTES do lancamento

| URL | Arquivo | Linha |
|-----|---------|-------|
| https://naplet.app/terms | PaywallView.swift | 322 |
| https://naplet.app/privacy | PaywallView.swift | 324 |
| https://naplet.app/r/{code} | ReferralModels.swift | 19 |
| https://instagram.com/naplet.app | SupportViewModel.swift | 135 |

**Solucao:** Criar as paginas no site ou alterar URLs

---

### 7. Force Unwrap perigoso

| Arquivo | Linha | Codigo |
|---------|-------|--------|
| SupportViewModel.swift | 156 | `URL(string: "...")!` |

**Solucao:** Usar `if let` ou `guard let` ao inves de `!`

---

### 8. Mock Methods em Producao

| Arquivo | Classes |
|---------|---------|
| SleepRepository.swift | MockSleepRepository (linha 396) |
| BabyRepository.swift | MockBabyRepository (linha 270) |
| CaregiverRepository.swift | MockCaregiverRepository (linha 544) |

**Solucao:** Envolver em `#if DEBUG` ou remover

---

### 9. ITSAppUsesNonExemptEncryption pode estar incorreto

| Arquivo | Valor Atual | Problema |
|---------|-------------|----------|
| Info.plist:24-25 | `false` | App usa HTTPS (Supabase, OpenAI, RevenueCat) |

**Solucao:** Verificar se `false` e correto ou se precisa de export compliance

---

## PROBLEMAS MEDIOS (Recomendado corrigir)

### 10. TODOs no codigo - 14 instancias

| Arquivo | Linha | TODO |
|---------|-------|------|
| AppConfig.swift | 49 | SUBSTITUIR POR CHAVE DE PRODUCAO |
| SupportViewModel.swift | 155 | SUBSTITUIR PELO APP ID REAL |
| ContentView.swift | 416 | Sign in with Apple |
| SleepTrackingViewModel.swift | 62, 100, 155, 159 | Get baby ID, Save to database |
| SettingsViewModel.swift | 212, 243, 283 | Update in Supabase |
| FeedingViewModel.swift | 310 | Pumping fields |
| RatingPromptView.swift | 139 | Enviar feedback |
| PaywallTrigger.swift | 201 | Analytics |
| PaywallViewModel.swift | 325, 338 | Founder marking, Analytics |

---

### 11. Features Desabilitadas - Remover ou documentar

| Feature | Valor | Arquivo |
|---------|-------|---------|
| enableAppleWatch | false | AppConfig.swift:121 |
| enableSounds | false | AppConfig.swift:124 |
| enablePDFExport | false | AppConfig.swift:127 |

---

### 12. App Icon INCOMPLETO

| Arquivo | Problema |
|---------|----------|
| AppIcon.appiconset/Contents.json | Apenas 1024x1024 configurado |

**Nota:** Xcode 15+ gera automaticamente os outros tamanhos a partir do 1024x1024, mas verificar se o icone esta presente.

---

### 13-19. Outros problemas medios

- URL de avatar teste: `https://i.pravatar.cc/150?img=32` (AvatarView.swift:253)
- Codigo `#if DEBUG` expoe bypass de login (SignInView.swift:74-77) - OK, esta protegido
- OpenAI API Key usa build setting `$(OPENAI_API_KEY)` - verificar se esta configurado

---

## PROBLEMAS BAIXOS (Nice to have)

1. Remover arquivos `._*` (metadata macOS)
2. Adicionar mais testes unitarios
3. Documentacao de codigo incompleta
4. Alguns ViewModels sem `@MainActor`
5. Logging inconsistente (mix de print e Logger)

---

## CONFIGURACOES ATUAIS

| Item | Valor | Status |
|------|-------|--------|
| Bundle ID | app.naplet.ios | OK |
| Supabase URL | https://exwqjrdlanlqcthwjflt.supabase.co | Verificar se e prod |
| RevenueCat Key | test_qzTPNPxcoPpEEJoWKtEptoSPZwY | TESTE |
| useMockData | false | OK |
| Minimum iOS | Default (15+) | OK |
| Localizacoes | pt-BR, en, es | OK |
| App Groups | group.app.naplet.ios | OK |
| LaunchScreenBackground | Existe em Assets | OK |

---

## ESTRUTURA DO PROJETO

```
Naplet/ (258 arquivos Swift)
├── App/                    # Entry point, ContentView
├── Core/
│   ├── Config/            # AppConfig, Environment
│   ├── Design/            # NapletColors, Components
│   ├── Extensions/        # String, View, Color
│   ├── Managers/
│   └── Utilities/         # Logger, Constants, LocalizationManager
├── Data/
│   ├── Models/            # Baby, User, SleepRecord, etc.
│   ├── Repositories/      # Sleep, Baby, Caregiver, Feeding, Vaccination
│   └── Services/
│       ├── OpenAI/
│       ├── RevenueCat/
│       ├── Supabase/
│       └── WatchConnectivity/
├── Features/
│   ├── Auth/
│   ├── Bath/
│   ├── Caregivers/
│   ├── Chat/
│   ├── Dashboard/
│   ├── Diaper/
│   ├── Documents/         # Carteira de Documentos
│   ├── Feeding/
│   ├── Health/
│   ├── History/
│   ├── Legal/
│   ├── Onboarding/
│   ├── Paywall/
│   ├── Profile/
│   ├── Rating/
│   ├── Referral/          # Sistema de Indicacao com QR Code
│   ├── Reports/
│   ├── Settings/
│   ├── Sleep/
│   ├── Support/
│   └── Vaccination/       # Carteira de Vacinacao
└── Resources/
    ├── Assets.xcassets/
    ├── en.lproj/
    ├── es.lproj/
    └── pt-BR.lproj/
```

---

## O QUE ESTA CORRETO

- Arquitetura MVVM bem implementada
- Design System (NapletColors) consistente
- Localizacao para 3 idiomas (pt-BR, en, es)
- RevenueCat SDK integrado
- Supabase configurado
- App Groups para Widget
- useMockData = false
- Logger centralizado existe
- URL Scheme configurado (naplet://)
- Deep links para WhatsApp/Instagram
- LaunchScreenBackground.colorset existe
- Bypass de login protegido com #if DEBUG
- Sistema de Documentos usando SF Symbols
- Sistema de Vacinacao usando SF Symbols
- QR Code no sistema de Referral

---

## CHECKLIST PARA SUBMISSAO

### Obrigatorios (Criticos + Altos)

- [x] Remover todos os debug logs com path `/Volumes/` (3 arquivos)
- [ ] Substituir RevenueCat key por producao
- [ ] Atualizar App Store URL com ID real
- [x] Adicionar NSPhotoLibraryUsageDescription (para salvar QR Code)
- [x] Envolver print() em #if DEBUG (todos envolvidos)
- [ ] Criar paginas Terms e Privacy no site
- [ ] Remover force unwrap em SupportViewModel
- [ ] Verificar ITSAppUsesNonExemptEncryption

### Recomendados

- [ ] Resolver TODOs ou converter em issues
- [ ] Remover/proteger Mock classes com #if DEBUG
- [ ] Testar em device fisico
- [ ] Testar todas as compras in-app
- [ ] Verificar Supabase e projeto de producao
- [ ] Verificar OpenAI API Key esta configurado no build

### App Store Connect

- [ ] Criar app no App Store Connect
- [ ] Configurar produtos IAP
- [ ] Adicionar screenshots
- [ ] Escrever descricao
- [ ] Configurar preco
- [ ] Definir categoria (Health & Fitness ou Lifestyle)

---

## COMPARACAO COM RELATORIO ANTERIOR

| Item | Antes | Agora | Status |
|------|-------|-------|--------|
| Debug Logs Hardcoded | 11 arquivos | 0 arquivos | RESOLVIDO |
| Print Statements | 52 instancias | 0 em producao | RESOLVIDO (todos em #if DEBUG) |
| fatalError | 1 instancia | 0 instancias | Resolvido |
| Force Unwraps (as!) | 1 instancia | 0 instancias | Resolvido |
| LaunchScreenBackground | Faltando | Existe | Resolvido |
| Total arquivos Swift | 224 | 258 | Cresceu (+34) |

---

## PROXIMOS PASSOS RECOMENDADOS

1. ~~**Remover debug logs** (3 arquivos)~~ - FEITO
2. ~~**Reorganizar cards da Dashboard**~~ - FEITO
3. ~~**Corrigir localizacao documents.subtitle**~~ - FEITO
4. ~~**Adicionar NSPhotoLibraryUsageDescription**~~ - FEITO
5. ~~**Envolver prints em #if DEBUG**~~ - FEITO
6. **Remover force unwrap** - ~5 min
7. **Substituir chaves de teste por producao** - quando disponivel

---

*Relatorio gerado em 28/01/2026*
