#  Gerador de Senhas

Um aplicativo em **Flutter** para gerar senhas seguras a partir de informações personalizadas, 
utilizando diferentes algoritmos de **hash** (MD5, SHA-1 e SHA-256).

##  Funcionalidades

* Entrada de dados personalizados:

* **Serviço/Site** (obrigatório)
* **Usuário** (opcional)
* **Frase-base** (obrigatório, com ocultação de caracteres)
* Escolha do **comprimento da senha** (8 a 32 caracteres).
* Seleção do **algoritmo de hash** (MD5, SHA-1, SHA-256).
* Exibição da **força da senha** (Fraca, Média, Forte).
* **Cópia rápida** da senha para a área de transferência.

##  Tecnologias

* **Flutter** (Material Design)
* **Dart**
* **crypto** (para hashing)

##  Como Executar

1. Clone este repositório:

   ```bash
   git clone https://github.com/Grupo-MCR/gerador_senhas.git
   cd gerador-senhas-flutter
   ```

2. Instale as dependências:

   ```bash
   flutter pub get
   ```

3. Execute no emulador ou dispositivo físico:

   ```bash
   flutter run
   ```

##  Observações

* O aplicativo não armazena dados do usuário, apenas os utiliza para gerar a senha.
* O nível de força da senha é uma **estimativa simples**, baseada apenas no comprimento.
* **Este é um exercício acadêmico e não devem ser usadas senhas geradas por ele, pois o mesmo falta com com etapas utilizadas por geradores de senhas comerciais**
---
