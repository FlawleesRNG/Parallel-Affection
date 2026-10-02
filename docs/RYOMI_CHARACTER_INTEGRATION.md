# Integração da personagem Ryomi

Ryomi (`ryomi`) é a única personagem jogável desta versão. Ela tem 27 anos,
produz música e apresenta um programa de rádio noturno em uma cidade brasileira
fictícia.

## Dados e progresso

- Perfil: `assets/data/characters/ryomi.json`
- Estágios: `assets/data/relationship_stages/ryomi_stages.json`
- Falas curtas: `assets/data/dialogue/ryomi_lines.json`
- Presentes: `assets/data/gifts/gifts.json`
- Encontros: `assets/data/dates/ryomi_dates.json`
- Galeria: `assets/data/scenes/ryomi_scenes.json`

Os dados balanceáveis de execução ficam em `lib/data/idle_balance.dart`. O save
v4 migra o progresso legado de `lia` para `ryomi`, preservando afeição, estágio,
presentes, encontros e cenas.

## Estado da primeira arte oficial

Caminho registrado:

```text
assets/images/characters/ryomi/poses/ryomi_stage_01.png
```

O perfil mantém o arquivo como `defaultPoseAsset`, `stage_01` aponta para ele e
os demais estágios podem herdá-lo enquanto não possuírem pose própria. Um
`portraitAsset` específico ainda não existe; no futuro, a pose poderá fornecer
um enquadramento temporário de cabeça e ombros.

A interface atual renderiza o arquivo diretamente como arte principal da Ryomi,
sem silhueta, texto de pendência ou substituição visual. A pose é exibida com
`BoxFit.contain`, `Alignment.bottomCenter`, `FilterQuality.high`,
`isAntiAlias: true` e `gaplessPlayback: true`, preservando proporção e usando
limites responsivos de tamanho.

O arquivo original foi preservado: não foi editado, redimensionado, recortado
nem substituído. Um retrato dedicado em `portraits/ryomi_portrait.png` terá
prioridade sobre o recorte automático quando existir.

## Temas visuais

A identidade global do jogo fica em `GameVisualTheme`: HUD, fundo geral, menu
inferior, botões globais, modais e recursos. Ela segue a direção de cartões
ilustrados, adesivos colecionáveis e papelaria aconchegante, com paleta natural
centralizada nos tokens oficiais.

A identidade de Ryomi fica em `RyomiVisualTheme`, implementada sobre
`CharacterVisualTheme`: cenário, luz, moldura, balão, cor de vínculo e detalhes
de estúdio/rádio.

Essa separação impede que rádio, cidade noturna e ondas sonoras virem a
identidade visual de todo o jogo. Futuras personagens devem ganhar seus próprios
temas de personagem sem reconstruir o shell global.

## Separação da interface global

O shell global usa linguagem de coleção, cartões e adesivos. O destino antes
chamado `Mais` agora aparece como `Extras`, e a loja exibe categorias visuais
leves sem adicionar novos sistemas. Elementos de rádio e música permanecem
restritos ao cenário, falas e detalhes temáticos da Ryomi.

## Rota e cenas

Os dez estágios são:

1. Desconhecida
2. Mal-entendido
3. Conhecida
4. Colega
5. Amiga
6. Próxima
7. Interessada
8. Encantada
9. Apaixonada
10. Pessoa especial

A progressão combina afeição, hobby Música, dinheiro total, presentes e
encontros. `storyEpisodeId` é opcional e, nesta versão, apenas registra um
episódio desbloqueado e apresenta uma notificação placeholder. Falas, escolhas,
flags e variações continuam isoladas do módulo idle.

## Estrutura futura de assets

```text
assets/images/characters/ryomi/
  portraits/ryomi_portrait.png
  poses/ryomi_stage_01.png ... ryomi_stage_10.png
  expressions/
  scenes/
```

Não adicione processamento automático que sobrescreva a arte de origem.
