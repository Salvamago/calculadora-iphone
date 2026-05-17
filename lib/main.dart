import 'package:flutter/material.dart';

void main() {
  runApp(const CalculadoraIPhoneApp());
}

class CalculadoraIPhoneApp extends StatelessWidget {
  const CalculadoraIPhoneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CalculadoraIPhone(),
    );
  }
}

class CalculadoraIPhone extends StatefulWidget {
  const CalculadoraIPhone({Key? key}) : super(key: key);

  @override
  State<CalculadoraIPhone> createState() => _CalculadoraIPhoneState();
}

class _CalculadoraIPhoneState extends State<CalculadoraIPhone> {
  String _display = '0';
  String _operacionEnCurso = '';
  double? _primerNumero;
  String? _operacion;
  bool _debeLimpiarPantalla = false;

  // CONTROL DEL TRUCO (MENTALISMO)
  int _contadorMultiplicar = 0;
  bool _modoProgramacionActivo = false;
  bool _trucoConfigurado = false;
  int _minutosAgregar = 0;

  bool _faseForzajeActiva = false;
  String _numeroNecesitadoForzado = '';
  int _indiceDigitoForzado = 0; // Controla qué dígito del forzaje toca mostrar

  String _obtenerNumeroObjetivo() {
    DateTime ahora = DateTime.now();
    ahora = ahora.add(Duration(minutes: _minutosAgregar));

    String dia = ahora.day.toString().padLeft(2, '0');
    String mes = ahora.month.toString().padLeft(2, '0');
    String anio = ahora.year.toString();
    String hora = ahora.hour.toString().padLeft(2, '0');
    String minuto = ahora.minute.toString().padLeft(2, '0');

    return '$dia$mes$anio$hora$minuto';
  }

  void _presionarBoton(String texto) {
    setState(() {
      // 1. REINICIO TOTAL CON "C" O "AC"
      if (texto == 'C' || texto == 'AC') {
        _display = '0';
        _operacionEnCurso = '';
        _primerNumero = null;
        _operacion = null;
        _debeLimpiarPantalla = false;
        _contadorMultiplicar = 0;
        _modoProgramacionActivo = false;
        _trucoConfigurado = false;
        _faseForzajeActiva = false;
        _numeroNecesitadoForzado = '';
        _indiceDigitoForzado = 0;
        return;
      }

      // 2. DETECCIÓN DE LA SECUENCIA SECRETA (× × ×)
      if (texto == '×' && !_trucoConfigurado && !_faseForzajeActiva) {
        _contadorMultiplicar++;
        if (_contadorMultiplicar == 3) {
          _modoProgramacionActivo = true;
          _display = '0.0'; // Señal visual temporal discreta
          _contadorMultiplicar = 0;
          return;
        }
      } else if (texto != '×' && !_modoProgramacionActivo) {
        _contadorMultiplicar = 0;
      }

      // 3. LÓGICA EN MODO PROGRAMACIÓN
      if (_modoProgramacionActivo) {
        if (RegExp(r'^[1-9]$').hasMatch(texto)) {
          _minutosAgregar = int.parse(texto);

          _modoProgramacionActivo = false;
          _trucoConfigurado = true;
          _display = '0';
          _operacionEnCurso = '';
          _primerNumero = null;
          _operacion = null;
          return;
        }
        return;
      }

      // 4. INTERCEPCIÓN DÍGITO A DÍGITO (FASE DE FORZAJE)
      if (_trucoConfigurado && _faseForzajeActiva) {
        if (RegExp(r'^[0-9]$').hasMatch(texto) || texto == ',') {
          // Si es el primer toque del tercer número, limpiamos el display del subtotal
          if (_debeLimpiarPantalla) {
            _display = '';
            _debeLimpiarPantalla = false;
          }

          // Agrega los dígitos uno por uno a medida que el espectador presiona la pantalla
          if (_indiceDigitoForzado < _numeroNecesitadoForzado.length) {
            _display += _numeroNecesitadoForzado[_indiceDigitoForzado];
            _indiceDigitoForzado++;
          }

          String primNumStr =
              _primerNumero! % 1 == 0
                  ? _primerNumero!.toInt().toString()
                  : _primerNumero.toString();
          _operacionEnCurso = '$primNumStr $_operacion $_display';
          return;
        }
      }

      // DISPARADOR DEL TRUCO AL PRESIONAR EL SIGNO "+" DESPUÉS DE MULTIPLICAR
      if (_trucoConfigurado &&
          texto == '+' &&
          _operacion == '×' &&
          _primerNumero != null) {
        double segundoNumero =
            double.tryParse(_display.replaceAll(',', '.')) ?? 0;
        double subtotalMultiplicacion = _primerNumero! * segundoNumero;

        // Calculamos la cifra completa que va a hacer falta meter
        double objetivo = double.parse(_obtenerNumeroObjetivo());
        double necesario = objetivo - subtotalMultiplicacion;

        if (necesario < 0) necesario = necesario.abs();

        _numeroNecesitadoForzado =
            necesario % 1 == 0
                ? necesario.toInt().toString()
                : necesario.toString().replaceAll('.', '');

        _primerNumero = subtotalMultiplicacion;
        _operacion = '+';

        // Muestra el subtotal tal cual lo haría el comportamiento nativo de iOS
        _display =
            subtotalMultiplicacion % 1 == 0
                ? subtotalMultiplicacion.toInt().toString()
                : subtotalMultiplicacion.toString().replaceAll('.', ',');
        _operacionEnCurso = '$_display +';
        _debeLimpiarPantalla = true;

        _faseForzajeActiva = true;
        _indiceDigitoForzado =
            0; // Reseteamos para arrancar desde el primer dígito
        return;
      }

      // 5. RESOLUCIÓN DEL FORZAJE AL PRESIONAR "="
      if (texto == '=' && _trucoConfigurado && _faseForzajeActiva) {
        double resultadoFinal = double.parse(_obtenerNumeroObjetivo());
        _display =
            resultadoFinal % 1 == 0
                ? resultadoFinal.toInt().toString()
                : resultadoFinal.toString();
        _operacionEnCurso = '';
        _primerNumero = null;
        _operacion = null;
        _debeLimpiarPantalla = true;

        _trucoConfigurado = false;
        _faseForzajeActiva = false;
        _indiceDigitoForzado = 0;
        return;
      }

      // 6. FUNCIONAMIENTO ORDINARIO DE LA CALCULADORA
      if (texto == '+' || texto == '-' || texto == '×' || texto == '÷') {
        _primerNumero = double.tryParse(_display.replaceAll(',', '.'));
        _operacion = texto;
        _operacionEnCurso = '$_display $texto';
        _debeLimpiarPantalla = true;
      } else if (texto == '=') {
        if (_primerNumero != null && _operacion != null) {
          double segundoNumero =
              double.tryParse(_display.replaceAll(',', '.')) ?? 0;
          double resultado = 0;

          switch (_operacion) {
            case '+':
              resultado = _primerNumero! + segundoNumero;
              break;
            case '-':
              resultado = _primerNumero! - segundoNumero;
              break;
            case '×':
              resultado = _primerNumero! * segundoNumero;
              break;
            case '÷':
              resultado =
                  segundoNumero != 0 ? _primerNumero! / segundoNumero : 0;
              break;
          }

          _operacionEnCurso = '';
          _display =
              resultado % 1 == 0
                  ? resultado.toInt().toString()
                  : resultado.toString().replaceAll('.', ',');
          _primerNumero = null;
          _operacion = null;
          _debeLimpiarPantalla = true;
        }
      } else {
        if (RegExp(r'^[0-9]$').hasMatch(texto) || texto == ',') {
          if (_display == '0' || _debeLimpiarPantalla) {
            _display = texto;
            _debeLimpiarPantalla = false;
          } else {
            _display += texto;
          }

          if (_operacion != null && _primerNumero != null) {
            String primNumStr =
                _primerNumero! % 1 == 0
                    ? _primerNumero!.toInt().toString()
                    : _primerNumero.toString();
            _operacionEnCurso = '$primNumStr $_operacion $_display';
          }
        }
      }
    });
  }

