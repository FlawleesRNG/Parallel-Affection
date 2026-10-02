# Rodada 6B — Fase 13.12

Auditoria final manual da Etapa 13 — Sistema de Empregos.

## Roteiro 1 — Jogo novo

1. Abrir o jogo manualmente.
2. Entrar em **Empregos**.
3. Confirmar exatamente 9 cards.
4. Confirmar **Entregas de Bairro** disponível desde o início.
5. Confirmar demais empregos bloqueados com requisitos legíveis.
6. Iniciar Entregas, observar ciclo, pagamento, XP, pausa e retomada.

## Roteiro 2 — Progressão

1. Usar gameplay real ou DEV/ROOT.
2. Subir Entregas para nível 2.
3. Confirmar desbloqueio de Panfletagem sem iniciar automaticamente.
4. Subir Panfletagem para nível 3 e atingir R$ 250.
5. Confirmar desbloqueio permanente de Cafeteria.
6. Gastar/baixar dinheiro via DEV e confirmar que Cafeteria não volta a bloquear.

## Roteiro 3 — Tempo

1. Ativar trabalhos até reservar 6/6 Tempo.
2. Tentar iniciar outro emprego com custo maior que o disponível.
3. Confirmar feedback contextual de Tempo insuficiente.
4. Pausar um emprego e confirmar liberação de Tempo.
5. Levar emprego ativo ao nível 10 e confirmar custo 0.

## Roteiro 4 — Boost

1. Iniciar um emprego.
2. Comprar impulso x2 por 5 Cerejas.
3. Confirmar desconto exato e duração de 10 minutos ativos.
4. Pausar e confirmar que o boost congela.
5. Retomar e confirmar que o boost continua.
6. Tentar comprar outro boost durante o ativo e confirmar que não empilha.

## Roteiro 5 — Domínio

1. Usar DEV/ROOT para definir um emprego no nível 10.
2. Confirmar **DOMÍNIO MÁXIMO**.
3. Confirmar XP zero/sem nível 11.
4. Confirmar custo de Tempo 0.
5. Confirmar pagamento contínuo de 1 segundo em velocidade x1.

## Roteiro 6 — Offline

1. Deixar um ou mais empregos ativos.
2. Fechar manualmente o jogo.
3. Aguardar ou simular pela DEV.
4. Abrir manualmente e confirmar resumo offline único.
5. Confirmar dinheiro, XP, level up, boosts e limite de 8 horas.
6. Reabrir novamente e confirmar que o mesmo período não é pago duas vezes.

## Roteiro 7 — Save

1. Preparar vários empregos com níveis, boosts, ciclos parciais e desbloqueios.
2. Salvar.
3. Fechar e reabrir manualmente.
4. Confirmar persistência dos estados reais.
5. Confirmar que ROOT/DEV e flags administrativas não persistem.

## Roteiro 8 — ROOT

1. Entrar em Extras e autenticar ROOT.
2. Confirmar que `DEV` aparece no dock.
3. Ativar Tempo Infinito, desbloquear empregos e iniciar vários acima da capacidade.
4. Ativar Cerejas Infinitas e comprar boost com saldo insuficiente.
5. Confirmar que saldo real não muda e boost real existe.
6. Fazer logout.
7. Confirmar que DEV desaparece, flags desligam e Tempo é reconciliado.

## Roteiro 9 — Responsividade

Validar manualmente, sem redimensionar screenshot artificialmente:

- 1024×768
- 1152×648
- 1280×720
- 1366×768
- 1440×900
- 1600×900
- 1920×1080
- 2560×1440

Confirmar:

- HUD e dock fixos;
- conteúdo de Empregos com scroll interno;
- uma coluna quando compacto;
- duas colunas quando amplo;
- nunca três colunas comprimidas;
- filtros legíveis;
- cards sem overflow;
- textos longos legíveis;
- requisitos de Eventos legíveis.

## Resultado esperado

Após esta auditoria, a Etapa 13 pode ser considerada fechada somente se `flutter analyze`, `flutter test` e `flutter build windows --release` passarem sem erros.
