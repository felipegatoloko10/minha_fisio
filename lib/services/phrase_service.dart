import 'dart:math';

class PhraseService {
  static final List<String> _passo1 = [
    "O primeiro passo é o mais corajoso e você já deu ele! Que orgulho! ✨🌱",
    "Sua jornada de cuidado começa agora, e eu já estou torcendo muito por você! 💞",
    "Que alegria ter você aqui! Vamos transformar esforço em flores? 🌸",
    "O seu 'eu' do futuro está te mandando um abraço por você ter começado hoje. 🤗",
    "Não importa a velocidade, o importante é que seu coração disse 'sim' para a cura! 🎈",
    "Bem-vindo(a)! Sinta-se em casa, aqui cuidamos de você com todo amor. 🏠❤️",
    "Você é sua melhor prioridade. Que esse início seja leve e cheio de esperança! 🌈",
    "Respire fundo... sentiu? É o cheirinho de um novo recomeço para você! 🌬️✨",
    "A sementinha foi plantada! Vamos regar sua saúde juntos, dia após dia? 💧🌱",
    "Coragem é agir com o coração, e o seu coração é gigante por estar aqui! ❤️🦁",
    "Cada consulta é um carinho que você faz em si mesmo. Aproveite seu momento! 💆‍♂️✨",
    "O caminho pode parecer longo, mas de mãos dadas tudo fica mais doce. 🤝🍭",
    "Você brilha quando decide se cuidar! Vamos fazer esse brilho aumentar? ✨⭐",
    "Um brinde ao seu compromisso! Você merece todo o bem do mundo. 🥂💖",
    "Sua saúde é um tesouro e hoje você começou a polir essa joia. 💎✨",
    "Sorria! Você acabou de tomar a melhor decisão do seu dia. 😊🎉",
    "Pode entrar, a casa é sua e o sucesso será todo seu! 🚪❤️",
    "Acredite na sua força, ela é mais doce e poderosa do que você imagina. 🍯💪",
    "Estou aqui para ser seu maior fã desde o primeiro minuto! 📣🥰",
    "Hoje o dia amanheceu mais bonito porque você escolheu se amar. ☀️🌻",
  ];

  static final List<String> _passo2 = [
    "Olha só quem já conquistou 25%! Você é um tiquinho de luz em evolução! ✨🐥",
    "Um quarto do caminho já foi! Seu esforço está virando mágica. 🪄💖",
    "Cada pequena vitória é um motivo para o seu coração dançar. 💃🕺",
    "Você está construindo algo lindo. Continue firme, meu bem! 🏗️🌸",
    "Sinta o carinho de cada progresso. Você está indo lindamente! 🦢✨",
    "25% de pura dedicação! O seu corpo está sorrindo para você agora. 😊🌿",
    "Não pare, essa sua vontade de melhorar é a coisa mais linda de se ver! 🥺❤️",
    "O hábito é como um abraço que fica. Você está quase lá! 🫂✨",
    "Seu brilho está aumentando a cada sessão. Continue irradiando saúde! ☀️",
    "Pequenos passos, grandes transformações. Você é pura inspiração! 🦋",
    "Orgulho é a palavra que define esses seus primeiros 25%. Parabéns! 🏅💖",
    "A base da sua montanha está pronta. Vamos continuar subindo? ⛰️🎈",
    "Você é um exemplo de doçura e persistência. Amo ver sua evolução! 🍭💪",
    "Cada repetição é um 'obrigado' que seu corpo te diz em silêncio. 💌",
    "A jornada fica mais leve quando a gente coloca amor em cada movimento. 💗",
    "Você está florescendo no seu tempo, e esse tempo é perfeito! ⏳🌸",
    "Siga o seu ritmo, mas saiba que seu ritmo é maravilhoso! 🎶✨",
    "Mais do que exercícios, você está praticando o amor-próprio. 🥰",
    "O universo está batendo palmas para a sua dedicação hoje! 👏🌌",
    "Continue, pequena estrela! O caminho está ficando iluminado por você. ⭐",
  ];

