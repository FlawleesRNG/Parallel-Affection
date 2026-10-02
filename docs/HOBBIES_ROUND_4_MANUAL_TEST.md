# Hobbies — Etapa 14 Rodada 4

Roteiro manual para validar as Fases 14.7 e 14.8: progresso offline completo, save definitivo, versionamento e migração dos Hobbies.

## Escopo entregue

- Hobbies ativos progridem offline usando o mesmo período global dos Empregos.
- Hobbies pausados não ganham XP, não completam ciclos e não consomem boost.
- O limite offline é o global de 8 horas.
- Ciclos, XP, level ups, múltiplos níveis e Domínio podem ocorrer offline.
- Boost x2 de Hobby é consumido offline somente quando o Hobby estava ativo.
- Expiração de boost é segmentada entre x2 e x1.
- Hobbies desbloqueáveis podem abrir offline, mas não treinam retroativamente.
- Requisitos de Empregos podem ser satisfeitos por níveis de Hobbies obtidos offline.
- Skills continuam derivadas do Hobby fonte e não possuem save próprio.
- O resumo offline único agora inclui resultados de Hobbies.
- Save global atualizado para schema v6.
- Migração conserva IDs oficiais, aliases de Hobbies, boost restante e saneia dados inválidos.

## Validação — offline simples

1. Abrir o jogo manualmente.
2. Entrar em **Hobbies**.
3. Iniciar **Leitura**.
4. Anotar nível, XP e progresso da barra.
5. Fechar o jogo manualmente.
6. Aguardar alguns minutos.
7. Abrir manualmente.
8. Confirmar o resumo único “Enquanto você estava fora”.
9. Confirmar que a seção de Hobbies mostra XP/treinos quando houver ganho.
10. Abrir Hobbies e confirmar que o progresso não foi aplicado duas vezes.

## Validação — boost offline

1. Iniciar Leitura.
2. Comprar o impulso x2 por 5 Cerejas.
3. Fechar o jogo manualmente.
4. Aguardar.
5. Abrir manualmente.
6. Confirmar que:
   - o boost restante diminuiu;
   - XP de Hobby aumentou;
   - cada ciclo ainda vale +2 XP;
   - não houve desconto adicional de Cerejas.

## Validação — Hobby pausado

1. Ativar boost em um Hobby.
2. Pausar o Hobby.
3. Fechar o jogo.
4. Aguardar.
5. Abrir novamente.
6. Confirmar que XP, progresso parcial e boost restante permaneceram congelados.

## Validação — desbloqueios e Domínio

1. Usar DEV para colocar Leitura perto do nível 2.
2. Simular offline ou fechar/abrir após tempo suficiente.
3. Confirmar que **Música** desbloqueia e não inicia automaticamente.
4. Usar DEV para colocar um Hobby perto do nível 10.
5. Simular offline.
6. Confirmar:
   - nível 10;
   - Hobby inativo;
   - boost zerado;
   - Tempo liberado;
   - Skill correspondente dominada.

## Validação — requisito de Emprego

1. Preparar os demais requisitos de um Emprego.
2. Deixar o Hobby exigido próximo do nível necessário.
3. Processar offline.
4. Confirmar que o Emprego desbloqueia.
5. Confirmar que o Emprego novo não inicia automaticamente nem produz retroativamente.

## Validação — save e migração

1. Criar estados variados de Hobbies:
   - níveis diferentes;
   - XP parcial;
   - alguns ativos;
   - alguns pausados;
   - boost restante;
   - progresso parcial.
2. Salvar, fechar e abrir manualmente.
3. Confirmar que todos os 10 Hobbies persistem por ID oficial.
4. Confirmar que Skills não aparecem como bloco salvo separado.
5. Confirmar que ROOT Tempo/Cerejas Infinitas não persistem após reinício.
6. Confirmar que dinheiro, Cerejas, Roxanne, Kai e Empregos não foram alterados por migração de Hobbies.

## DEV mínimo

Na aba DEV, usar os botões de simulação offline:

- 10s;
- 1min;
- 10min;
- 1h;
- 8h;
- 12h.

O cenário de 12h deve processar somente 8h e informar o limite no resumo.

## Ainda não implementado nesta rodada

- Painel ROOT/DEV completo dos Hobbies.
- Auditoria final da Etapa 14.
- Bônus numéricos de Skills.
- Estatísticas completas.
- Conquistas completas.
- Mapa, turnos e minigames.
