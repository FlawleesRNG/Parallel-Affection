# Rodada 5B — Validação manual de save, migração e recuperação dos Empregos

Este roteiro valida o save global definitivo dos Empregos sem alterar assets, balanceamento ou UI aprovada.

## Schema atual

- Versão atual do save: `5`.
- Empregos continuam dentro do save global.
- A chave persistente de cada Emprego é o `jobId` oficial.
- Dados derivados do catálogo, como nome, cargo, recompensa, duração e custo de Tempo, não são persistidos.

## Campos persistidos por Emprego

- `level`
- `experience`
- `cycles`
- `continuousPayments`
- `active`
- `cycleStartedAt`
- `accumulatedCycleProgressMs`
- `lastProcessedAtUtc`
- `lifetimeMoneyEarned`
- `activePlayTimeMs`
- `firstStartedAtUtc`
- `hasBeenStarted`
- `isUnlocked`
- `remainingBoostActiveTimeMs`
- `boostReferenceTimestampUtc`

## Roteiro — save normal

1. Abrir o jogo em ambiente de teste.
2. Iniciar dois Empregos.
3. Aguardar ciclos de dinheiro e XP.
4. Pausar um Emprego.
5. Ativar impulso no outro.
6. Fechar o jogo.
7. Reabrir.
8. Confirmar:
   - saldo preservado;
   - XP preservado;
   - níveis preservados;
   - Tempo reconstruído;
   - Emprego pausado continua pausado;
   - Emprego ativo continua ativo;
   - impulso restante preservado/consumido apenas se ativo.

## Roteiro — nível 10

1. Colocar `Entregas de Bairro` no nível 10 via DEV.
2. Deixar o Emprego ativo.
3. Confirmar que o custo de Tempo é 0.
4. Fechar e reabrir.
5. Confirmar:
   - nível 10 preservado;
   - XP normalizado para 0;
   - fração da produção contínua preservada;
   - pagamentos offline corretos;
   - nenhum nível 11.

## Roteiro — offline + restart

1. Iniciar um Emprego.
2. Fechar o jogo.
3. Aguardar um período offline.
4. Abrir e conferir o resumo offline.
5. Fechar o resumo.
6. Fechar o jogo imediatamente.
7. Abrir novamente.
8. Confirmar que o mesmo período offline não foi pago duas vezes.

## Roteiro — save antigo

Usar apenas fixture/cópia de teste.

1. Carregar um save antigo com apenas `neighborhood_deliveries`.
2. Confirmar que os outros oito Empregos foram criados com defaults.
3. Confirmar que Entregas preservou nível, XP, ciclos, progresso parcial e dinheiro vitalício.
4. Confirmar que o saldo global não recebeu novamente `lifetimeMoneyEarned`.
5. Fechar e abrir novamente.
6. Confirmar idempotência.

## Roteiro — corrupção recuperável

Usar apenas ambiente de teste.

1. Gerar um save válido.
2. Criar backup.
3. Corromper a cópia principal.
4. Carregar.
5. Confirmar que o backup foi usado.
6. Confirmar que a aplicação não quebrou.
7. Se não houver backup válido, confirmar estado novo seguro.

