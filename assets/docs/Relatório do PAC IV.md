# REINOS DA ÁREA

**Relatório de Acompanhamento de Projeto**
*Disciplina: PAC IV | Católica SC | 2026*
*Equipe: Enzo Camelo Vieira | Vinícius de Castilhos*

> **Versão atualizada.** Esta edição mantém a estrutura do relatório original e acrescenta, na seção 3, o **status de cada item planejado para a N2** (✅ implementado · ⚠️ parcial · ⏳ futuro) e as **decisões de design** tomadas durante a implementação. O protótipo passou da v0.1 para a **v0.2**.

---

## 1. Pacote de Entregas do PAC III

Os recursos e documentos elaborados no escopo desta etapa estão estruturados nos seguintes componentes para avaliação:

### 1.1 Game Design Document (GDD)

Documento orientador de todo o design do projeto. Desenvolvido e aprofundado ao longo do PAC, conta com 15 seções detalhadas que abrangem desde a premissa central e os objetivos pedagógicos até o level design dos 5 cenários, a especificação dos três arquétipos, as regras de combate e a identidade visual. O GDD está formatado em HTML (totalmente exportável para PDF), com ilustrações, diagramas de fluxo, tabelas de balanceamento de combate e detalhamento passo a passo do ciclo de gameplay.

> **Atualização:** o GDD evoluiu para a **v5** (`GDD/Reinos da Área - Game Design Document.md`), alinhado ao que foi implementado na N2.

### 1.2 Protótipo Executável (.zip)

Arquivo compactado que reúne a estrutura completa do projeto na engine Godot 4. Inclui os scripts em GDScript, o arquivo de inicialização `project.godot` e todo o acervo de efeitos sonoros e trilhas. O projeto é executável imediatamente no Godot 4.2 ou versões posteriores, sem necessidade de dependências extras.

> **Atualização (v0.2):** além de `Main.gd`, `TerritoryRenderer.gd`, `GameManager.gd` e `TerritoryGenerator.gd`, o projeto agora tem `scripts/autoload/`, `scripts/data/`, `scripts/systems/`, `scripts/ui/` e `scripts/screens/`, além de testes automatizados em `tests/`. Recomenda-se Godot **4.6.x** (o projeto está configurado para 4.6).

### 1.3 Documento Complementar

O documento complementar é entregue em anexo à atividade. Era uma pendência da matéria do PAC III, para comparação entre o protótipo e o GDD. Está atualizado em `Documento_Complementar_Reinos_Da_Area.md`.

---

## 2. Relatório de Progresso e Estado Atual

Este tópico apresenta o panorama evolutivo do *Reinos da Área*, pontuando o avanço desde as definições preliminares do PAC III até o fechamento da N1. O conceito inicial do One Page GDD amadureceu para um protótipo jogável integrado a uma interface imersiva, combate balanceado e criação procedural de cenários.

### 2.1 Visão Geral do Jogo

*Reinos da Área* é uma experiência de estratégia medieval em turnos voltada para PC e Web, cuja premissa central é a expansão de domínio por meio da estimativa visual de superfícies. Como diferencial mecânico, a malha quadriculada é visível apenas nas terras do próprio jogador, enquanto o território adversário permanece liso, exigindo percepção geométrica antes de cada ação. O aprendizado de geometria plana opera via *stealth learning* (aprendizagem implícita), dispensando questionários ou exercícios formais.

O planejamento completo da campanha prevê **20 fases** distribuídas em **5 cenários** medievais temáticos, com **10 rodadas** cada. O jogador inicia com uma determinada Área X e 0% de Domínio do Mapa, tendo a missão de conquistar ao menos 70% do território antes do término dos turnos.

### 2.2 Funcionalidades operacionais implementadas (N1)

- **Geração procedural de territórios:** o `TerritoryGenerator` emprega o algoritmo BFS ponderado pela distância ao centro para criar contornos orgânicos encaixados na grade. A quantidade de células é calculada rigorosamente, mantendo a variação de área entre os oponentes na faixa de 2% a 8% e oferecendo confrontos inéditos a cada turno.
- **Sistema de combate determinístico:** confronto sem componentes aleatórios. A resolução decorre do confronto direto entre os valores de área das duas partes, ponderados pelos modificadores do terreno. As ações possuem custos assimétricos de risco:
  - *Atacar* de forma incorreta acarreta perda de 20% da área própria;
  - *Defender* de forma equivocada consome 10% da área;
  - *Recuar* compromete unicamente 3% do Domínio do Mapa, preservando a área do jogador.
