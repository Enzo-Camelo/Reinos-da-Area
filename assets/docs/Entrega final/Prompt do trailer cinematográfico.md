# Prompt — Trailer cinematográfico do Reinos da Área (40 s)

> Copie tudo abaixo da linha e cole numa sessão do Claude Code aberta na pasta do projeto (`C:\Desenvolvimento\ReinosDaArea`), com o plugin **HyperFrames** instalado.

---

Você vai criar o **trailer cinematográfico narrativo** do jogo **Reinos da Área**, um jogo de estratégia medieval feito em Godot 4 em que o jogador vence batalhas calculando a área dos reinos. O trailer é uma entrega da faculdade: ele precisa **contar a história do jogo** (o universo, os personagens e o conflito que dá início à jornada) com motion graphics e prints reais do jogo. A trilha e os sons do próprio jogo criam o clima.

Antes de começar, carregue a skill `hyperframes:hyperframes` e siga o contrato de render e o fluxo de trabalho dela. Use também `hyperframes:hyperframes-registry` antes de construir à mão efeitos como granulado de filme, partículas, transições ou tipografia cinética, e `hyperframes:media-use` para mixar o áudio.

## Especificações

| Item | Valor |
|---|---|
| Duração | **exatamente 40 s** |
| Formato | 1920×1080, 30 fps, MP4 (H.264 + AAC) |
| Idioma | Português do Brasil, com acentuação correta |
| Pasta do projeto do trailer | `trailer/` na raiz do repositório. **Antes de tudo, crie `trailer/.gdignore` (arquivo vazio)**, senão o Godot tenta importar os arquivos do vídeo como recursos do jogo |
| Saída final | `trailer/render/Reinos da Área - Trailer.mp4` |
| Não altere | nada fora de `trailer/` (código do jogo, `assets/`, docs) |

## O universo (use estes nomes, sem inventar outros)

- **Geometria:** o continente. Por séculos, as disputas foram resolvidas pelas **Leis da Forma**: compara-se o território, e quem tem mais área vence. Sem sangue.
- **Império das Formas Irregulares:** o vilão. Deforma as próprias fronteiras para que ninguém consiga calculá-las, e engole, um a um, os reinos que erram a conta.
- **Arquiteto-Rei:** o protagonista, o jogador. Herda uma coroa pequena; não tem o maior exército, mas tem a única arma que importa: **saber medir**.
- **A Cartógrafa:** a mentora. Ensina o Arquiteto e, aos poucos, o deixa caminhar sozinho; no fim, resta só uma carta dela.
- **As cinco regiões:** Planícies de Aldrath, Vales de Kheldorn, Serra das Pedras Vivas, Arquipélago do Oblívio e Abismo Irregular (o trono do Império).
- **Lema:** *Conquiste territórios. Calcule para vencer.*

A fonte da história é `scripts/data/StoryData.gd` (prólogo, capítulos e rivais). Leia esse arquivo antes de escrever os textos.

## Identidade visual

- **Clima:** manuscrito medieval à luz de vela. Pergaminho envelhecido, tinta, ouro e sombras profundas. Nada de neon nem de estética "tech".
- **Fontes** (estão no repositório, use os arquivos locais):
  - `assets/fonts/Cinzel.ttf`: títulos e nomes, em caixa alta.
  - `assets/fonts/Baskerville.ttf`: frases narrativas.
  - `assets/fonts/SourceSans.ttf`: só textos pequenos (créditos).
- **Cores** (as mesmas do jogo, em `scripts/ui/UiKit.gd`):

| Uso | Cor |
|---|---|
| Fundo escuro | `#120E0A` |
| Painel | `#1C160E` |
| Ouro (bordas) | `#947026` |
| Ouro (texto) | `#D4B45A` |
| Ouro claro (destaques) | `#F0D278` |
| Texto claro | `#EEE8DA` |
| Pergaminho | `#BBA375` |
| Reino do jogador (azul) | `#3C6EBE` |
| Reino inimigo (vermelho) | `#A01E1E` |
| Acerto (verde) | `#50B478` |

