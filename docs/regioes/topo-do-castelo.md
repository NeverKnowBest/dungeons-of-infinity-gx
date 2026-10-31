# Região: Topo do Castelo

Piloto do plano de ferramentas: a primeira região feita pelo fluxo novo (spec, importação, ficha de fase, templates, inimigos, validador, teste). Reaproveita os inimigos do castelo, então o risco fica nas ferramentas e não em mecânicas novas.

* **Estado:** em produção
* **Sexta rodada (out/2026):** as salas voltaram às da terceira rodada (a repintura da F12b-2 e os arredores do castelo da F18 foram recusados no jogo e desfeitos), com as correções feitas à mão: tranca que fecha a passagem inteira, ponta da mureta nas passagens de cima com o canto da própria mureta, porta lateral junto ao canto de cima passando por baixo da mureta, rachadura só na face da mureta. Detalhes em `docs/roadmap.md` (R1, sexta rodada). Falta o Guilherme jogar e aprovar.
* **Terceira rodada (out/2026):** resolveu as quatro pendências da segunda (salas com seção pintadas, muretas que se encaixam, portão, clima conferido)
* **Origem:** ALttP, Castelo de Hyrule na noite da chuva (abertura do jogo), parte de fora e alta do castelo
* **Tipo:** telhado do castelo visto de cima (área 0x1B do overworld do ALttP), montado como uma dungeon (`Layout` Outdoor, layouts do castelo)
* **Fase:** `DungeonLevel.CastleTop` (novo), nome no jogo "Castle Rooftops"
* **Capítulo:** variante do capítulo 2 (`Depth` 2), ao lado do Castle Basement. Vem depois do capítulo 1 (Hyrule Castle, a entrada do castelo) e segue para o capítulo 3 (Castle Prison, com o chefe)
* **Pools de saída:** entra na `NextPool` do Hyrule Castle com peso 1, ao lado do Castle Basement com peso 2 (cada saída do castelo leva ao topo em 1 de cada 3 sorteios). A `NextPool` dele é só o Castle Prison; `ExitCount` e `ExitHidden` no padrão da ficha
* **Visual da saída:** no Hyrule Castle, a saída que leva ao topo é a escadaria para cima (`StairsUp`). No topo, a chegada e a saída são o portão do ALttP que leva à Torre de Agahnim (`ArriveLook` e `OwnExitLooks` "Gate"); a saída que não cabe na parede de cima desce pela escada da frente do castelo (`GateStairs`)
* **Gráficos:** `incoming/topo-do-castelo/`: o tileset `ts_CastleTop` (área 0x1B cortada da ROM pelo `owdump.py tiles`) e o trovão (`Sound_Thunder`)

## Ideia

Em vez de entrar pelos corredores, o Link sobe pelos telhados e passarelas do castelo, debaixo da tempestade da abertura. É o mesmo castelo e os mesmos guardas, mas ao ar livre: chuva caindo sobre a tela, relâmpagos que clareiam tudo por um instante e o trovão logo depois. Chega-se a ele por uma escadaria que sobe, e no fim uma escada desce de volta para dentro, rumo à prisão.

## Visual

* O telhado do Castelo de Hyrule como na área 0x1B do ALttP: o terraço verde-azulado é o piso, o alto creme pontilhado e a face bege com rebites das muretas são as paredes. As salas são pintadas tile a tile com o `ts_CastleTop` (salas pintadas, F12b-1), com peças recortadas da própria área, então a luz e a perspectiva são as do original.
* Passagem é um corte reto na mureta (em cima, embaixo e dos lados), sem moldura de porta.
* A mureta continua de uma sala para a outra: a borda da sala não tem face externa nem ponta, e os cantos são células inteiras da área, com o contorno escuro.
* Decoração: torres de lâmpada verde (com o pé sobre o piso) encostadas na mureta de cima e o brasão de Hyrule no piso. O portão da Torre de Agahnim não é mais decoração: é a entrada e a saída da fase.
* Natureza invadindo: árvores e moitas sobre manchas irregulares de grama que tomam o piso (motivos `Nature/trees` e `Nature/bushes`; as bordas são as da trilha de terra da 0x1B com a terra trocada pelo piso).
* Salas com vista para baixo (Overlook, CourtView, GateView, LongOverlook, WideOverlook, WideView, WideViewMiddle): a face externa do castelo cai na grama, com árvores e moitas lá embaixo.
* Moitas: cada moita do motivo `Nature/bushes` é um `oBush` do DoI (corta com a espada, levanta com a luva, item de pote dentro), sobre a grama; nunca tile de parede (oitava rodada).
* A noite é a mesma da entrada (nível `Start`): tela azulada e escura, chuva caindo e relâmpagos que clareiam tudo, com o trovão logo depois.
* Sem portas de dungeon (revisão de out/2026): a porta fechada vira passagem aberta, a trancada é o corte com dois blocos de fechadura, a secreta é a mureta rachada que abre com bomba. O portão abre (fechado, abrindo, aberto) quando o Link entra e fecha atrás dele quando chega.

