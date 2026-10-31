# Receitas

Passo a passo das tarefas que se repetem. Detalhes do motor em `engine-notes.md`; scripts em `tools/README.md`.

## Antes de qualquer coisa

* As salas do jogo ficam em `game/datafiles/data/rooms/` (um arquivo por classe, git normal) e são geradas pelo `tools/templates/convert.py`; não edite à mão. Os layouts (`data_d`) estão no Git LFS; os dois PCs têm o LFS, mas num clone sem LFS ele é só um ponteiro de texto.
* Teste o GML no jogo, em qualquer um dos dois PCs: pelo IDE ou com um cenário de teste automático (`python tools/test/run.py`, receita "Teste automático" abaixo).
* Rode `python tools/check/validate.py` antes de entregar. Ele pega recursos faltando, eventos sem arquivo, assets inexistentes no GML e as armadilhas abaixo.
* Só compila o que está no `Zelda.yyp`. O código morto da versão original foi apagado na F1; se o validador acusar uma pasta órfã nova (por exemplo, um recurso removido no IDE, que deixa a pasta no disco), apague a pasta.
* GML que já deu problema: um array literal não pode começar com cor `#RRGGBB` (`[#` é acessor de ds_grid); use `make_colour_rgb`. `global.Font_Small` só tem letras maiúsculas.

## Teste automático (cenário)

1. Comece pelo `boot` (`python tools/test/run.py boot`): ele compila, monta a primeira fase e fecha. Erro de compilação ou de GML aparece em texto na saída do script.
2. Para testar uma mudança, copie `tools/test/scenarios/smoke.json` para um cenário com nome do assunto e escreva só os passos que provam a mudança: a fase (`level`), itens e cheats, os comandos (`hold`, `press`, `room`, `spawn`) e as checagens (`expect`, `state`, `shot` quando a imagem importa). Formato em `tools/README.md` ("test/").
3. Ache as salas da fase pelo log: as linhas `room` e `sheet` mostram a posição no grid e o template de cada uma. Para ir direto a uma sala, `{"do": "room", "x": 4, "y": 4}`.
4. Rode e leia o `RESULT` e o log. Para repetir sem mudar o GML (só o cenário), use `--no-build`.
5. Se um passo falhar, olhe a linha `FAIL` ou `crash` e o print do momento antes de mexer no código. A mesma semente sempre joga igual, então o erro se repete.
6. Cenário que prova algo que pode quebrar de novo fica em `tools/test/scenarios/` (o validador confere todos).
7. Durante o trabalho, rode só os cenários que a mudança afeta (`run.py smoke arch_trace`: vários numa chamada compilam uma vez). Antes da entrega, a bateria inteira uma vez: `python tools/test/run.py --all` (com `--save after` se houver baseline de antes para comparar). O jogo roda numa área de trabalho escondida, sem aparecer na tela nem pegar o foco; `--show` mostra o jogo.

## Folha de contato de uma fase

1. `python tools/test/run.py --sheet <Fase> --seeds 4` (nomes do enum `DungeonLevel`: Castle, Sewers, Mines...). Para sementes escolhidas: `--seeds 7,9,12`.
2. Saem `tools/test/out/sheet_<nível>_<semente>.png` (fase inteira em 1x) e `sheet_<nível>.png` (todas lado a lado, em meio tamanho). O log lista cada sala com grid e template.
3. Serve para conferir salas novas e a variedade da geração sem jogar. Para comparar antes e depois de uma mudança, rode as mesmas sementes nas duas versões.

## Comparar antes e depois (cenários de referência)

Para mudanças que não deveriam mudar o jogo (refatoração, faxina, troca de tabela por ficha):

1. Antes de mexer no código: `python tools/test/baseline.py save before` (compila e roda os 14 `ref_*`, uns 15 min; rode em segundo plano). Se já mexeu, faça o baseline numa cópia do commit: `git worktree add --detach %TEMP%/doi-base HEAD`, copie para lá as ferramentas de teste que mudaram, rode `save before` nela e copie `tools/test/baseline/before` de volta. Não rode dois testes ao mesmo tempo: os dois usam o mesmo arquivo de cenário e a mesma pasta de saída.
2. Depois da mudança: `python tools/test/baseline.py save after` (ou, já na bateria final, `python tools/test/run.py --all --save after`, que roda também os outros cenários) e `python tools/test/baseline.py compare before after`. Baseline feito antes da F3b (jogo na tela) difere em `ref surface N` (um a mais fora da tela): compare com `--handles`.
3. `SAME` prova que as 14 fases são geradas igual (salas, objetos e suas variáveis, tiles, globais, folhas de contato). Se aparecer diferença, leia as linhas: global renomeado ou removido de propósito é esperado; qualquer outra coisa é mudança de comportamento. Se a mudança cria sprites ou surfaces, todo dump muda nos números delas: compare com `--handles`, que ignora esses números.
4. Fase nova ganha um `ref_NN_<Fase>.json` copiado de um parecido (no `probe`, só inimigos que existem na fase).

## Sala nova no hub

