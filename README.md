# 🏥 Minha Fisio

> O seu companheiro digital para uma recuperação organizada e eficiente.

## 🚀 Versão 2.0 - Funcionalidades Completas
 
 Esta versão consolida todas as funcionalidades planejadas, trazendo estabilidade e novos recursos de segurança e usabilidade:
 
 ![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
 ![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
 ![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
 ![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)
 
 **Minha Fisio** é uma solução móvel desenvolvida em Flutter para simplificar a gestão de tratamentos fisioterapêuticos. Com foco na usabilidade e na adesão ao tratamento, o aplicativo oferece ferramentas poderosas para pacientes e profissionais.
 
 ## 📥 Download
 
 [**Baixar Minha Fisio v2.0.1 (APK Correção Notificações)**](https://github.com/felipegatoloko10/minha_fisio/raw/main/releases/v2.0.1/MinhaFisio-v2.0.1.apk)

## ✨ Funcionalidades Principais

### 🔒 Segurança e Acesso
- **Autenticação Biométrica**: Proteja seus dados sensíveis com acesso via impressão digital ou reconhecimento facial.

### 📅 Gestão Inteligente
- **Cronograma Automático**: Gere datas e horários de sessões automaticamente baseados na frequência semanal prescrita.
- **Calendário Interativo**: Visualize e gerencie o status de cada sessão (pendente, realizada, cancelada) em uma interface intuitiva.
- **Data de Início Flexível**: Planeje tratamentos com início futuro sem complicações.

### 🔔 Lembretes e Widgets
- **Notificações Inteligentes**: Receba alertas configuráveis antes de cada sessão para garantir a pontualidade.
- **Widget de Tela Inicial**: Acompanhe sua próxima sessão diretamente da tela principal do seu Android.

### 📊 Acompanhamento
- **Progresso Visual**: Monitore a porcentagem de conclusão do seu tratamento em tempo real.
- **Histórico Detalhado**: Mantenha um registro completo de tratamentos anteriores.

## 🛠️ Stack Tecnológica

O projeto foi construído seguindo as melhores práticas de desenvolvimento mobile:

- **Linguagem**: Dart
- **Framework**: Flutter
- **Banco de Dados**: SQLite (`sqflite`)
- **Gerenciamento de Estado**: Provider / Built-in State
- **Pacotes Principais**:
  - `local_auth`: Biometria
  - `flutter_local_notifications`: Sistema de notificações
  - `table_calendar`: Calendário customizável
  - `home_widget`: Integração com widgets nativos
  - `shared_preferences`: Persistência leve

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK instalado
- Android Studio ou VS Code configurado
- Dispositivo Android ou Emulador

### Instalação

1.  **Clone o repositório**
    ```bash
    git clone https://github.com/felipegatoloko10/minha_fisio.git
    cd minha_fisio
    ```

2.  **Instale as dependências**
    ```bash
    flutter pub get
    ```

3.  **Execute o projeto**
    ```bash
    flutter run
    ```

## 📦 Estrutura do Projeto

```
lib/
├── models/      # Entidades (User, Treatment, Session)
├── screens/     # Interfaces (Dashboard, Login, Cadastro)
├── services/    # Regras de Negócio e Serviços Externos
├── widgets/     # Componentes Reutilizáveis
└── main.dart    # Ponto de Entrada
```

## 🤝 Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

---
Desenvolvido com 💙 por [Felipe](https://github.com/felipegatoloko10)