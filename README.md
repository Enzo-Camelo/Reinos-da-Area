# Reinos da Área

> *Conquiste territórios. Calcule para vencer.*

**Reinos da Área** é um jogo de estratégia territorial feito em **Godot 4**, em que o jogador aprende **cálculo de área** jogando. A cada rodada o reino inimigo aparece inteiro, mas **sem quadriculado**: o jogador estima quantos quadrados cabem nele, compara com o seu próprio reino (que tem o quadriculado) e decide entre **Atacar**, **Defender** ou **Recuar**. São **20 fases em 5 cenários**, com 10 rodadas por fase. A meta é dominar 70% do mapa.

Versão atual: **v0.2** (protótipo jogável da campanha completa). Autores: Enzo Camelo Vieira, Gabriel Luís de Santana e Bruno Faria Travessini.

**Sumário:** [Requisitos](#1-requisitos) · [Baixar](#2-baixar-o-projeto) · [Executar](#3-executar-o-jogo) · [Como jogar](#4-como-jogar) · [Controles](#5-controles) · [Regras e progressão](#6-objetivo-regras-e-progressão) · [Limitações](#7-limitações-conhecidas-e-o-que-ainda-não-existe) · [GDD e documentos](#8-gdd-e-documentação) · [Testes](#9-testes-automáticos) · [Estrutura](#10-estrutura-do-projeto)

---

## 1. Requisitos

| Item | Requisito |
|---|---|
| Sistema operacional | Windows 10 ou 11 (64 bits). É onde o jogo foi desenvolvido e testado; Linux e macOS devem funcionar com o Godot, mas não foram testados. |
| Engine | **Godot 4.6** ou superior (testado com a **4.6.3 stable**, versão padrão, sem .NET/C#). Download: <https://godotengine.org/download/windows/> |
| Placa de vídeo | Qualquer uma com **OpenGL 3.3** (o projeto usa o renderizador *Compatibility*). |
| Tela | Feito para **1920×1080**. Em outras resoluções a imagem escala mantendo a proporção 16:9. |
| Git | Opcional, só se for clonar o repositório pelo terminal. |
| Dependências extras | **Nenhuma.** Não há plugins nem assets externos para instalar; fontes, imagens e sons já estão no repositório. |

## 2. Baixar o projeto

**Opção A: ZIP (mais simples).** Na página do repositório, <https://github.com/Enzo-Camelo/Reinos-da-Area>, clique em **Code → Download ZIP** e extraia em uma pasta, por exemplo `C:\Jogos\Reinos-da-Area`. A pasta extraída deve conter o arquivo `project.godot`.

**Opção B: clonar com Git.**

```
git clone https://github.com/Enzo-Camelo/Reinos-da-Area.git
cd Reinos-da-Area
```

## 3. Executar o jogo

Não há instalação: basta ter o Godot e abrir o projeto. O Godot pode ser usado sem instalador (baixe o ZIP, extraia e execute `Godot_v4.6.3-stable_win64.exe`).

### Pelo editor do Godot (recomendado)

1. Abra o Godot. Na tela de projetos, clique em **Importar** (*Import*).
2. Selecione o arquivo `project.godot` da pasta do jogo e clique em **Importar e editar**.
3. Aguarde a **primeira importação** dos arquivos (de 20 a 60 segundos; aparece uma barra de progresso no canto superior). Ela é necessária porque a pasta `.godot/` de cache não vem no repositório.
4. Pressione **F5** (ou o botão ▶ no canto superior direito). O jogo abre na **tela de título**.

> Se aparecer algum erro de "classe não encontrada" logo depois de abrir, feche e reabra o projeto uma vez: o Godot só registra as classes novas depois da primeira importação completa.

### Pelo terminal (alternativa)

Substitua o caminho pelo do seu Godot:

```
"C:\Godot\Godot_v4.6.3-stable_win64.exe" --path "C:\Jogos\Reinos-da-Area"
```

### Gerar o executável (.exe), opcional

O executável **não está no repositório** (passa de 100 MB). Para gerá-lo: no editor, abra **Projeto → Exportar…**, selecione **Windows Desktop** e clique em **Exportar projeto…**, salvando em `build/Desktop/ReinosDaArea.exe`. É preciso ter os *export templates* do Godot 4.6.3 instalados (o editor oferece baixar em **Editor → Gerenciar modelos de exportação**). Se o `.pck` for gerado como arquivo separado, mantenha o `.exe` e o `.pck` na mesma pasta.

Mais detalhes de instalação com imagens e passos: [`assets/docs/Guia de instalação - Reinos da Área.md`](assets/docs/Guia%20de%20instala%C3%A7%C3%A3o%20-%20Reinos%20da%20%C3%81rea.md).

## 4. Como jogar

### Iniciar uma partida

1. Na **tela de título**, pressione qualquer tecla (ou clique).
2. No **menu principal**, escolha **Jogar campanha**. (Se já houver progresso, aparece **Continuar** para voltar direto à próxima fase.)
3. Na primeira vez, escolha o seu **conselheiro** (arquétipo): Estrategista, Engenheiro ou Guerreiro. Dá para trocar depois no menu ou no mapa.
4. No **mapa de campanha**, clique no selo da **Fase 1** (as demais estão bloqueadas até vencer as anteriores). Leia o *briefing* e clique em **Iniciar fase**.
5. Na primeira vez na Fase 1, a **Cartógrafa** conduz um tutorial curto (5 passos, dá para pular).

### O que acontece em cada rodada

1. **Análise** (cerca de 1,5 s): aparecem o seu reino, à **esquerda, com o quadriculado**, e o reino inimigo, à **direita, liso**. Cada quadradinho do quadriculado vale uma unidade de área.
2. **Decisão** (tempo limitado conforme o cenário): estime visualmente a área do inimigo e compare com a sua. Em seguida escolha:
   - **Atacar:** acredite que o **seu reino é maior** (considerando o terreno).
   - **Defender:** acredite que o **inimigo é maior**.
   - **Recuar:** na dúvida, a opção segura. Custa 3% de Domínio, mas você não perde área.
3. **Revelação:** o quadriculado do inimigo aparece e o jogo mostra o cálculo (áreas × modificadores de terreno). É assim que se aprende a estimar melhor.
4. Aperte **Enter** (ou clique em *Próxima rodada*) para seguir. Depois de 10 rodadas a fase termina.

Se o tempo acabar, o jogo conta como **Recuo** automaticamente.

## 5. Controles

O jogo funciona com **mouse** e **teclado**.

| Tecla | Ação |
|---|---|
| **A** | Atacar |
| **D** | Defender |
| **R** | Recuar |
| **E** | Ativar a habilidade ativa do conselheiro (1× por fase, gasta Recursos Estratégicos) |
| **Enter / Espaço** | Próxima rodada (na tela de resultado) e confirmar botão em foco |
| **Esc** | Pausar (na batalha) · voltar/fechar (nos menus, mapa e opções) |
| **Setas** | Navegar entre botões e selos de fase no teclado |
| **Mouse** | Clicar em botões e selos; passar o mouse sobre as estatísticas mostra uma explicação |

No menu de **Opções**: volume da música e dos efeitos, tela cheia e **Reduzir movimento** (desliga tremor e partículas). Em **Opções** também há **Reiniciar progresso**, que apaga o jogo salvo.

## 6. Objetivo, regras e progressão

**Objetivo:** em cada fase, chegar a **70% de Domínio** do mapa ao final das **10 rodadas**.

### Regras básicas (combate determinístico, sem sorte)

```
Força do jogador = Área do jogador × bônus de ataque do terreno × (1 + Embalo) × Muralha
Força do inimigo = Área do inimigo × bônus de defesa do terreno
ATACAR vence se Força do jogador > Força do inimigo.   DEFENDER vence se Força do inimigo > Força do jogador.
```

Atacar e Defender são opostos: **sempre existe exatamente uma decisão certa**. O terreno só desloca o ponto de equilíbrio. O jogo garante uma diferença mínima de 1% entre as forças, então não há empate.

| Ação | Se acertar | Se errar |
|---|---|---|
| **Atacar** | Domínio +10% e área +10% | perde 20% da área (15% com Consolidação) |
| **Defender** | Domínio +10% e área +5% | perde 10% da área |
| **Recuar** ou tempo esgotado | nada | Domínio −3% (a área fica intacta) |

### Condições de vitória, derrota e progressão

- **Vitória da fase:** Domínio ≥ 70% depois da 10ª rodada. A fase seguinte é liberada no mapa.
- **Derrota da fase** (pode repetir quantas vezes quiser):
  - terminar as 10 rodadas com Domínio abaixo de 70%;
  - ou ficar com **menos de 4 unidades de área**;
  - ou, na **Fase 20 (morte súbita)**, errar uma única decisão.
- **Estrelas** (vale a melhor conquistada):
  - ★ Bronze: 70% de Domínio ao final das 10 rodadas.
  - ★★ Prata: Bronze e 70% atingidos já até a 6ª rodada.
  - ★★★ Ouro: Bronze, Índice de Precisão ≥ 85% e nenhuma derrota.
- **Índice de Precisão (IP):** mede o quanto suas decisões foram certas (100 por decisão certa; recuo vale 70 ou 40; erro vale 50, 25 ou 0 conforme a margem). Você não digita estimativas: o jogo calcula pelas decisões.
- **Pontuação:** vitória na rodada = 100 pontos + bônus de sequência (+50 por vitória seguida) + bônus de velocidade (até 200); derrota = −50. XP da fase = pontos + 100 por estrela.
- **Recursos Estratégicos (RE):** você começa com 3 e ganha +1 ao concluir uma fase pela primeira vez. São gastos nas habilidades ativas.
- **Progresso salvo automaticamente** em `%APPDATA%\Godot\app_userdata\Reinos da Área\reinos_save.cfg`.

### Os 5 cenários

| Cenário | Fases | Terreno (ataque / defesa) | Formas dos reinos | Quadriculado ao redor do inimigo | Tempo por rodada | Unidade |
|---|---|---|---|---|---|---|
| Planícies de Aldrath | 1–4 | 1,0 / 1,0 | Retângulos | Total | 60 s | m² |
| Vales de Kheldorn | 5–8 | 1,0 / 1,25 | Meios-blocos e diagonais | 1 célula | 60 s | m² → km² |
| Serra das Pedras Vivas | 9–12 | 0,85 / 1,25 | Trapézios e formas compostas | Nenhum | 60 s | km² |
| Arquipélago do Oblívio | 13–16 | 1,10 / 0,90 | Formas complexas | Nenhum | 45 s | hectares |
| Abismo Irregular | 17–20 | misto (muda a cada rodada) | Malhas com buracos | Nenhum | 30 s | hectares |

A diferença de tamanho entre os reinos vai diminuindo ao longo da campanha (de 25–35% na Fase 1 até 2–5% na Fase 20), então estimar fica cada vez mais difícil.

### Conselheiros (arquétipos)

| | Passiva (sempre ativa) | Ativa (1× por fase, custa RE) |
|---|---|---|
| **Estrategista** | *Olho de Águia*: +2 células de quadriculado ao redor do inimigo | *Análise de Campo* (1 RE): mostra a área real e o quadriculado do inimigo por 5 s |
| **Engenheiro** | *Consolidação*: errar ao atacar custa 15% em vez de 20% | *Muralha de Emergência* (2 RE): seu território vale ×1,25 por 1 rodada |
| **Guerreiro** | *Embalo de Combate*: +5% por vitória seguida (até +15%) | *Golpe Decisivo* (1 RE): dobra o ganho ou a perda da rodada |

## 7. Limitações conhecidas e o que ainda não existe

**Ainda não implementado:**
- Evolução visual do castelo do jogador e estados visuais dos reinos inimigos (Estável, Alerta, Vulnerável, Conquistado).
- Trilha sonora e ambientação sonora próprias de cada cenário (hoje há uma trilha única) e voz da Cartógrafa.
- Versão Web ou para celular.

**Limitações da versão atual:**
- **A dificuldade ainda não foi calibrada com testes de jogadores reais.** Os testes automáticos garantem que sempre há uma decisão certa e que cada fase é vencível, mas a curva de dificuldade pode precisar de ajuste.
- Os sons de sino (precisão) e de página (transição) foram **gerados por código** como substitutos de desenvolvimento e podem ser trocados por gravações finais.
- Testado apenas em **Windows**. Resolução ideal: 1920×1080.
- O executável (`.exe`) não é versionado por causa do tamanho; é preciso abrir pelo Godot ou exportar (seção 3).
- A pasta de cache `.godot/` não vem no repositório, por isso a primeira abertura demora mais.

## 8. GDD e documentação

O **Game Design Document (GDD) atualizado (v5)** está em:

- 📄 [`assets/docs/GDD/Reinos da Área - Game Design Document.md`](assets/docs/GDD/Reinos%20da%20%C3%81rea%20-%20Game%20Design%20Document.md) (versão em Markdown, legível direto no GitHub)
- PDF e HTML da mesma pasta: [`assets/docs/GDD/`](assets/docs/GDD/)

Os demais documentos do projeto estão em [`assets/docs/`](assets/docs/), cada um em **PDF** e em **Markdown atualizado** (mesmo nome): Apresentação, Documento Complementar (comparação protótipo × GDD), Guia de instalação e Relatório do PAC IV.

## 9. Testes automáticos

Opcional, para quem quiser verificar o projeto (substitua pelo caminho do seu Godot em modo console):

```
Godot_v4.6.3-stable_win64_console.exe --headless --path . --import
Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd    # regras e gerador (497 verificações)
Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/integration_test.tscn    # fases completas (295 verificações)
```

## 10. Estrutura do projeto

```
Reinos-da-Area/
├── project.godot
├── scenes/Main.tscn              ← única cena (tudo é montado por código)
├── scripts/
│   ├── Main.gd                   ← roteador de telas, janela e cursores
│   ├── GameManager.gd            ← controlador de uma fase (rodadas, tempo, habilidades, fim de fase)
│   ├── TerritoryGenerator.gd     ← 6 estratégias de forma, meios-blocos e áreas vazadas
│   ├── TerritoryRenderer.gd      ← desenho dos territórios, quadriculado e animações
│   ├── AudioManager.gd           ← autoload: música e efeitos
│   ├── autoload/GameState.gd     ← autoload: progresso salvo
│   ├── data/                     ← CampaignData (20 fases), ArchetypeData
│   ├── systems/                  ← CombatResolver, AccuracyTracker, UnitFormatter
│   ├── ui/                       ← UiKit, MedievalTheme, OrnateStyleBox, ScreenTransition
│   │   └── widgets/              ← barra de Domínio, rodadas, relógio, moedas de RE, pausa, opções...
│   └── screens/                  ← TitleScreen, MainMenu, ArchetypeSelect, CampaignMap, BattleScreen,
│                                    PhaseEndPanel, CartographerPanel, TutorialOverlay
├── shaders/                      ← pergaminho por cenário, vinheta, brilho dourado
├── tests/                        ← testes automáticos e captura de telas
└── assets/                       ← audios, cursor, fonts, icons, ui, docs
```
