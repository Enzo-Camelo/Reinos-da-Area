# Reinos da Área

**Feito por:** Enzo Camelo e Vinícius de Castilhos

> Apresentação em formato texto, atualizada para o protótipo **v0.2**. Os slides originais (Canva) têm 11 páginas; aqui cada slide é uma seção. Slides puramente visuais (5 e 9) estão descritos entre colchetes.

---

## Slide 1 — Capa

**Reinos da Área**
Jogo de conquista territorial baseado em cálculo de área.
*Conquiste territórios. Calcule para vencer.*

---

## Slide 2 — Problema

- Estudantes do Ensino Fundamental precisam de uma boa base em **geometria plana** para se aprofundar no Ensino Médio.
- Jogos educativos existentes funcionam como **provas disfarçadas**, o que não engaja.
- Faltava um jogo onde **aprender área fosse uma consequência natural de jogar**.

---

## Slide 3 — Sobre o projeto

| | |
|---|---|
| **Engine e linguagem** | Godot 4 (GDScript) |
| **Ferramentas de apoio** | Google Fonts · GitHub para versionamento · GDD como documentação |
| **Público-alvo** | 12–16 anos · 7º ano do EF ao 2º ano do EM |
| **Plataformas suportadas** | PC (versão Web planejada) |

---

## Slide 4 — Conceito

**Reinos da Área** é um jogo de conquista territorial onde a força de cada ataque é determinada pela **área do reino controlado (azul)**.

O território inimigo aparece inteiramente visível no mapa, porém **o grid não é exibido sobre ele**. O jogador precisa olhar para a forma do reino inimigo, usar o grid em volta e **estimar quantos quadrados existem ali dentro**. Quando o jogador encontra quantos quadrados tem o território inimigo, ele decide a ação: **Atacar, Defender ou Recuar**.

*[Slide 5 — imagem: concept sketch do mapa com território azul (jogador) e vermelho (inimigo).]*

---

## Slide 6 — Mecânicas

1. **Assimetria de informação visual.** Você vê seu território com grid completo. O inimigo aparece sem grid. A dificuldade nasce dessa diferença, não de regras complexas.
2. **Sistema de combate determinístico.** Sem dados, sem sorte. O resultado depende 100% da comparação de áreas. Atacar com área maior vence. Errar custa território real. *(v0.2: a comparação considera os modificadores de terreno e das habilidades.)*
3. **Progressão de formas geométricas.**
   - Cenário 1: retângulos simples
   - Cenário 2: meios-blocos e arestas diagonais
   - Cenário 3: trapézios e formas compostas
   - Cenário 4: figuras complexas e preenchidas
   - Cenário 5: malhas vazadas (subtração de áreas)
4. **Arquétipos de jogo.** Três estilos que mudam a estratégia (cada um com uma passiva e uma ativa que gasta Recursos Estratégicos):
   - **Estrategista:** revela informações do inimigo (Olho de Águia · Análise de Campo)
   - **Engenheiro:** reduz perdas e acumula bônus defensivo (Consolidação · Muralha de Emergência)
   - **Guerreiro:** cresce em sequências de vitórias consecutivas (Embalo de Combate · Golpe Decisivo)

---

## Slide 7 — Identidade visual

Referências visuais: ***Into the Breach*** · ***Crusader Kings*** · ***Clash of Clans***.

Estética de **cartografia medieval**: ouro, pergaminho e couro; tipografia Cinzel (títulos), Libre Baskerville (textos) e Source Sans 3 (HUD); cursores temáticos; animações procedurais (sem sprites).

---

## Slide 8 — Cenário atual e futuro

### O que está funcionando hoje (v0.2)

- ✅ Geração de territórios (seis estratégias: retângulo, diagonal, trapézio, composta, complexa e vazada)
- ✅ Sistema de combate completo, com resultado baseado em comparação e **modificadores de terreno**
- ✅ Grid seletivo com revelação pós-combate e grade de referência por cenário
- ✅ HUD medieval com barra de domínio, bolinhas de rodada, painel de ações e medidor de Recursos Estratégicos
- ✅ Sistema de pontuação com sequência de vitórias
- ✅ Som ambiente e de interações (com sinos de precisão)
- ✅ **Tela inicial** e menu (arquétipo, opções de áudio, transição de pergaminho)
- ✅ **Tutorial** guiado pela Cartógrafa
- ✅ **Sistema de arquétipos** (3 perfis, passivas e ativas)
- ✅ **Mapa de fases** (20 fases em 5 cenários, com estrelas e desbloqueio)
- ✅ **Progressão de dificuldade** (diferença de área e tempo por cenário)
- ✅ **Formas variadas** (meios-blocos, diagonais, trapézios, compostas, vazadas)
- ✅ **Conversão de medidas** (m² → km² → hectares)
- ✅ **Modificadores de terreno** (Plano, Vale, Serra, Costeiro, misto)
- ✅ **Painel de fim de fase** com Índice de Precisão e insígnias bronze/prata/ouro

### O que ainda falta (futuro)

- ⚠️ Calibração fina da curva de dificuldade com playtests
- ⏳ Evolução visual do castelo e estados visuais dos reinos inimigos
- ⏳ Trilha por cenário, ambientação sonora e voz da Cartógrafa
- ⏳ Versão Web

*[Slide 9 — imagem: telas do jogo.]*

---

## Slide 10 — Gameplay

*[Demonstração do jogo: menu → escolha de conselheiro → mapa de campanha → rodada de combate (estimar, decidir, revelar) → painel de fim de fase.]*

**Roteiro de uma rodada:** observar o mapa → estimar a área inimiga → escolher **A**tacar, **D**efender ou **R**ecuar (opcionalmente **E** para a habilidade) → ver o resultado e o cálculo → grid do inimigo revelado → próxima rodada.

---

## Slide 11 — Fim

**Fim**

Obrigado!