1. Monte a imagem da sala (veja "Imagem de sala a partir do ALttP"). Use uma camada de baixo (`sHub_<Nome>`) e, se houver partes que cobrem o Link (topo de paredes, lustres), uma de cima (`sHub_<Nome>_Over`).
2. Em `tools/hub/build3.py`, acrescente a sala em `ROOMS`: nome do template, posição livre no mapa do Tiled, posição no grid (até 8x8; o Santuário ocupa 3..4, o Hall 5..6) e tamanho (1x1, 2x1, 1x2 ou 2x2). Rode o script.
3. Em `__Hub.gml`: `Hub_RoomTemplateName` devolve o nome pela posição no grid; em `Hub_CreateScenery` acrescente o `case` da sala com as imagens, as paredes (`Hub_CreateWalls`, retângulos em tiles de 8 px), objetos e portas.
4. Porta entre salas do hub: um `oHubDoor` no vão da porta (caixa de gatilho) com `DestTemplate`, `DestX`, `DestY` (posição de chegada, já no vão da outra porta) e `DestFacing`. A troca de sala rola a câmera como nas dungeons (`oHubTravel`).
5. Teste: andar por todas as bordas, passar pelas portas nos dois sentidos, conferir que o Link não entra em paredes nem fica atrás de objetos que deveriam cobri-lo.

## Template de sala no Tiled

1. Abra o mapa da classe em `data/room-templates/` (`Room Templates <Classe>.json`) no Tiled 1.10 ou mais novo.
2. Desenhe o retângulo da sala na camada `Rooms` (tamanho em múltiplos de 256; meia sala de 256x128 só nas classes Main) e preencha `type` com a subclasse quando a classe for por tipo (Special, Other, Village, Mines, Obstacles). Os objetos vão nas camadas de mesmo nome, sempre com a propriedade `Room` apontando para o retângulo.
3. Gere as salas do jogo: `python tools/templates/convert.py --summary`. Ele avisa camada desconhecida, objeto sem `Room`, tamanho de sala inválido e porta fora das posições de porta, e grava `game/datafiles/data/rooms/<Classe>.json`.
4. Confira no `git diff` que só mudou o arquivo da classe e só as linhas das salas novas ou alteradas (cada template é uma linha). Para comparar com uma versão anterior pelo conteúdo: `python tools/templates/compare.py <pasta antiga> game/datafiles/data/rooms`.
5. Rode o validador (ele acusa se o mapa do Tiled mudou e as salas não foram geradas de novo) e teste no jogo.

Os mapas de um conjunto de salas ficam em `data/room-templates/sets/<Conjunto>/`, com o mesmo nome e as mesmas camadas dos mapas compartilhados. Um mapa escrito pelo `make_rooms.py` tem a propriedade `Generator` e é refeito a partir do `rooms.json`; para desenhar à mão no Tiled, apague essa propriedade (o script deixa de mexer nele) e tire do `rooms.json` as meias salas daquela classe.

## Conjunto de salas de uma região

Salas próprias de uma fase (formas, portas, seções e decoração composta por motivos), sem desenhar no Tiled (roadmaps F11 e F11b). Detalhes em `docs/dev/engine-notes.md` ("Room sets"); formato da descrição em `tools/README.md` ("templates/").

1. Nome do conjunto: o membro de `DungeonLevel` da fase (ex.: `CastleTop`). Crie `data/room-templates/sets/<Conjunto>/rooms.json` copiando o `sets/Example/rooms.json`.
2. Descreva as meias salas (a metade de cima de cada sala; o conversor junta cada par que se encaixa, a de baixo espelhada). Para cobrir quase todas as salas da fase: pelo menos uma meia sala `Main_Upper` `1x1` e uma `1x2` com todas as portas e as quatro seções (`"sections": [1, 2, 9, 17]`), e uma `Main_Lower` `1x1` e uma `1x2`. As outras dão a forma da região: recortes (`cut`) e `props` (ex.: `ForceWallTheme`). Cada sala com uma função clara (direção de design).
3. Decoração: `python tools/templates/motifs.py --report` lista o catálogo (motivos por camada, com âncora, tamanhos, recuos e passos medidos nas salas compartilhadas). Cada meia sala nomeia em `motifs` os que contam a função dela (lago: `Water/axis` e `Water/top` com `within`; galeria: `Monuments/side`, `Torches/side`, `Spikes/side`; salão: `Monuments/corner`, `Pots/top_center`, `CarpetsFull/area`); as camadas que ela não nomeia pegam o motivo mais usado. Prévia sem o jogo: `python tools/templates/make_rooms.py <Conjunto> --map` mostra cada meia sala em texto (paredes, vãos das portas e as peças de cada motivo).
4. `python tools/templates/make_rooms.py <Conjunto>`: escreve os mapas e mostra, por classe e tamanho, quantas salas saem, as portas e as seções cobertas. Erros comuns: recorte que deixa menos de 48 px entre dois cantos, porta pedida fora de uma parede reta, água que separa o piso sem `zones`, seção sem as portas dela, motivo que não acha lugar (troque recuo, tamanho ou âncora; o erro lista os do catálogo) e "loose composition" (peça solta, sem par, encostada ou no vão de uma porta).
5. `python tools/templates/convert.py --summary`: grava `game/datafiles/data/rooms/sets/<Conjunto>/` e o `sets.json` e registra os arquivos no `Zelda.yyp` (com o projeto aberto, o GameMaker pede para recarregar).
6. Na ficha da fase: `RoomSet = "<Conjunto>";`. Antes de a fase existir, dá para testar numa fase qualquer pelo cenário (`"levels": {"Castle": {"RoomSet": "<Conjunto>"}}`, como em `tools/test/scenarios/room_sets.json`).
7. Prova: o log tem `roomset <Conjunto> rooms=N/M` e as linhas `room ... set=<Conjunto>`; `expect` com `set_rooms_min`; a folha de contato mostra as salas; o validador passa (ele acusa mapa fora da descrição, catálogo de motivos velho, arquivo do jogo velho e arquivo fora do `.yyp`).

