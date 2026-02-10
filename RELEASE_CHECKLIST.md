# Naplet - Release Checklist v1.0

## Pre-Release Verification

### Code Quality
- [x] Remover API keys expostas do código
- [x] Verificar que não há `print()` statements em produção
- [x] Verificar que não há `fatalError()` desnecessários
- [x] Revisar TODOs - apenas os não-críticos permanecem
- [x] `useMockData = false` no AppConfig
- [x] OpenAI API key configurada via Info.plist/Build Settings

### Build Configuration
- [ ] Version number atualizado (CFBundleShortVersionString)
- [ ] Build number atualizado (CFBundleVersion)
- [ ] Bundle ID correto: `app.naplet.ios`
- [ ] Signing configurado com certificado de distribuição
- [ ] Provisioning profile de App Store selecionado

### Info.plist
- [x] `ITSAppUsesNonExemptEncryption = NO`
- [x] Localizações configuradas (pt-BR, en, es)
- [x] URL Scheme configurado
- [x] Required device capabilities
- [x] Supported orientations

### Dependencies
- [ ] RevenueCat API Key configurada (produção)
- [ ] Supabase URL e Key configurados (produção)
- [ ] OpenAI API Key configurada (produção)

---

## App Store Connect

### App Information
- [ ] Nome do app em todos os idiomas
- [ ] Subtítulo em todos os idiomas
- [ ] Categoria primária: Health & Fitness
- [ ] Categoria secundária: Lifestyle
- [ ] Privacy Policy URL
- [ ] Support URL

### Pricing & Availability
- [ ] Preço: Grátis (com IAP)
- [ ] Disponibilidade: Todos os países
- [ ] Pre-orders: Desativado (primeira versão)

### In-App Purchases
- [ ] `app.naplet.premium.monthly` - Assinatura mensal
- [ ] `app.naplet.premium.yearly` - Assinatura anual
- [ ] Produtos vinculados ao app
- [ ] Revisar preços por região

### App Privacy
- [ ] Data types collected
- [ ] Data linked to user
- [ ] Tracking purposes
- [ ] Privacy Nutrition Label completa

### Version Information
- [ ] Descrição em pt-BR
- [ ] Descrição em inglês
- [ ] Descrição em espanhol
- [ ] What's New / Notas de versão
- [ ] Keywords em todos os idiomas
- [ ] Promotional text

### Media Assets
- [ ] App Icon (1024x1024)
- [ ] Screenshots iPhone 6.7" (6 imagens)
- [ ] Screenshots iPhone 6.5" (6 imagens) - opcional
- [ ] Screenshots iPad 12.9" (6 imagens) - se suportado
- [ ] App Preview Video (opcional)

---

## Screenshots Checklist

### Telas Recomendadas
1. [ ] Dashboard com timer ativo
2. [ ] Estatísticas semanais
3. [ ] Convite de cuidadores
4. [ ] Chat com IA
5. [ ] Paywall/Premium
6. [ ] Widget na Home Screen

### Especificações
- iPhone 6.7" (1290 x 2796 pixels)
- Formato: PNG ou JPEG
- Sem alpha channel
- Sem cantos arredondados (Apple aplica)

---

## Final Checks

### Testing
- [ ] Testar fluxo completo de onboarding
- [ ] Testar registro de sono (iniciar/parar)
- [ ] Testar convite de cuidadores
- [ ] Testar chat com IA (se configurado)
- [ ] Testar compra de assinatura (sandbox)
- [ ] Testar restaurar compras
- [ ] Testar notificações
- [ ] Testar em diferentes tamanhos de tela
- [ ] Testar com VoiceOver (acessibilidade)

### Archive & Upload
- [ ] Clean Build Folder
- [ ] Archive em Release mode
- [ ] Validar archive no Organizer
- [ ] Upload para App Store Connect
- [ ] Verificar build no App Store Connect
- [ ] Associar build à versão

### Submission
- [ ] Selecionar build
- [ ] Responder App Review Information
- [ ] Demo account (se necessário)
- [ ] Contact information
- [ ] Notes for reviewer (se necessário)
- [ ] Submeter para Review

---

## Post-Release

### Monitoring
- [ ] Monitorar crash reports no Xcode
- [ ] Verificar reviews na App Store
- [ ] Responder reviews negativas
- [ ] Monitorar analytics (se configurado)

### Marketing
- [ ] Anunciar lançamento nas redes sociais
- [ ] Atualizar website
- [ ] Enviar para sites de review de apps

---

## RevenueCat Setup

### Dashboard
- [ ] Criar projeto no RevenueCat
- [ ] Adicionar App Store app
- [ ] Configurar products (monthly, yearly)
- [ ] Configurar entitlements (premium)
- [ ] Configurar offerings (default)
- [ ] Testar em sandbox

### App Configuration
- [ ] API Key de produção no AppConfig
- [ ] Verificar ProductIds corretos
- [ ] Testar restore purchases

---

## Supabase Production

### Project Setup
- [ ] Criar projeto de produção (se diferente de dev)
- [ ] Executar migrations/schema
- [ ] Configurar RLS policies
- [ ] Configurar Edge Functions (se houver)

### Security
- [ ] RLS habilitado em todas as tabelas
- [ ] API keys de produção configuradas
- [ ] Backup automático ativado

---

## Notes

### Versioning
- Major.Minor.Patch (ex: 1.0.0)
- Build number sempre incrementa

### Tempo de Review
- Primeira submissão: 24-48 horas (pode variar)
- Updates: geralmente mais rápido
- Rejeições comuns: screenshots, privacy, crashes

### Contatos
- Apple Developer Support
- RevenueCat Support
- Supabase Support

---

*Última atualização: Janeiro 2026*