- **Grid seletivo com revelação pedagógica:** o `TerritoryRenderer` oculta as demarcações internas do reino rival. Imediatamente após a resolução do turno, o grid do adversário é revelado por 3 segundos com animação suave, validando a estimativa do jogador de maneira educativa e sem tom punitivo.
- **HUD medieval refatorado:** barra superior com área total, barra percentual de conquista, marcadores de rodada e indicador de Mundo e Fase; o rodapé acomoda as três decisões táticas com indicação de hover e bloqueio dinâmico de botões.
- **Mecânicas de pontuação e streak:** o `GameManager` computa os pontos de vitória, bonificações pelo tempo restante e multiplicadores por sequências invictas. Derrotas reduzem 50 pontos e encerram a sequência.
- **Design de áudio integrado:** sonoplastia de impacto para ataques, vitórias e derrotas, somada a uma trilha medieval ambiente contínua.

> **Nota de correção (v0.2):** no protótipo v0.1 o Recuar descontava 5% da área, em desacordo com o GDD e com este relatório. Na v0.2 o Recuar custa **apenas 3% de Domínio** e preserva a área.

### 2.3 Amadurecimento do GDD

O escopo inicial foi expandido para um GDD robusto de 15 páginas, reunindo: High Concept, Visão Geral, Design Goals, Mecânica de Cálculo de Área, Dinâmica de Combate, Core Game Loop, Sistema de Arquétipos e Habilidades, Progressão, Ambientação (5 cenários), Narrativa, Direção Artística, Paisagem Sonora, Level Design detalhado (20 fases com gradação de figuras planas), Demonstração de Gameplay e Fundamentação como Jogo Sério alinhada às diretrizes da BNCC.

---

## 3. Planejamento de Implementações para a N2

Esta seção compila os desenvolvimentos, expansões de escopo e refinamentos previstos para a entrega de N2, justificando a relevância de cada recurso no produto final. Cada item traz o **status na v0.2**.

| Item | Status |
|---|---|
| 3.1 Tela inicial e menu principal | ✅ |
| 3.2 Três arquétipos | ✅ |
| 3.3 Mapa de campanha e 5 cenários | ✅ |
| 3.4 Matriz de modificadores de terreno | ✅ |
| 3.5 Escalas e unidades | ✅ |
| 3.6 Melhorias e refinamentos | ✅ (com ⚠️ na calibração fina) |
| Tutorial (slide "Cenário atual e futuro") | ✅ |

### 3.1 Tela Inicial e Menu Principal — ✅

Diferente da versão anterior, que carregava imediatamente no campo de batalha, existe agora uma tela de boas-vindas com título, lema (*"Conquiste territórios. Calcule para vencer."*), escolha de arquétipo, opções de áudio e transição animada de desdobramento de mapa para o início da campanha.

**Como ficou:** `MainMenu` (Jogar Campanha, Selecionar Arquétipo, Mapa de Cenários, Opções, Sair); `ArchetypeSelect` com três cartões; opções com volumes independentes de música e efeitos (buses `Music` e `SFX`) e reinício de progresso com confirmação; `ScreenTransition` com o pergaminho que se desdobra (menu → campanha) e que vira a página (entre fases), feito só com Tween.

### 3.2 Implementação dos Três Arquétipos — ✅

Os três perfis táticos substituem o modelo anterior de atributos padronizados, cada um com uma habilidade passiva e uma ativa:

- **Estrategista**
  - *Olho de Águia* (passiva): projeta 2 células de grade adicionais ao redor do adversário como referencial visual.
  - *Análise de Campo* (ativa, 1 Recurso Estratégico): exibe a área real do oponente por 5 segundos.
  - *Objetivo:* solucionar a falta de alternativas de visualização e dar suporte analítico.
- **Engenheiro**
  - *Consolidação* (passiva): reduz o prejuízo por derrota de 20% para 15%.
  - *Muralha de Emergência* (ativa, 2 RE): confere o modificador defensivo de montanha (×1,25) ao próprio território por uma rodada.
  - *Objetivo:* enriquecer escolhas defensivas e o controle de perdas.
- **Guerreiro**
  - *Embalo de Combate* (passiva): +5% de área efetiva por vitória consecutiva (até +15%), zerado se recuar ou perder.
  - *Golpe Decisivo* (ativa, 1 RE): dobra o ganho de território no sucesso, mas duplica a penalidade em caso de revés.
  - *Objetivo:* dinâmicas de alto risco e alta recompensa.

