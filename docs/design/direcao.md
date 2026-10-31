# Direção de game design

Este documento é o guia para as decisões artísticas e de design. O Guilherme dá liberdade criativa, desde que tudo pareça ter saído de um Zelda 2D, em especial de A Link to the Past. Quando algo não estiver coberto aqui, a pergunta é: "isso existiria no ALttP ou num Zelda 2D da Nintendo?". Se a resposta for não, repense.

## Conceito (Guilherme, out/2026)

**O DoI é um Zelda top down novo a cada run.** É o lugar onde o fã de Zelda experimenta tudo o que há na franquia num jogo só, com infinitas combinações. Quando o Zelda e o roguelike brigam, o Zelda ganha.

* **A fantasia é explorar e descobrir**, não montar uma build. O prazer de uma boa run é ter achado segredos e entendido os lugares, não ter ficado forte demais.
* **Itens como nos Zeldas.** Cada item se comporta quase exatamente como no jogo de origem: uns abrem caminhos, outros mudam o combate. Adaptação só quando o formato pede (como as kinstones do Minish Cap).
* **Itens abrem segredos, nunca a progressão.** Nenhum item é necessário para terminar uma fase ou a run. Eles abrem lugares opcionais com recompensa: a varinha de fogo que o jogador escolheu levar na fase 1 acende as tochas de um puzzle opcional na fase 7, que leva a um item ou outro prêmio. O inventário limitado é parte do jogo (quase um survival horror): escolher o que carregar é uma aposta.
* **Um jogo como espinha por run.** Cada run tem um Zelda como espinha, e os outros entram como desvios e ramificações pelas saídas da fase (saída X, Y ou as duas, e o jogador escolhe). Cada área tem as suas áreas seguintes e os seus ramos.
* **Formato da run mantido.** O tamanho atual da run está bom, e salvar no meio continua como hoje.
* **Morreu, acabou.** Sem rede de segurança além das que o próprio Zelda tem (fada na garrafa).

## Pilares

1. **Parece ALttP.** Quem jogou o original reconhece salas, sons, menus e o jeito dos personagens.
2. **Roguelike honesto.** Cada run é curta e diferente; o progresso permanente é pequeno e conquistado (skins, itens iniciais, estátuas), nunca comprado nem óbvio.
3. **Segredos como recompensa.** Descobrir é parte da graça (modelo Binding of Isaac): o jogo não explica o que libera, só comemora quando acontece.
4. **Pouco texto, muita clareza visual.** O jogador entende uma sala olhando para ela.

## Visual

