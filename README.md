# Gerador de Senhas Determinístico

Aplicativo Flutter para gerar **senhas seguras e reproduzíveis**, baseadas em **frase-base (chave mestra)**, **serviço/site** e **algoritmos de hash/cripto**.  

As senhas nunca são armazenadas: elas são sempre calculadas no momento, garantindo **privacidade e segurança**.

---

## Funcionalidades

- Geração de senhas **determinísticas** (sempre iguais para a mesma combinação de dados).  
- Suporte a algoritmos de hash/cripto:
  - `MD5`  
  - `SHA-1`  
  - `SHA-256` (padrão)  
  - `AES-CBC`  
- Controle de **comprimento da senha** (8 a 32 caracteres).  
- Personalização de classes de caracteres:
  - Letras minúsculas  
  - Letras maiúsculas  
  - Números  
  - Símbolos  
- Indicador de **força da senha** (fraca, média, forte).  
- Botão para **copiar senha** para a área de transferência.  
- Armazena suas **preferências locais** (comprimento, algoritmo e seleção de caracteres).  

---

## Interface

- **Campos de entrada**:  
  - Serviço/Site  
  - Usuário (opcional)  
  - Frase-base (obrigatório, chave mestra)  
  - Sal/Seed extra (opcional, aumenta entropia)  

- **Configurações**:  
  - Comprimento da senha (slider)  
  - Algoritmo de hash/cripto (dropdown)  
  - Seleção de letras, números e símbolos (switches)  

- **Saída**:  
  - Senha gerada (campo selecionável)  
  - Barra de força da senha  
  - Botão de copiar senha  

---

## Como rodar o projeto

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.x recomendado)  
- Dart >= 2.17  

### Executando
```bash
# Clone o repositório
git clone https://github.com/seu-usuario/gerador-senhas.git
cd gerador-senhas

# Instale as dependências
flutter pub get

# Rode no emulador ou dispositivo físico
flutter run
