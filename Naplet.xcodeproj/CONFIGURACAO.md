# Configuração do Naplet App

## 📋 Checklist de Configuração

### ✅ 1. Configurar Supabase

1. Acesse [https://supabase.com](https://supabase.com)
2. Crie uma nova conta (se não tiver)
3. Crie um novo projeto
4. Na página do projeto, vá em **Settings** → **API**
5. Copie os seguintes valores:
   - **Project URL** (exemplo: `https://xxxx.supabase.co`)
   - **Anon/Public Key** (chave longa começando com `eyJ...`)

### ✅ 2. Configurar RevenueCat

1. Acesse [https://app.revenuecat.com](https://app.revenuecat.com)
2. Crie uma nova conta (se não tiver)
3. Crie um novo app no dashboard
4. Configure os produtos de assinatura:
   - ID do produto mensal: `com.naplet.premium.monthly`
   - ID do produto anual: `com.naplet.premium.yearly`
5. Copie a **API Key** (público)
   - Para desenvolvimento: Use a chave **Sandbox**
   - Para produção: Use a chave **Production**

### ✅ 3. Adicionar as Chaves ao Projeto

Você tem duas opções:

#### Opção A: Variáveis de Ambiente (Recomendado)

1. No Xcode, selecione o scheme do seu app (canto superior esquerdo)
2. Clique em **Edit Scheme...**
3. Vá em **Run** → **Arguments**
4. Em **Environment Variables**, adicione:

```
SUPABASE_URL = sua_url_aqui
SUPABASE_ANON_KEY = sua_chave_anon_aqui
REVENUECAT_API_KEY = sua_chave_revenuecat_aqui
```

#### Opção B: Direto no Código (Apenas para teste)

Edite o arquivo `AppConfig.swift` e substitua:

```swift
static let supabaseURL = "https://sua-url.supabase.co"
static let supabaseAnonKey = "sua-chave-anon-aqui"
static let revenueCatAPIKey = "sua-chave-revenuecat-aqui"
```

⚠️ **Importante**: Nunca commite chaves reais no Git!

### ✅ 4. Configurar Capacidades do App

1. No Xcode, selecione o target do seu app
2. Vá na aba **Signing & Capabilities**
3. Adicione as seguintes capabilities:
   - ✅ **Push Notifications**
   - ✅ **Background Modes** (marque "Remote notifications")
   - ✅ **Sign in with Apple** (se for usar)

### ✅ 5. Info.plist Configurações

Adicione as seguintes entradas no seu `Info.plist`:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Usamos isso para fornecer uma melhor experiência e recomendações personalizadas.</string>

<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### ✅ 6. Dependências

Certifique-se de que todas as dependências estão instaladas:

- ✅ Supabase Swift SDK
- ✅ RevenueCat SDK
- ✅ SwiftUI (nativo)

Se estiver usando Swift Package Manager, adicione:

```
https://github.com/supabase/supabase-swift
https://github.com/RevenueCat/purchases-ios
```

## 🧪 Testando a Configuração

Após configurar tudo:

1. Compile o projeto (⌘ + B)
2. Execute no simulador (⌘ + R)
3. Verifique os logs do console para confirmar:
   - "App services configured"
   - "Environment: Development"
   - Sem erros de API keys

## 🐛 Problemas Comuns

### Erro: "Invalid Supabase URL"
- ✅ Verifique se a URL está correta (deve começar com https://)
- ✅ Remova barras finais da URL

### Erro: "RevenueCat configuration failed"
- ✅ Verifique se a chave está correta
- ✅ Confirme que está usando a chave do ambiente correto (Sandbox/Production)

### App não compila
- ✅ Verifique se todos os arquivos foram criados corretamente
- ✅ Clean build folder (Shift + ⌘ + K)
- ✅ Rebuild (⌘ + B)

## 📝 Próximos Passos

Depois da configuração:

1. ✅ Configure o esquema do banco de dados no Supabase
2. ✅ Configure os produtos no App Store Connect
3. ✅ Teste o fluxo de autenticação
4. ✅ Teste as compras (no sandbox)

---

## 🆘 Suporte

Se tiver problemas, verifique:
- Documentação do Supabase: https://supabase.com/docs
- Documentação do RevenueCat: https://docs.revenuecat.com
