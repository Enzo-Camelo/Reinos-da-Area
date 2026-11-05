# Apresentação do Protótipo: Reinos da Área

**Acadêmicos:** Enzo Camelo Vieira

> **Versão atualizada para o protótipo v0.2 (N2).** A comparação com o GDD abaixo registra o que foi fiel, o que divergiu e por quê. O GDD correspondente é a **v5**.

---

## 1. Comparação entre Protótipo e GDD

O protótipo v0.1 focou em validar o núcleo do *Game Design Document*: o **Core Game Loop** e a premissa do **Aprendizado Invisível**. A v0.2 expande esse núcleo para a campanha completa. Durante a transição do papel para a engine (Godot), foi possível fidelizar os seguintes aspectos:

- **Mecânica central (matemática invisível e risco real):** o sistema de combate assimétrico está implementado. O jogador tem o grid ativo para calcular a própria área, mas precisa estimar visualmente a área do reino inimigo (gerada proceduralmente) para decidir entre Atacar, Defender ou Recuar. Na v0.2 a comparação passa a considerar os **modificadores de terreno** e as habilidades de arquétipo, mantendo o resultado **determinístico**.
- **UI e experiência do usuário:** a interface foi traduzida do conceito visual (wireframes) para a engine, mantendo a divisão entre o "HUD Topo" (informações globais e de domínio) e o "Painel Inferior" (batalha, modificadores e arquétipo). Na v0.2 foram acrescentados o menu principal, a seleção de arquétipo, o mapa de campanha, o painel de fim de fase e o tutorial — os três wireframes do GDD (§12) agora existem.
- **Geração procedural:** o algoritmo de expansão celular (BFS orgânico) deu origem a um gerador com **seis estratégias** (retângulo, diagonal, trapézio, composta, complexa e vazada), com meios-blocos e áreas vazadas, cobrindo a progressão "retangular → irregular" do GDD e validando o pilar de *Profundidade Emergente*.

### 1.1 Mapa de fidelidade ao GDD

| Tema do GDD | Situação no protótipo v0.2 |
|---|---|
| Combate determinístico (Pilar 02) | ✅ Sem RNG; comparação única em que Atacar e Defender são complementares; margem mínima de 1% evita empates. |
| Grid seletivo e revelação pós-combate | ✅ Com anel de referência por cenário e revelação "desenhada à mão". |
| 20 fases em 5 cenários, 10 rodadas | ✅ Tabela de campanha completa em `CampaignData.gd`. |
| Três arquétipos | ✅ Conforme o Relatório PAC IV (ver divergência abaixo). |
| Modificadores de terreno | ✅ Plano, Vale, Serra, Costeiro e relevo misto no Abismo. |
| Índice de Precisão e estrelas | ✅ Derivado das decisões (ver divergência abaixo). |
| Cartógrafa (FSM por fase) | ✅ Ativa 1–6, silenciosa 7–9, ausente 10+. |
| Unidades de medida | ✅ m², km² e hectares com equivalência visível. |
| FSM dos reinos inimigos (4 estados visuais) | ⏳ Futuro. |
| Evolução visual do castelo | ⏳ Futuro. |
| Trilha por cenário e ambientação sonora | ⏳ Futuro (trilha única hoje). |

### 1.2 Divergências e justificativas