## Sala pintada com o tileset da região

Sala inteira pintada tile a tile com peças de uma área do ALttP, com colisão pelos tiles (F12b-1). Detalhes em `docs/dev/engine-notes.md` ("Painted rooms"); formato em `tools/README.md` ("templates/", "Painted rooms").

1. A região já tem o tileset importado (receita "Tiles e sons da ROM para uma região"): `incoming/<regiao>/tiles/` com `tiles.png`, `tiles.json` e `areas.json` (a área em números de bloco), `data/tiles/<Regiao>.json` com `solid` e o tileset do Tiled em `data/room-templates/tilesets/<Regiao>.json`.
2. Prévia antes (é visual): `python tools/alttp/owdump.py png <área>` e uma imagem da sala montada com os blocos, ao lado da colisão. Escolha as peças na área renderizada (coluna e linha de blocos de 16x16; os números de `areas.json`): piso, os três pedaços de cima, do meio e de baixo da moldura, a abertura de cada lado de porta e a decoração.
3. No `rooms.json` do conjunto: `kit` (tileset, área, peças, moldura, aberturas) e `painted` (nome, tamanho, portas, decoração com `pair` para a cópia espelhada). Exemplo: `data/room-templates/sets/CastleTop/rooms.json`.
4. Quais salas fazer (conjunto da fase inteira): copie `tools/test/scenarios/castle_top_layouts.json` para a fase (monta 12 sementes e o passo `rooms` lista cada sala com classe, tamanho, portas e se veio do conjunto), rode e conte, por tamanho, as combinações de portas das salas `Main_Upper` (as `Obstacles` também, se a ficha tiver `ObstacleRooms = false`). Uma sala pintada serve às salas cujas portas ela tem, e duas posições vizinhas não cabem na mesma sala 1x1 (as passagens se encostam; as 12 posições formam um anel). Escolha o menor grupo de conjuntos de portas sem vizinhas que cobre todas (no topo do castelo, 6 salas 1x1, 2 salas 1x2 e 3 salas 2x1 cobriram tudo menos as salas especiais e as de seção) e dê a cada sala uma decoração própria. Tamanhos: `1x1`, `1x2` e `2x1`; sala pintada nunca gira.
5. `python tools/templates/make_rooms.py <Conjunto> --png <arquivo>` desenha as salas (portas fechadas e abertas) para a prévia; `--map` mostra cada sala em texto (`#` parede, `.` piso, `o` passagem, `D` célula de porta). O script recusa decoração em cima de uma passagem, passagens que se encostam e porta cuja passagem não chega do meio da sala até a borda.
6. `make_rooms.py <Conjunto>` e `convert.py --summary`; na ficha, `RoomSet`, `RegionTiles` igual ao tileset da pintura (o validador confere) e, ao ar livre, `Layout = LevelLayout.Outdoor`.
7. Moldura: a parede continua além da borda da sala (sem face externa nem ponta na borda), para salas vizinhas se ligarem; cantos e pontas sempre de células inteiras da área, com o contorno escuro (procure na área o canto certo, por exemplo o canto de um fosso, em vez de montar com cor lisa). Moldura alternativa (vista para baixo, sala especial) vai em `frames` e a sala a nomeia em `frame`. Onde a passagem corta a mureta, a ponta é o canto da própria mureta deslocado meio bloco: a marca `"h"` na célula (`[50, r, "h"]` é a metade direita da célula 50 ao lado da metade esquerda da 51), que deixa a passagem com a largura da porta; o creme que sobra no pé do canto vira piso com uma recoloração em `tiles/extra.json` (`passage` no topo do castelo) e `owdump.py tiles`. Porta lateral junto ao canto de cima passa por baixo da mureta (a face fica inteira, o `make_rooms.py` não pinta a abertura lateral acima da altura da parede de cima, e a mureta continua por cima do corredor até a borda da sala). Onde a passagem atravessa uma borda fina, ela é um corredor: as aberturas `open_bottom`, `open_left` e `open_right` usam as peças das paredes laterais das salas e os cantos inteiros da ROM (topo do castelo: `[48,8]`, `[49,8]`, `[50,8]`, `[13,36]`, `[15,36]`, `[16,36]`); para a passagem lateral ter os 32 px da porta, a borda de baixo desce meio bloco com a marca `"vh"`. Confira com `castle_top_seams` e `seam_sheet.py` (as duas salas juntas na emenda).
8. Natureza (motivo, nunca coordenada): `nature` na sala com `Nature/trees` (salas 2x1 ou 1x2) ou `Nature/bushes` (um par espelhado; cada moita vira um `oBush` do DoI, que corta e levanta, e onde a moita 2x2 não cabe sai 2x1, 1x2 ou uma só de cada lado); o kit precisa de `grass` (bordas de grama da ROM sobre outro chão, recoloridas para o piso pelo `tiles/extra.json` e `owdump.py tiles`) e `nature`. "finds no place" quer dizer que as portas não deixam lugar: use o motivo numa sala com menos portas ou portas simétricas; "the grass ... does not cover its pieces", tire uma decoração do meio (o brasão). Mais natureza sem sala nova de portas: uma variante com moitas da mesma sala (mesmas portas), e o jogo alterna as duas.
9. Entrada e saída ao ar livre: `gate` no kit (peça e posição por parede), e na ficha `OwnExitLooks`, `ArriveLook` e, se a porta só existe na parede de cima, `ExitWall = "Top"`. Animação da porta: quadros da ROM em `tiles/extra.json` (`map16`), lidos pelo jogo como `named`.
10. Salas com seção (parte da sala separada no layout) e combinações de portas que nenhuma sala tem: salas com `"doors": "all"` (escolhidas só quando nenhuma outra serve, `Fallback`) e `"sections"` com os ids, um por grupo (1-3-6-8 e 21 a 24, 2-4-5-7, 9 a 16, 17 a 20); no kit, `parapet` com as linhas e colunas da moldura que fazem a mureta (`paint_sections.py`, formato em `tools/README.md`). Para cobrir tudo: no 1x1 `[1,2,9,17]`, `[6,7,11,18]`, `[4,13,19]`, `[15]`, `[21]` e `[23]` (o espelho dá os outros; 21 a 24 é o canto grande que as dungeons fazem com a classe `Sections`, no grupo dos cantos), no 1x2 `[1,2,9,17]` e `[6,7,11,18]`, no 2x1 (sem espelho, `"transforms": "None"`) `[1,4,13,19]`, `[3,5,14,20]`, `[6,15]` e `[8,16]`, e uma sala lisa de cada tamanho. Prévia: renderize as salas com a camada da seção por cima. Prova: cobertura em muitas sementes (cenário com `level` e `rooms`, contar as linhas sem `set=`) e o passo `painted` numa sala com seção (`castle_top_sections`).
11. Salas especiais da região: `specials` no `rooms.json` com uma moldura (o topo do castelo usa uma de topo mais baixo, para os objetos caberem). O `make_rooms.py` gera o mapa `Special` do conjunto e falha se alguma subclasse ficar sem sala. Porta de onde o Link não entra na sala desviando dos objetos (moldura pintada mais grossa que a parede da dungeon para a qual os objetos foram arrumados) sai da sala especial; a linha `Special <subclasse>: ... doors` mostra as portas que sobraram.
12. Prova: passo `painted` de um cenário (vai à primeira sala pintada e confere tile a tile: linha `painted ... mismatch=0`), `expect` com `free` depois de andar contra as paredes, e uma foto. Para achar uma semente em que a sala aparece, monte a fase em várias sementes (`level` com `seed`) e leia as linhas `roomset <Conjunto> rooms=N/M`. Exemplo: `tools/test/scenarios/castle_top_room.json`. Cobertura da fase: a linha `roomset` do cenário de medição, antes e depois, e a folha de contato. Fotos combinadas (regra "Uma revisão só" do `CLAUDE.md`): o passo `tour` fotografa todas as salas da fase na luz dela (exemplo: `castle_top_photos`, sementes 1 e 7; `castle_top_section_photos` só as salas com seção); o `run.py` apaga `tools/test/out` a cada rodada, então copie as fotos antes de rodar de novo. Portas abertas: o passo `pass` atravessa uma porta (exemplo: `castle_top_pass`); trancas: o passo `lock` (`castle_top_lock`). Todas as portas de várias sementes, as secretas com bomba e a saída: cenário `castle_top_doors` (passos `passall` e `bomb`). Emendas entre salas vizinhas: `castle_top_seams` (passo `doorshots`, câmera encostada na borda da porta) e `python tools/test/seam_sheet.py castle_top_seams`; para revisar, recorte em volta de cada porta na escala real (a montagem cola cada foto onde a câmera estava, então degrau na foto é degrau no jogo). Todas as portas a partir do meio da sala, como o jogador anda: passo `walkall` (`castle_top_walk`, a 300 quadros por segundo com `speed`). Moitas que cortam: passo `cut`. Que salas a fase usa em 100 sementes (classe, conjunto, natureza, vista, seções acima de 20): `castle_top_census` e `python tools/test/census.py castle_top_census`.

