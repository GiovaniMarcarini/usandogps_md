import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget{

  const HomePage ({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  final _linhas = <String>[];
  StreamSubscription<Position>? _subscription;
  Position? _ultimaLocalizacaoConhecida;
  double _calculoDistacia = 0;
  
  bool get _monitorandoLocalizacao => _subscription != null;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usando GPS'),
      ),
      body: _criarBody(),
    );
  }

  Widget _criarBody() => Padding(
    padding: EdgeInsets.all(10),
    child: Column(
      children: [
        ElevatedButton(
            onPressed: _obterUltimaLocalizacaoConhecida,
            child: const Text('Obter a ultima localização conhecida')
        ),
        ElevatedButton(
            onPressed: _obterLocalizacaoAtual,
            child: const Text('Obter localização atual')
        ),
        ElevatedButton(
            onPressed: _monitorandoLocalizacao ? _pararMonitoramento : _iniciarMonitoramento,
            child: Text(_monitorandoLocalizacao ? 'Parar monitoramento' : 'Iniciar monitoramento')
        ),
        ElevatedButton(
            onPressed: _limparLog,
            child: Text('Limpar Log')
        ),
        Divider(),
        Expanded(
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: _linhas.length,
                itemBuilder: (_, index) => Padding(
                  padding: EdgeInsets.all(5),
                  child: Text(_linhas[index]),
                )
            )
        )
      ],
    ),
  );

  void _obterUltimaLocalizacaoConhecida() async{
    bool permissoesPermitidas = await _permissoePermitidas();
    if(!permissoesPermitidas){
      return;
    }
    Position? position = await Geolocator.getLastKnownPosition();
    setState(() {
      if (position == null){
        _linhas.add('Nenhuma localização encontrada');
      }else{
        _linhas.add('Latitude: ${position.latitude}  |   Longetude: ${position.longitude}');
      }
    });
  }

  void _obterLocalizacaoAtual() async{
    bool servicoHabilitado = await _servicoHabilitado();

    if(!servicoHabilitado){
      return;
    }

    bool permissoesPermitidas = await _permissoePermitidas();
    if(!permissoesPermitidas){
      return;
    }

    Position? position = await Geolocator.getCurrentPosition();

    setState(() {
      _linhas.add('Latitude: ${position.latitude}  |   Longetude: ${position.longitude}');
    });
  }

  Future<bool> _permissoePermitidas() async{
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied){
        _mostrarMensagem('Não será possível utilizar o recurso por falta de'
            ' permissão!!!');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever){
      await _mostrarDialogMessagem(
          'Para utilizar esse recurso, você deverá acessar as configurações do app'
              ' e permitir a utilização do serviço de localização');
      Geolocator.openAppSettings();
      return false;
    }
    return true;

  }

  Future<bool> _servicoHabilitado() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();

    if(!servicoHabilitado){
      await _mostrarDialogMessagem(
          'Para utiliar este recurso, você deverá habilitar o serviço de localização do dispositivo'
      );
      Geolocator.openLocationSettings();
      return false;
    }

    return true;
  }

  void _iniciarMonitoramento(){
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100
    );
    _subscription = Geolocator.getPositionStream(
      locationSettings: locationSettings).listen((Position position){

    });
  }

  void _pararMonitoramento() {
    _subscription?.cancel();
    setState(() {
      _subscription = null;
      _ultimaLocalizacaoConhecida = null;
      _calculoDistacia = 0;
    });
  }

  void _limparLog(){
    setState(() {
      _linhas.clear();
    });
  }

  void _mostrarMensagem(String mensagem){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mensagem)
    ));
  }

  Future<void> _mostrarDialogMessagem(String mensagem) async{
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: const Text('ATENÇÃO'),
            content: Text(mensagem),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK')
              )
            ]
        )
    );
  }
}