* **Escala.** Tela de 256x224, tiles de 8x8 montados em blocos de 16x16, Link com cerca de 16x24. Objetos seguem a escala do original: pote 16x16, estátua de Armos 16x32, baú 16x16, chefes 32x32 ou maiores só quando são chefes. Nada fica "gigante" fora de contexto.
* **Perspectiva.** Vista de cima em 3/4: paredes de cima mostram a face; paredes laterais e de baixo aparecem como borda grossa. Objetos altos têm a parte de cima desenhada sobre o Link quando ele passa atrás, mas no hub preferimos que o Link não passe atrás deles.
* **Paleta.** Cores do SNES (32 níveis por canal, passos de cerca de 8), contorno escuro (quase preto) nos sprites, poucas cores por objeto (4 a 7). Ao trazer sprites de outros jogos (GBA, Game Boy), ajuste para essas regras: contorno escuro, paleta limitada, sem degradês suaves. O kit de importação (`incoming/README.md`) faz esse ajuste sozinho e avisa o que não conseguiu.
* **Assets.** Primeiro a ROM do ALttP, depois o DoI, depois outros Zeldas 2D. Desenhar do zero é o último recurso e deve imitar o estilo (veja os vasos e a toalha da banca do Flute Boy).
* **Salas.** Formas simples e quase sempre simétricas, com o tamanho de 1 ou 2 telas. Portas no meio das paredes. Decoração conta a função da sala: igreja tem bancos e vitrais; galeria tem pedestais e lamparinas; loja tem balcão e prateleiras.
* **Composição das salas.** Nada fica solto no meio do piso: cada peça segue um motivo das salas originais (cantos de cima, parede de cima, eixo do meio, paredes laterais, grade simétrica), em pares espelhados, com as portas e os caminhos livres. As salas criadas pelas ferramentas usam o catálogo de motivos medido nas salas do DoI (`tools/templates/motifs.py`); disposição nova entra no catálogo a partir de salas reais (do DoI, do ALttP ou de outro Zelda), nunca como coordenada inventada.
* **Salas pintadas com arte do ALttP.** A sala é montada com peças recortadas de uma área real (moldura, aberturas, decoração), para manter a luz e a perspectiva do original: as faces das muretas olham para o sul e a sombra cai do lado em que cai no ALttP. Por isso a sala pintada só aparece no original ou espelhada na horizontal; virar de cabeça para baixo ou girar fica para peças que não têm lado (Guilherme aprovou a sala do telhado assim, out/2026).
* **Mureta contínua e peças inteiras.** Numa sala pintada, a parede continua além da borda da sala, como no overworld do ALttP: duas salas vizinhas se ligam sem borda no meio. Toda peça vem inteira da ROM, com o contorno escuro; canto ou ponta montado com cor lisa parece cortado (Guilherme, out/2026).
* **Emendas só como a ROM mostra.** Entre salas pintadas vizinhas, cada encontro de blocos tem de existir no mapa original ou ser uma junção aprovada pelo Guilherme uma a uma. Emenda que não fecha não vira junção por padrão: o gerador evita o caso (muda a porta de lugar, sorteia outra disposição). Vão encostado em mureta e quinas cruzadas foram recusados (out/2026).
* **Salas especiais seguem a área.** Loja, tesouro, rupias, fada e as outras salas especiais combinam com a área onde aparecem: numa dungeon, o tema dela; numa região pintada, a moldura da região com os objetos da sala. Isso é feito pela ferramenta para toda região, não à mão (Guilherme, out/2026).
* **Natureza invadindo.** Numa construção ao ar livre, a natureza pode tomar parte do piso: manchas irregulares de grama com moitas ou uma árvore no meio, sempre como motivo de composição (eixo, pares espelhados, caminhos das portas livres), nunca peça solta. As bordas da grama vêm da ROM, com o chão de baixo trocado pelo piso da região (Guilherme, out/2026). Moita é sempre o objeto do DoI (`oBush`: corta com a espada, levanta, pode ter item), nunca tile de parede; a mancha de grama é piso (Guilherme, oitava rodada do R1).
* **Ao ar livre, sem portas de dungeon.** Passagem é um corte na mureta; trancada vira bloco com fechadura no corte, secreta vira parede rachada ou lisa que abre com bomba, e a porta que fecha até matar os inimigos não existe. Entrada e saída usam uma porta do overworld do ALttP com a animação dela (Guilherme, out/2026).
* **O modelo do DoI com a arte da região (Guilherme, out/2026, sexta rodada do R1).** Região pintada continua sendo o DoI: salas que mudam a cada run, com portas, trancas e seções, pintadas com os tiles da região. A ROM dá as peças e o jeito delas, não o mapa: a fase nunca vira uma cópia de uma área do original (os arredores do castelo em telas fixas, F18, foram recusados e desfeitos), nem muda de lugar ou de nome sem o Guilherme decidir sabendo o custo. Onde a passagem corta a mureta, a ponta é o canto da própria mureta da ROM, deslocado meio bloco se preciso, com a passagem da largura da porta; nunca corte reto. Onde a passagem atravessa uma borda fina, ela é um corredor com a mesma borda fina com contorno dos dois lados, igual nas duas salas que liga (sétima rodada, aprovado no jogo). Defeito de tile se corrige na peça, à mão, sem trocar o modelo da região nem criar ferramenta nova para isso. Piso e decoração vêm da parte da área que corresponde ao lugar: passarela do pátio não vai no telhado.
* **Luz e vida.** Elementos animados com moderação (fogo das lamparinas, água, chuva). Nada gira, pisca ou se mexe sem motivo dentro do mundo do jogo.

## Câmera e salas

* Troca de sala sempre no padrão das dungeons: a câmera rola e o Link dá alguns passos para dentro, chegando pela porta. Fade só para mudar de lugar (entrar e sair de um nível).
* Cada sala tem uma função clara. Se uma sala nova serve para a mesma coisa que outra, ela deve parecer diferente.

## Interface e som

* Menus usam as janelas e fontes que o DoI já tem (`sHUD_Window_Curse`, `global.MenuFont`, `global.Font_Small` só com maiúsculas).
* Sons do ALttP para cada ação: cursor (`Sound_Text`), confirmar (`Sound_TextDone`), voltar (`Sound_Throw`), erro (`Sound_Error`), item ganho (`Sound_ItemGet`), segredo (`Sound_Secret`). Não use som de escada para coisas que não são escadas.
* Música: temas do ALttP com intro e loop. O hub usa o tema do Santuário.

## Texto

* Em inglês, curto, no tom da Nintendo dos anos 90: gentil, um pouco engraçado, às vezes enigmático. Sem gírias atuais e sem quebrar a quarta parede além do que o ALttP já faz.
* NPCs falam uma ou duas frases. Dicas são indiretas ("I heard something rumble under the castle...") e nunca dizem a recompensa.
* Nomes de conquistas e itens são curtos e com trocadilho leve quando couber ("Worm Food", "Rich Kid").

## Hub (Santuário)

* É o lugar seguro entre as runs, como a casa do Link ou o santuário do original. Música calma, nenhum inimigo.
* Cresce com o progresso, como o hub de Hades: NPCs e salas novas aparecem conforme o jogador avança. Cada NPC tem uma função só (o Flute Boy cuida das skins).
* Funções novas entram pelo mundo, não por menus soltos: um personagem, um objeto ou uma sala que o jogador visita.

