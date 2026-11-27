# Roteiro do vídeo de apresentação — Reinos da Área

Vídeo de tela no estilo live gravada, com **cerca de 12 minutos** (o mínimo é 10). As falas são um guia: digam com as próprias palavras, sem ler.

- **Na tela:** o que deve aparecer.
- **Fala:** o que comentar.
- **[CORTE: vídeo antigo]:** inserir um trecho da gravação da versão anterior, para o antes e depois.

---

## Antes de gravar (checklist)

1. **Backup do progresso.** Copie `%APPDATA%\Godot\app_userdata\Reinos da Área\reinos_save.cfg` para outro lugar. O vídeo precisa de dois estados de jogo:
   - **Jogo zerado**, para mostrar a primeira vez (prólogo, escolha de conselheiro, tutorial). Use **Opções → Reiniciar progresso**.
   - **Jogo avançado**, com a Fase 9 liberada (Serra, exige 16 estrelas), para o desafio representativo e o mapa. Jogue antes ou use o save do backup. Depois, devolva o arquivo copiado.
2. **Volume.** Em **Opções**, deixe a música em cerca de 30% e os efeitos em 50%. Grave 20 segundos de teste e confira se a voz fica bem acima da música.
3. **Gravação.** OBS Studio (gratuito) ou a Barra de Jogo do Windows (**Win + Alt + R**). Grave em 1920×1080, com o microfone em uma faixa separada se der.
4. **Vídeo antigo.** Separe os trechos da versão anterior que mostram: o relógio de 60 s, o resultado da rodada escrito sobre o campo, o fim de fase com 1 medalha mesmo acertando muito e a falta de história e de guia.
5. Feche notificações (Modo Foco do Windows) e o overlay da NVIDIA (**Alt + Z**).

---

## Bloco 1 — Abertura e identificação (0:00 – 0:50)

**Na tela:** tela de título, com a música tocando. Não aperte nenhuma tecla ainda.

**Fala:**
> "Olá! Eu sou o Enzo Camelo Vieira e o jogo que eu desenvolvi é o **Reinos da Área**. Este é o vídeo da versão final do jogo. Hoje vou jogar ao vivo, mostrar como alguém que nunca jogou aprende a jogar e, principalmente, o que mudou depois das duas devolutivas que recebi: a ficha técnica da outra equipe no Dia do Analista e o feedback da professora."

> "O Reinos da Área é um jogo de estratégia feito na Godot 4 em que você aprende **cálculo de área** sem perceber que está estudando. O lema é este aqui: *conquiste territórios, calcule para vencer*."

---

## Bloco 2 — Proposta, história e objetivo (0:50 – 2:30)

**Na tela:** aperte uma tecla → menu principal → **Jogar campanha** (com o jogo zerado). O **prólogo** abre no mapa: leia as 4 páginas com calma.

**Fala (enquanto as páginas passam):**
> "A proposta: unir um jogo de estratégia com o conteúdo de área de figuras planas do ensino fundamental e médio. A gente queria que a matemática fosse a própria arma do jogador, e não uma prova disfarçada."

> "A história se passa no continente de **Geometria**, onde as disputas eram resolvidas pelas **Leis da Forma**: quem tem mais área vence. Até que surge o **Império das Formas Irregulares**, que deforma as próprias fronteiras para ninguém conseguir calcular, e engole os reinos que erram a conta."

> "Você é o **Arquiteto-Rei**, o governante de um reino pequeno. Você não tem o maior exército, mas tem a única arma que importa: **saber medir**. Ao seu lado está a **Cartógrafa**, a mentora que ensina e que, ao longo da campanha, vai deixando você caminhar sozinho."

> "O objetivo é atravessar **cinco regiões**, com **20 fases**, até o trono do Império. Em cada fase são **10 rodadas**, e para vencer é preciso terminar com pelo menos **60% de Domínio** do mapa."

**Destaque:** essa história inteira é nova. Na versão anterior, ela só existia no GDD.

---

## Bloco 3 — Primeiros passos: como quem joga pela primeira vez aprende (2:30 – 4:30)

**Na tela:**
1. Escolha de **conselheiro**: passe pelos três cards e escolha um (sugestão: **Estrategista**, para mostrar a habilidade de revelar o quadriculado).
2. **Mapa de campanha**: mostre a trilha com as fases, o cadeado nas fases seguintes e a contagem de estrelas.
3. Abra o **Capítulo I** (Planícies) e a **lição do retângulo**.
4. Clique na **Fase 1** e mostre o **briefing**, com o rival e a provocação.
5. Volte ao menu rapidamente e abra **Como jogar**: passe pelas 6 abas.

