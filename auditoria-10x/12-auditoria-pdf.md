# 12 - Auditoria do PDF para Pediatra

**Data:** 2026-05-11
**Versão:** 1.0
**Autor:** Claude Code (Opus 4.7)

---

## Por que esse documento importa

O PDF para pediatra é, junto com o Chat IA, **o único diferencial verdadeiro** do Naplet contra o Napper. Mas o PDF atual é fraco — gera, mas parece amador. Isso queima um trunfo enorme.

---

## O PDF é real ou fake?

**REAL.** Gerador em [PDFReportService.swift:239](Naplet/Data/Services/PDF/PDFReportService.swift:239):

```swift
func generateCompletePDF(from data: CompleteReportData) -> Data
```

Usa `UIGraphicsPDFRenderer` (framework nativo iOS). Múltiplas páginas, dados de Sleep/Feeding/Diaper/Health/Vaccination. Não é imagem, não é HTML — é PDF de verdade.

---

## O que está bom

| Item | Estado | Detalhe |
|---|---|---|
| Gerador real | ✅ | UIGraphicsPDFRenderer, múltiplas páginas |
| Conteúdo de sono | ✅ | Total, média diária, naps, durações, qualidade com gráficos de barras |
| Conteúdo de alimentação | ✅ | Total, mama, mamadeira (ml), sólidos + tabela de 10 registros recentes |
| Conteúdo de fralda | ✅ | Contagem total, wet/dirty/mixed |
| Conteúdo de temp/medicamento | ✅ | Registros recentes |
| Conteúdo de vacinação | ✅ | Lista com status |
| Gráficos de barras | ✅ | Cores qualitativas (verde/amarelo/vermelho) |
| Nome do arquivo | ✅ | `Naplet_{baby.name}_{YYYY-MM-DD}.pdf` |
| Compartilhamento | ✅ | UIActivityViewController (WhatsApp, Mail, AirDrop) |
| Prévia antes de exportar | ✅ | PDFKit PDFView |
| Gate de paywall | ✅ | Premium-only para compartilhar |

---

## O que está mal

| Item | Estado | Problema |
|---|---|---|
| Logo do Naplet | ❌ | Nenhum logo no PDF |
| Identidade visual | ❌ | Cores fortes (roxo 0.4,0.2,0.6) sem coesão |
| Tipografia | ⚠️ | Sistema UIFont, inconsistente entre seções |
| Espaçamento | ⚠️ | 30-40pt entre seções, não uniforme |
| Peso/altura | ❌ | NÃO inclui peso e altura. Pediatra **sempre** quer ver peso. |
| Campo de notas para o pediatra | ❌ | Sem espaço para anotações manuais |
| Campo de assinatura | ❌ | Sem campo para o pediatra assinar/validar |
| Cabeçalho institucional | ❌ | Sem dados de "consulta com Dr. ___" |
| Sumário/índice | ❌ | PDF jorra direto para conteúdo, sem TOC |
| Marca d'água em free | ❌ | Free user gera e exporta sem watermark, sem freio claro |

---

## Comparação com o que o pediatra ESPERA

Pediatras estão acostumados a relatórios médicos com:

1. **Cabeçalho institucional** (nome do paciente, idade, sexo, data do relatório)
2. **Sumário executivo** (1 parágrafo com destaques)
3. **Dados antropométricos** (peso, altura, percentis) ← Naplet **não tem**
4. **Tabela de sinais vitais** (temperatura mínima/máxima, frequência)
5. **Padrão de sono** (com gráfico) ← Naplet tem ✅
6. **Padrão alimentar** (com gráfico) ← Naplet tem parcial
7. **Eliminações** (fraldas com padrão) ← Naplet tem ✅
8. **Imunizações** (com calendário PNI) ← Naplet tem ✅
9. **Medicações em uso**
10. **Notas dos cuidadores** ← Naplet não pede
11. **Campo para o médico anotar**
12. **Logo + nome do app gerador** (para credibilidade)
13. **Data e versão do PDF** (para rastreabilidade)

Naplet entrega 5 de 13. Suficiente para "funcionar", insuficiente para impressionar.

---

## Proposta de redesign do PDF

### Página 1 — Cabeçalho + Sumário

```
[LOGO NAPLET]                                    [Versão 1.0 · 11 Mai 2026]

Relatório de Acompanhamento Infantil

Paciente: Alice Souza (3 meses · feminino)
Período: 28-Abr-2026 a 11-Mai-2026 (14 dias)
Cuidador relatante: Edy Souza (Pai)

──────────────────────────────────────────────────────────────────
SUMÁRIO DO PERÍODO
──────────────────────────────────────────────────────────────────

Sono total médio:     13h12 / dia    (faixa ideal 14h-16h)  ⚠️
Sonecas / dia:        3 (recomendado: 3-4)
Despertares noturnos: 2.1 / noite   (semana passada: 3.4)  ↘
Alimentação:          7-8 mamadas/dia
Fraldas trocadas:     8.3 / dia
Última febre:         Nenhuma no período
Peso atual:           5.2 kg (P50 OMS)
Altura atual:         58 cm (P50 OMS)
```