**Decisões de implementação:**

- Este relatório prevalece sobre o GDD v4 nas habilidades (decisão da equipe); o GDD foi atualizado para a v5.
- **Recursos Estratégicos (RE):** o jogador começa com 3 e ganha +1 ao concluir uma fase pela primeira vez. Cada ativa só pode ser usada **1× por fase** (selo de "usada" no botão).
- Sem RE suficiente, o botão vibra e fica vermelho por 0,5 s, sem outra penalidade.
- O Olho de Águia só altera o jogo onde a grade de referência é limitada (Vales em diante); nas Planícies o grid já cobre o mapa inteiro.
- A Muralha aplica ×1,25 à força do jogador na rodada, em qualquer postura.

### 3.3 Mapa de Campanha e Progressão pelos 5 Cenários — ✅

Um mapa geral conecta os 5 cenários, introduzindo complexidade geométrica gradativa:

| Cenário | Fases | Formas | Grade ao redor do inimigo | Cartógrafa | Status |
|---|---|---|---|---|---|
| **Planícies** | 1–4 | Polígonos retangulares simples, com ampla discrepância entre os lados | Total | Assistência contínua | ✅ |
| **Vales** | 5–8 | Meios-blocos e arestas diagonais | Reduzida (1 célula) | Ativa (5–6), silenciosa (7–8) | ✅ |
| **Serras** | 9–12 | Formas trapezoidais e compostas | Suprimida | Silenciosa (9), ausente a partir da 10 | ✅ |
| **Arquipélagos** | 13–16 | Figuras complexas e preenchidas; **45 s** por turno | Suprimida | Ausente | ✅ |
| **Abismo Irregular** | 17–20 | Malhas vazadas (blocos internos ausentes); **30 s** por turno; Fase 20 sob **morte súbita** | Suprimida | Ausente | ✅ |

**Decisão:** na divergência entre GDD e Relatório sobre as formas de cada cenário, valeu o **Relatório**. A tabela de fases fica em `scripts/data/CampaignData.gd`. O mapa guarda estrelas e libera a fase seguinte ao vencer; cada fase tem um briefing (terreno, tempo, formas, unidade, estado da Cartógrafa) antes de iniciar.

### 3.4 Matriz de Modificadores de Terreno — ✅

Os multiplicadores de terreno estão integrados ao cálculo de combate e destacados no HUD (terreno da rodada, força de ataque e de defesa já multiplicadas):

| Cenário / Fases | Modificador de terreno | Impacto prático |
|---|---|---|
| **Planícies** (1–4) | Plano (×1,0 para ambos) | Confronto puramente numérico. |
| **Vales** (5–8) | Defensor ×1,25 | Forças menores na defesa podem vencer; a percepção visual direta passa a requerer maior cuidado. |
| **Serras** (9–12) | Defensor ×1,25 · Atacante ×0,85 | Ausência de linhas-guia aliada a formas compostas exige maior cálculo mental. |
| **Arquipélagos** (13–16) | Atacante ×1,10 · Defensor ×0,90 | Privilegia posturas ofensivas e decisões ágeis contra o relógio (45 s). |
| **Abismo Irregular** (17–20) | Modificadores mistos | Margem de erro mínima: ignorar o relevo é tão penalizante quanto errar a área (30 s). |

**Decisão:** no Abismo, o terreno é **sorteado a cada rodada** entre Plano, Vale, Serra e Costeiro e exibido no HUD.

**Fórmula de combate adotada** (uma única comparação determinística):
`Força_J = Área_J × atacante × (1+Embalo) × Muralha` · `Força_I = Área_I × defensor`.
Atacar vence se Força_J > Força_I; Defender vence se Força_I > Força_J. As duas ações são complementares (sempre há exatamente uma decisão certa) e o gerador garante margem mínima de 1%, então não há empates.

> **Lição da verificação:** uma primeira versão avaliava Atacar e Defender com forças diferentes (o jogador como defensor na segunda). Isso criava uma zona em que *ambas* as ações perdiam e, na Serra, tornava as fases impossíveis. Os testes de equilíbrio por fase (item 3.8) pegaram o problema; a comparação única o resolve. Além disso, o tamanho do inimigo é gerado pela razão **efetiva** (com o terreno), para que a diferença de 25–35% → 2–5% mantenha as duas decisões equilibradas em todas as fases.

