# Hobbies — Etapa 14 Rodada 3

Roteiro manual para validar as Fases 14.5 e 14.6: Habilidades oficiais derivadas dos Hobbies e impulso individual x2 por Cerejas.

## Escopo entregue

- Exatamente 10 Habilidades oficiais, uma para cada Hobby.
- Nível de Habilidade derivado diretamente do nível do Hobby fonte.
- Nenhum XP, barra, timestamp ou save próprio de Habilidade.
- `SkillId` separado dos IDs e aliases legados de Hobby.
- Cards de Hobbies mostrando a Habilidade pelo catálogo central.
- Impulso individual de Hobby por 5 Cerejas, x2 por 10 minutos de treino ativo.
- Confirmação dentro do card, cancelamento sem custo e saldo insuficiente sem desconto.
- Pausa congelando o impulso; retomada continuando o tempo restante.
- Expiração segmentada entre trecho x2 e trecho x1.
- Domínio no nível 10 encerrando treino e impulso sem reembolso.
- ROOT Cerejas Infinitas ativando o impulso sem alterar o saldo real.
- DEV mínima com ativar boost grátis, remover, definir restante, expirar e processar tempo pelo runtime real.

## Mapeamento oficial Hobby → Habilidade

1. Leitura → Inteligência
2. Academia → Condicionamento
3. Teatro → Carisma
4. Meditação → Paciência
5. Videogames → Estratégia
6. Música → Criatividade Musical
7. Culinária → Talento Culinário
8. Fotografia → Percepção
9. Oratória → Comunicação
10. Programação → Tecnologia

## Validação manual — Habilidades

1. Abrir a aba **Hobbies** manualmente.
2. Confirmar que cada card mostra `Desenvolve:` com a Habilidade correta.
3. Usar a aba DEV para alterar o nível de um Hobby.
4. Confirmar que a Habilidade exibida acompanha o nível do Hobby.
5. Validar especialmente os domínios separados:
   - Skill `carisma` vem de Teatro, sem recriar Hobby Carisma.
   - Skill `condicionamento` vem de Academia.
   - Skill `comunicacao` vem de Oratória.
   - Skill `tecnologia` vem de Programação.
6. Dominar Leitura e confirmar que o card pode indicar `HABILIDADE DOMINADA` para Inteligência nível 10.

## Validação manual — Impulso x2

1. Definir 5 Cerejas ou mais.
2. Iniciar Leitura.
3. Clicar em `ACELERAR — 5 CEREJAS`.
4. Confirmar que aparece a pergunta `Acelerar este Hobby por 10 minutos?`.
5. Cancelar e confirmar que o saldo não muda.
6. Abrir a confirmação novamente e confirmar.
7. Verificar:
   - saldo reduzido em exatamente 5 Cerejas;
   - card mostra `IMPULSO x2`;
   - contador aparece em `MM:SS`;
   - XP por ciclo continua `+2 XP/ciclo`;
   - custo de Tempo não muda.
8. Tentar comprar novamente enquanto ativo e confirmar que não empilha.

## Pausa, retomada e expiração

1. Com impulso ativo, pausar o Hobby.
2. Confirmar que o card mostra `IMPULSO PAUSADO` e preserva o tempo restante.
3. Aguardar alguns segundos com o Hobby pausado.
4. Confirmar que o tempo restante não caiu.
5. Retomar o Hobby.
6. Confirmar que o contador volta a consumir.
7. Pela DEV, definir boost restante para 10s ou 30s.
8. Processar tempo e confirmar que, ao expirar, o Hobby segue treinando em x1 sem perder progresso parcial.

## Domínio e ROOT

1. Usar DEV para colocar um Hobby próximo do nível 10.
2. Ativar impulso.
3. Processar o treino até dominar.
4. Confirmar:
   - nível 10;
   - treino parado;
   - Tempo liberado;
   - impulso zerado;
   - sem reembolso do custo do impulso.
5. Ativar ROOT Cerejas Infinitas.
6. Com saldo real baixo, comprar impulso em outro Hobby ativo.
7. Confirmar que o impulso entra e o saldo real permanece igual.
8. Desligar ROOT e confirmar que futuras compras voltam a exigir saldo real.

## Navegação e save mínimo

1. Ativar impulso em Leitura.
2. Abrir Empregos, Paixões, Loja, Extras e DEV.
3. Voltar para Hobbies e confirmar que o contador segue consistente.
4. Fechar o jogo manualmente após salvar e reabrir manualmente.
5. Confirmar que o boost restante foi preservado e que, nesta rodada, não houve XP offline de Hobby.

## Ainda não implementado nesta rodada

- Bônus numéricos de Habilidades.
- Aba separada de Habilidades.
- XP offline de Hobbies.
- Resumo offline de Hobbies.
- Migração definitiva específica da Etapa 14.
- Painel ROOT/DEV completo dos Hobbies.