### Conjunto pintado por moldura (F12b-2, fora de uso)

Nenhuma região usa este caminho desde a sexta rodada do R1: as salas que ele fez no topo do castelo foram recusadas no jogo (pontas quebradas, vista perdida) e o topo voltou às peças da terceira rodada, corrigidas à mão (receita acima). A F13 decide se ele fica. As salas saem de regras aprendidas na ROM, não de peças recortadas. Detalhes em `docs/dev/engine-notes.md` ("Automatic painting") e `tools/README.md` ("Rooms from a frame").

1. Regras da região: `python tools/templates/tile_rules.py <regiao>` (grava `incoming/<regiao>/tiles/rules.json`; o validador acusa se ficar velho).
2. Moldura (`data/room-templates/sets/<Conjunto>/frame.json`): a sala de referência que se emenda consigo mesma, a passagem de cada posição de porta (56, 112, 168 e 240 px) e o portão e a escada. Ela quase sempre precisa de junções (janelas 2x2 que a ROM não mostra): proponha em `incoming/<regiao>/tiles/joins.json` ("proposed"), mostre a folha numerada e só passe para "approved" o que o Guilherme aprovar. Recusadas ficam em "refused" para sempre. Emenda feia não se aprova por padrão: se uma emenda não fecha, evite o caso no gerador (decisão "Nada de vão nem de cruz nas emendas").
3. No `rooms.json`: `kit` com `"auto": {"frame": "frame.json", "seeds": {...}}` (sementes de material, células da área, para o miolo das salas 1x2 e 2x1) e as salas em `painted` (nome, tamanho, portas, `"doors": "all"` para as de reserva).
4. `python tools/templates/make_rooms.py <Conjunto>` (pinta, confere cada sala fechada, com cada porta aberta e com o portão, e para com a mensagem se algo não encaixa; grava `solver_cache.json`) e `python tools/templates/convert.py` (grava também `rooms/sets/<Conjunto>/Fit.json`).
5. `python tools/check/validate.py`: zero erros de encaixe ("misfits", "border").
6. Costuras: um cenário com `level` em 12 sementes e o passo `seams` depois de cada uma (`misfits=0`; o `castle_top_seams` saiu na sexta rodada do R1). Na falha, as linhas `seams edge` e `seams doors` dizem se é a moldura (bloco diferente na borda) ou uma porta aberta de um lado só (entrada ou saída encostada numa sala).
7. Folha de contato: `python tools/test/run.py --sheet <Fase> --seeds 5`.