## Salas

* Mesma classe de dungeon e mesmos layouts do castelo (`DungeonClass.Castle`, `data_d`); muda o conjunto de salas: `CastleTop`, escrito pelo `tools/templates/make_rooms.py` e escolhido por `RoomSet` na ficha.
* 26 salas pintadas, cada uma com um conjunto de portas e uma decoração: 1x1 Terrace (a da prévia aprovada), Crossroads (moitas), TwinGates, Rampart, SideTower, LampCourt, LowGates, Gatehouse, uma variante com moitas de cada uma das seis últimas (TwinGarden, RampartGarden, SideGarden, LampGarden, LowGarden, GateGarden, oitava rodada) e Overlook, CourtView e GateView (vista); 1x2 LongTerrace, LongRampart e LongOverlook (vista); 2x1 WideTerrace, WideGarden (moitas), WideCourt (moitas), Grove (árvores), WideOverlook, WideView e WideViewMiddle (vista). Os conjuntos de portas são os menores que cobrem todas as salas que os layouts do castelo deram em 12 sementes (cenário `castle_top_layouts`). Uma sala lisa de cada tamanho com todas as portas (OpenTerrace, LongOpenTerrace, WideOpenTerrace) fica de reserva, escolhida só quando nenhuma outra serve (`Fallback`).
* Sem salas de obstáculo (`ObstacleRooms = false`): são quebra-cabeças de dungeon.
* Salas especiais (loja, tesouro, rupias, fada e as outras) são cópias pintadas das salas especiais compartilhadas (`specials` no `rooms.json`, moldura de topo mais baixo): 21 das 66 cabem, todas as subclasses cobertas.
* Salas com seção (parte da sala separada no layout): a seção fica atrás de uma mureta baixa pintada com as peças da própria moldura (`paint_sections.py`), em todas as formas que os layouts dão (cantos, meios, cantos largos, faixas, nos três tamanhos): WalledCorner, WalledLow, WalledSide, WalledTall, WalledBig e WalledBigLow (1x1; as duas últimas, o canto grande das seções 21 a 24, que antes vinha da classe `Sections` da dungeon, oitava rodada), LongWalledTop e LongWalledLow (1x2), WideWalledA a WideWalledD (2x1). Com elas e as salas de reserva, todas as salas da fase saem do telhado: 156 de 156 em 12 sementes e 718 de 718 em 60.
* Referência para a F8: salas da Torre de Agahnim e o exterior do castelo no ALttP (as ids saem na conversão).

## Inimigos

| Objeto | Peso | Variante (energia, ataque, cor) | Ficha |
|--------|------|---------------------------------|-------|
| `oEnemy_Soldier_Simple` | 3 | verde, energia 1, ataque 0.5 (igual ao castelo) | `docs/ref/doi.md` |
| `oEnemy_Soldier_Advanced` | 2 | verde, energia 2, ataque 0.5 (igual ao castelo) | `docs/ref/doi.md` |
| `oEnemy_Keese` | 1 | padrão (energia 0, ataque 0.25) | `docs/ref/doi.md` |

Os soldados usam a mesma tabela do castelo. O morcego entra com peso baixo: são os morcegos do porão espantados pela tempestade, e ele já existe no porão e na prisão. Nenhum inimigo novo.

## Chefe

Nenhum. O capítulo 2 não tem chefe (o do capítulo 3, Armos, continua na prisão).

## Itens e recompensas

Iguais aos do castelo (baús, potes e o que mais o castelo sortear). Nenhuma conquista nova na primeira versão; uma conquista de "achar o telhado" pode vir depois, junto com outras de conteúdo novo (roadmap, passo 3).

## Música e som

* Música do castelo (`SongIndex.Castle`, `Music_Castle_Intro` e `Music_Castle_Main`).
* Chuva (`Sound_Rain`) tocando o nível inteiro, no mesmo volume da entrada (o `oIntro` e o castelo usam 0.3).
* Trovão: `Sound_Thunder`, extraído da ROM na F6b (`incoming/topo-do-castelo/sounds/Thunder.wav`, 1.69 s, pelo `tools/alttp/sfx.py 2 0x36`). No ALttP é o efeito 0x36 (54) de `sound_effect_1`, a porta 2 do APU, tocado pelo `OverworldOverlay_HandleRain` (zelda3, `src/overworld.c`).

## Clima e efeitos

