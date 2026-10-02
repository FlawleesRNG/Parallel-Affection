# Rodada 5A — Validação manual do progresso offline dos Empregos

Este roteiro valida o progresso offline real dos Empregos sem abrir sistemas futuros.

## Pré-condições

- Usar uma build com aba DEV disponível somente quando necessário:
  `--dart-define=ENABLE_DEV_TOOLS=true`.
- Ter pelo menos um emprego desbloqueado.
- Não usar `flutter run` automaticamente durante validações de build.

## Cenários obrigatórios

### 1. Emprego ativo em nível baixo

1. Inicie `Entregas de Bairro`.
2. Feche o jogo por mais de um ciclo completo.
3. Abra novamente.
4. Confirme no resumo offline:
   - dinheiro recebido;
   - XP profissional recebido;
   - ciclos concluídos;
   - progresso parcial preservado.

### 2. Emprego pausado

1. Pause um emprego com progresso parcial.
2. Feche o jogo.
3. Abra novamente.
4. Confirme que:
   - não houve dinheiro;
   - não houve XP;
   - o progresso parcial permaneceu;
   - impulso restante não foi consumido.

### 3. Level up offline

1. Coloque um emprego próximo do XP necessário para subir de nível.
2. Deixe-o ativo.
3. Simule ou aguarde período offline suficiente.
4. Confirme que:
   - o nível subiu;
   - o dinheiro usou a recompensa correta de cada segmento;
   - a duração do ciclo seguinte mudou;
   - o excedente de XP foi preservado.

### 4. Produção contínua no nível máximo

1. Coloque um emprego no nível 10.
2. Deixe-o ativo.
3. Simule ou aguarde progresso offline.
4. Confirme que:
   - o estado exibido é produção contínua;
   - o pagamento ocorre como 1 segundo por ciclo em velocidade x1.0;
   - não há XP real;
   - não tenta alcançar nível 11.

### 5. Impulso x2 consumido offline

1. Ative um impulso em um emprego ativo.
2. Feche o jogo enquanto o impulso ainda tem tempo restante.
3. Abra após parte do impulso expirar.
4. Confirme que:
   - o período com impulso gerou progresso equivalente em x2;
   - o período restante gerou progresso normal;
   - o tempo de impulso foi consumido;
   - o resumo informa expiração quando aplicável.

### 6. Limite de 8 horas

1. Simule ausência superior a 8 horas pela aba DEV.
2. Confirme que:
   - apenas 8 horas foram aplicadas;
   - o excedente foi descartado;
   - o resumo informa o tempo real ausente e o limite aplicado.

### 7. Desbloqueios offline

1. Deixe um emprego ativo próximo de cumprir requisito de desbloqueio.
2. Feche o jogo.
3. Abra após o requisito ser alcançado offline.
4. Confirme que:
   - o novo emprego foi desbloqueado;
   - o novo emprego não iniciou automaticamente;
   - o resumo offline listou o desbloqueio.

### 8. Idempotência

1. Abra o jogo após período offline e observe o resumo.
2. Salve/feche/abra novamente imediatamente.
3. Confirme que o mesmo período não foi aplicado duas vezes.