## Clima de uma fase (chuva, folhas, relâmpago, trovão, noite)

1. Na ficha, `Weather = {...}` com os campos que mudam do padrão (`Weather_Defaults` em `scripts/__Weather`: `Rain`, `Leaves`, `Lightning`, `Thunder`, `ThunderDelay`, `ThunderGain`, `Tint`, `Volume`). Ex.: o topo do castelo tem `{Thunder: true}`, a entrada `{Leaves: true}`.
2. O `oWeather` nasce sozinho no `Dungeon_InitLevel` e some no `Dungeon_Clear`. Campo novo no clima: no `Weather_Defaults` e no `oWeather`, nunca com nome de macro (o validador recusa; `Night` é do xadrez).
3. Prova: a linha `weather level=<n> {...}` no log de um cenário na fase, uma foto (a folha de contato não mostra a noite nem o relâmpago) e, se mexer no `oWeather`, o `ref_00_Start` igual no `baseline.py compare` (menos a instância `oWeather` nos dumps).

## Imagem de sala a partir do ALttP

1. Descubra o número da sala no ALttP (wikis e o próprio zelda3 ajudam).
2. Gere o dump com `tools/alttp/roomdump.c` e renderize com `tools/hub/z3room.py` (camada baixa e alta separadas; tiles animados com `ANIMFRAME`).
3. Colisão: os atributos de tile do dump dizem o que é parede; converta em retângulos (como `sanct_walls.json`).
4. Para variar uma sala, recorte e recombine peças da mesma sala ou do mesmo tileset (foi assim com a porta lateral, que é a porta da frente girada, e com o Hall, montado com as paredes do corredor da igreja). Não copie uma sala inteira para outro uso: o Guilherme percebe e não gosta.
5. Monte uma prévia em PNG, olhe e só depois gere os sprites.

## NPC no hub

1. Sprite: `sVillager_<Nome>_Down` (e `_Up`, `_Left`, `_Right` se existir). Se não houver no DoI, extraia da ROM com `sprdump.c` (veja como foi feito o Flute Boy em `tools/hub/flute/`).
2. Objeto `oVillager_<Nome>` com pai `oNPC_Sitting` (`gm_assets.obj`).
3. No `ROOMS` do `build3.py`: objeto NPC (gid 209), nome `Villager_<Nome>`, propriedades `Dialogue` (uma fala por linha; `?` no começo faz pergunta sim/não) e `NoWall` se a colisão for feita à parte. A posição é o canto superior esquerdo do sprite.
4. Para abrir um menu depois da fala, veja `oVillager_FluteBoy` (Step_2: quando `DB_Started`, espera a caixa de diálogo fechar e cria `oMenu_Game` com um `Mode`).

## Conquista nova

1. Acrescente em `global.AchievementList` (`__Achievements.gml`): `Key`, `Statue`, `Name`, `Desc` (o que pedir), `Skin` e `Gear` (recompensa ou -1).
2. Chame `Achievement_Unlock("Key")` onde ela acontece, ou estenda `Achievements_CheckStats` se depender das estatísticas.
3. Regras: a recompensa é segredo até ser conquistada (não aparece na galeria nem nos menus). Nada é liberado com cheats ligados.

## Overworld do ALttP (ler, medir, desenhar)

1. A ROM e o zelda3 ficam na pasta `zelda3` ao lado do repositório (`zelda3.sfc` dentro dela). Se faltarem no PC, peça ao Guilherme; o `owdump.py` diz onde procurou.
2. Ache a área: `python tools/alttp/owdump.py areas` (número, nome, tamanho, música, entradas, segredos, inimigos).
3. Detalhe e colisão: `owdump.py area 0x2c` mostra o mapa de atributos em texto (borda de mão única, arbusto, água, escada, entrada). Aberturas para as vizinhas: `edges`. Composição: `stats` e `vocab`.
4. Imagem: `owdump.py png 0x2c --scale 0.5` (ou `world --scale 0.25`). Olhe em escala reduzida e amplie só a região que importa.
5. Números já medidos estão em `docs/ref/alttp-overworld.md`; acrescente lá o que medir de novo.

## Música da ROM

1. `musicdump.c` renderiza a música (carregue o banco certo: intro ou indoor/overworld).
2. Ache o ponto de loop com `loopfind.py`, corte em `Intro` e `Main`.
3. `gm_assets.sound(...)`, depois acrescente em `SongIndex` e na tabela de músicas (`__Music.gml`).

## Especificação de região

