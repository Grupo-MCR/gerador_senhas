import 'dart:convert'; // Para codificação UTF-8 e manipulação de strings
import 'dart:math'; // Funções matemáticas, ex: max()
import 'dart:typed_data'; // Para lidar com arrays de bytes
import 'package:flutter/material.dart'; // Widgets do Flutter
import 'package:flutter/services.dart'; // Para copiar dados para o clipboard
import 'package:crypto/crypto.dart'; // Algoritmos de hash (MD5, SHA-1, SHA-256)
import 'package:encrypt/encrypt.dart' as enc; // Biblioteca de criptografia
import 'package:shared_preferences/shared_preferences.dart'; // Armazenamento local (salva preferências do usuário)

void main() {
  runApp(const MyApp()); // Executa o aplicativo iniciando pela classe MyApp
}

/// App principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove a faixa "debug"
      title: 'Gerador de Senhas', // Título do app
      theme: ThemeData(primarySwatch: Colors.indigo), // Tema padrão
      home: const PasswordPage(), // Tela inicial
    );
  }
}

/// Tela única (onde o usuário gera senhas)
class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _formKey = GlobalKey<FormState>(); // Chave para validação do formulário

  // Controladores de texto para capturar os dados digitados
  final servicoController = TextEditingController();
  final usuarioController = TextEditingController();
  final fraseController = TextEditingController();
  final salController = TextEditingController(); // Campo opcional (seed extra)

  // Configurações padrão
  double comprimento = 12; // Tamanho da senha
  String metodo = 'SHA-256'; // Algoritmo inicial
  bool useLower = true; // Usar letras minúsculas
  bool useUpper = true; // Usar letras maiúsculas
  bool useDigits = true; // Usar números
  bool useSymbols = false; // Usar símbolos

  // Variáveis para mostrar a senha e a força
  String senhaGerada = '';
  double strengthScore = 0.0;
  String strengthLabel = '—';

  @override
  void initState() {
    super.initState();
    _loadPrefs(); // Carrega preferências salvas
  }

  /// Carrega preferências do usuário (método, comprimento e opções de caracteres)
  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      metodo = sp.getString('metodo') ?? 'SHA-256';
      comprimento = sp.getDouble('comprimento') ?? 12.0;
      useLower = sp.getBool('useLower') ?? true;
      useUpper = sp.getBool('useUpper') ?? true;
      useDigits = sp.getBool('useDigits') ?? true;
      useSymbols = sp.getBool('useSymbols') ?? false;
    });
  }

  /// Salva preferências escolhidas
  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('metodo', metodo);
    await sp.setDouble('comprimento', comprimento);
    await sp.setBool('useLower', useLower);
    await sp.setBool('useUpper', useUpper);
    await sp.setBool('useDigits', useDigits);
    await sp.setBool('useSymbols', useSymbols);
  }

  /// Constrói uma "semente" única com os dados fornecidos
  String _buildSeed() {
    final service = servicoController.text.trim();
    final user = usuarioController.text.trim();
    final pass = fraseController.text;
    final salt = salController.text.trim();
    return 'svc:$service|usr:$user|pass:$pass|salt:$salt';
  }

  /// Deriva bytes de forma determinística a partir da semente
  List<int> _deriveBytesDeterministic({
    required String seed,
    required String passphrase,
    required int neededLen,
  }) {
    final bytes = <int>[];
    int counter = 0;

    List<int> nextChunk() {
      final counterStr = '::$counter';
      final material = utf8.encode(seed + counterStr);

      // Escolhe o algoritmo de acordo com a opção selecionada
      if (metodo == 'MD5') {
        return md5.convert(material).bytes;
      } else if (metodo == 'SHA-1') {
        return sha1.convert(material).bytes;
      } else if (metodo == 'AES-CBC') {
        // Usa AES em modo CBC
        final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
        final ivFull = sha256.convert(utf8.encode(seed)).bytes;
        final iv = enc.IV(Uint8List.fromList(ivFull.sublist(0, 16)));
        final key = enc.Key(Uint8List.fromList(keyBytes));
        final aes = enc.Encrypter(
            enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'));
        final ct = aes.encryptBytes(material, iv: iv);
        return ct.bytes;
      } else {
        // Padrão: SHA-256
        return sha256.convert(material).bytes;
      }
    }

    // Gera bytes até atingir o tamanho necessário
    while (bytes.length < neededLen) {
      bytes.addAll(nextChunk());
      counter++;
      if (counter > 1e6) break; // Limite de segurança
    }
    return bytes.sublist(0, neededLen);
  }

  /// Embaralhamento determinístico da lista de caracteres
  void _detShuffle<T>(List<T> list, List<int> rndBytes) {
    int i = list.length - 1;
    int p = 0;
    while (i > 0) {
      final b1 = rndBytes[p % rndBytes.length];
      final b2 = rndBytes[(p + 1) % rndBytes.length];
      final b = (b1 << 8) ^ b2;
      final j = b % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
      i--;
      p += 2;
    }
  }

  /// Gera a senha formatada com base nas regras definidas
  String _formatPassword({
    required String seed,
    required int length,
    required bool lower,
    required bool upper,
    required bool digits,
    required bool symbols,
    required List<int> rndBytes,
  }) {
    // Conjuntos de caracteres disponíveis
    final lowers = List<String>.generate(26, (i) => String.fromCharCode(97 + i));
    final uppers = List<String>.generate(26, (i) => String.fromCharCode(65 + i));
    final nums = List<String>.generate(10, (i) => String.fromCharCode(48 + i));
    final syms = r'!@#$%^&*()-_=+[]{};:,.?/'.split('');

    // Adiciona pools de acordo com a escolha do usuário
    final pools = <List<String>>[];
    if (lower) pools.add(lowers);
    if (upper) pools.add(uppers);
    if (digits) pools.add(nums);
    if (symbols) pools.add(syms);

    if (pools.isEmpty) {
      throw StateError('Selecione ao menos uma classe de caracteres.');
    }

    // Junta todos os caracteres possíveis
    final alphabet = <String>[];
    for (final p in pools) alphabet.addAll(p);

    int idx = 0;
    int next() {
      final b1 = rndBytes[idx % rndBytes.length];
      final b2 = rndBytes[(idx + 1) % rndBytes.length];
      idx += 2;
      return ((b1 << 8) ^ b2) & 0x7fffffff;
    }

    // Garante pelo menos 1 caractere de cada classe escolhida
    final chars = <String>[];
    for (final pool in pools) {
      final n = next() % pool.length;
      chars.add(pool[n]);
    }

    // Preenche até o tamanho desejado
    while (chars.length < length) {
      final n = next() % alphabet.length;
      chars.add(alphabet[n]);
    }

    // Embaralha os caracteres
    final shuffleSeed = sha256.convert(utf8.encode(seed + '::shuffle')).bytes;
    _detShuffle(chars, shuffleSeed);

    return chars.take(length).join(); // Retorna a senha final
  }

  /// Calcula a "força" da senha gerada
  void _calcStrength(String pwd) {
    if (pwd.isEmpty) {
      strengthScore = 0.0;
      strengthLabel = '—';
      return;
    }
    int classes = 0;
    if (RegExp(r'[a-z]').hasMatch(pwd)) classes++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) classes++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) classes++;
    if (RegExp(r'[!@#\$%\^&\*\(\)\-\_\=\+\[\]\{\};:,\.\?\/]').hasMatch(pwd)) classes++;

    // Calcula pontuação com base no comprimento e variedade de caracteres
    final lenScore = (pwd.length / 20).clamp(0.0, 1.0);
    final classScore = (classes / 4).clamp(0.0, 1.0);
    strengthScore = (0.6 * lenScore + 0.4 * classScore).clamp(0.0, 1.0);

    // Classificação da força
    if (strengthScore < 0.33) {
      strengthLabel = 'Fraca';
    } else if (strengthScore < 0.66) {
      strengthLabel = 'Média';
    } else {
      strengthLabel = 'Forte';
    }
  }

  /// Gera a senha final
  void gerarSenha() {
    final seed = _buildSeed();

    // Verifica se o usuário selecionou alguma classe de caracteres
    if (!(useLower || useUpper || useDigits || useSymbols)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos uma classe de caracteres.')),
      );
      return;
    }

    final needed = max(comprimento.toInt() * 2, 64); // Bytes necessários
    final rnd = _deriveBytesDeterministic(
      seed: seed,
      passphrase: fraseController.text,
      neededLen: needed,
    );

    // Gera senha formatada
    final pwd = _formatPassword(
      seed: seed,
      length: comprimento.toInt(),
      lower: useLower,
      upper: useUpper,
      digits: useDigits,
      symbols: useSymbols,
      rndBytes: rnd,
    );

    senhaGerada = pwd;
    _calcStrength(pwd); // Avalia força da senha

    setState(() {}); // Atualiza tela
  }

  /// Copia a senha gerada para o clipboard
  void copiarSenha() {
    if (senhaGerada.isEmpty) return;
    Clipboard.setData(ClipboardData(text: senhaGerada));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha copiada!')),
    );
  }

  /// Interface gráfica
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerador de Senhas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo: Serviço/Site
              TextFormField(
                controller: servicoController,
                decoration: const InputDecoration(
                  labelText: 'Serviço/Site',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o serviço' : null,
              ),
              const SizedBox(height: 12),

              // Campo: Usuário (opcional)
              TextFormField(
                controller: usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Campo: Frase-base (obrigatório)
              TextFormField(
                controller: fraseController,
                decoration: const InputDecoration(
                  labelText: 'Frase-base',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Esconde texto digitado
                validator: (v) => v == null || v.isEmpty ? 'Informe a frase-base' : null,
              ),
              const SizedBox(height: 12),

              // Campo: Sal (opcional)
              TextFormField(
                controller: salController,
                decoration: const InputDecoration(
                  labelText: 'Sal/Seed (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Slider: comprimento da senha
              Text('Comprimento: ${comprimento.round()}'),
              Slider(
                value: comprimento,
                min: 8,
                max: 32,
                divisions: 24,
                onChanged: (v) {
                  setState(() => comprimento = v);
                  _savePrefs();
                },
              ),
              const SizedBox(height: 12),

              // Dropdown: método de hash/cripto
              DropdownButtonFormField<String>(
                value: metodo,
                decoration: const InputDecoration(
                  labelText: 'Método',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'MD5', child: Text('MD5')),
                  DropdownMenuItem(value: 'SHA-1', child: Text('SHA-1')),
                  DropdownMenuItem(value: 'SHA-256', child: Text('SHA-256')),
                  DropdownMenuItem(value: 'AES-CBC', child: Text('AES-CBC')),
                ],
                onChanged: (v) {
                  setState(() => metodo = v!);
                  _savePrefs();
                },
              ),
              const SizedBox(height: 12),

              // Switches para selecionar classes de caracteres
              SwitchListTile(
                title: const Text('Letras minúsculas'),
                value: useLower,
                onChanged: (v) {
                  setState(() => useLower = v);
                  _savePrefs();
                },
              ),
              SwitchListTile(
                title: const Text('Letras maiúsculas'),
                value: useUpper,
                onChanged: (v) {
                  setState(() => useUpper = v);
                  _savePrefs();
                },
              ),
              SwitchListTile(
                title: const Text('Números'),
                value: useDigits,
                onChanged: (v) {
                  setState(() => useDigits = v);
                  _savePrefs();
                },
              ),
              SwitchListTile(
                title: const Text('Símbolos'),
                value: useSymbols,
                onChanged: (v) {
                  setState(() => useSymbols = v);
                  _savePrefs();
                },
              ),
              const SizedBox(height: 20),

              // Botão para gerar senha
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) gerarSenha();
                },
                child: const Text('Gerar Senha'),
              ),
              const SizedBox(height: 20),

              // Exibe senha e força caso exista
              if (senhaGerada.isNotEmpty) ...[
                SelectableText(
                  senhaGerada,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: strengthScore,
                  minHeight: 6,
                  color: strengthScore > 0.66
                      ? Colors.green
                      : strengthScore > 0.33
                          ? Colors.orange
                          : Colors.red,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Text('Força: $strengthLabel'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: copiarSenha,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
