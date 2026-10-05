import '../../core/character_catalog.dart';

/// Static relationship dialogue content. Gameplay state never owns these texts.
class ConversationDialogue {
  const ConversationDialogue({required this.id, required this.text});

  final String id;
  final String text;
}

abstract final class CharacterDialogueCatalog {
  static const unavailableConversation = ConversationDialogue(
    id: 'conversation_unavailable',
    text: 'Mais diálogos serão adicionados futuramente.',
  );

  static const Map<String, Map<int, List<ConversationDialogue>>> conversations =
      {PlayableCharacterIds.roxanne: _roxanneConversations};

  static List<ConversationDialogue> conversationPool(
    String characterId,
    int stage,
  ) {
    final canonicalId = PlayableCharacterCatalog.canonicalId(characterId);
    return conversations[canonicalId]?[stage] ?? const [];
  }

  static const Map<int, List<ConversationDialogue>> _roxanneConversations = {
    0: [
      ConversationDialogue(
        id: 'roxanne_stage_01_dialogue_01',
        text:
            'Hm? Você queria alguma coisa... ou só resolveu ficar me olhando?',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_01_dialogue_02',
        text:
            'Eu não sou muito boa com conversa de elevador. Nem com conversa fora dele, pra ser sincera.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_01_dialogue_03',
        text:
            'Você apareceu de novo. Acho que a noite ficou um pouco menos silenciosa.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_01_dialogue_04',
        text:
            'Se estiver procurando assunto, talvez seja melhor começar com música. É mais fácil que falar de mim.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_01_dialogue_05',
        text:
            'Não leva pro lado pessoal se eu ficar quieta. Silêncio nunca me incomodou.',
      ),
    ],
    1: [
      ConversationDialogue(
        id: 'roxanne_stage_02_dialogue_01',
        text:
            'Ainda não decidi se você é insistente ou só muito ruim em perceber quando alguém quer ficar sozinho.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_02_dialogue_02',
        text:
            'Tá... talvez eu tenha tirado uma conclusão meio rápida sobre você. Não se acostuma com eu admitindo isso.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_02_dialogue_03',
        text:
            'Você sempre volta depois de uma conversa estranha? Isso é coragem ou falta de bom senso?',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_02_dialogue_04',
        text:
            'Eu não estou brava. Minha cara é assim mesmo... na maior parte do tempo.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_02_dialogue_05',
        text:
            'Talvez você não seja exatamente o que eu pensei. Ainda estou verificando.',
      ),
    ],
    2: [
      ConversationDialogue(
        id: 'roxanne_stage_03_dialogue_01',
        text:
            'Olha só, já consigo conversar com você sem planejar uma rota de fuga. Progresso.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_03_dialogue_02',
        text:
            'Tem alguma música que você consegue ouvir cem vezes sem cansar? Eu tenho várias.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_03_dialogue_03',
        text:
            'Eu gosto mais da rádio quando fica tarde. Parece que tem menos gente fingindo estar acordada.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_03_dialogue_04',
        text: 'Você é fácil de conversar. Isso é um pouco suspeito, sabia?',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_03_dialogue_05',
        text:
            'Se eu te mandar uma música algum dia, escuta até o final. Eu provavelmente escolhi por algum motivo.',
      ),
    ],
    3: [
      ConversationDialogue(
        id: 'roxanne_stage_04_dialogue_01',
        text:
            'Você chegou numa hora boa. Eu estava começando a conversar comigo mesma.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_04_dialogue_02',
        text:
            'Algumas pessoas precisam de café pra funcionar. Eu preciso de café e uma playlist decente.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_04_dialogue_03',
        text:
            'Já percebeu que você aparece bastante por aqui? Não é uma reclamação... só uma observação.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_04_dialogue_04',
        text:
            'Se quiser ficar um pouco, fica. Eu consigo trabalhar e conversar ao mesmo tempo. Mais ou menos.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_04_dialogue_05',
        text:
            'Tenho a impressão de que você já sabe quando eu estou fingindo que está tudo bem. Isso é inconveniente.',
      ),
    ],
    4: [
      ConversationDialogue(
        id: 'roxanne_stage_05_dialogue_01',
        text:
            'Foi um dia horrível. Ainda bem que você apareceu antes de eu decidir declarar guerra ao mundo.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_05_dialogue_02',
        text:
            'Eu não costumo contar certas coisas pras pessoas... mas acho que com você é diferente.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_05_dialogue_03',
        text:
            'Sabe quando você encontra alguém com quem o silêncio não fica estranho? É... acho que chegamos nesse ponto.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_05_dialogue_04',
        text:
            'Se você quiser escolher a música hoje, eu deixo. Aproveita, porque isso é um privilégio raro.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_05_dialogue_05',
        text: 'Você virou uma parte estranhamente confortável da minha rotina.',
      ),
    ],
    5: [
      ConversationDialogue(
        id: 'roxanne_stage_06_dialogue_01',
        text:
            'Eu pensei em te mandar mensagem mais cedo. Desisti umas três vezes antes de perceber que isso era ridículo.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_06_dialogue_02',
        text:
            'Quando alguma coisa acontece, você está virando uma das primeiras pessoas em quem eu penso. Não sei se gosto do que isso diz sobre mim.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_06_dialogue_03',
        text: 'Pode ficar mais um pouco? Não precisa falar nada. Só... fica.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_06_dialogue_04',
        text:
            'Tem coisas que parecem bem menores depois que eu conto pra você.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_06_dialogue_05',
        text:
            'Eu acho engraçado como você conseguiu entrar na minha vida sem fazer muito barulho.',
      ),
    ],
    6: [
      ConversationDialogue(
        id: 'roxanne_stage_07_dialogue_01',
        text:
            'Você sabe que fica difícil fingir normalidade quando você chega sorrindo desse jeito, né?',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_07_dialogue_02',
        text:
            'Eu estava pensando em você. Antes que pergunte: não, eu não vou explicar por quê.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_07_dialogue_03',
        text:
            'Você podia parar de ser tão agradável de ter por perto. Está começando a virar um problema.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_07_dialogue_04',
        text:
            'Se alguém perguntar, eu definitivamente não estava esperando você aparecer hoje.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_07_dialogue_05',
        text:
            'Às vezes você chega perto e eu esqueço completamente o que ia dizer. Extremamente irritante.',
      ),
    ],
    7: [
      ConversationDialogue(
        id: 'roxanne_stage_08_dialogue_01',
        text: 'Eu sinto sua falta mais rápido do que gostaria de admitir.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_08_dialogue_02',
        text:
            'Já aconteceu de uma música começar a lembrar uma pessoa? Porque... é. Você estragou várias pra mim desse jeito.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_08_dialogue_03',
        text: 'Eu gosto quando você aparece. Pronto. Falei. Não faz essa cara.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_08_dialogue_04',
        text:
            'Com você eu não sinto que preciso preencher cada silêncio. Acho que é uma das coisas que eu mais gosto na gente.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_08_dialogue_05',
        text:
            'É meio assustador gostar tanto de alguém... mas eu não quero voltar atrás.',
      ),
    ],
    8: [
      ConversationDialogue(
        id: 'roxanne_stage_09_dialogue_01',
        text:
            'Vem cá. Eu tive um dia longo e estou oficialmente reivindicando alguns minutos com você.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_09_dialogue_02',
        text:
            'Ainda acho estranho poder sentir saudade de alguém que eu provavelmente vou ver daqui a pouco.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_09_dialogue_03',
        text:
            'Eu fiz uma playlist pra você. Não, você não pode rir do nome dela.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_09_dialogue_04',
        text:
            'Se meus planos para hoje incluírem você, sofá, alguma coisa pra beber e nenhuma obrigação... você reclama?',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_09_dialogue_05',
        text: 'Eu gosto disso. Da gente. Até das partes meio desajeitadas.',
      ),
    ],
    9: [
      ConversationDialogue(
        id: 'roxanne_stage_10_dialogue_01',
        text:
            'Eu passei muito tempo achando que ficar sozinha era a mesma coisa que estar em paz. Você me mostrou a diferença.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_10_dialogue_02',
        text:
            'Quando eu imagino o que vem depois, você simplesmente está lá. Nem preciso tentar.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_10_dialogue_03',
        text:
            'Ainda quero minhas noites quietas, minhas músicas e meu espaço... só que agora eu quero você fazendo parte disso também.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_10_dialogue_04',
        text:
            'É engraçado. No começo eu nem sabia o que dizer pra você. Agora parece que eu poderia passar a noite inteira conversando.',
      ),
      ConversationDialogue(
        id: 'roxanne_stage_10_dialogue_05',
        text:
            'Não sei como vai ser daqui pra frente. Só sei que quero descobrir com você.',
      ),
    ],
  };
}
