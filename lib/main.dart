import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

void main() {
  runApp(const LanternaInteligenteApp());
}

class LanternaInteligenteApp extends StatelessWidget {
  const LanternaInteligenteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lanterna Inteligente',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B10),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const LanternaScreen(),
    );
  }
}

class LanternaScreen extends StatefulWidget {
  const LanternaScreen({super.key});

  @override
  State<LanternaScreen> createState() => _LanternaScreenState();
}

class _LanternaScreenState extends State<LanternaScreen> {
  bool _lanternaLigada = false;
  bool _modoAutomatico = false;
  bool _possuiFlash = false;
  bool _verificandoFlash = true;

  Timer? _timerAutomatico;

  // Cores principais
  static const Color fundo = Color(0xFF0B0B10);
  static const Color painel = Color(0xFF15151F);
  static const Color painelclaro = Color(0xFF1D1D2A);
  static const Color roxo = Color(0xFF8B5CF6);
  static const Color roxoClaro = Color(0xFFA78BFA);
  static const Color amarelo = Color(0xFFFFC857);
  static const Color cinza = Color(0xFF8B8B98);

  // O torch_light funciona em Android e iOS.
  bool get _podeUsarFlashFisico {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void initState() {
    super.initState();
    _verificarFlash();
  }

  @override
  void dispose() {
    _timerAutomatico?.cancel();
    super.dispose();
  }

  // Verifica se o aparelho possui flash.
  Future<void> _verificarFlash() async {
    if (!_podeUsarFlashFisico) {
      setState(() {
        _possuiFlash = false;
        _verificandoFlash = false;
      });
      return;
    }

    try {
      final disponivel = await TorchLight.isTorchAvailable();

      if (!mounted) return;

      setState(() {
        _possuiFlash = disponivel;
        _verificandoFlash = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _possuiFlash = false;
        _verificandoFlash = false;
      });
    }
  }

  // Liga ou desliga a lanterna.
  Future<void> _alternarLanterna() async {
    // Se o dispositivo tiver flash físico, tenta controlar o flash real.
    if (_podeUsarFlashFisico && _possuiFlash) {
      try {
        if (_lanternaLigada) {
          await TorchLight.disableTorch();
        } else {
          await TorchLight.enableTorch();
        }

        if (!mounted) return;

        setState(() {
          _lanternaLigada = !_lanternaLigada;
        });
      } on Exception {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível controlar o flash deste dispositivo.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Sem flash físico: funciona como simulação visual.
      setState(() {
        _lanternaLigada = !_lanternaLigada;
      });

      if (!_podeUsarFlashFisico) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Modo visual ativado: este dispositivo não possui controle de flash.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Ativa/desativa o modo automático.
  void _alterarModoAutomatico(bool valor) {
    setState(() {
      _modoAutomatico = valor;
    });

    if (valor) {
      _iniciarModoAutomatico();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo automático ativado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _pararModoAutomatico();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo automático desativado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // O modo automático faz a lanterna alternar sozinha.
  void _iniciarModoAutomatico() {
    _timerAutomatico?.cancel();

    _timerAutomatico = Timer.periodic(
      const Duration(milliseconds: 1600),
      (_) async {
        if (!_modoAutomatico) return;

        if (_podeUsarFlashFisico && _possuiFlash) {
          try {
            if (_lanternaLigada) {
              await TorchLight.disableTorch();
            } else {
              await TorchLight.enableTorch();
            }
          } catch (_) {
            // Caso o flash não possa ser controlado,
            // mantém apenas o efeito visual.
          }
        }

        if (!mounted || !_modoAutomatico) return;

        setState(() {
          _lanternaLigada = !_lanternaLigada;
        });
      },
    );
  }

  void _pararModoAutomatico() {
    _timerAutomatico?.cancel();
    _timerAutomatico = null;
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(),

                  const SizedBox(height: 24),

                  _painelStatus(),

                  const SizedBox(height: 18),

                  _controlePrincipal(),

                  const SizedBox(height: 18),

                  _painelAutomatico(),

                  const SizedBox(height: 18),

                  _painelDispositivo(),

                  const SizedBox(height: 22),

                  Center(
                    child: Text(
                      'Lanterna Inteligente • Projeto Flutter',
                      style: TextStyle(
                        color: cinza.withOpacity(0.65),
                        fontSize: largura < 400 ? 11 : 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // CABEÇALHO
  // ------------------------------------------------------------

  Widget _cabecalho() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: roxo.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: roxo.withOpacity(0.35),
            ),
          ),
          child: const Icon(
            Icons.flashlight_on_rounded,
            color: roxoClaro,
            size: 25,
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMART TORCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Central de iluminação',
                style: TextStyle(
                  color: cinza,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: roxoClaro,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: roxo.withOpacity(0.7),
                      blurRadius: 7,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ONLINE',
                style: TextStyle(
                  color: cinza,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PAINEL DE STATUS
  // ------------------------------------------------------------

  Widget _painelStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lanternaLigada
            ? const Color(0xFF211E18)
            : painel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _lanternaLigada
              ? amarelo.withOpacity(0.55)
              : Colors.white.withOpacity(0.07),
          width: 1.2,
        ),
        boxShadow: _lanternaLigada
            ? [
                BoxShadow(
                  color: amarelo.withOpacity(0.13),
                  blurRadius: 35,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STATUS ATUAL',
                style: TextStyle(
                  color: cinza,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _lanternaLigada ? 'ATIVA' : 'INATIVA',
                  key: ValueKey(_lanternaLigada),
                  style: TextStyle(
                    color: _lanternaLigada ? amarelo : cinza,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Círculo central da lanterna
          AnimatedScale(
            scale: _lanternaLigada ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lanternaLigada
                    ? amarelo.withOpacity(0.15)
                    : const Color(0xFF111119),
                border: Border.all(
                  color: _lanternaLigada
                      ? amarelo
                      : Colors.white.withOpacity(0.08),
                  width: 2,
                ),
                boxShadow: _lanternaLigada
                    ? [
                        BoxShadow(
                          color: amarelo.withOpacity(0.38),
                          blurRadius: 45,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    _lanternaLigada
                        ? Icons.light_mode_rounded
                        : Icons.lightbulb_outline_rounded,
                    key: ValueKey(_lanternaLigada),
                    size: 58,
                    color: _lanternaLigada
                        ? amarelo
                        : Colors.white.withOpacity(0.25),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _lanternaLigada
                  ? 'ILUMINAÇÃO ATIVA'
                  : 'ILUMINAÇÃO DESATIVADA',
              key: ValueKey(_lanternaLigada),
              style: TextStyle(
                color: _lanternaLigada ? Colors.white : cinza,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _lanternaLigada
                ? 'A lanterna está emitindo luz.'
                : 'A lanterna está aguardando comando.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cinza.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CONTROLE PRINCIPAL
  // ------------------------------------------------------------

  Widget _controlePrincipal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: painel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTROLE MANUAL',
                  style: TextStyle(
                    color: cinza,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _lanternaLigada
                      ? 'Desligar iluminação'
                      : 'Acionar iluminação',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Botão diferente do tradicional
          GestureDetector(
            onTap: _modoAutomatico ? null : _alternarLanterna,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _modoAutomatico
                    ? Colors.white.withOpacity(0.05)
                    : (_lanternaLigada ? amarelo : const Color(0xFF292936)),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _lanternaLigada
                      ? amarelo
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: _lanternaLigada
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _lanternaLigada
                        ? Colors.white
                        : const Color(0xFF666674),
                    boxShadow: _lanternaLigada
                        ? [
                            BoxShadow(
                              color: amarelo.withOpacity(0.45),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _lanternaLigada
                        ? Icons.power_settings_new_rounded
                        : Icons.power_settings_new_rounded,
                    size: 18,
                    color: _lanternaLigada
                        ? const Color(0xFF7A5A00)
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MODO AUTOMÁTICO
  // ------------------------------------------------------------

  Widget _painelAutomatico() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _modoAutomatico
            ? const Color(0xFF1B1725)
            : painel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _modoAutomatico
              ? roxo.withOpacity(0.65)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _modoAutomatico
                  ? roxo.withOpacity(0.20)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _modoAutomatico ? roxoClaro : cinza,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Automático',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Alterna a iluminação automaticamente.',
                  style: TextStyle(
                    color: cinza,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: _modoAutomatico,
            onChanged: _alterarModoAutomatico,
            activeColor: roxoClaro,
            activeTrackColor: roxo.withOpacity(0.45),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMAÇÕES DO DISPOSITIVO
  // ------------------------------------------------------------

  Widget _painelDispositivo() {
    String titulo;
    String descricao;
    IconData icone;
    Color cor;

    if (_verificandoFlash) {
      titulo = 'Verificando dispositivo';
      descricao = 'Analisando disponibilidade do flash...';
      icone = Icons.sync_rounded;
      cor = cinza;
    } else if (_possuiFlash) {
      titulo = 'Flash físico disponível';
      descricao = 'O aplicativo pode controlar a iluminação real.';
      icone = Icons.phone_android_rounded;
      cor = const Color(0xFF55D98A);
    } else {
      titulo = 'Modo visual';
      descricao = 'Sem flash físico. A lanterna funciona pela interface.';
      icone = Icons.desktop_windows_rounded;
      cor = roxoClaro;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            color: cor,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: cor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: cinza,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}