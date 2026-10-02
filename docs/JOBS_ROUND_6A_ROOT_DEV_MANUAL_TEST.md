# Rodada 6A — Fase 13.11

Roteiro manual para validar o painel ROOT/DEV completo dos Empregos.

## Acesso

1. Abrir o jogo manualmente.
2. Confirmar que o dock normal não mostra `DEV`.
3. Entrar em `Extras` e autenticar ROOT.
4. Confirmar que o dock passa a mostrar `DEV`.
5. Abrir `DEV` e localizar a seção `Empregos — ROOT/DEV completo`.

## Validações principais

1. Confirmar o resumo global: empregos cadastrados, desbloqueados, ativos, Tempo, impulsos, domínio máximo.
2. Selecionar cada um dos nove empregos e confirmar inspector com ID, nível, cargo, XP, ciclo, renda, Tempo e impulso.
3. Ativar `Tempo infinito`, desbloquear empregos e iniciar vários trabalhos acima da capacidade normal.
4. Desativar `Tempo infinito` e confirmar reconciliação: empregos antigos permanecem, excedentes recentes pausam.
5. Ativar `Cerejas infinitas`, comprar impulso com saldo insuficiente e confirmar que o boost real entra sem desconto.
6. Desativar `Cerejas infinitas` e confirmar que o boost continua ativo, mas novas compras voltam a exigir Cerejas reais.
7. Testar controles por emprego: iniciar, pausar, desbloquear, bloquear, definir nível, adicionar XP, completar nível, zerar XP, progresso parcial e completar ciclo.
8. Testar simulação virtual de tempo sem espera real: 1s, 10s, 1min, 10min, 1h e 8h.
9. Testar simulação offline: 10s, 1min, 10min, 1h, 8h e 12h; o limite oficial continua 8h.
10. Validar requisitos usando o avaliador real e reavaliar desbloqueios.
11. Testar reset individual e reset global; dinheiro, Cerejas, personagens e hobbies devem ser preservados.
12. Clicar `Salvar agora`, fechar manualmente e reabrir; alterações reais de empregos persistem, ROOT e flags temporárias não persistem.

## Logout ROOT

1. Com `Tempo infinito` ativo e excesso de empregos ativos, sair do modo admin.
2. Confirmar que `DEV` desaparece.
3. Confirmar que `Tempo infinito` e `Cerejas infinitas` desligam.
4. Confirmar que a reconciliação de Tempo preserva progresso, XP, boost e dinheiro já recebidos.

O painel DEV é apenas uma camada administrativa sobre os serviços reais de Empregos, Tempo, requisitos, simulação e save.
