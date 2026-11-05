# Reinos da Área — Protótipo Godot 4 (v0.2)

## Jogo de estratégia territorial baseado em cálculo de área

> *Conquiste territórios. Calcule para vencer.*

O território inimigo aparece inteiro, mas **sem grid**. Estime quantos quadrados cabem nele, compare com o seu reino e decida: **Atacar, Defender ou Recuar**. São 20 fases em 5 cenários, 10 rodadas por fase, e a meta é dominar 70% do mapa.

---

## Estrutura do projeto

```
ReinosDaArea/
├── project.godot
├── scenes/Main.tscn              ← única cena (tudo é montado por código)
├── scripts/
│   ├── Main.gd                   ← roteador de telas + cursores/janela
│   ├── GameManager.gd            ← controlador de uma fase (rodadas, timer, habilidades, fim de fase)
│   ├── TerritoryGenerator.gd     ← 6 estratégias de forma, meios-blocos e áreas vazadas
│   ├── TerritoryRenderer.gd      ← desenho via _draw(), grid de referência, animações
│   ├── AudioManager.gd           ← autoload: buses Music/SFX
│   ├── autoload/GameState.gd     ← autoload: progresso salvo (user://reinos_save.cfg)
│   ├── data/                     ← CampaignData (20 fases), ArchetypeData
│   ├── systems/                  ← CombatResolver, AccuracyTracker, UnitFormatter
│   ├── ui/                       ← UiKit, MedievalTheme (Theme global), OrnateStyleBox, ScreenTransition
│   │   └── widgets/              ← DominanceBar, RoundTracker, TimerMedallion, ResourcePips, KeyBadge,
│   │                                PhaseNode, StarMedal, FloatingText, OptionsPanel, PauseMenu
│   └── screens/                  ← TitleScreen, MainMenu, ArchetypeSelect, CampaignMap, BattleScreen,
│                                    PhaseEndPanel, CartographerPanel, TutorialOverlay
├── shaders/                      ← parchment (pergaminho por cenário), vignette, gold_sheen
├── tests/                        ← run_tests.gd, integration_test.tscn, screenshot_test.tscn
├── assets/                       ← audios, cursor, fonts, icons, ui, docs
└── build/Desktop/                ← build exportado (reexportar para a v0.2)
```

## Como abrir

1. Abra o **Godot 4.6** (ou superior) → **Import** → selecione `project.godot` → **Import & Edit**.
2. Aguarde a importação inicial dos arquivos (necessária para registrar as classes novas).
3. Pressione **F5**. Mais detalhes em `assets/docs/Guia de instalação - Reinos da Área.md`.

## Fluxo do jogo

`Tela de título` → `Menu` → `Seleção de arquétipo` → `Mapa de campanha` → `Briefing` → `Batalha (10 rodadas)` → `Fim de fase` (estrelas, IP, XP).

Na primeira vez na Fase 1, a Cartógrafa conduz um tutorial curto.

## Controles

| Tecla | Ação |
|---|---|
| **A** | Atacar |
| **D** | Defender |
| **R** | Recuar |
| **E** | Ativar a habilidade do arquétipo |
| **Enter / Espaço** | Próxima rodada (na tela de resultado) |
| **Esc** | Pausar (na batalha) · voltar (nos menus) |

## Interface

- **Tema medieval global** (`MedievalTheme` + `OrnateStyleBox`): painéis de couro com borda dourada dupla e rebites, tooltips e sliders no mesmo estilo.
- **Campo de batalha em pergaminho** (shader), com aparência própria por cenário (planície, vale com curvas de nível, serra hachurada, arquipélago com ondas, abismo com rachaduras); reinos em aguada azul/vermelha com contorno de pena.
- **HUD da batalha:** Domínio com bandeira na meta de 70%, histórico das 10 rodadas em escudos, relógio circular, selos de tecla (A/D/R/E/Enter), moedas de Recurso Estratégico e *tooltips* nas estatísticas.
- **Pausa (Esc):** congela o relógio; abandonar a fase pede confirmação. **Opções:** música, efeitos, tela cheia e "Reduzir movimento".
- **Navegação por teclado** nos menus e no mapa (setas + Enter).
- **Tutorial** com holofote no elemento explicado.

## Mecânicas