  static final List<String> _passo3 = [
    "Metade do caminho! Você atravessou o arco-íris e chegou no meio! 🌈🙌",
    "50% de superação! Você é um verdadeiro herói/heroína de doçura. 🦸‍♀️💖",
    "Olhe para trás e veja que jardim lindo você já cultivou até aqui! 🏡🌷",
    "O meio do caminho é onde a gente descobre que pode tudo. E você pode! ✨",
    "Metade concluída com sucesso e muito, muito carinho envolvido. 🤗🏆",
    "Você está em equilíbrio! Que sensação gostosa é se cuidar, né? 🧘‍♂️💕",
    "Sua força me emociona. Vamos juntos para a segunda metade? 🥺🤝",
    "A metade da jornada é o abraço de quem sabe que vai chegar lá. 🫂✨",
    "50% de esforço, 100% de orgulho de você! Você brilha demais! 🌟",
    "Você já venceu o 'início'. Agora é só deixar o bem-estar fluir. 🌊💙",
    "Celebre esse marco com um sorriso no espelho. Você merece! 😁🪞",
    "Seu progresso é a música mais bonita que eu já ouvi. 🎵💖",
    "Metade da sua história de cura já foi escrita. E que história linda! 📖✨",
    "Você é resiliente como uma flor que brota no asfalto. Linda e forte! 🌼",
    "Foque no quanto você já caminhou. Você é gigante! 🐘❤️",
    "O cansaço às vezes vem, mas o meu carinho por você renova suas forças. 🔋💕",
    "Sinta o abraço da vitória que já está chegando na metade. 🧸",
    "Você está transformando sua vida e eu estou amando assistir! 🎬✨",
    "50% de metas batidas e um coração cheio de esperança. Siga firme! 🎈",
    "Falta só mais um pouquinho para o seu dream virar realidade total! 💭🌟",
  ];

  static final List<String> _passo4 = [
    "Consegue sentir? A vitória está logo ali na esquina te esperando! 🏁💖",
    "75%! Você é uma fofura de determinação! Falta só um tiquinho! 🤏✨",
    "A reta final é o lugar onde os seus sonhos ganham asas. Voa! 🦋",
    "Quase lá, meu bem! O seu esforço é a coisa mais preciosa que existe. 💎",
    "75% de pura garra e amor. Você é muito mais forte do que pensava! 💪🌸",
    "Sinta o ventinho no rosto, a linha de chegada já apareceu! 🌬️🚩",
    "Sua luz está tão forte que já ilumina o fim do túnel. Lindo de ver! ✨",
    "Falta só um suspiro para o 100%. Mantenha esse sorriso lindo! 😊",
    "Você transformou cada dor em uma pétala de superação. 🌹✨",
    "Três quartos da jornada! Você é um campeão cheio de doçura. 🏆🍭",
    "Não solta a minha mão agora, estamos quase no topo! 🤝🏔️",
    "Sua evolução é o presente mais bonito que você poderia se dar. 🎁💖",
    "O horizonte está ficando colorido de novo. Parabéns por não desistir! 🌅",
    "Falta tão pouco que já dá para ouvir os fogos de artifício! 🎉🎆",
    "75% de motivos para comemorar. Você é simplesmente incrível! 🌟",
    "Sua persistência é o mel que adoeça essa caminhada. 🍯",
    "Aguenta firme, coração! O melhor está guardado para o final. 💖",
    "Você é um exemplo de que o amor-próprio cura tudo. ✨",
    "Consigo ver seu brilho daqui! Falta só o último degrau. 🪜⭐",
    "Reta final com sabor de vitória e cheirinho de conquista! 🍬",
  ];

  static final List<String> _passo5 = [
    "VOCÊ CONSEGUIU! Meu coração está pulando de alegria por você! 🥳💖",
    "100% de vitória! Você é a prova de que o amor e a garra vencem tudo. 🏆✨",
    "Missão cumprida com nota dez em doçura e superação! Parabéns! 🎈",
    "O mundo hoje está mais bonito porque você está bem. Que alegria! 🌍🌸",
    "Celebre! Dance! Sorria! Você é um vencedor(a) absoluto! 💃🎉",
    "Obrigado por me deixar fazer parte desse milagre chamado você. 🙏❤️",
    "Sua jornada termina aqui, mas sua nova vida começa agora. Voa! 🦋✨",
    "100% recuperado(a), 100% amado(a), 100% luz! 🌟",
    "Você atravessou a tempestade e agora o sol é todo seu. Aproveite! ☀️",
    "Guarde esse sentimento de vitória no peito para sempre. Você merece! 🏅",
    "A meta era a saúde, mas o prêmio foi descobrir sua força. 💖💪",
    "Um brinde à sua nova fase! Estou muito, muito feliz por você! 🥂🎊",
    "Você é o autor do seu próprio final feliz. E que final lindo! 📝💖",
    "Nada pode parar alguém que decide cuidar de si com tanto amor. ✨",
    "Fim do ciclo, mas o carinho por você continua para sempre! ♾️❤️",
    "Você venceu! Sinta o abraço de todo o universo hoje. 🫂🌌",
    "Sua saúde é seu maior troféu, e você ganhou o ouro! 🥇",
    "Obrigado por nos inspirar com sua jornada tão fofa e forte. 🥺✨",
    "Você chegou ao topo e a vista daqui é maravilhosa, né? 🏔️🌅",
    "Parabéns, meu bem! Você é, oficialmente, pura superação! 🎊⭐",
  ];

