import 'package:flutter/material.dart';
import 'chat.dart';
import 'dart:io';
import 'package:wifi/wifi.dart';

import 'package:http/http.dart' as http;

final Color _primaryColor = Colors.green;

String _loopIp = "";

class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final _serverIpController = TextEditingController();
  final _usernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(builder: (BuildContext context) {
          return buildForm(context);
        }),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    selfIP;
  }

  Form buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        children: <Widget>[
          SizedBox(height: 80.0),
          Column(
            children: <Widget>[
              Text(
                'GC',
                style: TextStyle(
                    fontSize: 64.0,
                    letterSpacing: -6.0,
                    color: _primaryColor,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Welcome to Go Chat!',
                style: TextStyle(fontSize: 26.0),
              ),
            ],
          ),
          SizedBox(height: 120.0), // Changed code
          new GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: TextFormField(
              controller: _serverIpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Server IP',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return "Server IP can't be empty.";
                }
              },
            ),
          ),
          SizedBox(height: 12.0), // Changed code
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return "Username can't be empty.";
              }
            },
          ),

          ButtonBar(
            children: <Widget>[
              FlatButton(
                child: Text('CLEAR'),
                onPressed: () {
                  _serverIpController.clear();
                  _usernameController.clear();
                },
              ),
              RaisedButton(
                child: Text('CONNECT'),
                color: _primaryColor,
                textColor: Colors.white,
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    checkConnection(context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future checkConnection(BuildContext context) async {
    try {
      final response = await http.get('http://' +
          _serverIpController.text +
          ':8080/join/' +
          _usernameController.text);
      if (response.statusCode == 200) {
        if (response.body == "") {
          Scaffold.of(context).hideCurrentSnackBar();
          Scaffold.of(context).showSnackBar(
              new SnackBar(content: new Text('Username already exists')));
          return;
        }
        var route = new MaterialPageRoute(
          builder: (BuildContext context) => new ChatPage(
                serverIp: _serverIpController.text,
                userName: _usernameController.text,
                token: response.body,
              ),
        );
        Navigator.of(context).push(route);
      } else {
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text('Unable to connect to server')));
      }
    } catch (e) {
      print(e);
      Scaffold.of(context).hideCurrentSnackBar();
      Scaffold.of(context).showSnackBar(
          new SnackBar(content: new Text('Unable to connect to server')));
    }
  }

  Future<InternetAddress> get selfIP async {
    String ip = await Wifi.ip;
    var internetIp = InternetAddress(ip);
    if (internetIp.rawAddress.length <= 4) {
      for (var i = 0; i < 3; i++) {
        _loopIp += internetIp.rawAddress[i].toString() + ".";
      }
    }

    return internetIp;
  }
}