- **Movimento:** lento e pesado no começo (Ken Burns, fades de tinta), acelerando na montagem e parando seco no logo. Vinheta escura nas bordas e granulado leve durante todo o vídeo.
- **Formas geométricas como motion graphics:** quadriculados que se desenham, reinos (polígonos azuis e vermelhos) que crescem e encolhem, fórmulas que se escrevem com traço de pena. É o diferencial do jogo: a matemática aparece como magia.

## Arquivos disponíveis

**Arte** (PNG com transparência, exceto quando indicado):

| Arquivo | Conteúdo |
|---|---|
| `assets/ui/mapa.png` | Mapa ilustrado do continente, 2816×1536 |
| `assets/ui/arquiteto-rei.png` | Retrato do Arquiteto-Rei, 941×1672 |
| `assets/ui/cartografa.png` | Retrato da Cartógrafa, 941×1672 |
| `assets/ui/capa.png` | Capa ilustrada, 687×758 |
| `assets/icons/brasao.png` | Brasão azul com leão, 1429×1842 (logo) |
| `assets/ui/coroa.png` | Coroa |
| `assets/ui/rosa-dos-ventos.png` | Rosa dos ventos |
| `assets/ui/bussola.png` | Bússola |
| `assets/ui/trilha.png` | Ornamento de trilha |
| `assets/icons/swords.png` | Ícone de Atacar |
| `assets/icons/shield.png` | Ícone de Defender |
| `assets/icons/boot.png` | Ícone de Recuar |
| `assets/icons/vs.png` | Selo de "versus" |

**Prints do jogo** (JPG 1600×900) em `assets/docs/GDD/assets/telas/`:

| Arquivo | Conteúdo |
|---|---|
| `titulo.jpg` | Tela de título |
| `mapa.jpg` | Mapa de campanha com a trilha |
| `briefing.jpg` | Briefing de fase com o rival |
| `licao.jpg` | Lição de cálculo da Cartógrafa |
| `batalha.jpg` | Batalha: reino azul com quadriculado à esquerda, inimigo vermelho liso à direita |
| `batalha_fase15.jpg` | Batalha no Arquipélago |
| `relatorio.jpg` | Relatório da rodada com o trapézio e as fórmulas |
| `fim_fase.jpg` | Fim de fase com medalhas |
| `conselheiros.jpg` | Escolha de conselheiro |
| `tutorial.jpg` | Tutorial |
| `guia.jpg` | Guia "Como jogar" |

Se quiser prints em 1920×1080 ou de outros momentos, o repositório tem `tests/screenshot_test.gd`. **Faça backup de `%APPDATA%\Godot\app_userdata\Reinos da Área\reinos_save.cfg` antes** e restaure depois. O Godot está em `C:\Users\Enzo\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe` (é uma pasta com o executável dentro). Uso:

```
Godot_v4.6.3-stable_win64.exe --path . --windowed --resolution 1920x1080 res://tests/screenshot_test.tscn -- <pasta_de_saida>
```

**Áudio** em `assets/audios/`:

| Arquivo | Uso no trailer |
|---|---|
| `background.mp3` | Trilha principal |
| `vento.mp3` | Ambiente da abertura |
| `pagina.wav` | Virar de página nas transições de texto |
| `atacar.mp3`, `defender.mp3`, `recuar.mp3` | Impactos na montagem |
| `inicio_da_rodada.mp3` | Começo da montagem |
| `sino_preciso.wav` | Acerto, quando a fórmula fecha |
| `tempo_esgotando.mp3` | Tensão na escalada |
| `derrota.mp3` | Chegada do Império |
| `brilho_da_vitoria.mp3` | Revelação do logo |

## Roteiro cena a cena

