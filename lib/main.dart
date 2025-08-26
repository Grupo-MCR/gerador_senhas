import 'dart:convert'; 
import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart'; 
import 'package:crypto/crypto.dart';

void main() {
  runApp(const MyApp());
}

// Classe principal do aplicativo
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // remove a faixa "debug" do canto da tela
      title: 'Gerador de Senhas',
      theme: ThemeData(primarySwatch: Colors.indigo), 
      home: const PasswordPage(),
    );
  }
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

// Estado da tela 
class _PasswordPageState extends State<PasswordPage> {
  final _formKey = GlobalKey<FormState>(); // chave para validar o formulário

  // Controladores para pegar o texto digitado
  final servicoController = TextEditingController();
  final usuarioController = TextEditingController();
  final fraseController = TextEditingController();

  double comprimento = 12; // comprimento padrão da senha
  String metodo = 'SHA-256'; // método padrão de hash
  String senhaGerada = ''; // senha que será gerada
  String forca = ''; // indicador de força da senha

  // Função para gerar a senha
  void gerarSenha() {
    String semente =
        servicoController.text + usuarioController.text + fraseController.text;

    // transformamos em bytes
    List<int> bytes = utf8.encode(semente);

    // escolhemos o algoritmo de hash
    Digest digest;
    if (metodo == 'MD5') {
      digest = md5.convert(bytes);
    } else if (metodo == 'SHA-1') {
      digest = sha1.convert(bytes);
    } else {
      digest = sha256.convert(bytes);
    }

    // convertemos o hash em base64 para virar caracteres legíveis
    String base = base64UrlEncode(digest.bytes);

    // cortamos a senha para o comprimento que o usuário escolheu
    senhaGerada = base.substring(0, comprimento.toInt());

    // calculamos o nivel de dificuldade da senha de forma simples
    if (senhaGerada.length < 10) {
      forca = 'Fraca';
    } else if (senhaGerada.length < 16) {
      forca = 'Média';
    } else {
      forca = 'Forte';
    }

    // atualiza a tela
    setState(() {});
  }

  // Função para copiar a senha para a área de transferência
  void copiarSenha() {
    if (senhaGerada.isEmpty) return; // só copia se tiver senha
    Clipboard.setData(ClipboardData(text: senhaGerada)); // copia
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha copiada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerador de Senhas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey, // liga o form à chave para validar
          child: ListView(
            children: [
              // Campo de Serviço/Site
              TextFormField(
                controller: servicoController,
                decoration: const InputDecoration(
                  labelText: 'Serviço/Site',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o serviço' : null,
              ),
              const SizedBox(height: 12),

              // Campo de Usuário (opcional)
              TextFormField(
                controller: usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Campo de Frase-base (obrigatório e oculto com bolinhas)
              TextFormField(
                controller: fraseController,
                decoration: const InputDecoration(
                  labelText: 'Frase-base',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // oculta o texto digitado
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe a frase-base' : null,
              ),
              const SizedBox(height: 20),

              // Slider para escolher o comprimento
              Text('Comprimento: ${comprimento.round()}'),
              Slider(
                value: comprimento,
                min: 8,
                max: 32,
                divisions: 24,
                onChanged: (v) {
                  setState(() => comprimento = v);
                },
              ),
              const SizedBox(height: 20),

              // Dropdown para escolher o método de hash
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
                ],
                onChanged: (v) => setState(() => metodo = v!),
              ),
              const SizedBox(height: 20),

              // Botão para gerar a senha
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    gerarSenha();
                  }
                },
                child: const Text('Gerar Senha'),
              ),
              const SizedBox(height: 20),

              // Mostra a senha gerada, força e botão de copiar
              if (senhaGerada.isNotEmpty) ...[
                SelectableText(
                  senhaGerada,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Força: $forca'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: copiarSenha,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}