**Fala:**
> "Primeiro escolhemos um conselheiro. São três: o **Estrategista**, que ganha mais quadriculado de referência ao redor do inimigo; o **Engenheiro**, que perde menos quando erra um ataque; e o **Guerreiro**, que fica mais forte a cada vitória seguida. Cada um também tem uma habilidade ativa, que gasta Recursos Estratégicos."

> "Este é o mapa. As fases seguem a trilha desenhada, e cada região tem o seu terreno. Para entrar num terreno novo, além de vencer a fase anterior, é preciso juntar estrelas: 8, 16, 24 e 32."

> "Cada região começa com um capítulo da história e uma **lição de cálculo** desenhada. Aqui, nas Planícies, a lição é o retângulo: não precisa contar bloco por bloco, basta contar a base, contar a altura e multiplicar."

> "Cada fase tem um **rival** com uma provocação. Esse aqui diz que o reino dele é um quadrado perfeito... e que o nosso é só um rascunho."

> "E se o jogador esquecer alguma regra, existe o **Como jogar**, que abre no menu, no mapa, na pausa ou com a tecla **H** no meio da batalha, com o relógio parado. São seis abas: objetivo, a rodada, como calcular cada forma, terreno e habilidades, medalhas e controles."

---

## Bloco 4 — Fase 1 com tutorial: as mecânicas principais (4:30 – 7:00)

**Na tela:** inicie a **Fase 1**. A Cartógrafa conduz o **tutorial de 6 passos**: avance devagar, lendo cada balão. Depois jogue 3 ou 4 rodadas, falando a conta em voz alta.

**Fala (no tutorial):**
> "Na primeira fase, a Cartógrafa ensina o jogo em seis passos curtos, apontando para cada parte da tela."

> "À esquerda está o **nosso reino**, com o quadriculado: dá para calcular a área exata. À direita está o **reino inimigo**, liso por dentro. É aqui que está o desafio: a gente precisa **estimar** a área dele usando a malha em volta como régua."

**Fala (jogando, rodada a rodada):**
> "Vamos lá. O meu reino tem 6 de base por 4 de altura: 24 quadrados. O inimigo... a base vai daqui até aqui, uns 5, e a altura uns 4: 20. O meu é maior, então eu **ataco**, com a tecla **A**."

> "Existem três decisões. **Atacar** quando a minha força é maior. **Defender** quando a do inimigo é maior. E **Recuar** na dúvida: custa só 3% de Domínio e não perde território. Errar custa caro: um ataque errado tira 20% da minha área."

> "Repare no **relógio**: aqui são 30 segundos. Se ele zera, o jogo recua sozinho."

> "Agora o **relatório da rodada**. Ele mostra os dois reinos lado a lado, **com o cálculo de cada área**, a força de cada lado com o terreno e qual era a decisão certa. Então, mesmo quando eu erro, eu aprendo por que errei."

> "Acima dos botões fica a linha da **meta**: ela diz quantas vitórias ainda faltam para a medalha de Bronze. E na barra de Domínio, lá em cima, estão as marcas de 60% e de 80%."

**Dica:** deixe pelo menos uma rodada com o relatório aberto por uns 5 segundos, para dar tempo de ler.

---

## Bloco 5 — Desafio representativo: Serra das Pedras Vivas, Fase 9 (7:00 – 9:30)

**Na tela:** carregue o **save avançado**. Mostre no mapa a trava de estrelas de algum terreno ainda bloqueado. Entre na **Fase 9** (lição do trapézio, se ainda não vista). Jogue a fase inteira ou até a vitória ficar garantida, usando a habilidade (**E**) uma vez.

**Fala:**
> "Agora um desafio representativo do meio da campanha: a **Serra das Pedras Vivas**. Aqui três coisas mudaram. As formas viraram **trapézios e figuras compostas**. A malha de referência em volta do inimigo **sumiu** (com o Estrategista ainda sobram 2 células, por causa da passiva Olho de Águia). E o **terreno** pesa: atacar vale só ×0,85, e defender vale ×1,25."

> "Isso quer dizer que não basta ver qual reino é maior: preciso comparar as **forças**. Se o meu reino tem 31 blocos e o inimigo 27, parece que eu ganho atacando. Só que 31 × 0,85 dá uns 26, e 27 × 1,25 dá quase 34. O inimigo é mais forte. O certo é **defender**."

> "Para o trapézio, a fórmula é base maior mais base menor, vezes a altura, dividido por 2. O relatório mostra a conta passo a passo, com os números da própria rodada."

> (ao usar **E**) "Agora vou usar a habilidade do meu conselheiro. A **Análise de Campo**, do Estrategista, mostra o quadriculado do inimigo por 5 segundos, mas **não dá o valor da área**: o cálculo continua sendo meu."

> (sobre a dificuldade) "A dificuldade cresce por região: as formas ficam mais complexas, a referência some, o terreno muda a conta e a diferença entre os reinos diminui, de 25 a 35% na primeira fase até só 2 a 5% na última. Na Fase 20, a última, é morte súbita: um único erro e o Império vence."