O fluxo inteiro de uma região nova (spec, importação, ficha, salas, inimigos, testes, docs e commit) é a skill `.claude/skills/nova-regiao/`; `python tools/region/status.py <regiao>` mostra onde a região está e o que falta nas ferramentas.

1. Copie `docs/regioes/_modelo.md` para `docs/regioes/<nome>.md` e preencha todas as seções, inclusive o campo **Fase** (o membro de `DungeonLevel`). Estado começa em "ideia" ou "especificada".
2. Números de inimigos, chefes e itens: tire de `docs/ref/` (ALttP em `alttp.md`, o que já existe em `doi.md`). Se faltar um jogo ou um inimigo, pesquise uma vez e acrescente a ficha lá (veja `docs/ref/README.md`), não na spec.
3. Cite os assets entre crases (`oEnemy_Rat`, `Sound_Rain`). Para os que ainda vão ser criados, escreva "(novo)" na linha.
4. Rode `python tools/check/validate.py`: ele acusa seção faltando, estado inválido e asset inexistente.
5. Mostre a spec ao Guilherme antes de construir; o que ele decidir vai na seção Decisões.
6. Ao avançar, atualize o Estado (em produção, pronta).

## Importar gráficos de uma região

1. O Guilherme põe os arquivos em `incoming/<regiao>/` (mesmo nome da spec em `docs/regioes/`), seguindo `incoming/README.md`. Se faltar o manifesto e algo não der para deduzir pelo nome (tamanho do quadro de uma folha, ponto de loop), escreva o `manifest.json` você mesmo.
2. `python tools/import/import_region.py <regiao> --dry-run` e leia o relatório: avisos de cores reduzidas, contorno claro ou meia transparência. Olhe a prévia (`tools/import/out/<regiao>/preview.png`) se houver aviso de contorno ou de cores, ou se for o primeiro lote da região; a escala aparece ao lado do Link.
3. Ajuste o manifesto (`outline`, `colors`, `origin`, `fps`) e repita até não sobrar aviso que importe. Mostre a prévia ao Guilherme se a conversão mudou muito o original.
4. `python tools/import/import_region.py <regiao>` grava os sprites e sons, registra no `.yyp` (pasta `Regions/<Regiao>` no IDE) e acrescenta as músicas em `SongIndex` e no `Music_InitData`. O `imported.json` da pasta vai no mesmo commit.
5. `python tools/check/validate.py` e `python tools/test/run.py boot` (compila e confere que o GameMaker aceita os arquivos).
6. Trocar um gráfico: substitua o arquivo em `incoming/` e importe de novo; o que saiu da pasta sai do projeto. Desfazer: `--remove`.
7. Paleta de um inimigo (cores por fase): recolorações em `palettes/<Nome>/1.png, 2.png...`, cada uma o mesmo quadro de um sprite da família pintado com outras cores. O relatório diz quantas cores e variantes saíram; erro se uma cor virar duas. A variante da fase escolhe a coluna com `ColorIndex` (receita "Variante de inimigo por fase").
8. Testar o importador sem gráficos novos: `python tools/import/make_example.py`, `python tools/import/import_region.py tools/import/out/example`, `python tools/test/run.py boot` e `--remove` no fim. A faixa de exemplo passa pelo `sTiles`: depois do `--remove` os pixels voltam iguais, mas os PNGs são regravados; restaure com `git checkout -- game/sprites/sTiles game/tilesets/Tileset/output_tileset.png` para o `git status` voltar limpo.

## Tiles e sons da ROM para uma região

Para a região usar peças do ALttP sem esperar os gráficos do Guilherme (F6b). Precisa da ROM e do zelda3 ao lado do repositório; se faltarem no PC, peça ao Guilherme.

1. Escolha as áreas do overworld: `python tools/alttp/owdump.py areas` e `png <área> --scale 0.5` (ficha `docs/ref/alttp-overworld.md`). O exterior do Castelo de Hyrule é a área 0x1B.
2. `python tools/alttp/owdump.py tiles 0x1b [outras] --region <regiao>` grava `incoming/<regiao>/tiles/tiles.png` e `tiles.json` (tiles de 8x8 já coloridos, uma vez só cada, com a classe tirada do atributo da ROM, e os blocos de 16x16 de cada área) e desenha os blocos em ordem em `tools/alttp/out/tiles_<regiao>_blocks.png`. Rodar de novo com mais áreas só acrescenta; `--fresh` recomeça (muda os números). `--transparent` deixa a cor 0 transparente em vez da cor de fundo da área.
3. Efeito sonoro: ache no zelda3 onde o jogo toca o efeito (`sound_effect_1 = 54` em `OverworldOverlay_HandleRain` é o trovão; `sound_effect_ambient` vai na porta 1, `sound_effect_1` na 2, `sound_effect_2` na 3) e rode `python tools/alttp/sfx.py <porta> <número> incoming/<regiao>/sounds/<Nome>.wav`. A primeira vez compila o `musicdump.c` (`tools/alttp/build.py`; sem compilador, `python -m pip install --user ziglang`) e pede o `zelda3_assets.dat` (`python assets/restool.py --extract-from-rom` na pasta do zelda3, com PyYAML).
4. `manifest.json` com `"name"` igual ao nome da fase (`CastleTop`), para os assets saírem `ts_CastleTop`, `Sound_Thunder`.
5. `python tools/import/import_region.py <regiao>`: tileset `ts_<Regiao>` com a textura, `datafiles/data/tiles/<Regiao>.json`, `Sound_<Nome>`.
6. Na ficha: `RegionTiles = "<Regiao>"`. Quem pinta são as salas pintadas (receita "Sala pintada com o tileset da região", F12b-1) ou o código da região, com `RegionTiles_PaintBlock`; o passo `paint` dos cenários pinta blocos numa sala para ver (cenário `region_tiles`).
7. Paredes e piso de dungeon com peças da ROM: exporte a faixa do tema mais próximo (`import_region.py --export-band Castle`), recombine por cima as peças de `tiles.png` sem mudar a arrumação, ponha como `incoming/<regiao>/tileset.png` com `"tileset": {"base": "Castle"}` e importe; na ficha, `TilesBand = "<Regiao>"` com `Theme` do tema base. É visual: prévia ao Guilherme antes.

