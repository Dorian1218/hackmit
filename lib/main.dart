import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:xml/xml.dart';
//import 'package:chaleno/chaleno.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  Gemini.init(apiKey: "AIzaSyDPdHzqj9t-QU6wBXLtETggAG9-GgxOsLU");
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
  String? annotation;
  List<String>? sources;
}

class _AppState extends State<App> {
  List<Article> articles = [];
  int? pageId;
  String updateUrl = "localhost:6363";
  List<String> rssContentUrls = [
    "https://www.rt.com/rss/news/",
    "https://moxie.foxnews.com/google-publisher/latest.xml",
  ];
  //String ajUrl = "https://www.aljazeera.com/xml/rss/all.xml";
  String bbcUrl = "https://feeds.bbci.co.uk/news/world/rss.xml";

  Future<void> update() async {
    //var response = await http.get(Uri.https(updateUrl));
    var client = http.Client();
    var rssArticles = <Article>[];
    /*var xmlString = (await client.get(Uri.parse(ajUrl))).body;
    var document = XmlDocument.parse(xmlString);
    var imageUrl =
        document
            .findAllElements("image")
            .first
            .findElements("url")
            .first
            .innerText;
    var items = document.findAllElements("item");
    for (var item in items) {
      rssArticles.add(
        Article(
          image: Image.network(imageUrl),
          title: item.getElement("title")!.innerText,
          subtitle: item
              .getElement("description")!
              .innerText
              .replaceAll(RegExp(r'\<.*?\/\>'), "")
              .replaceAll(RegExp(r'\<.*?\<\/'), ""),
          url: item.getElement("link")!.innerText,
          parts: [],
        ),
      );
    }*/
    for (var url in rssContentUrls) {
      var xmlString = (await client.get(Uri.parse(url))).body;
      var document = XmlDocument.parse(xmlString);
      var imageUrl =
          document
              .findAllElements("image")
              .first
              .findElements("url")
              .first
              .innerText;
      var items = document.findAllElements("item");
      for (var item in items) {
        rssArticles.add(
          Article(
            image: Image.network(imageUrl),
            title: item.getElement("title")!.innerText,
            subtitle: item
                .getElement("description")!
                .innerText
                .replaceAll(RegExp(r'\<.*?\>'), "")
                .replaceAll("Read Full Article at RT.com", ""),
            url: item.getElement("link")!.innerText,
            parts:
                item
                    .getElement("content:encoded")!
                    .innerText
                    .split(RegExp(r'\<\/?p\>'))
                    .map(
                      (e) =>
                          e
                              .replaceAll("&ldquo;", "'")
                              .replaceAll("&rdquo;", "'")
                              .replaceAll("&rsquo;", "'")
                              .replaceAll("&ndash;", "-")
                              .replaceAll("&hellip;", "...")
                              .replaceAll("&nbsp;", " ")
                              .replaceAll("Read more", "")
                              .replaceAll(RegExp(r'\<.*?\>'), "")
                              .trim(),
                    )
                    .where((e) => e.isNotEmpty)
                    .map((e) => ArticlePart(text: e))
                    .toList(),
          ),
        );
      }
    }
    Gemini.init(apiKey: "");
    articles = rssArticles;
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

    void updateArticle(Article a) {
      if (pageId == null) {
        return;
      }
      setState(() {
        articles[pageId!] = a;
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
      page = ArticlePage(
        article: articles[pageId!],
        rebuild: rebuild,
        updateArticle: updateArticle,
      );
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
  const ArticlePage({
    super.key,
    required this.rebuild,
    required this.article,
    required this.updateArticle,
  });

  final Function(int?) rebuild;
  final Function(Article) updateArticle;
  final Article article;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  Future<void> gemini() async {
    var parts = [
      Part.text(
        "ANALYZE THE BIASES OF THE ARTICLE THAT WILL BE GIVEN. GIVE BACK A VALID, MACHINE-READABLE JSON ENCODED DICTIONARY, WITH THE INDEX OF THE PARAGRAPH THE BIASED SECTION APPEARS IN, IN INTEGER FORMAT. THE CORRESPONDING VALUE SHOULD BE AN EXPLANATION OF THE BIAS, IN STRING FORMAT. DO NOT INCLUDE ANY MARKDOWN NOTATION FOR CODE BLOCKS. SIMPLY START THE RESPONSE WITH AN OPENING CURLY BRACKET AND END IT WITH A CLOSING CURLY BRACKET. ONLY INCLUDE RAW JSON.",
      ),
    ];
    parts.addAll(widget.article.parts.map((e) => Part.text(e.text)));
    Gemini.instance.prompt(parts: parts).then((value) {
      Map<String, dynamic> decoded = json.decode(value!.output!);
      var article = widget.article;
      for (var p in decoded.entries) {
        article.parts[int.parse(p.key)].annotation = p.value as String;
      }
      widget.updateArticle(article);
    });
  }

  /*Future<void> updateArticle() async {
    if (widget.article.parts.isEmpty) {
      var parser = await Chaleno().load(widget.article.url);
      var parts =
          parser!
              .querySelector("#main-content-area.wysiwyg")
              .innerHTML!
              .split(RegExp(r'\<\/?p\>'))
              .map(
                (e) =>
                    e
                        .replaceAll("&ldquo;", "'")
                        .replaceAll("&rdquo;", "'")
                        .replaceAll("&rsquo;", "'")
                        .replaceAll("&ndash;", "-")
                        .replaceAll("&hellip;", "...")
                        .replaceAll("&nbsp;", " ")
                        .replaceAll("Read more", "")
                        .replaceAll(RegExp(r'\<.*?\>'), "")
                        .trim(),
              )
              .where((e) => e.isNotEmpty)
              .map((e) => ArticlePart(text: e))
              .toList();
      widget.updateArticle(
        Article(
          image: widget.article.image,
          url: widget.article.url,
          title: widget.article.title,
          subtitle: widget.article.subtitle,
          parts: parts,
        ),
      );
    }
  }*/

  @override
  void initState() {
    super.initState();
    //updateArticle();
    if (widget.article.parts.isNotEmpty) {
      gemini();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didProp, _) async {
        widget.rebuild(null);
      },
      child: ListView(
        children: [
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                widget.rebuild(null);
              },
              child: Text("Home", style: TextStyle(fontSize: 22)),
            ),
          ),
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
                      text: "    ${part.text}\n",
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
          Spacer(),
          Text("Bias Detection", style: TextStyle(fontSize: 26)),
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