### Página 2 — Padrão de sono (com gráfico horizontal de 14 dias)

### Página 3 — Padrão alimentar + Eliminações

### Página 4 — Imunizações (calendário PNI com check)

### Página 5 — Medicações + Observações

### Página 6 — Espaço para anotações do médico

```
──────────────────────────────────────────────────────────────────
ANOTAÇÕES DO PROFISSIONAL
──────────────────────────────────────────────────────────────────


  [linhas em branco com pautas]



──────────────────────────────────────────────────────────────────
Profissional: _____________________     CRM: _____________________
Data: ____ / ____ / ____               Assinatura: _____________
──────────────────────────────────────────────────────────────────

Relatório gerado automaticamente pelo Naplet (versão X)
naplet.app  •  Não substitui avaliação médica
```

---

## Os 5 ajustes mais críticos do PDF

### 🔴 #1: Adicionar logo + cabeçalho institucional

**Esforço:** 2-3h.
**Mudança:** [PDFReportService.swift](Naplet/Data/Services/PDF/PDFReportService.swift) linhas 336-342. Adicionar `UIImage` do logo do app (usar o do .xcassets) e bloco de cabeçalho com nome, idade, sexo, período, cuidador.
**Impacto:** PDF imediatamente sente-se 5x mais profissional.

### 🔴 #2: Incluir peso e altura

**Esforço:** 4-6h.
**Mudança:** Criar tabela `growth_measurements` (peso, altura, perímetro cefálico, data). Pedir input no perfil do bebê. Adicionar seção "Dados antropométricos" no PDF com gráfico OMS.
**Impacto:** alto. Pediatra quer ESTE dado mais do que qualquer outro.

### 🔴 #3: Espaço para o médico anotar/assinar

**Esforço:** 1h.
**Mudança:** adicionar última página com pautas para anotação + campos de assinatura/CRM. PDFKit pode renderizar isso facilmente.
**Impacto:** o pediatra **usa** o documento na consulta em vez de só "olhar" e descartar. Aumenta percepção de "ferramenta médica de verdade".

### 🟠 #4: Watermark "AMOSTRA" para free + preview gratuito

**Esforço:** 3-4h.
**Mudança:** se `!hasPremiumAccess`, renderizar texto rotacionado 45° em diagonal por todas as páginas do PDF. Mostrar preview completo no app, mas o usuário não pode compartilhar sem upgrade.

Por que isso converte: deixar o free **ver o resultado** mostra o valor concretamente. Em vez de bloquear (que cria adversário), entrega + restringe (cria desejo).

**Impacto:** subir conversão do trigger `pdfReport` (que hoje nem está implementado).

### 🟠 #5: Refinar tipografia e espaçamento

**Esforço:** 4-6h.
**Mudança:**
- Trocar fonte do corpo para serif (Times, Georgia) — vibração "documento médico"
- Padronizar espaçamento entre seções (sempre 24pt)
- Reduzir intensidade do roxo (usar variant mais sóbria, 0.3,0.25,0.5)
- Aumentar tamanho dos números importantes (peso, sono total) para 18-22pt

**Impacto:** sutil mas cumulativo. Vira "documento" em vez de "relatório de app".

---

## Como tornar o PDF um ativo de marketing

Tirando esses 5 ajustes, o PDF vira **arma de divulgação**:

1. **Screenshot no App Store** dedicado: "O único app que entrega o relatório que seu pediatra quer ver"
2. **Landing page section** com mockup do PDF aberto
3. **Compartilhamento incentivado**: ao gerar PDF, "Compartilhe com o pediatra **e** com outros pais que possam precisar" (tag "made with naplet" no rodapé do PDF — vira viral)
4. **Parceria com clínicas**: oferecer Naplet Premium gratuito para pediatras (que recomendam aos pais)

---

## Conclusão

O PDF atual é a feature 🟡 que mais **sub-entrega**. Tem infraestrutura técnica boa (UIGraphicsPDFRenderer com múltiplas páginas), mas o resultado parece printscreen formatado. Com **2-3 dias de trabalho focado**, vira documento institucional digno. E aí o Edy pode usá-lo como diferencial central na App Store, no marketing e nas conversas com pediatras.

Não fazer isso é desperdiçar o trunfo mais defendível do Naplet contra o Napper.