Todos os textos entram com fade de tinta ou palavra por palavra, e ficam na tela tempo suficiente para serem lidos: cerca de 3 palavras por segundo. As frases narrativas usam Baskerville em `#EEE8DA` com sombra escura; os títulos, Cinzel em ouro.

### Cena 1 — Lenda (0:00 – 0:06)

- **Imagem:** tela preta. Um pergaminho `#BBA375` ilumina-se do centro, como vela acesa. O `mapa.png` surge por baixo da tinta, em Ken Burns lento (zoom de 110% para 100%) com vinheta forte.
- **Texto:**
  - 0:00,8: "Em **Geometria**, nenhuma guerra era decidida pela espada."
  - 0:03,5: "As **Leis da Forma** diziam: quem tem mais área, vence."
- **Motion:** sobre o mapa, um quadriculado dourado fino se desenha linha a linha (traço de pena) e se apaga.
- **Som:** `vento.mp3` em fade-in; a trilha `background.mp3` entra baixa (−18 dB) e sobe até 0:06. `pagina.wav` na troca de frase.

### Cena 2 — A ameaça (0:06 – 0:12)

- **Imagem:** sobre o mapa escurecido, vários pequenos reinos azuis em blocos quadriculados, posicionados nas regiões. Uma mancha vermelha `#A01E1E` de **bordas irregulares e tremidas** nasce no canto inferior direito (o Abismo) e avança, deformando-se e engolindo os blocos azuis um a um. Cada bloco engolido racha e some.
- **Texto:**
  - 0:06,5, em Cinzel vermelho, grande: "**O IMPÉRIO DAS FORMAS IRREGULARES**"
  - 0:09,5: "Fronteiras que ninguém consegue calcular."
- **Som:** `derrota.mp3` no surgimento do Império, com a trilha abafada (filtro passa-baixa) até o fim da cena.

### Cena 3 — O herói e a mentora (0:12 – 0:19)

- **Imagem:** fundo `#120E0A`. O `arquiteto-rei.png` entra pela esquerda, em contraluz dourado; o nome **ARQUITETO-REI** aparece em Cinzel abaixo. Aos 0:15,5, a `cartografa.png` entra pela direita, com o nome **A CARTÓGRAFA**. A `coroa.png` brilha discretamente acima do Arquiteto.
- **Texto:**
  - 0:13: "Seu reino é pequeno. Seu exército, menor ainda."
  - 0:16,5: "Mas você tem a única arma que importa:"
  - 0:18: "**SABER MEDIR.**" (ouro claro `#F0D278`, impacto com leve tremor)
- **Som:** a trilha volta ao volume normal; um golpe grave no "SABER MEDIR".

### Cena 4 — A matemática como arma (0:19 – 0:30)

Montagem rápida, com cortes no ritmo da música. Cada print entra com zoom de câmera (de 100% para 106%) e moldura dourada fina.

| Tempo | Plano | Detalhe |
|---|---|---|
| 0:19,0 – 0:21,5 | `batalha.jpg` | Zoom para o centro. Sobre o reino vermelho liso, um **quadriculado se desenha em motion** e a conta aparece com traço de pena: "base × altura". `inicio_da_rodada.mp3` |
| 0:21,5 – 0:24,0 | Motion graphic puro | Um trapézio vermelho sobre pergaminho, e a fórmula se escreve: **(B + b) × h ÷ 2 = 27**. Quando o resultado aparece, `sino_preciso.wav` e um brilho verde `#50B478` |
| 0:24,0 – 0:25,5 | Três palavras em Cinzel, uma por vez, com os ícones | **ATACAR** (`swords.png`, `atacar.mp3`) · **DEFENDER** (`shield.png`, `defender.mp3`) · **RECUAR** (`boot.png`, `recuar.mp3`), meio segundo cada |
| 0:25,5 – 0:27,5 | `relatorio.jpg` | Pan lateral do reino azul para o vermelho; o texto "O CERTO ERA DEFENDER" ganha um brilho |
| 0:27,5 – 0:30,0 | `briefing.jpg` | Sobre a imagem, a provocação do último rival em Baskerville itálico: *"Um único erro, Arquiteto, e seu reino será nosso."* |

