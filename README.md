# Minha Fisio 🏥

O **Minha Fisio** é um aplicativo Flutter desenvolvido para ajudar pacientes a gerenciarem seus tratamentos de fisioterapia de forma organizada, intuitiva e eficiente.

## 🚀 Versão 1.0 - Funcionalidades Principais

Esta versão traz uma refatoração completa e a implementação de recursos avançados:

*   **🔐 Autenticação Biométrica**: Acesso seguro via digital para proteger seus dados de saúde.
*   **📅 Cronograma Inteligente**: Gere automaticamente todas as sessões do seu tratamento com base na quantidade e nos dias da semana escolhidos.
*   **🕒 Notificações Automáticas**: Receba lembretes no celular 1 hora antes de cada sessão para nunca mais esquecer um atendimento.
*   **🖼️ Widget de Tela Inicial**: Visualize sua próxima sessão diretamente na tela inicial do Android com um card elegante e informativo.
*   **📊 Acompanhamento de Progresso**: Barra de progresso visual que mostra a porcentagem concluída do tratamento em tempo real.
*   **🗓️ Calendário Interativo**: Gerencie cada sessão individualmente (Realizada, Pendente, Cancelada ou Remarcada) com cores indicativas.
*   **💾 Persistência com SQLite**: Seus dados são salvos localmente em um banco de dados robusto e veloz.
*   **📍 Data de Início Flexível**: Planeje tratamentos que começarão em datas futuras.

## 🛠️ Tecnologias Utilizadas

*   **Flutter & Dart**
*   **SQLite** (`sqflite`) para armazenamento local.
*   **SharedPreferences** para configurações rápidas.
*   **Local Auth** para biometria.
*   **Flutter Local Notifications** para lembretes.
*   **Home Widget** para integração com a tela inicial do sistema.
*   **Table Calendar** para gestão de datas.

## 📦 Estrutura do Projeto

O código segue as melhores práticas de organização:
*   `lib/models/`: Classes de dados (User, Treatment, Session).
*   `lib/screens/`: Interfaces de usuário (Login, Cadastro, Dashboard, Criação).
*   `lib/services/`: Lógica de negócio (Banco de dados, Notificações, Biometria, Widget).
*   `lib/widgets/`: Componentes visuais reutilizáveis.

---
Desenvolvido por [Felipe](https://github.com/felipegatoloko10)