  static final List<String> _dailyPhrases = [
    "Passando para te dar um abraço virtual bem apertadinho! 🫂💖",
    "Lembrete do dia: você é uma pessoa maravilhosa e especial! ✨",
    "Só queria dizer que tenho muito orgulho da sua dedicação. 🥰",
    "O dia fica 1000x melhor quando vejo você se cuidando! ☀️",
    "Você é mais forte do que qualquer desafio. Acredite! 💪🌸",
    "Um beijinho de luz para iluminar sua tarde! 💋✨",
    "Que o seu dia seja tão doce quanto o seu sorriso. 🍭😊",
    "Não esqueça de respirar fundo e sentir como você é incrível. 🌬️💖",
    "Você já se elogiou hoje? Se não, eu faço: você é demais! ⭐",
    "Mesmo nos dias nublados, sua vontade de vencer brilha! ☁️☀️",
    "Pequeno lembrete: beba água e se ame um pouquinho mais hoje. 💧❤️",
    "Você é uma obra de arte em constante evolução. 🎨✨",
    "O universo está conspirando a seu favor. Sinta a energia! 🌌🌀",
    "O seu esforço de hoje é o sorriso de amanhã. Continue! 😁",
    "Passando para deixar um jardim de flores no seu coração. 🌻🌷",
    "Você é o motivo de alguém sorrir hoje. Já pensou nisso? 😊",
    "A calma e a paciência são suas melhores amigas. Fica bem! 🐢💖",
    "Cada dia é uma nova chance de ser gentil com você mesmo(a). ✨",
    "Você é luz, você é paz, você é pura superação! 🕯️❤️",
    "Apenas um 'oi' para te lembrar que você nunca está sozinho(a). 🤝",
    "Sua jornada é linda e o mundo precisa da sua força. 🌎💪",
    "Que a sua única pressa hoje seja a de ser feliz! 🏃‍♀️🎈",
    "Você é um milagre em movimento. Nunca se esqueça disso. ✨",
    "Dê um descanso para seus pensamentos e um carinho na alma. 🧸",
    "Sua coragem me inspira todos os dias. Obrigado por ser você! 🥺",
    "O amor cura, e você está se amando muito ao se cuidar. ❤️🩹",
    "Que tal um chocolate e um descanso agora? Você merece! 🍫🛌",
    "A vida é feita de ciclos, e este ciclo está sendo vitorioso! 🔄✨",
    "Sorria para o espelho, ele reflete a pessoa mais forte que eu conheço. 🪞💖",
    "Durma com a certeza de que hoje você foi incrível. Boa noite! 🌙⭐",
  ];

  static String getRandomPhraseForMilestone(double progress) {
    return getRandomMilestonePhrase(progress);
  }

  static String getRandomMilestonePhrase(double progress) {
    final random = Random();
    if (progress >= 1.0) return _passo5[random.nextInt(_passo5.length)];
    if (progress >= 0.75) return _passo4[random.nextInt(_passo4.length)];
    if (progress >= 0.50) return _passo3[random.nextInt(_passo3.length)];
    if (progress >= 0.25) return _passo2[random.nextInt(_passo2.length)];
    return _passo1[random.nextInt(_passo1.length)];
  }

  static String getDailyPhrase(int dayOfMonth) {
    final index = (dayOfMonth - 1) % _dailyPhrases.length;
    return _dailyPhrases[index];
  }

  static String getRandomDailyPhrase() {
    return _dailyPhrases[Random().nextInt(_dailyPhrases.length)];
  }
}