### 3.5 Sistema Progressivo de Escalas e Unidades — ✅

Antes, as dimensões eram expressas em unidades de grid (u²). A v0.2 converte medidas conforme a ampliação do domínio:

- **Fases 1–4 (Planícies):** metros quadrados; cada bloco equivale a 1 m².
- **Fases 5–12 (Vales e Serras):** transição automática para quilômetros quadrados ao ultrapassar 10.000 m². *Implementação:* Vales usam 400 m² por bloco (começam em m² e viram km² ao cruzar o limite); Serras usam 50.000 m² por bloco (sempre em km²).
- **Fases 13–20 (Arquipélagos e Abismo):** hectares; 1 bloco = 1 ha.

A interface exibe a unidade correspondente com uma indicação sutil da equivalência anterior (ex.: **2,5 km²** · *= 2.500.000 m²*). Os números seguem o padrão pt-BR.

### 3.6 Melhorias e Refinamentos Complementares

- ✅ **Painel de encerramento de fase** com a taxa de exatidão das estimativas (**Índice de Precisão**) e ranqueamento por insígnias (bronze, prata e ouro), com estrelas que se acendem em sequência.
- ✅ **Transição interpolada entre rodadas:** o território rival da rodada seguinte é revelado progressivamente, por varredura de colunas.
- ⚠️ **Calibração das curvas de dificuldade:** implementada como interpolação linear do intervalo de diferença de área (25–35% na Fase 1 até 2–5% na Fase 20). Os valores são constantes ajustáveis e **ainda precisam de validação com testes de jogo** para afinar fase a fase.
- ✅ **Expansão do `TerritoryGenerator`:** blocos inteiros e meios-blocos triangulares; estratégias retangular, diagonal (chanfros), trapezoidal, composta (L/T/U), complexa e vazada; todas verificadas por testes automáticos (área, região e conectividade).
- ✅ **Medidor de Recursos Estratégicos** no HUD e no mapa de campanha, para o acionamento transparente das habilidades ativas.
- ✅ **Tutorial** (listado na apresentação): 5 passos guiados pela Cartógrafa na primeira Fase 1, com opção de pular.

### 3.7 Decisões de design registradas na implementação

| Tema | Decisão |
|---|---|
| **Índice de Precisão (IP)** | Derivado das decisões, sem entrada de estimativa (evita virar um exercício). Decisão certa = 100; recuo = 70 (margem < 5%) ou 40; erro = 50 / 25 / 0 conforme a margem real (< 5% / < 15% / ≥ 15%). IP da fase = média. |
| **Som de precisão** | IP ≥ 90: sino cristalino; 40–89: silêncio; < 40: sino grave. |
| **Fim de fase** | Sempre 10 rodadas. Vitória: Domínio ≥ 70% ao final. |
| **Estrelas** | Bronze: 70% ao final. Prata: 70% até a 6ª rodada. Ouro: IP ≥ 85% e nenhuma derrota. Vale a mais alta. |
| **Derrota imediata** | Área abaixo de 4 u², ou qualquer erro na Fase 20 (morte súbita). |
| **Cartógrafa** | Máquina de estados fixa por fase: ativa (1–6), silenciosa (7–9), ausente (10+). |
| **Teclas** | A (atacar), D (defender), R (recuar), E (habilidade), Esc (voltar ao mapa). |

### 3.8 Verificação

- Testes automáticos de regras (combate, terreno, habilidades, IP, estrelas, unidades, campanha e gerador), incluindo uma checagem de equilíbrio das 20 fases (Atacar e Defender corretos em 30–70% das rodadas cada): **497 verificações**, todas passando.
- Teste de integração que joga fases completas (1, 5, 9, 13, 17 e 20) com os três arquétipos, inclusive uma partida de **jogo ótimo** que vence cada cenário com 3 estrelas: **295 verificações**, todas passando.
- Capturas de tela das telas principais e dos cenários para inspeção visual de layout.
- **Pendente:** playtest humano completo (balanceamento, ritmo de 10 rodadas por fase, calibração das curvas) e revisão de acessibilidade/contraste.

### 3.9 Fora do escopo da N2 (⏳ futuro)

Evolução visual do castelo; estados visuais por reino inimigo (Estável/Alerta/Vulnerável/Conquistado); trilha própria por cenário e ambientação sonora; voz da Cartógrafa; versão Web.

---

*Reinos da Área | PAC IV | Católica SC | 2026*
