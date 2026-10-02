# Projeto Conexões

Vertical slice de um idle dating clicker original em Flutter. Ryomi, 27 anos,
produtora musical e apresentadora de rádio noturno, é a primeira e única
personagem desta versão.

## Experiência atual

- Game shell único, sem AppBar ou Scaffold aninhado nas áreas internas.
- Interface desktop-first em três áreas e layouts próprios para tablet e celular.
- Barra compacta de recursos e dock com Ryomi, Empregos, Hobbies, Conquistas,
  Loja e Extras.
- Quatro ações centrais: Conversar, Interagir, Presentear e Encontro.
- Presentes em modal com grid, resumo e quantidades 1, 10, 100 e máximo.
- Encontros em modal com custos, duração, blocos, recompensa e motivo de bloqueio.
- Nove empregos oficiais e dez hobbies oficiais em telas independentes.
- Dez estágios de relacionamento, de Desconhecida a Pessoa especial.
- Meta de afeição inicial de 100 pontos, separada do indicador de estágio.

## Sistemas preservados

- Seis blocos de tempo iniciais e alocação simultânea de atividades.
- Ciclos em tempo real, promoções, níveis e desbloqueios cruzados.
- Simulação por timestamp, inclusive minimizada e offline por até oito horas.
- Dinheiro, diamantes, multiplicadores, prestígio e conquistas.
- Afeição, conversa com recarga, interação, presentes e encontros.
- Save local v5 com migração tolerante, saneamento e recuperação por backup.
- Aba DEV exclusiva de sessão ROOT para inspecionar e testar os sistemas reais,
  incluindo o painel completo de Empregos da Rodada 6A e a DEV mínima de
  Hobbies da Etapa 14 Rodada 1.
- Base narrativa isolada com episódios, flags, histórico e variações futuras.
- Tema visual global separado do tema individual da Ryomi.
- Direção visual global de cartões ilustrados, adesivos colecionáveis e
  papelaria aconchegante.

## Arquitetura

```text
lib/app/                                  inicialização e GameController
lib/core/layout/game_breakpoints.dart     breakpoints compacto/médio/amplo
lib/core/design/                          fachada do sistema de design
lib/core/theme/                           tokens, tema Material e temas visuais
lib/data/idle_balance.dart                definições e balanceamento
lib/features/game_shell/                  shell, barra, dock e áreas secundárias
lib/features/characters/                  gameplay da Ryomi e modais
lib/features/activities/                  cards, Empregos e Hobbies
lib/services/simulation_service.dart      ciclos e progresso offline
lib/models/narrative_models.dart          contratos narrativos futuros
test/game_shell_widget_test.dart          breakpoints, modais e navegação
test/root_dev_jobs_test.dart              ROOT/DEV dos Empregos
```

O módulo idle controla tempo, dinheiro, atividades, afeição, presentes,
encontros e requisitos. O módulo narrativo permanece separado e é integrado
somente pela progressão da personagem. Um estágio pode declarar
`storyEpisodeId`; nesta versão isso registra o desbloqueio e abre apenas um
placeholder.

## Direção visual

A identidade global do jogo usa uma paleta natural e clara:

- marfim suave `#F5F1E8`;
- areia clara `#EAE2D5`;
- branco aveia `#FFFDF7`;
- bege rosado `#F3E8DF`;
- ameixa escura `#39323B`;
- cores de sistema foscas para Relação, Empregos, Hobbies, Conquistas, Loja,
  Mais e recursos.

Os componentes globais são tratados como cartões, etiquetas e adesivos de jogo,
com bordas visíveis, sombras quentes curtas, botões preenchidos em repouso e
padrões discretos feitos em Flutter. Rádio, música e cidade noturna ficam
confinados ao tema visual da Ryomi.

## Loja e Extras

A loja usa categorias visuais de vitrine (`Presentes`, `Melhorias`, `Blocos` e
`Cosméticos futuros`) apenas como organização de interface nesta versão. Isso
não adiciona novas mecânicas nem altera economia, progressão ou salvamento. O
antigo destino `Mais` foi renomeado para `Extras` para combinar melhor com a
direção colecionável e amigável do jogo.

## Arte da Ryomi

O arquivo
`assets/images/characters/ryomi/poses/ryomi_stage_01.png` está registrado como
pose padrão, fallback de estágios e primeira arte oficial integrada. A camada
visual carrega esse asset diretamente com `Image.asset`, `BoxFit.contain` e
alinhamento inferior central. O arquivo original não foi alterado.

Consulte
[docs/RYOMI_CHARACTER_INTEGRATION.md](docs/RYOMI_CHARACTER_INTEGRATION.md).

## Auditoria de Empregos

A Etapa 13 possui roteiros manuais em `docs/JOBS_ROUND_*`. O fechamento final
da Rodada 6B está documentado em
[docs/JOBS_ROUND_6B_FINAL_AUDIT.md](docs/JOBS_ROUND_6B_FINAL_AUDIT.md).

## Hobbies

A Etapa 14 Rodada 1 introduz o catálogo definitivo dos 10 Hobbies e o motor
central de treino: iniciar, pausar, retomar, reservar Tempo, completar ciclos,
ganhar XP, subir níveis, desbloquear Hobbies dependentes e parar no nível 10
como DOMINADO.

A Rodada 2 consolida os 10 Hobbies jogáveis e troca a interface piloto pela
aba definitiva com cabeçalho, resumo, filtros, cards, barras separadas de
treino/XP e feedback contextual local.

A Rodada 3 adiciona o sistema oficial de Habilidades derivadas dos Hobbies e
o impulso individual x2 por 5 Cerejas. Habilidades não possuem XP, nível ou
save próprios: o nível é sempre lido do Hobby fonte. O impulso de Hobby dura
10 minutos de treino ativo, não empilha, não altera o XP por ciclo, congela
quando o Hobby é pausado e é encerrado ao dominar o Hobby.

A Rodada 4 ativa o progresso offline completo dos Hobbies dentro do mesmo
período offline global dos Empregos. Hobbies ativos treinam offline até o
limite de 8h, Hobbies pausados congelam, boosts x2 são consumidos apenas
durante tempo processável, desbloqueios podem ocorrer offline e o save global
passa para o schema definitivo v6 sem persistir Skills derivadas.

Roteiros manuais:

- [docs/HOBBIES_ROUND_1_MANUAL_TEST.md](docs/HOBBIES_ROUND_1_MANUAL_TEST.md)
- [docs/HOBBIES_ROUND_2_MANUAL_TEST.md](docs/HOBBIES_ROUND_2_MANUAL_TEST.md)
- [docs/HOBBIES_ROUND_3_MANUAL_TEST.md](docs/HOBBIES_ROUND_3_MANUAL_TEST.md)
- [docs/HOBBIES_ROUND_4_MANUAL_TEST.md](docs/HOBBIES_ROUND_4_MANUAL_TEST.md)

## Executar

```bash
flutter pub get
dart analyze
flutter test
flutter run -d windows
```

## Limitações

A loja usa categorias visuais leves sem novos sistemas ativos; as cenas usam
placeholders e os episódios narrativos ainda não contêm falas ou escolhas
ramificadas. Ferramentas de debug aparecem somente em builds de depuração.