| Divergência | Justificativa |
|---|---|
| **Arquétipos:** o GDD v4 trazia Fortificações/Espólios, Legião de Cativos/Aço Duplo e Infiltração/Cartografia Roubada; o protótipo usa Consolidação/Muralha, Embalo/Golpe Decisivo e Olho de Águia/Análise de Campo. | O Relatório PAC IV (mais recente) redefiniu as habilidades com custo em Recursos Estratégicos; a equipe decidiu que ele prevalece. O GDD v5 foi atualizado. |
| **Índice de Precisão sem estimativa digitada.** | Pedir um número ao jogador seria uma "tela de exercício", contra o Pilar 06. O IP é derivado da decisão e da margem real entre as áreas. |
| **Fim de fase:** o GDD dizia "70% ao final das 10 rodadas" mas a estrela Prata pedia "≤ 60% das rodadas". | Passou a haver sempre 10 rodadas; a Prata ficou "atingir 70% até a 6ª rodada". |
| **Formas por cenário:** GDD (quinas irregulares → L/T → diagonais → polígonos de 12 lados) × Relatório (meios-blocos → trapézios → complexas → vazadas). | Valeu o Relatório; o GDD v5 foi atualizado. |
| **Recuar:** o protótipo v0.1 descontava 5% da área, contrariando o GDD. | Corrigido: Recuar custa 3% de Domínio e preserva a área. |

Em suma, o protótipo reflete o estado de **MVP ampliado**, no qual a mecânica de estimativa geométrica e a consequência das ações funcionam de forma fluida e determinística (sem fatores de sorte), como proposto na Seção 3 (Pilares de Design) do GDD.

---

## 2. Referências e Fundamentação

O design e as mecânicas do protótipo foram embasados em duas frentes: a lúdica (indústria de games) e a pedagógica (jogos sérios).

**Referências de game design**

- ***Civilization VI*, *Risk* (War) e *Territorial.io*:** inspiraram a sensação de macroestratégia e conquista de mapa.
- ***Slay the Spire* e *Into the Breach*:** fundamentaram a UI limpa e o sistema de "informação perfeita", em que o jogador vê tudo o que o inimigo tem (a forma da área), removendo a aleatoriedade e premiando a leitura tática pura.
- ***Crusader Kings* e *Clash of Clans*:** referências de identidade visual (heráldica e mapas medievais).

**Fundamentação acadêmica**

- **Gee (2003) — *Game-based learning*:** o jogo é projetado em torno de um contexto significativo, em que o ciclo de feedback imediato ensina sem punições textuais.
- **Sweller (1988) — Teoria da Carga Cognitiva:** a ausência do grid no inimigo e a pressão de tempo (timer de rodada) gerenciam a carga cognitiva, fazendo o jogador usar a abstração espacial natural para resolver o cálculo da área. Na v0.2, a complexidade só cresce por cenário (formas, grade de referência, tempo), nunca de uma vez.

---

## 3. Assets Visuais

> Todas as imagens utilizadas estão no projeto, em `assets/icons`, `assets/cursor` e (novo) `assets/ui`.

A direção de arte estabelecida no GDD foca em uma estética de **cartografia medieval**:

- **Texturas e cores:** paletas quentes baseadas em antiguidade, ouro e couro. O mapa de batalha usa uma pixel art de grama para indicar o terreno da fase.
- **Tipografia:** **Cinzel** para títulos, **Libre Baskerville** para textos narrativos e **Source Sans 3** para dados técnicos.
- **Cursores personalizados:** a seta clássica foi substituída por cursores temáticos configurados na engine.

### Inventário de assets

| Pasta | Arquivos |
|---|---|
| `assets/icons` | `swords.png`, `shield.png`, `boot.png` (ações), `vs.png`, `brasao.png`, `fundo.jpg` |
| `assets/cursor` | `default.png/.cur`, `pointer.png/.cur` |
| `assets/fonts` | `Cinzel.ttf`, `Baskerville.ttf`, `SourceSans.ttf` |
| `assets/ui` **(novo)** | `capa.png` (menu), `mapa.png` (campanha), `cartografa.png`, `arquiteto-rei.png`, `coroa.png`, `rosa-dos-ventos.png` (transição), `trilha.png`, `bussola.png` |

---

## 4. Design de Áudio (Sound Design)

> Os arquivos de áudio e o gerenciador de som estão em `assets/audios` e `scripts/AudioManager.gd`.

O áudio é uma ferramenta de **feedback tátil e tensão**, não ornamento.