### Combate (determinístico)

```
Força_J = Área_J × atacante × (1+Embalo) × Muralha        Força_I = Área_I × defensor
ATACAR vence se Força_J > Força_I · DEFENDER vence se Força_I > Força_J
```

Atacar e Defender são complementares: sempre há exatamente uma decisão certa (o terreno só desloca o limiar). A diferença de área entre os reinos é calculada na razão efetiva, já com o terreno.

| Ação | Acerto | Erro |
|---|---|---|
| ATACAR | Domínio +10%, área +10% | −20% da área (−15% com Consolidação) |
| DEFENDER | Domínio +10%, área +5% | −10% da área |
| RECUAR / tempo esgotado | — | −3% de Domínio (a área fica intacta) |

O gerador garante margem mínima de 1% entre as forças, então não há empates.

### Cenários

| Cenário | Fases | Terreno (atq / def) | Formas | Grade ao redor do inimigo | Tempo | Unidade |
|---|---|---|---|---|---|---|
| Planícies de Aldrath | 1–4 | 1,0 / 1,0 | Retângulos | Total | 60 s | m² |
| Vales de Kheldorn | 5–8 | 1,0 / 1,25 | Meios-blocos e diagonais | 1 célula | 60 s | m² → km² |
| Serra das Pedras Vivas | 9–12 | 0,85 / 1,25 | Trapézios e compostas | Nenhuma | 60 s | km² |
| Arquipélago do Oblívio | 13–16 | 1,10 / 0,90 | Complexas e preenchidas | Nenhuma | 45 s | hectares |
| Abismo Irregular | 17–20 | misto (sorteado por rodada) | Malhas vazadas | Nenhuma | 30 s | hectares |

A Fase 20 tem **morte súbita**: uma decisão errada encerra a fase. O intervalo de diferença de área vai de 25–35% (Fase 1) a 2–5% (Fase 20).

### Arquétipos (custos em Recursos Estratégicos — RE)

| | Passiva | Ativa (1× por fase) |
|---|---|---|
| **Estrategista** | *Olho de Águia*: +2 células de grid ao redor do inimigo | *Análise de Campo* (1 RE): área real e grid do inimigo por 5 s |
| **Engenheiro** | *Consolidação*: erro ao atacar custa 15% em vez de 20% | *Muralha de Emergência* (2 RE): ×1,25 no seu território por 1 rodada |
| **Guerreiro** | *Embalo de Combate*: +5% por vitória seguida (até +15%) | *Golpe Decisivo* (1 RE): dobra ganho e perda da rodada |

Começa-se com 3 RE e ganha-se +1 ao concluir uma fase pela primeira vez.

### Índice de Precisão (IP) e estrelas

O IP é derivado das decisões (sem digitar estimativas): decisão certa = 100; recuo = 70 ou 40; erro = 50 / 25 / 0 conforme a margem real. IP da fase = média.

- ★ **Bronze:** Domínio ≥ 70% ao final das 10 rodadas.
- ★★ **Prata:** bronze e 70% atingido até a 6ª rodada.
- ★★★ **Ouro:** bronze, IP ≥ 85% e nenhuma derrota.

### Pontuação

Vitória: 100 pts + bônus de sequência (+50 por vitória consecutiva além da primeira) + bônus de velocidade (até 200). Derrota: −50 (mínimo 0). XP da fase = pontos + 100 por estrela.

## Testes

```
Godot_console.exe --headless --path . --import
Godot_console.exe --headless --path . --script res://tests/run_tests.gd          # regras e gerador
Godot_console.exe --headless --path . res://tests/integration_test.tscn          # fases completas
```

## Documentação

`assets/docs/` tem cada documento do projeto em **PDF** e em **Markdown atualizado** (mesmo nome): Apresentação, Documento Complementar, Guia de instalação, Relatório do PAC IV e, em `GDD/`, o Game Design Document (v5).

## Extensões futuras

- [ ] Evolução visual do castelo e estados visuais dos reinos inimigos
- [ ] Trilha e ambientação sonora por cenário; voz da Cartógrafa
- [ ] Calibração fina da dificuldade com playtests
- [ ] Versão Web

## Dependências

- Godot 4.6+
- Nenhum plugin ou asset externo necessário