## Progresso, conquistas e segredos

* Recompensas permanentes são pequenas: aparência (skins) ou um empurrão no começo da run (itens iniciais). Nunca algo que deixa o jogo trivial.
* O que uma conquista pede pode ser visto (na galeria); o que ela dá é segredo até acontecer.
* Desafios (vida menor, mais inimigos, escuridão) existem para quem quer dificuldade e podem ser exigidos por conquistas.

## Conteúdo novo

* **Ferramenta antes de atalho.** O projeto é escalável e modular em tudo. Quando uma região pede o que as ferramentas não fazem, cria-se ou melhora-se a ferramenta (uma etapa do plano, com prova de que o resto continua igual); a região não é simplificada e não ganha uma solução de uma vez só. As alternativas da skill `nova-regiao` servem para o Guilherme decidir, não para o Claude escolher sozinho o caminho mais curto.
* **Capítulos e variantes.** A run é uma sequência de capítulos, como no Binding of Isaac: cada posição da run (o `Depth` da ficha de fase) é um capítulo, e um capítulo pode ter variantes (o capítulo 2 do Isaac pode ser Caves, Catacombs ou Flooded Caves). Toda região nova diz de qual capítulo é variante. Uma variante pode ser uma área externa da franquia (jardim, campina, floresta), não só uma dungeon.
* **Saídas.** Nada é garantido: pools com pesos sorteiam quantas saídas a fase tem (uma ou duas), se a extra fica escondida e para qual variante do próximo capítulo cada uma leva; muitas runs têm uma saída só. Duas saídas nunca ficam perto: uma de um lado do mapa, a outra do lado oposto, para quem corre muitas vezes nem achar a segunda. A extra pode ficar numa sala secreta atrás de uma parede que abre com bomba; a principal nunca fica escondida, para ninguém ficar preso sem bombas.
* **O visual da saída mostra o destino.** Ele vem da ficha da fase de destino, nunca fixo no gerador: escadaria para baixo é o padrão, escadaria para cima leva ao topo do castelo, e um destino ao ar livre pode ter, por exemplo, uma parede explodida. O jogador aprende a ler a saída antes de entrar. O Link sempre acompanha os degraus desenhados no vão (saindo e chegando), e quem sobe chega por uma escada que desce, como no ALttP.
* **Estágios alternativos** devem ser lugares que fazem sentido no mundo do ALttP ou de outro Zelda (topo do castelo, Palácio do Leste, Torre de Hera...), com inimigos e clima coerentes. Variação de um estágio existente reaproveita os inimigos dele.
* **Identidade da região (Guilherme, out/2026).** Nenhuma região pode ser só outra fase com inimigos e cores trocados. Toda região tem pelo menos: uma mecânica própria (escuridão com lamparina, gelo, correnteza, chão que cai, vento, água rasa e funda), uma arquitetura característica (formas de sala que só ela tem) e uma sala marco (um lugar memorável: altar, ponte, salão desabado). A spec da região diz quais são, e a região só é aprovada com os três. Área externa ou pintada é uma alavanca a mais, não a única: os Esgotos e as Catacumbas dividem as mesmas salas e se destacam pelo resto.
* **ALttP primeiro, até esgotar.** O conteúdo gira em volta do ALttP (dungeons, áreas externas, inimigos, itens) até ele se esgotar; outros jogos (Deku Tree, Minish Cap, Oracles) vêm só depois. Até lá eles servem de exemplo para manter as ferramentas modulares (nada preso ao formato do ALttP), não de próximo passo.
* **Ramos da run.** As ramificações podem se reencontrar (um ramo externo volta às Catacumbas) ou terminar a run em si mesmas, com final e chefe próprios, como os caminhos alternativos do Binding of Isaac.
* **Outros Zeldas** (Minish Cap, Link's Awakening, Oracle) entram como "regiões" inteiras: tiles, inimigos, chefe e música da mesma origem, convertidos para as regras visuais acima. Não misture um inimigo de Minish Cap num estágio do ALttP sem motivo.
* **Itens novos** seguem a lógica de Zelda: cada item abre uma possibilidade (um caminho, um jeito de lutar), não só aumenta números.

## Evitar

* Copiar uma sala inteira para outro uso.
* Objetos fora de escala, girando, piscando ou com efeitos modernos (brilho, partículas demais, tremer de tela sem motivo).
* Revelar recompensas e segredos antes da hora.
* Decoração de outro tema (natalina, moderna, de loja onde não há loja).
* Menus que substituem coisas que poderiam acontecer no mundo do jogo.
* Textos longos ou explicativos demais.

## Antes de entregar algo visual

1. A prévia passa no teste "isso existiria no ALttP"?
2. A escala está certa em relação ao Link?
3. As cores e o contorno seguem a paleta?
4. O Link anda pela sala sem entrar em paredes nem ficar atrás do que não deveria?
5. Os sons e as transições são os do jogo?