* O clima é o `oWeather`, tirado do `oIntro` e usado pela entrada e por esta região (campo `Weather` da ficha, `{Thunder: true}` aqui): gotas `oRainDrop`, respingos `oRainSplash`, flash branco de 2 ou 3 quadros a cada 30 a 180 e a tinta azul da noite.
* Ritmo do ALttP como referência: no original o céu pisca nos quadros 3 a 5, 36 a 44 e 88 a 90 de um ciclo de 256, e o trovão toca no quadro 36. O DoI mantém o sorteio e toca o trovão 12 quadros depois do flash (se o anterior já acabou).
* Com o desafio de escuridão ligado, o relâmpago segue a regra que o `oIntro` já tem.

## Regras especiais

Nenhuma na primeira versão. Ideias para depois (não fazer agora): vento que empurra o Link nas passarelas, buraco no telhado que leva direto à prisão.

## Mudanças no código

A ficha de fase (F4) e os caminhos ramificados (F4b) já existem, então a região é uma entrada nova na ficha:

* `DungeonLevel` ganha o membro do topo (novo) e `Levels_Init` a entrada: `Depth` 2, `Next` e `NextPool` no Castle Prison, `Theme` e `EnemyStats` do castelo, `ExitLook` "StairsUp", a música e a lista de inimigos acima.
* `NextPool` do Hyrule Castle: `[[DungeonLevel.CastleBasement, 2], [<topo>, 1]]`. Só isso liga o sorteio de saídas no castelo (quantas, escondida, destino); nenhuma outra fase muda.
* Salas: conjunto de salas `CastleTop` (novo) em `data/room-templates/sets/CastleTop/rooms.json` e `RoomSet = "CastleTop"` na ficha (a escolha por conjunto já existe desde a F11).
* Clima: criar `oWeather` (novo) no começo da fase e passar o `oIntro` a usá-lo para a chuva e o relâmpago.
* Os soldados: confirmar se usam os números do castelo (`EnemyStats` do castelo, como decidido) agora que a fase está no capítulo 2, onde o porão usa os dele.
* `tools/check/validate.py` e `docs/dev/engine-notes.md`: registrar o que for aprendido.

## Pendências (out/2026, Guilherme jogou a rodada da revisão)

A rodada fez: portas ao ar livre (fechada vira passagem, trancada com blocos de fechadura, secreta como mureta rachada), portão da Torre de Agahnim na chegada e na saída com a animação da ROM e a saída na parede de cima, torre com o pé, mureta que continua além da borda da sala com cantos inteiros da ROM, salas com vista para baixo, natureza com grama tomando o piso e salas especiais pintadas pela ferramenta (21 de 66). Ainda falta:

1. **Salas com seção de interior de torre** (resolvida na terceira rodada, out/2026): a sala em L de piso cinza e paredes douradas era uma sala com seção (parte da sala separada no layout), que nenhuma sala pintada servia. Agora a seção fica atrás de uma mureta baixa do telhado e todas as salas da fase são pintadas (prévia aprovada pelo Guilherme, opção "mureta de pedra").
2. **Muretas de salas vizinhas** (resolvida na terceira rodada): entre salas pintadas a mureta já formava uma estrutura só; quem quebrava a junção eram as salas que ainda vinham do castelo por dentro (as com seção e 17 de 718 salas com combinações de portas que nenhuma sala pintada tinha). Com as salas com seção e as de reserva, nenhuma sala da fase usa mais as paredes de dungeon.
3. **Porta de entrada e saída** (corrigida na terceira rodada, out/2026): o Link chegava em cima da mureta, ficava parado no vão e a porta de dungeon do castelo se fechava atrás dele por cima do portão (o bloco marrom com pedras azuis); na saída, ele atravessava o portão fechado e só depois ele abria. Agora ele sai do vão aberto, o portão fecha atrás dele, e na saída o portão abre quando o Link encosta nele de frente (como a porta do palácio do ALttP) e ele entra pelo vão. Prova: cenário `castle_top_gate` (fotos da chegada e da saída).
4. **Chuva e noite** (conferido na terceira rodada): as fotos do jogo no cenário `castle_top_gate` mostram a chuva, os respingos e a tinta azul da noite no topo, chegando pelo Hyrule Castle. Se o Guilherme ainda não vir jogando, falta saber por qual caminho ele chegou (run nova pelo hub, continuar um jogo salvo).

## Pronto quando

* Em várias runs, o capítulo 2 aparece às vezes como o topo do castelo (por uma escadaria para cima no Hyrule Castle), com as salas do conjunto CastleTop, chuva, relâmpago e trovão, e o capítulo seguinte é a prisão normal.
* Cenários de teste da F3: começar no topo do castelo com semente fixa, andar até a escada de saída e conferir no log que as salas carregaram, os soldados apareceram e nada deu erro; folha de contato com 5 sementes mostrando as salas.
* O validador passa e a entrada (nível `Start`) continua igual com o `oWeather` (novo).
* O Guilherme joga uma run e aprova o visual.

