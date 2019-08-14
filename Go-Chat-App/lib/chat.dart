import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String serverIp;
  final String userName;
  final String token;

  ChatPage(
      {@required this.serverIp, @required this.userName, @required this.token});

  @override
  State<StatefulWidget> createState() {
    return _ChatPageState();
  }
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = new TextEditingController();

  bool _isComposing = false;
  bool _isFirstTime = true;

  int _lastMessageId = 0;

  bool _runGetRequest = false;

  @override
  void initState() {
    super.initState();
    _runGetRequest = true;
    performGetRequests();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Go Chat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: new Column(
        //modified
        children: <Widget>[
          //new
          new Flexible(
            //new
            child: new ListView.builder(
              //new
              padding: new EdgeInsets.all(8.0), //new
              reverse: true, //new
              itemBuilder: (_, int index) => _messages[index], //new
              itemCount: _messages.length, //new
            ), //new
          ), //new
          new Divider(height: 1.0), //new
          new Container(
            //new
            decoration:
                new BoxDecoration(color: Theme.of(context).cardColor), //new
            child: _buildTextComposer(), //modified
          ), //new
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      //new
      data: new IconThemeData(color: Theme.of(context).accentColor), //new
      child: new Container(
        //modified
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                decoration:
                    new InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? new CupertinoButton(
                        child: new Text("Send"),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text) //new
                            : null,
                      )
                    : //new
                    new IconButton(
                        //modified
                        icon: new Icon(Icons.send),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      )),
          ],
        ),
      ), //new
    );
  }

  void addChatMessage(Message msg) {
    _lastMessageId = msg.id;
    bool isme = msg.name == widget.userName;
    if (isme && !_isFirstTime) {
      return;
    }
    ChatMessage message = new ChatMessage(
      text: msg.msg,
      name: msg.name,
      isMe: isme,
      animationController: new AnimationController(
        //new
        duration: new Duration(milliseconds: 300), //new
        vsync: this, //new
      ), //new
    );
    setState(() {
      _messages.insert(0, message);
    });
    message.animationController.forward();
  }

  void _handleSubmitted(String text) {
    performPostRequest(text);
    _textController.clear();
    setState(() {
      //new
      _isComposing = false; //new
    });
    ChatMessage message = new ChatMessage(
      text: text,
      name: widget.userName,
      isMe: true,
      animationController: new AnimationController(
        //new
        duration: new Duration(milliseconds: 700), //new
        vsync: this, //new
      ), //new
    ); //new
    setState(() {
      _messages.insert(0, message);
    });
    message.animationController.forward();
  }

  @override
  void dispose() {
    //new
    for (ChatMessage message in _messages) //new
      message.animationController.dispose(); //new
    _runGetRequest = false;
    super.dispose(); //new
  }

  performPostRequest(String message) {
    var body =
        jsonEncode({"Id": 1, "Name": widget.userName, "Message": message});
    http.post(getServerGetIp(),
        headers: {"Content-Type": "application/json"}, body: body);
  }

  performGetRequests() async {
    while (_runGetRequest) {
      final response = await http.get(getServerGetIp());
      print(response.body);
      if (response.body != '') {
        List<Message> messages = parseMessages(response.body);
        print(messages);
        for (var message in messages) {
          print(message.name);
          addChatMessage(message);
        }
        _isFirstTime = false;
      }

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  String getServerGetIp() {
    return 'http://' +
        widget.serverIp +
        ':8080/chat/' +
        widget.token +
        '/' +
        _lastMessageId.toString();
  }

  List<Message> parseMessages(String responseBody) {
    final parsed = json.decode(responseBody);
    print(parsed);
    return (parsed as List)
        .map<Message>((json) => new Message.fromJson(json))
        .toList();
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage(
      {@required this.text,
      @required this.name,
      @required this.isMe,
      @required this.animationController});
  final String text;
  final String name;
  final bool isMe;
  final AnimationController animationController;

  Widget getContainer() {
    return Row(
      children: <Widget>[
        isMe
            ? Expanded(
                child: SizedBox(),
              )
            : SizedBox(),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
              color: isMe
                  ? Colors.teal[800]
                  : name == "Server" ? Colors.indigo : Colors.blueGrey[800],
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                  bottomLeft:
                      isMe ? Radius.circular(16.0) : Radius.circular(0.0),
                  bottomRight:
                      !isMe ? Radius.circular(16.0) : Radius.circular(0.0))),
          child: new Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              !isMe
                  ? new Text(name,
                      style: TextStyle(fontWeight: FontWeight.bold))
                  : Container(
                      width: 0,
                      height: 0,
                    ),
              new Container(
                margin: isMe
                    ? const EdgeInsets.only(right: 5.0)
                    : const EdgeInsets.only(top: 5.0),
                child: new Text(text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget build(BuildContext context) {
    return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animationController, curve: Curves.easeOut),
        axisAlignment: 0.0, //new
        child: getContainer());
  }
}

class Message {
  final int id;
  final String name;
  final String msg;

  Message({this.id, this.name, this.msg});

  factory Message.fromJson(Map<String, dynamic> json) {
    return new Message(
      id: json['Id'] as int,
      name: json['Name'] as String,
      msg: json['Message'] as String,
    );
  }
}