- **Música e ambiente:** trilha orquestrada sutil para a imersão de "um rei planejando a guerra em sua tenda", sem atrapalhar a concentração matemática.
- **UI e ações:** sons de materiais da época — trompetas e violinos nas vitórias e derrotas, arco esticando no hover e flecha ao clicar, espadas e escudos nas decisões de batalha.
- **Tensão e pressão:** o cronômetro usa "batidas de guerra" nos últimos 10 segundos.
- **Feedback de precisão (novo):** ao final de cada rodada, durante a revelação do grid, um **sino cristalino** (IP ≥ 90), **silêncio** (40–89) ou **sino grave** (< 40) — sem texto de punição.
- **Transições (novo):** som de pergaminho ao desdobrar o mapa e virar a página.
- **Infraestrutura:** o padrão Autoload/Singleton (`AudioManager`) agora cria os buses **Music** e **SFX**, com volumes independentes configuráveis em **Opções** e salvos no progresso.

> Os sons novos (`sino_preciso.wav`, `sino_impreciso.wav`, `pagina.wav`) foram **sintetizados por código** como substitutos de desenvolvimento; podem ser trocados por gravações finais mantendo os mesmos nomes de chave em `AudioManager.gd`.

---

### 3.1 Refatoração visual do front-end (v0.2.1)

- **Tema global medieval:** `MedievalTheme` define fontes, botões, painéis, tooltips e sliders; `OrnateStyleBox` desenha por código painéis de couro com borda dourada dupla, chanfros e rebites.
- **Pergaminho procedural (`shaders/parchment.gdshader`):** ruído, manchas, borda queimada e vinheta; o campo de batalha ganha um motivo por cenário (colinas, rochas, ondas, rachaduras). Substitui a grama em pixel art.
- **Tela de título** com brasão, título dourado com brilho, brasas e "Pressione qualquer tecla"; menu com estandarte à esquerda e capa emoldurada à direita.
- **HUD profissional:** barra de Domínio com meta, rodadas em escudos, medalhão de tempo, selos de tecla, moedas de RE e painel de resultado com chips de variação.
- **Mapa de campanha** com selos de cera sobre a ilustração, trilha tracejada e briefing em pergaminho; **fim de fase** como "crônica da batalha" com medalhões e contagem animada.
- **Boas práticas:** pausa com confirmação, navegação por teclado e foco visível, opção "Reduzir movimento", *tooltips* e *juice* (números flutuantes, tremor na derrota).
- `assets/ui/bussola.png` **não é usado**: contém marca d'água de banco de imagens.

## 5. Animações via Código (Procedurais e Tweens)

Nenhuma das animações principais usa *sprite sheets* ou GIFs. Toda a fluidez visual é programada matematicamente com a API de desenho e de interpolação da engine (GDScript).

- **Partículas geométricas:** vitória (estrelas brilhantes e faíscas), derrota (o "X" pulsante) e recuo (linhas de vento) são desenhadas em `_draw()`, calculando eixos X e Y com `sin` e `cos`.
- **Interpolação (Tweens):** a entrada do ícone "VS" no centro da tela e as mudanças de opacidade usam curvas de desaceleração (*ease out cubic*).
- **Novas na v0.2:**
  - **Tinta azul** que se espalha a partir do centro do território conquistado (0,6 s).
  - **Borda dourada pulsante** no inimigo durante a decisão (0,8 s) e **borda vermelha pulsante** na derrota (2 s).
  - **Revelação do grid "desenhada à mão"**, por varredura de colunas (0,4 s).
  - **Entrada do inimigo** por varredura de colunas entre rodadas.
  - **Transição de tela** (pergaminho que se desdobra / vira a página, 0,9 s) e **estrelas** do fim de fase acendendo em sequência (1,5 s).
  - **Vibração** do botão de habilidade sem recursos (0,5 s).