---

## Bloco 6 — O que mudou com as devolutivas: antes e depois (9:30 – 11:30)

**Na tela:** alterne entre o **[CORTE: vídeo antigo]** e o jogo atual. Uma boa sequência é terminar a fase do Bloco 5 e mostrar a **tela de fim de fase**, com as medalhas.

**Fala, por devolutiva:**

**1. Ficha técnica da outra equipe** (dificuldade avaliada em 3/5)

> "A outra equipe deu nota 3 de 5 para a dificuldade e fez cinco sugestões. Aplicamos todas."

- **Popup pós-rodada com as áreas lado a lado e o cálculo.**
  [CORTE: vídeo antigo, com o resultado escrito sobre o campo]
  > "Antes, o resultado da rodada aparecia espalhado em cima do campo de batalha. Agora existe o relatório que vocês já viram: os dois reinos lado a lado, com a conta de cada um. Isso também resolveu outra sugestão, a de deixar a vitória da rodada menos poluída. O campo fica limpo, e com a tecla **V** dá para esconder o relatório e olhar as formas."
- **Tempo menor, para gerar tensão.**
  [CORTE: vídeo antigo, com o relógio de 60 s]
  > "Antes eram 60 segundos por rodada; sobrava tempo para contar quadrado por quadrado. Agora são 30 segundos nas Planícies, 35 na Serra e 25 no Abismo. O jogador é empurrado a **estimar** com base vezes altura, que é exatamente a habilidade que o jogo quer treinar. E as esperas entre as rodadas ficaram mais curtas, então o jogo não tem mais momentos mortos."
- **Calibrar as medalhas: 90% de acerto dava só 1 medalha.**
  [CORTE: vídeo antigo, com o fim de fase com 1 estrela]
  > "Esse era o problema mais grave. A Prata exigia 70% de Domínio até a rodada 6, só que 6 vitórias somam no máximo 60%. Ou seja, era impossível. Agora a medalha depende só do Domínio final: **Bronze com 60%, Prata com 80% e Ouro com 100%**. E quem não chega a 60% perde a fase e tenta de novo."
- **Aumentar a recompensa da medalha.**
  > "As medalhas agora dão 150, 350 e 600 de XP, e cada medalha nova rende 1 Recurso Estratégico para usar nas habilidades. E as estrelas passaram a ter função: elas destravam os terrenos novos no mapa."

**2. Feedback da professora**

- **Tutorial e guia dentro do jogo.**
  > "O tutorial foi reescrito em seis passos, apontando para cada parte da tela e ensinando a conta, não só os botões. E foi criado o guia **Como jogar**, que pode ser aberto a qualquer momento sem perder a rodada."
- **Jornada intuitiva.**
  > "Nos colocamos no lugar de quem joga. O jogador sempre sabe quanto falta: tem a linha de meta, as marcas na barra, o aviso de estrelas no mapa e a trilha mostrando o caminho."
- **História e envolvimento.**
  > "O jogo ganhou uma história contada dentro dele: prólogo, um capítulo por região com uma lição, um rival com provocação em cada uma das 20 fases e um desfecho no fim de cada região. A Cartógrafa começa guiando e vai se afastando até deixar só uma carta no final. É a história do próprio aprendizado: no começo você precisa dela, no final já calcula sozinho."

---

## Bloco 7 — Fechamento (11:30 – 12:30)

**Na tela:** volte ao mapa e mostre as regiões. Depois, rapidamente, a página do repositório no GitHub (README e GDD). Termine na tela de título.

**Fala:**
> "Resumindo: o Reinos da Área virou um jogo em que o jogador entende o que fazer desde o primeiro minuto, tem um motivo para continuar e aprende com cada erro, porque vê a conta logo depois."

> "Por trás disso tem engenharia: o combate é determinístico, sem sorte nenhuma. Sempre existe exatamente uma decisão certa, e isso é conferido por mais de 800 verificações automáticas, incluindo testes que jogam as 20 fases sozinhos."

> "Tudo está no nosso GitHub: o código-fonte, o GDD atualizado com as mecânicas desta versão e o executável para baixar e jogar no Windows sem instalar nada. Os links estão na entrega."

> "Obrigado por assistir. Agora é com vocês: conquistem territórios e calculem para vencer!"

---

## Depois de gravar

- Assista ao vídeo inteiro com fone e confira se a voz está clara em todos os blocos e a música não cobre a fala.
- Confira se a duração passou de 10 minutos.
- Restaure o `reinos_save.cfg` do backup.
- Suba o vídeo (YouTube "não listado" ou Google Drive com "qualquer pessoa com o link") e teste o link numa janela anônima.