  Widget _crearBoton(
    String texto,
    Color colorFondo,
    Color colorTexto,
    double alturaMaximaBoton, {
    bool esDoble = false,
  }) {
    return Expanded(
      flex: esDoble ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SizedBox(
          height: alturaMaximaBoton,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorFondo,
              shape: esDoble ? const StadiumBorder() : const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => _presionarBoton(texto),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double tamanoFuente = constraints.maxHeight * 0.36;
                return Text(
                  texto,
                  style: TextStyle(
                    fontSize: tamanoFuente,
                    fontWeight: FontWeight.w400,
                    color: colorTexto,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color grisClaro = const Color(0xFFA5A5A5);
    Color grisOscuro = const Color(0xFF333333);
    Color naranja = const Color(0xFFFF9F0A);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // PANTALLA DE RESULTADOS
              Expanded(
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(right: 12, bottom: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_operacionEnCurso.isNotEmpty)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _operacionEnCurso,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _display,
                          style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // TECLADO ADAPTATIVO
              LayoutBuilder(
                builder: (context, constraints) {
                  double alturaBoton =
                      MediaQuery.of(context).size.height * 0.085;
                  if (alturaBoton > 85) alturaBoton = 85;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _crearBoton(
                            _display == '0' ? 'AC' : 'C',
                            grisClaro,
                            Colors.black,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '+/-',
                            grisClaro,
                            Colors.black,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '%',
                            grisClaro,
                            Colors.black,
                            alturaBoton,
                          ),
                          _crearBoton('÷', naranja, Colors.white, alturaBoton),
                        ],
                      ),
                      Row(
                        children: [
                          _crearBoton(
                            '7',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '8',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '9',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton('×', naranja, Colors.white, alturaBoton),
                        ],
                      ),
                      Row(
                        children: [
                          _crearBoton(
                            '4',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '5',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '6',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton('-', naranja, Colors.white, alturaBoton),
                        ],
                      ),
                      Row(
                        children: [
                          _crearBoton(
                            '1',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '2',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton(
                            '3',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton('+', naranja, Colors.white, alturaBoton),
                        ],
                      ),
                      Row(
                        children: [
                          _crearBoton(
                            '0',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                            esDoble: true,
                          ),
                          _crearBoton(
                            ',',
                            grisOscuro,
                            Colors.white,
                            alturaBoton,
                          ),
                          _crearBoton('=', naranja, Colors.white, alturaBoton),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
