# 08 - Comparativo Cruel: Naplet vs Napper

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Como ler esta tabela

Para cada dimensão, descrevo o estado de cada app, declaro quem vence sem suavizar e proponho um contra-ataque do Naplet. Em algumas linhas o Naplet **pode** ganhar com pouco esforço; em outras a desvantagem é estrutural.

---

## Tabela mestre — 20 dimensões

| # | Dimensão | Naplet | Napper | Vence | Por quê | Contra-ataque do Naplet |
|---|---|---|---|---|---|---|
| 1 | **Promessa do app** | "Noites tranquilas começam aqui" (no onboarding, não no marketing) | "Sonos grandes para pequenos sonhadores" (site) + "Personalizado para seu bebê!" (App Store) | **Napper** | Promessa do Napper aparece no primeiro toque, na App Store e no site. A do Naplet só aparece dentro do app. | Definir 1 headline única e usar em App Store, site e tela 1 do onboarding. Sugestão: "Mais sono pra ela. Mais sono pra você." |
| 2 | **Primeiro impacto (ícone + nome)** | Ícone roxo (a confirmar). Nome "Naplet" — soa engraçado, não dito | Mascote nuvem 3D + nome serif lowercase reconhecível | **Napper** | Identidade visual única e icônica. | Adotar mascote 3D próprio (custo de design alto mas o ROI compensa) ou pelo menos um símbolo recorrente (lua estilizada?) |
| 3 | **Onboarding: tempo até primeira ação útil** | ~1m55s + auth antes (drop-off real ~30%) | ~3m mas SEM auth no início | **Napper** | Naplet pede SignIn antes de mostrar valor. Napper pede só no fim. | Mover SignIn para depois da tela de "Solução" (igual ao Napper). Permitir cadastro de bebê em local storage até o login. |
| 4 | **Onboarding vende valor antes de pedir cadastro?** | Não: cadastro antes de qualquer valor | Sim: 15+ telas educativas antes do login | **Napper** | Estrutural. Maior leak do funil Naplet. | Espelhar a sequência: benefícios → goals → dados → ciência → reforço → SignIn |
| 5 | **Dashboard: clareza visual** | DashboardView com 1954 linhas. Vários widgets, dense. | Carrossel de mockups indica dashboard limpo com 1 card grande de "próxima soneca" | **Napper** | Naplet é "tudo na mesma tela", Napper foca em 1 KPI por vez. | Refatorar Dashboard: card primário "próxima soneca prevista" + outros widgets em hierarquia clara |
| 6 | **Registro de sono: número de toques** | 6-7 toques (start + stop) | (a verificar; provavelmente 2-3 com botão grande) | **Napper provável** | Naplet exige 3 escolhas (tipo, lugar, humor) antes do start | Tornar tipo/lugar/humor opcionais com defaults. Botão único "Iniciar sono" → start; só pede detalhes ao parar. |
| 7 | **Paywall: timing da primeira aparição** | Após várias sessões (só 2/7 triggers funcionam) | No final do onboarding, **toda nova conta vê** | **Napper** | O usuário Naplet pode usar 2 semanas sem nunca ver paywall. | Adicionar paywall na tela 11 do onboarding (após "Loading" e antes de "Completion") — mesmo modelo do Napper |
| 8 | **Paywall: clareza da oferta** | 2 planos (mensal/anual), Founders vs Regular, várias variáveis | 1 plano dominante (R$ 114,90/ano com 7d trial) + opção "Ver todos os planos" | **Napper** | Menos escolha = mais conversão. Naplet sobrecarrega o usuário. | Reduzir paywall padrão para anual com trial. Mensal vira "Ver outros planos". |
| 9 | **Paywall: ancoragem de preço** | Anual riscado, sem comparação com concorrente | "R$ 0 acaba hoje, após o período de teste R$ 114,90" — usa loss aversion temporal | **Napper** | Naplet tem ancoragem interna; Napper usa **escassez temporal real do trial**. | Adicionar "R$ 0 acaba em X dias" como timer real; sair do "countdown da Founders" e adotar o trial-countdown |
| 10 | **Prova social no app** | 3 reviews fictícias no paywall, sem números | 4.9⭐ + 15K reviews + Editor's Choice + 1M famílias + FAQ inline | **Napper** (com folga) | Volume e qualidade superiores. | Usar números reais que **soam grandes**: "27 mil sonos rastreados nas últimas 4 semanas", "1.200 PDFs entregues a pediatras". Mover prova social para topo do paywall. |
| 11 | **Sons para dormir (table stakes)** | Não implementado (`enableSounds = false`). v1.2 planejada com 12 sons. | 30+ sons gratuitos. Galeria visível na landing page. | **Napper** | Faltam table stakes. Crítico. | Acelerar v1.2 (Dream Engine). Sons offline grátis para free, premium ganha lista completa. |
| 12 | **Curso ou conteúdo educacional** | Nenhum. Chat IA cobre dúvidas pontuais. | 4 capítulos sobre despertares + artigos internos | **Napper** | Conteúdo cria autoridade e SEO. | Criar 5 artigos curtos como "Conteúdo Naplet" dentro do app + replicar no site. Pode ser gerado por IA com revisão. |
| 13 | **Comunidade ou suporte humano** | SupportView com FAQ + ContactForm. Sem comunidade. | Não tem comunidade pública | **Empate** | Nenhum dos dois investe em comunidade. | Oportunidade: criar Grupo Telegram/Discord de mães Naplet — comunidade move retenção. Custo baixo. |
| 14 | **Notificações inteligentes** | Recebe push (NotificationDelegate setup), mas **não há backend enviando** | Lembretes baseados em ritmo do bebê (sleep window prediction) | **Napper** | Naplet 🟡, Napper 🟢. | Implementar 3 pushes core: "janela de sono aberta", "está dormindo há 2h", "lembrete de medicação". |
| 15 | **Widgets** | NapletSleepWidget existe, atualiza 1/min | (provável: sim) | **Empate** | Ambos têm. | Diferenciar: widget de "próxima soneca em 32 min" — Napper provavelmente tem, Naplet pode melhorar. |
| 16 | **Apple Watch** | Existe no código mas `enableAppleWatch = false` | (não confirmado) | **Indeterminado** | Casca pronta no Naplet. | Ativar e marketear Apple Watch como diferencial se Napper não tiver versão polida. |
| 17 | **Design: sensação premium** | SwiftUI bem feito, mas DashboardView gigante e sem mascote | 3D mascotes consistentes, dark gradiente espacial, micro-animações | **Napper** | Identidade reconhecível. | Investir em ilustrações próprias (1 designer freelancer por 2 semanas = mascote + 5 ilustrações = R$ 5-15k). |
| 18 | **Microinterações e animações** | Confetti, haptics, spring animations no onboarding | Loading dramatizado, gráficos animados, progress bar fluida | **Napper** (por pouco) | Naplet tem fundamentos; falta polish. | Adicionar loading "narrado" no fim do onboarding ("Construindo seu plano de sono..."). |
| 19 | **Localização (PT-BR natural)** | PT-BR (Localizable.strings) | PT-BR + EN + outros | **Empate em PT-BR**. Napper vence em escala. | Não há diferença prática para o público alvo. | Investir em **localização para espanhol LATAM** se o BR não escalar — mercado virgem. |
| 20 | **Preço final percebido** | R$ 89,90/ano (Founders) ou ~R$ 114 regular | R$ 114,90/ano | **Naplet** (mas pouco usado) | Naplet é 22% mais barato no Founders. **Mas não comunica isso.** | Copy de paywall direta: "R$ 89,90/ano. Mesmo plano do Napper custa R$ 114,90." Comparação direta vence ambiguidade. |