## Estágio alternativo (variante de capítulo, ex.: topo do castelo no capítulo 2)

Como os níveis são montados hoje:

* Tudo o que muda de um nível para outro está na ficha de fase, `game/scripts/__Levels/__Levels.gml` (`global.LevelDefs`, um bloco por nível; cada campo tem comentário no `Level_Create`). Detalhes em `docs/dev/engine-notes.md` ("Level sheet" e "Branched exits").
* A run é uma sequência de capítulos (o `Depth` da ficha); as fases com o mesmo `Depth` são variantes do capítulo. Uma variante entra na run pelas saídas das fases do capítulo anterior: a `NextPool` de cada uma (`[[fase, peso], ...]`) sorteia para onde cada saída leva. Enquanto a `NextPool` de uma fase tiver um destino só, ela não sorteia nada e sai igual a antes da F4b.
* Cada nível escolhe uma classe de dungeon (`Class`): um conjunto de layouts em `data_d` (grade de salas, portas, escadas) e de salas em `game/datafiles/data/rooms/` (templates do Tiled, por classe e subclasse).
* O visual vem dos tiles do DoI (`sTiles`, linhas do tema `Theme` em `LevelTilesY`) desenhados a partir dos templates, mais as regras de decoração de cada tema (`switch(LevelDef.Theme)`). Os inimigos vêm da lista `Enemies` da ficha (objeto e peso).
* A saída do nível não é uma sala: é uma porta com status `Exit` na parede de cima ou de baixo de uma sala (a classe de templates Stairs é outra coisa, as escadas internas entre os dois andares de uma sala). O desenho dela vem do `ExitLook` da fase de destino.

Passos:

1. Novo valor no fim de `DungeonLevel` e uma entrada no `Levels_Init`. Copie a entrada do nível mais parecido e mude o que for diferente: `Name`, `Depth` (o capítulo do qual ela é variante), `Theme` e `EnemyStats` do nível cujo visual e inimigos ele usa (`DungeonLevel.Castle` no topo do castelo), `Class`, `Song`, `Enemies`, escuridão, água, obstáculos. `Next` (e, se o próximo capítulo tiver variantes, `NextPool`) aponta para o próximo capítulo. O `Level_Create` tira do índice do enum o `Depth`, o `Theme`, o `BaseTheme`, o `EnemyStats`, o `Next` (índice + 1) e o `StartDir` (pela paridade), e o índice de uma fase nova não bate com o capítulo: escreva todos, com o `StartDir` igual ao das outras variantes do capítulo. Conserte também a macro `DungeonLevels` (`__Dungeon.gml`, hoje sem uso).
2. Caminho: acrescente a fase nova na `NextPool` de cada fase do capítulo anterior, com o peso que dá a chance desejada (ex.: Hyrule Castle `[[DungeonLevel.CastleBasement, 2], [<nova>, 1]]` leva ao topo em 1 de cada 3 saídas). Isso já liga o sorteio de quantas saídas a fase tem e se a extra fica escondida (`ExitCount`, `ExitHidden`, padrão na ficha).
3. Visual da saída: `ExitLook` na entrada da fase nova (`"StairsDown"` é o padrão, `"StairsUp"` a escadaria para cima). Para um visual que ainda não existe, acrescente uma entrada em `ExitLooks_Init` (`__Doors.gml`): uma função que desenha a viga e o vão da porta de saída em cima e embaixo, o som de saída, a animação do Link (`LinkAnim`: quatro sprites `global.LinkSpr_<LinkAnim>_Top1/_Bottom1/_Top2/_Bottom2` criadas em `LinkSprites_Construct` e apagadas em `LinkSprites_Destroy`; `LinkSprite_Remix` deriva uma de outra existente, escolhendo, deslocando e espelhando quadros), o som de chegada (`ArriveSound`), o vão por onde o Link chega na fase seguinte (`Entrance`, a coluna do tile de decoração em cima e embaixo) e o ícone do mapa. O Link deve sempre acompanhar os degraus desenhados no vão, na saída e na chegada. Nem o gerador nem o Link mudam.
4. Layouts: no editor de dungeons (`editors/dungeon-editor`) ou gerando o JSON do `data_d` direto.
5. Salas: um conjunto de salas da região (receita "Conjunto de salas de uma região") e `RoomSet` na ficha. Sem conjunto, a fase usa os templates compartilhados com o tema dela.
6. Clima: a chuva e o relâmpago do começo da run estão no `oIntro` (gotas `oRainDrop`, respingos `oRainSplash`, flash nos alarmes 1 e 2, som `Sound_Rain`). Para outra região, extraia a chuva do `oIntro` para um controlador próprio (veja `docs/regioes/topo-do-castelo.md`).
7. Inimigos: reaproveite os do castelo; é só a lista `Enemies` da entrada, com `EnemyStats` de um nível onde eles existem. Os soldados funcionam em qualquer fase (pegam a variante padrão); para outra cor, energia ou ataque, ponha a variante na própria ficha: `EnemyVariants = {oEnemy_Soldier_Simple: {HeadIndex: SoldierHead.Normal, ColorIndex: SoldierColor.Red, Energy: 1, Attack: 0.5}}` (receita "Variante de inimigo por fase").
8. Teste: antes de existir a fase, dá para ver o sorteio com uma ramificação temporária no cenário (chave `"levels"`, como em `tools/test/scenarios/branch_exits.json`); com ela pronta, folha de contato da fase anterior com várias sementes e o passo `exit` para atravessar cada saída.
9. Cenário de referência `ref_NN_<Fase>.json` para a fase nova (veja "Comparar antes e depois").

