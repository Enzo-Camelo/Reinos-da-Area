# Guia de instalação — Reinos da Área

> Atualizado para a **v0.2, entrega final** (Godot 4.6.x). Feito por: Enzo Camelo Vieira.

> **Só quer jogar?** Não precisa do Godot. Baixe o executável pronto em <https://github.com/Enzo-Camelo/Reinos-da-Area/releases/latest/download/ReinosDaArea-Windows.zip>, extraia o ZIP e dê dois cliques em `ReinosDaArea.exe` (detalhes na seção 7). Os passos abaixo são para abrir o **código-fonte** no editor.

---

## 1) Baixe o Godot 4.6.3 (ou superior)

Use a página oficial de download do Godot: <https://godotengine.org/download/windows/>

Na página, clique em **"Godot Engine"** e o download do instalador iniciará.

> **Recomendação:** o projeto está configurado para o Godot **4.6** (`config/features` do `project.godot`). A versão 4.6.3 é compatível com o padrão descrito no `README.md`. Versões anteriores à 4.6 podem abrir o projeto, mas não são testadas.

---

## 2) Instale o Godot

### Opção A — instalar com executável

1. Depois de baixar o arquivo `Godot_v4.6.3-stable_win64.exe` (ou nome parecido), clique duas vezes nele.
2. Siga o assistente:
   - Aceite os termos.
   - Escolha a pasta de instalação, por exemplo: `C:\Godot\Godot_v4.6.3-stable_win64`.
3. Finalize a instalação.

### Opção B — instalar sem instalador (portátil)

1. Baixe o arquivo ZIP do Godot.
2. Crie uma pasta, por exemplo: `C:\Godot`.
3. Extraia o ZIP dentro dessa pasta.
4. Depois da extração, você terá o executável, como: `C:\Godot\Godot_v4.6.3-stable_win64\Godot_v4.6.3-stable_win64.exe`.

---

## 3) Baixe o projeto

O projeto contém o arquivo de configuração principal `project.godot`.

Se você recebeu o projeto como ZIP:

1. Vá até a pasta onde o ZIP foi baixado.
2. Clique com o botão direito no arquivo ZIP.
3. Escolha **"Extrair tudo…"** (Windows) ou use 7-Zip / WinRAR.

Exemplo de destino: `ReinosDaArea`. Depois da extração, a pasta deve ficar assim:

```
C:\Desenvolvimento\ReinosDaArea\
├── project.godot
├── README.md
├── scenes\
├── scripts\
│   ├── autoload\    (GameState: progresso salvo)
│   ├── data\        (campanha e arquétipos)
│   ├── systems\     (combate, precisão, unidades)
│   ├── screens\     (menu, mapa, batalha...)
│   └── ui\          (kit de UI e transições)
├── tests\           (testes automáticos)
└── assets\
```

> **Importante:** a pasta que você abrir no Godot deve conter o arquivo `project.godot` dentro dela.

---

## 4) Abra o projeto no Godot

1. Abra o executável do Godot (`Godot_v4.6.3-stable_win64.exe`).
2. Na tela inicial, clique em **"Import"** (ou **"Open Project"**).
3. Navegue até a pasta onde extraiu o projeto (`ReinosDaArea`).
4. Selecione o arquivo `project.godot`.
5. Clique em **"Import & Edit"** (ou **"Abrir Projeto"**).

> **Na primeira abertura**, aguarde o Godot importar os arquivos (barra de progresso no canto). Isso registra as classes novas e os áudios. Se aparecer erro de "identificador não encontrado", feche e abra o projeto de novo depois que a importação terminar.

---

## 5) Como rodar o jogo

1. Com o projeto aberto, pressione **F5** (ou clique no botão **Play**).
2. O jogo abre no **Menu Principal**. Escolha **Jogar Campanha**.
3. Se ainda não escolheu um conselheiro, a tela de **Seleção de Arquétipo** aparece primeiro; depois você vai ao **Mapa de Campanha**.
4. Selecione a **Fase 1**, leia o briefing e clique em **Iniciar Fase**. Na primeira vez, a Cartógrafa conduz um tutorial curto.

### Controles

| Tecla | Ação |
|---|---|
| **A** | Atacar |
| **D** | Defender |
| **R** | Recuar |
| **E** | Ativar a habilidade do arquétipo |
| **H** | Abrir o guia *Como jogar* (o relógio para) |
| **V** | Esconder ou mostrar o relatório da rodada |
| **Enter / Espaço** | Próxima rodada (na tela de resultado) |
| **Esc** | Pausar a batalha · voltar nos menus |

---

## 6) Progresso e dados salvos

O progresso (arquétipo, fases liberadas, estrelas, Recursos Estratégicos, XP e volumes) é salvo automaticamente em `user://reinos_save.cfg`. No Windows, fica em:

```
%APPDATA%\Godot\app_userdata\Reinos da Área\reinos_save.cfg
```

Para recomeçar do zero: **Menu → Opções → Reiniciar progresso** (pede confirmação), ou apague esse arquivo com o jogo fechado.

---

## 7) Jogar pelo executável (sem Godot)

1. Baixe `ReinosDaArea-Windows.zip` na página de versões do repositório: <https://github.com/Enzo-Camelo/Reinos-da-Area/releases/latest>.
2. Clique com o botão direito no ZIP → **Extrair tudo…** (não rode o jogo de dentro do ZIP).
3. Dê dois cliques em `ReinosDaArea.exe`. É um arquivo único, com tudo embutido.
4. Se o Windows mostrar **"O Windows protegeu o computador"**, clique em **Mais informações → Executar assim mesmo**. O aviso aparece porque o executável não tem assinatura digital paga.

**Gerar um executável novo:** no editor, **Projeto → Exportar… → Windows Desktop → Exportar projeto…** (salva em `build/Desktop/ReinosDaArea.exe`), com os *export templates* do Godot 4.6.3 instalados. Pelo terminal:

```
Godot_v4.6.3-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/Desktop/ReinosDaArea.exe
```

O preset (`export_presets.cfg`) embute os dados no `.exe` e deixa de fora `assets/docs/` e `tests/`.

---

## 8) Rodar os testes automáticos (opcional)

Use o executável **console** do Godot, na pasta do projeto:

```
Godot_v4.6.3-stable_win64_console.exe --headless --path . --import
Godot_v4.6.3-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd
Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/integration_test.tscn
```

- O primeiro comando só importa o projeto (necessário uma vez, ou abra o editor).
- `run_tests.gd`: regras (combate, terreno, IP, estrelas, unidades, campanha e gerador de territórios).
- `integration_test.tscn`: joga fases completas com os três arquétipos.

Ao final cada um imprime `N ok, 0 falhas`. O teste de integração preserva o seu arquivo de progresso.

---

## 9) Problemas comuns

| Problema | Solução |
|---|---|
| "Identifier not found" para uma classe (ex.: `CombatResolver`) | Feche o projeto e reabra; ou rode o comando `--import` da seção 8. |
| Sem som | Verifique os volumes em **Opções**. Os arquivos `sino_preciso.wav`, `sino_impreciso.wav` e `pagina.wav` ficam em `assets/audios/`. |
| A janela abre em tela cheia | É o padrão. Desmarque **Tela cheia** em **Opções** dentro do jogo. |
| "O Windows protegeu o computador" ao abrir o `.exe` | **Mais informações → Executar assim mesmo** (executável sem assinatura digital). |
| Fonte/ícone ausente | Confira se as pastas `assets/fonts`, `assets/icons` e `assets/ui` vieram no ZIP. |

---

Feito por: Enzo Camelo Vieira
