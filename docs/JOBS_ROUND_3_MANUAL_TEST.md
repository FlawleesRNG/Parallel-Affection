# Rodada 3 — Fases 13.5 e 13.6

Roteiro manual para validar a interface definitiva da aba Empregos e o sistema central de Tempo.

## Fase 13.5 — Interface definitiva dos Empregos

1. Abrir o jogo manualmente e entrar na aba **Empregos** pelo dock.
2. Confirmar que a tela exibe:
   - cabeçalho com título e explicação curta;
   - painel de resumo com renda atual, empregos ativos, Tempo livre e domínios;
   - filtros **Todos**, **Ativos**, **Disponíveis**, **Bloqueados** e **Nível máximo**;
   - cards em grade responsiva, com no máximo duas colunas no desktop;
   - cards com nome, categoria, nível, cargo, requisitos, barras, renda, XP, Tempo e botão de ação.
3. Confirmar que os estados aparecem de forma contextual:
   - **DISPONÍVEL** para emprego liberado e parado;
   - **EM ANDAMENTO** para emprego ativo;
   - **SEM TEMPO** quando não há Tempo suficiente;
   - **BLOQUEADO** quando requisitos não foram cumpridos;
   - **PRODUÇÃO CONTÍNUA** no nível máximo.
4. Usar os filtros e confirmar que eles mudam apenas a lista visível, sem alterar estado real.
5. Confirmar que não há pop-ups globais nem SnackBars ao iniciar ou pausar empregos.

## Fase 13.6 — Sistema central de Tempo

1. Iniciar **Entregas de Bairro** e confirmar:
   - o botão muda para **PAUSAR**;
   - o HUD de Tempo reduz de acordo com a reserva;
   - o resumo da aba Empregos reflete o Tempo livre.
2. Iniciar outros empregos disponíveis até consumir a capacidade de Tempo.
3. Tentar iniciar um emprego sem capacidade suficiente e confirmar:
   - o emprego não inicia;
   - o estado real não muda;
   - o card mostra aviso contextual de Tempo;
   - não aparece notificação global.
4. Pausar um emprego ativo e confirmar:
   - o Tempo reservado é liberado;
   - outro emprego pode ser iniciado;
   - o progresso acumulado do emprego pausado é preservado.
5. Ajustar um emprego para nível 10 pela aba DEV/ROOT e confirmar:
   - o emprego permanece ativo;
   - entra em **PRODUÇÃO CONTÍNUA**;
   - não reserva Tempo;
   - paga uma vez por segundo em Velocidade x1.0;
   - não ganha XP real nem tenta subir para nível 11.

## Responsividade manual

Validar em janelas de desktop:

- 1024 × 768;
- 1280 × 720;
- 1600 × 900;
- 1920 × 1080.

Confirmar:

- HUD em uma linha;
- dock completo;
- cards sem overflow;
- grade com uma ou duas colunas conforme espaço;
- filtros utilizáveis;
- rolagem apenas na área de conteúdo dos Empregos;
- nenhuma alteração visual indevida na tela principal das personagens.