### Cena 5 — A jornada (0:30 – 0:35)

- **Imagem:** volta ao `mapa.jpg` (ou ao `mapa.png`). Uma linha tracejada dourada percorre a trilha das Planícies até o Abismo. Os nomes das cinco regiões acendem em sequência ao longo do caminho, cerca de 0,8 s cada, em Cinzel pequeno.
- **Motion:** no canto, um relógio circular conta **30 → 25** e pulsa em vermelho no final.
- **Texto:** 0:33,5: "Cinco regiões. Vinte batalhas. Um Império."
- **Som:** `tempo_esgotando.mp3` acompanhando o relógio, e a trilha no auge.

### Cena 6 — Título (0:35 – 0:40)

- **Imagem:** corte seco para preto, um segundo de silêncio (só um eco do vento). O `brasao.png` surge com brilho dourado varrendo da esquerda para a direita. Abaixo, **REINOS DA ÁREA** em Cinzel `#F0D278`, grande, com contorno escuro. Embaixo, em Baskerville: "*Conquiste territórios. Calcule para vencer.*"
- **Rodapé** (pequeno, SourceSans, `#A0947A`, a partir de 0:37,5): "Enzo Camelo Vieira" e, na linha de baixo, "Disponível para Windows".
- **Som:** `brilho_da_vitoria.mp3` na entrada do brasão. A trilha termina com fade-out até 0:40.

## Áudio

- A trilha (`background.mp3`) é a base do vídeo inteiro, cortada e com fades para durar exatamente 40 s.
- Os efeitos ficam abaixo da trilha, exceto nos golpes (0:18, 0:24–0:25,5 e 0:35), em que aparecem bem.
- Não há narração falada obrigatória: a história é contada pelo texto na tela. **Se** a skill `media-use` permitir gerar uma voz em português de qualidade (grave e calma, de contador de histórias), pode narrar exatamente os textos das cenas 1, 3 e 5. Faça uma versão sem voz primeiro.
- Normalize o resultado final em torno de −14 LUFS, sem distorção.

## Como trabalhar

1. Leia `scripts/data/StoryData.gd` e confira os arquivos listados acima. Abra os prints e as artes para ver o que de fato contêm.
2. Monte o projeto em `trailer/` (lembre do `.gdignore`), cena por cena, seguindo o roteiro.
3. Antes do render final, gere **quadros de verificação** em 0:03, 0:09, 0:15, 0:18, 0:22, 0:25, 0:29, 0:33 e 0:38. Olhe cada um e confira: o texto está legível e com acentos corretos, nada está cortado nas bordas e a imagem não está pixelada (os prints de 1600×900 aceitam zoom de até cerca de 110%).
4. Renderize, assista ao MP4 inteiro e confira a duração (40 s), a sincronia dos sons com os cortes e se o áudio não satura.
5. Ao terminar, informe o caminho do MP4, liste o que precisou adaptar no roteiro e por quê, e diga se gerou voz ou não.

OBSERVACOES IMPORTANTES:
- O trailer é **uma entrega da faculdade**: não invente nada que não esteja no roteiro, nem adicione efeitos ou falas extras.
- Use sons no video apenas do jogo, não adicione músicas ou efeitos de terceiros. todos os arquivos de audio estao na pasta `assets/audios/` do repositório.
- Nao utilize glows, nem neons, nem efeitos de luzes que não estejam no roteiro. O clima é medieval, pergaminho e tinta.
- Utilize motion graphics a vontade, mas apenas os que estão descritos no roteiro. Não invente outros.
- Nao precisa de narracao no video