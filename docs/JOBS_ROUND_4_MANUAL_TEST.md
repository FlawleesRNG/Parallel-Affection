# Rodada 4 — Fases 13.7 e 13.8

Roteiro manual para validar o impulso individual por Cerejas e o acabamento da Produção Contínua no nível máximo.

## Impulso por Cerejas

1. Abrir o jogo manualmente.
2. Entrar na aba **Empregos**.
3. Iniciar **Entregas de Bairro**.
4. Confirmar que o card mostra **ACELERAR — 5 CEREJAS**.
5. Clicar em acelerar e confirmar que nenhuma Cereja é descontada ainda.
6. Confirmar que aparece, dentro do card, a pergunta **Confirmar impulso x2 por 5 Cerejas?**.
7. Clicar em **CANCELAR** e confirmar que o saldo permanece igual.
8. Abrir novamente a confirmação e clicar em **CONFIRMAR**.
9. Confirmar desconto de exatamente 5 Cerejas.
10. Confirmar etiqueta **IMPULSO x2** e contador em formato `MM:SS`.
11. Observar a barra do trabalho avançando mais rápido.
12. Pausar o emprego e confirmar **IMPULSO PAUSADO** com o contador congelado.
13. Retomar o emprego e confirmar que o mesmo contador continua diminuindo.
14. Tentar comprar outro impulso durante o impulso ativo e confirmar que não empilha.
15. Usar a DEV para definir poucos segundos restantes e processar até expirar.
16. Confirmar que o card volta para x1 sem perder progresso parcial.

## Saldo insuficiente

1. Usar DEV/ROOT para definir Cerejas abaixo de 5.
2. Iniciar um emprego.
3. Abrir a confirmação do impulso.
4. Confirmar a mensagem **Faltam X Cerejas**.
5. Confirmar que o botão de confirmação não conclui a compra.
6. Confirmar que o saldo não fica negativo.

## Domínio Máximo e Produção Contínua

1. Usar DEV/ROOT para levar **Entregas de Bairro** ao nível 10.
2. Confirmar cargo **Cidade sem Atrasos**.
3. Confirmar **NÍVEL MÁXIMO** e **PRODUÇÃO CONTÍNUA**.
4. Confirmar custo de Tempo 0 e Tempo liberado no HUD/resumo.
5. Observar a barra de renda preenchendo em ciclo de 1 segundo.
6. Confirmar pagamento de R$ 39 por segundo em velocidade x1.0.
7. Confirmar que XP permanece como **DOMÍNIO MÁXIMO** e não mostra nível 11.
8. Ativar impulso x2.
9. Confirmar renda informativa dobrada e dois pagamentos equivalentes por segundo.
10. Pausar em fração parcial e retomar.
11. Confirmar que a fração do próximo pagamento é preservada.
12. Repetir o teste com outro emprego no nível 10 e validar a recompensa específica.

## Navegação

1. Ativar impulso em um emprego.
2. Sair da aba Empregos.
3. Abrir Paixões, Hobbies, Estatísticas, Conquistas, Loja, Extras e DEV.
4. Voltar para Empregos.
5. Confirmar que o progresso, o contador e o dinheiro refletem o processamento por timestamp.
6. Confirmar que não houve duplicação de pagamentos por troca de aba.

## Responsividade

Validar:

- 1024 × 768;
- 1152 × 648;
- 1280 × 720;
- 1366 × 768;
- 1440 × 900;
- 1600 × 900;
- 1920 × 1080;
- 2560 × 1440.

Confirmar:

- confirmação cabe dentro do card;
- contador do impulso não gera overflow;
- etiqueta x2 é legível;
- barra de renda permanece visível;
- **DOMÍNIO MÁXIMO** é legível;
- resumo superior mostra Renda atual, Ativos, Tempo livre, Domínios e Impulsos;
- HUD e dock permanecem fixos.
