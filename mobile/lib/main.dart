import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class Article {
  const Article({
    required this.url,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.parts,
  });

  final String url;
  final String title;
  final String subtitle;
  final Image image;
  final List<ArticlePart> parts;

  static List<Article> fromJson(String body) {
    List<Article> articles = [];
    List<dynamic> decoded = json.decode(body);
    for (var article in decoded) {
      List<ArticlePart> parts = [];
      for (var part in article["parts"] as List<dynamic>) {
        parts.add(
          ArticlePart(
            text: part["text"],
            annotation: part["annotation"],
            sources:
                part["sources"] != null
                    ? List<String>.from(part["sources"])
                    : null,
          ),
        );
      }
      articles.add(
        Article(
          url: article["url"] as String,
          title: article["title"] as String,
          subtitle: article["subtitle"] as String,
          image: Image.network(article["image"] as String),
          parts: parts,
        ),
      );
    }
    return articles;
  }
}

class ArticlePart {
  ArticlePart({required this.text, this.annotation, this.sources});

  final String text;
  final String? annotation;
  final List<String>? sources;
}

class _AppState extends State<App> {
  List<Article> articles = [];
  int? pageId;
  String updateUrl = "localhost:6363";

  Future<void> update() async {
    //var response = await http.get(Uri.https(updateUrl));
    articles = Article.fromJson(
      "[{\"url\":\"localhost:636\",\"title\":\"Title\",\"subtitle\":\"Subtitle\",\"image\":\"https://miro.medium.com/v2/resize:fit:1280/format:webp/1*uyZqUA7yQuJYrHtuDv49Rw.jpeg\",\"parts\":[{\"text\": \"First \"},{\"text\":\"Second\",\"annotation\":\"Annotation\",\"sources\":[\"https://nytimes.com\"]}]}]",
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    update();
  }

  @override
  Widget build(BuildContext context) {
    Widget? page;
    void rebuild(int? newPageId) {
      setState(() {
        pageId = newPageId;
      });
    }

    void setUpdateUrl(String url) {
      setState(() {
        updateUrl = url;
      });
    }

    if (pageId == null) {
      page = HomePage(
        articles: articles,
        setUpdateUrl: setUpdateUrl,
        updateUrl: updateUrl,
        rebuild: rebuild,
      );
    } else {
      page = ArticlePage(article: articles[pageId!], rebuild: rebuild);
    }
    return MaterialApp(
      title: 'Bias Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RefreshIndicator(onRefresh: update, child: Scaffold(body: page)),
    );
  }
}

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.rebuild, required this.article});

  final Function(int?) rebuild;
  final Article article;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didProp, _) async {
        widget.rebuild(null);
      },
      child: ListView(
        children: [
          Text(
            widget.article.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 36),
          ),
          Text(
            widget.article.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28),
          ),
          Text.rich(
            TextSpan(
              children:
                  widget.article.parts.map((part) {
                    return TextSpan(
                      text: part.text,
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              if (part.annotation != null) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        part.annotation!,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      content: Text(
                                        part.sources?.join("\n") ?? "",
                                      ),
                                    );
                                  },
                                );
                              }
                            },
                      style:
                          part.annotation != null
                              ? TextStyle(
                                fontSize: 18,
                                background: Paint()..color = Colors.amber,
                              )
                              : TextStyle(fontSize: 18),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.rebuild,
    required this.setUpdateUrl,
    required this.updateUrl,
    required this.articles,
  });

  final Function(int?) rebuild;
  final Function(String) setUpdateUrl;
  final String updateUrl;
  final List<Article> articles;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Row(
        children: [
          Text("Home", style: TextStyle(fontSize: 20)),
          Spacer(),
          IconButton.filled(
            icon: Icon(Icons.settings_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: TextFormField(
                      autocorrect: false,
                      initialValue: widget.updateUrl,
                      onChanged: (url) {
                        widget.setUpdateUrl(url);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ];
    children.addAll(
      widget.articles.map((article) {
        return Card(
          child: ListTile(
            title: Text(article.title, style: TextStyle(fontSize: 20)),
            subtitle: Text(article.subtitle, style: TextStyle(fontSize: 16)),
            leading: article.image,
            onTap: () {
              widget.rebuild(widget.articles.indexOf(article));
            },
          ),
        );
      }),
    );
    return ListView(children: children);
  }
}
