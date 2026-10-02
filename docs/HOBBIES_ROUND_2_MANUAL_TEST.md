# Hobbies — Etapa 14 Rodada 2

Esta rodada consolida os 10 Hobbies como sistemas jogáveis e substitui a interface piloto pela aba definitiva em identidade **Conexões — Cozy Arcade Journal**.

## Entregas da rodada

- Dez Hobbies oficiais continuam na ordem fixa: Leitura, Academia, Teatro, Meditação, Videogames, Música, Culinária, Fotografia, Oratória e Programação.
- Cinco Hobbies começam disponíveis e cinco começam bloqueados por requisitos reais.
- Todos usam o mesmo runtime central de treino.
- Cada Hobby mantém nível, XP, ciclo, progresso parcial, estado ativo, ciclos completos e tempo ativo independentes.
- Tempo é compartilhado com Empregos por reservas `job:*` e `hobby:*`.
- Hobbies não recebem XP offline nesta rodada.
- Nível 10 vira **DOMINADO**, encerra o treino e libera Tempo.
- A aba Hobbies agora possui cabeçalho, resumo, filtros, cards definitivos, barras separadas de treino/XP e feedback local.

## Roteiro — novo save

1. Abrir a aba Hobbies.
2. Confirmar 10 cards.
3. Confirmar cinco disponíveis: Leitura, Academia, Teatro, Meditação e Videogames.
4. Confirmar cinco bloqueados: Música, Culinária, Fotografia, Oratória e Programação.
5. Conferir o resumo:
   - Ativos: 0
   - Tempo livre: 6 / 6
   - Dominados: 0 / 10
   - Nível total: 10
6. Iniciar Leitura.
7. Confirmar Tempo livre 4 / 6.
8. Observar a barra de treino.
9. Confirmar +2 XP ao completar ciclo.
10. Pausar Leitura.
11. Confirmar progresso congelado.
12. Retomar Leitura.
13. Confirmar continuidade do ciclo.

## Roteiro — desbloqueios

1. Elevar Leitura ao nível 2.
2. Confirmar Música disponível e parada.
3. Elevar Meditação ao nível 2.
4. Confirmar Culinária disponível e parada.
5. Elevar Leitura ao nível 3.
6. Confirmar Fotografia disponível e parada.
7. Elevar Teatro ao nível 3.
8. Confirmar Oratória disponível e parada.
9. Elevar Leitura ao nível 4.
10. Confirmar Programação disponível e parada.

## Roteiro — Tempo compartilhado

1. Confirmar Tempo livre 6 / 6.
2. Iniciar Entregas.
3. Confirmar Tempo livre 4 / 6.
4. Iniciar Leitura.
5. Confirmar Tempo livre 2 / 6.
6. Iniciar Academia.
7. Confirmar Tempo livre 0 / 6.
8. Tentar iniciar outro Hobby.
9. Confirmar feedback local de Tempo insuficiente no card.
10. Pausar Entregas ou um Hobby.
11. Confirmar liberação correta do Tempo sem afetar as outras atividades.

## Roteiro — nível 5

1. Usar DEV mínima.
2. Colocar Leitura no nível 4.
3. Deixar Leitura ativa.
4. Completar o nível.
5. Confirmar Leitura nível 5.
6. Confirmar custo de Tempo 1.
7. Confirmar liberação de exatamente 1 Tempo.

## Roteiro — domínio

1. Usar DEV mínima.
2. Colocar um Hobby próximo do nível 10.
3. Completar o nível.
4. Confirmar status **DOMINADO**.
5. Confirmar XP encerrado.
6. Confirmar Tempo 0 no card.
7. Confirmar reserva liberada.
8. Confirmar treino encerrado.
9. Confirmar botão de treino removido/desabilitado.
10. Confirmar que não existe nível 11.

## Roteiro — requisitos de Empregos

1. Abrir um Emprego bloqueado por Hobby.
2. Observar requisito pendente.
3. Desenvolver o Hobby correspondente.
4. Voltar aos Empregos.
5. Confirmar requisito atualizado.
6. Confirmar desbloqueio somente quando os demais requisitos também estiverem cumpridos.

## Roteiro — responsividade

Validar manualmente:

- 1024×768
- 1152×648
- 1280×720
- 1366×768
- 1440×900
- 1600×900
- 1920×1080
- 2560×1440

Confirmar:

- nenhuma sobreposição;
- nenhum RenderFlex overflow;
- card legível;
- filtros legíveis;
- resumo legível;
- barras de treino e XP legíveis;
- HUD fixo;
- dock fixo;
- scroll interno da aba Hobbies.

## Fora do escopo desta rodada

- Boost de Hobbies por Cerejas;
- XP offline de Hobbies;
- resumo offline de Hobbies;
- save/migração definitiva específica da Etapa 14;
- DEV completa dos Hobbies;
- efeitos avançados das habilidades;
- estatísticas e conquistas completas.
