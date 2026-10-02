# Hobbies — Etapa 14 Rodada 1

Esta rodada entrega o catálogo definitivo dos 10 Hobbies e o motor central de treino.

## Catálogo oficial

Ordem fixa:

1. Leitura
2. Academia
3. Teatro
4. Meditação
5. Videogames
6. Música
7. Culinária
8. Fotografia
9. Oratória
10. Programação

Começam desbloqueados: Leitura, Academia, Teatro, Meditação e Videogames.

Dependem de requisitos:

- Música: Leitura nível 2
- Culinária: Meditação nível 2
- Fotografia: Leitura nível 3
- Oratória: Teatro nível 3
- Programação: Leitura nível 4

## Regras da rodada

- Todos os Hobbies têm níveis 1 a 10.
- Cada ciclo completo concede 2 XP.
- Nível 1 exige 10 XP para o nível 2.
- Ciclos parciais não concedem XP.
- O progresso parcial é preservado ao pausar/retomar.
- O custo de Tempo é 2 nos níveis 1–4, 1 nos níveis 5–9 e 0 no nível 10.
- No nível 10 o Hobby fica DOMINADO, para automaticamente, zera XP real e libera Tempo.
- Hobbies não geram dinheiro.
- Hobbies não consomem dinheiro por ciclo.
- Offline de Hobbies ainda não concede XP nesta rodada.

## Validação manual sugerida

1. Abrir a aba Hobbies.
2. Confirmar os 10 Hobbies na ordem oficial.
3. Iniciar Leitura e confirmar reserva de 2 Tempo.
4. Pausar Leitura e confirmar liberação do Tempo.
5. Retomar Leitura e confirmar preservação da barra parcial.
6. Completar 5 ciclos de Leitura e confirmar nível 2.
7. Confirmar desbloqueio automático de Música.
8. Ativar Entregas + Leitura + Academia e confirmar Tempo 0 / 6.
9. Tentar iniciar outro Hobby e confirmar falha controlada sem reserva parcial.
10. Definir um Hobby no nível 10 via DEV e confirmar estado DOMINADO.

## DEV mínima

A aba DEV inclui controles mínimos de Hobbies:

- desbloquear;
- iniciar/pausar/retomar;
- definir nível;
- adicionar XP;
- completar ciclo;
- processar 10 segundos;
- processar 1 minuto;
- definir fração do ciclo;
- reset individual.

Todos os controles usam o runtime, Tempo e save reais.