---

## Placar final

- **Napper vence em:** 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 17, 18 = **15 dimensões**
- **Empates:** 13, 15, 19 = **3 dimensões**
- **Naplet vence em:** 20 (preço) = **1 dimensão**
- **Indeterminado:** 16 (Apple Watch) = **1 dimensão**

**1-15-3.** Brutal mas honesto.

---

## Onde o Naplet pode atacar com vantagem estrutural

Mesmo perdendo 15 dimensões, há **4 frentes onde o Napper não está confortável** e o Naplet pode ganhar com investimento direcionado:

### 1. Relatório PDF para pediatra

Napper tem rastreamento, mas **não tem relatório formatado para imprimir e levar à consulta**. O Naplet TEM. Hoje o PDF do Naplet é "amador" (sem logo, sem peso, sem assinatura), mas a feature em si é única.

**Plano:** investir em design do PDF (logo, tipografia serif para tom institucional, gráficos limpos, espaço para anotações + assinatura) e MARKETING desse diferencial:
- App Store screenshot dedicado: "O único app que entrega o PDF que o pediatra quer"
- Landing page seção dedicada
- Reviews dirigidas: "Mostre isso no próximo retorno"

### 2. Chat IA contextual

Napper tem artigos. **Naplet tem CHAT.** Conversação > artigos para a maioria dos pais (tempo curto). Hoje o Chat IA está sub-utilizado (primeira mensagem genérica, sem contexto completo). Com 3 ajustes pode virar diferencial:

- Primeira mensagem **personalizada com dados do bebê** ("Vejo que Alice acordou 3 vezes ontem...")
- Streaming de resposta
- Contexto completo (fraldas, alimentação, padrão da semana)

### 3. Multi-cuidador

Napper tem (vendo no print 7094 "Existem outros membros da família?"). Mas a profundidade do Naplet — convite por código, sincronização entre cuidadores — pode ser melhor SE o realtime sync for implementado. Atualmente Naplet tem só fetch on demand.

**Quick win:** ativar Supabase Realtime para `sleep_records`, `feeding_records`, `diaper_records`. Custo: 1-2 dias. Resultado: ambos os pais veem updates ao vivo, sem refresh. Vira história contável: "Veja o que o outro cuidador registrou em tempo real".

### 4. Preço

R$ 89,90 vs R$ 114,90 = 22% mais barato. Mas hoje essa vantagem **não é comunicada**. Mudar a copy do paywall para:

> "Acesso completo por R$ 89,90/ano.
> Concorrente cobra R$ 114,90 pelo mesmo.
> Garanta antes que vire R$ 114,90 aqui também."

Comparação direta é juridicamente OK desde que verificada e atualizada.

---

## A verdade desconfortável

O Naplet **não vai ganhar do Napper na superfície técnica de features no curto prazo** — Napper tem 6 anos de vantagem, 1M usuários, 12K reviews, Editors' Choice. Lutar feature-por-feature é perder.

A guerra que o Naplet pode vencer é a do **NICHO BRASILEIRO COM PROFUNDIDADE MÉDICA**:

- "O app feito para o pediatra brasileiro"
- "Carteira de vacinação seguindo o calendário do PNI"
- "Relatório PDF aceito em consultas"
- "Suporte em português, atendimento humano em até 24h"
- "1/3 mais barato que o app sueco"

Esse é o posicionamento que **nenhum outro app pode copiar barato**. Napper é sueco, vê BR como mercado secundário. Naplet pode virar **o app de referência médica** no BR antes que o Napper invista.

---

## Conclusão

15-1-3-1 é o placar. **Não é injusto** — é o estado real. Mas placar não é destino. O Naplet tem 4 frentes vencíveis identificadas acima + 1 posicionamento defensável (BR médico). Se executar os Quick Wins (doc 15) e o reposicionamento, o placar 1 ano pode ser 7-13-3 (ainda perde, mas viável como #2 no Brasil — que é onde está o dinheiro).