## Decisões

* Terceira rodada (out/2026, Guilherme escolheu a opção A na prévia): salas com seção pintadas com uma mureta de pedra do telhado, em vez de tirar as seções do topo. Como a mureta grossa do ALttP não cabe entre as portas de uma sala 1x1, ela segue a linha dos trilhos do DoI, 24 px de altura e 16 de largura, feita com as peças da própria moldura. O portão de saída abre quando o Link encosta nele de frente, como a porta do palácio do ALttP.
* Revisão do Guilherme (out/2026, prévias 1 a 4 aprovadas): sem portas de dungeon ao ar livre; portão da Torre de Agahnim na chegada e na saída, com a animação da ROM, e a saída na parede de cima (ou a escada da frente do castelo quando não cabe); torre com o pé; mureta contínua entre salas, com peças inteiras; salas com vista para baixo; natureza em cima do telhado, com grama tomando o piso; salas especiais pintadas como a região. Poças de chuva ficaram de fora (o ALttP não tem).

* Mesmos inimigos do castelo, chuva e relâmpagos como no começo da run (roadmap, out/2026).
* É o piloto do plano de ferramentas: só começa depois das etapas F1 a F10, para testar o fluxo inteiro.
* Chance de 1 em 3 e o morcego com peso 1 foram escolhas do Claude dentro da direção de design; mudar se o Guilherme preferir.
* É variante do capítulo 2 (`Depth` 2, no lugar do Castle Basement), entre o Hyrule Castle e o Castle Prison, e a saída que leva a ele é a escadaria para cima (Guilherme, out/2026). A versão anterior desta spec o punha no lugar do Hyrule Castle; isso foi corrigido.
* O topo é o telhado do castelo visto de cima, como na área 0x1B do ALttP: telhado verde-azulado no chão, passarelas creme com pinos e face bege como paredes, a entrada da Torre de Agahnim (Guilherme, out/2026). A faixa do castelo recolorida (paredes em pedra bege com ameias, piso claro) foi recusada: é o castelo por dentro com outra cor. As seções Tipo, Visual e Salas acima ainda descrevem a versão de dungeon e serão reescritas com a F12b.
* F12b-1 feita (out/2026): o Guilherme aprovou a prévia da sala 1x1 do terraço (terraço verde-azulado como piso, muretas creme e bege como paredes, torres de lâmpada verde dos dois lados da passagem de cima, brasão de Hyrule no meio). A ficha ganhou `Layout` Outdoor, `RoomSet` CastleTop, `Ceiling` false e `Dark` Never; o conjunto `CastleTop` (`data/room-templates/sets/CastleTop/rooms.json`) tem só essa sala, "Terrace", com portas 12 e 6. As outras salas da fase, a chuva (o `oWeather` (novo)), as portas trancadas e de saída ao ar livre e os cenários da fase são o resto do piloto. As seções Visual e Salas acima ainda descrevem a versão de dungeon.
* A região espera a F12b: as salas saem pintadas tile a tile com o `ts_CastleTop`, porque as paredes do DoI são simétricas (um canto girado faz os quatro) e não dão a luz do telhado do ALttP (Guilherme escolheu a F12b em vez de uma faixa com quatro cantos, out/2026).
* Já feito e mantido para a F12b: a ficha `DungeonLevel.CastleTop` ("Castle Rooftops", `Depth` 2, `Next` Castle Prison, `ExitLook` "StairsUp", `RegionTiles` "CastleTop", os inimigos acima), o trovão e o `ts_CastleTop`. Ela ficou fora de toda `NextPool` até a F12b-1 (o Guilherme pediu); o resto do piloto religou o Hyrule Castle com o peso 1 dela ao lado do 2 do porão. A faixa recusada saiu do `sTiles`.
* Resto do piloto feito (out/2026, escolhas do Claude dentro da direção, a aprovar): 11 salas pintadas novas no conjunto `CastleTop` com aberturas laterais (o mesmo corte reto da passagem aprovada) e salas 2x1 próprias (sala pintada nunca gira); `oWeather` com chuva, relâmpago, trovão e a noite; Hyrule Castle com `NextPool` `[[CastleBasement, 2], [CastleTop, 1]]`; sem salas de obstáculo; salas especiais e de seção como interiores de torre (salas compartilhadas do castelo); portas especiais com o desenho das portas do castelo no corte da mureta. O trovão não entrou na entrada (nível `Start`), que ficou igual.