## Inimigo novo por arquétipo

Para inimigo simples (anda, persegue, corre, investe), sem código próprio (roadmap F7). Campos e movimentos no topo de `game/scripts/__EnemyArch/__EnemyArch.gml`; exemplos prontos lá mesmo (rato, cobra, caranguejo, Hover).

1. Sprites pelo kit de importação, com o nome `Enemy_<Nome>_<Ação>_<Direção>` (`_Left`, `_Right`, `_Up`, `_Down`); sem direção, um sprite só por ação. Cores por fase: recolorações em `palettes/Enemy_<Nome>/1.png, 2.png...` (veja `incoming/README.md`), que viram o `sEnemy_<Nome>_Pal`.
2. Objeto sem eventos, filho do `oEnemy_Archetype`, com o primeiro sprite como sprite do objeto: `gm_assets.obj('oEnemy_<Nome>', {}, sprite_name='sEnemy_<Nome>_Walk_Down', parent='oEnemy_Archetype', folder=('Enemies', 'folders/Objects/Characters/Enemies.yy'))` (em `tools/hub/gm_assets.py`).
3. `EnemyDataInit` em `Enemies_InitData` (energia, ataque, itens, pontos, efeitos das armas; copie a linha do inimigo mais parecido).
4. `EnemyArch(oEnemy_<Nome>, {...})` em `EnemyArch_Init`: `Vars` (tamanho, velocidades, água), `States` com `Move`, `Time` e `Next`, `Sprites`, `Palette`, `Recover`. Partir do rato (anda e para), da cobra (anda e corre) ou do Hover (investida) e mudar os números de `docs/ref/`.
5. Variante por fase, se houver: `EnemyVariant(oEnemy_<Nome>, {}, [[DungeonLevel.X, {ColorIndex: 1, Energy: 2}]])` em `EnemyVariants_Init`, ou `EnemyVariants` na ficha da fase.
6. O inimigo na lista `Enemies` da ficha da fase.
7. Teste: `python tools/check/validate.py`, e um cenário com `spawn` e `trace` (como `tools/test/scenarios/arch_patterns.json`) para ler no log se ele anda, para e vira como deveria. Movimento que o arquétipo ainda não tem (atirar, pular, voar em onda, se esconder): veja a F7 no `docs/roadmap.md`; até lá, inimigo assim continua com código próprio.

## Variante de inimigo por fase

O que um inimigo muda de uma fase para outra (cor, energia, ataque, cabeça e arma dos soldados, sprites) fica em `EnemyVariants_Init` (`__EnemyArch.gml`): `EnemyVariant(objeto, padrão, [[DungeonLevel.X, {...}], ...])`. Campos são variáveis do inimigo (`ColorIndex` escolhe a coluna da paleta), mais `Energy` (índice de energia) e, nos arquétipos, `Sprites`. Lista vira sorteio (`HeadIndex: [SoldierHead.Pig, SoldierHead.Demon]`). Uma fase pode ter a sua sem mexer na tabela: `EnemyVariants = {oEnemy_X: {...}}` na ficha. Ordem: a da ficha, a da fase de `EnemyStats`, a padrão. Inimigo que não é arquétipo precisa chamar `Enemy_ApplyVariant()` no `Create` (os soldados chamam).

## Conteúdo de outro Zelda (ex.: Minish Cap)

Ter os sprites e o código original ajuda muito, mas não é uma tradução 1 para 1:

* O código do original é de outra máquina (GBA, assembly ou decompilação em C) e conversa com o hardware dele (OAM, tilemaps, física em subpixels). Aqui cada inimigo é um objeto do GameMaker que precisa conversar com o DoI: estados (`EnemyState`), dano (`EnemyHitsToKill`, `Enemy_CheckHit`), drops, colisão com `oWall`, salas, pausa, iluminação e paletas.
* O que se aproveita direto: sprites e animações, padrões de movimento e ataque, tempos e números (vida, velocidade, dano), sons e músicas.
* Ordem sugerida: primeiro os sprites e um inimigo simples (andar e tocar no Link); depois os que atiram; por último o chefe, com sala própria.
* Os sprites entram pelo kit de importação (receita "Importar gráficos de uma região"), que já ajusta as cores e o contorno.
* Para cada inimigo novo: se ele cabe num arquétipo, vira dados (receita "Inimigo novo por arquétipo"); senão, objeto filho do inimigo do DoI mais parecido, sprite por direção e estado, `EnemyDataInit` com energia e ataque, e o inimigo na lista `Enemies` da ficha do nível onde ele aparece.
