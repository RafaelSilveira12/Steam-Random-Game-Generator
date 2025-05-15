import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class Game {
  final int appId;
  final String name;
  final String imageUrl;

  Game({required this.appId, required this.name, required this.imageUrl});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      appId: json['appid'],
      name: json['name'],
      imageUrl: '', 
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogos Aleatórios Steam',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameListScreen(),
    );
  }
}

class GameListScreen extends StatefulWidget {
  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  final String apiUrl = 'https://api.steampowered.com/ISteamApps/GetAppList/v2/';
  late Future<Game> randomGame;

  @override
  void initState() {
    super.initState();
    randomGame = fetchRandomGame();
  }

  
  Future<List<Game>> fetchGames() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> apps = data['applist']['apps'];

      List<Game> games = apps.map((json) => Game.fromJson(json)).toList();
      return games;
    } else {
      throw Exception('Falha ao carregar jogos');
    }
  }

  // Função para pegar a imagem do jogo pela API
  Future<String> fetchGameImage(int appId) async {
    final response = await http.get(Uri.parse('https://store.steampowered.com/api/appdetails?appids=$appId'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      if (data['$appId'] != null && data['$appId']['success']) {
        String imageUrl = data['$appId']['data']['header_image'];
        return imageUrl;
      } else {
        throw Exception('Imagem não encontrada');
      }
    } else {
      throw Exception('Falha ao carregar imagem');
    }
  }

  Future<Game> fetchRandomGame() async {
    List<Game> games = await fetchGames();
    games.shuffle();
    Game randomGame = games.first;


    String imageUrl = await fetchGameImage(randomGame.appId);

    
    return Game(
      appId: randomGame.appId,
      name: randomGame.name,
      imageUrl: imageUrl,
    );
  }

 
  Future<void> launchGameLink(int appId) async {
    final url = 'https://store.steampowered.com/app/$appId';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não foi possível abrir o link';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jogos Aleatórios Steam'),
      ),
      body: FutureBuilder<Game>(
        future: randomGame,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar jogos: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Nenhum jogo encontrado.'));
          }

          Game game = snapshot.data!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Jogo Aleatório:', style: TextStyle(fontSize: 20)),
                SizedBox(height: 20),
                Text(
                  game.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                game.imageUrl.isNotEmpty
                    ? Image.network(game.imageUrl)
                    : Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey,
                        child: Center(child: Text('Sem imagem')),
                      ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      randomGame = fetchRandomGame(); 
                    });
                  },
                  child: Text('Novo Jogo'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => launchGameLink(game.appId), 
                  child: Text('Ver no Steam'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
