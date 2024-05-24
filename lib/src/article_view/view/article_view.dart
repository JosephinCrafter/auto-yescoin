import 'package:ahl/src/article_view/bloc/bloc.dart';
import 'package:ahl/src/article_view/event/event.dart';
import 'package:ahl/src/article_view/state/state.dart';
import 'package:ahl/src/firebase_constants.dart';
import 'package:ahl/src/theme/theme.dart';
import 'package:ahl/src/utils/breakpoint_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../utils/date_time_utils.dart';

import 'package:ahl/src/ahl_barrel.dart';
import 'package:ahl/src/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import 'package:http/http.dart' as http;

import "package:firebase_article/firebase_article.dart";

import 'dart:developer' as developer;
import 'dart:convert';

String monthTextResolve(BuildContext context, String monthName) {
  List vowels = ['a', 'e', 'i', 'o', 'u', 'y'];

  /// If the first element is a vowel.
  //todo: change based on locale to.
  if (vowels.contains(monthName.characters.first.toLowerCase())) {
    return "Mois d'$monthName";
  } else {
    return 'Mois de $monthName';
  }
}

/// Article Page
class ArticleContentPage extends StatefulWidget {
  const ArticleContentPage({
    super.key,
    this.article,
  });

  static const String routeName = '/articles';
  final Article? article;

  @override
  State<ArticleContentPage> createState() => ArticleContentPageState();
}

class ArticleContentPageState extends State<ArticleContentPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Scaffold(
        endDrawer: constraints.maxWidth <= ScreenSizes.large
            ? const AhlDrawer()
            : null,
        appBar: const AhlAppBar(),
        body: ArticleContentView(
          article: widget.article,
        ),
      ),
    );
  }
}

class ArticleContentView extends StatelessWidget {
  const ArticleContentView({
    super.key,
    required this.article,
  });

  final Article? article;

  Future<String> get content async {
    final bytes = await storage
        .child('articles/${article?.id}/${article?.contentPath}')
        .getData();

    String decodedString = utf8.decode(bytes!.toList());
    return decodedString;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: resolveForBreakPoint(
          screenWidth,
          other: Margins.small,
          extraHuge: Margins.extraHuge,
          huge: Margins.huge,
          extraLarge: Margins.extraLarge,
          large: Margins.large,
        ),
      ),
      constraints: BoxConstraints(
        maxWidth: ContentSize.maxWidth(
          screenWidth,
        ),
      ),
      child: FutureBuilder(
        future: content,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasData) {
                return MarkdownWidget(
                  data: snapshot.data ?? 'Error loading article.',
                );
              } else {
                return Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      Text('Error loading article content: ${snapshot.error}')
                    ],
                  ),
                );
              }

            default:
              return const Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              );

            // default:
            //   return Align(
            //     alignment: Alignment.center,
            //     child: Icon(
            //       Icons.warning_rounded,
            //       color: Theme.of(context).colorScheme.error,
            //     ),
            //   );
          }
        },
      ),
    );
  }
}

/// A tile of article
class ArticleTile extends StatefulWidget {
  const ArticleTile({
    super.key,
    required this.article,
  });

  final Article article;

  @override
  State<ArticleTile> createState() => _ArticleTileState();
}

class _ArticleTileState extends State<ArticleTile> {
  late Article _article;

  @override
  void initState() {
    super.initState();

    _article = widget.article;
  }

  Future<String?> getHeroHeaderImageUrl() async {
    final heroHeaderImageRef = storage.child(
      "articles/${_article.id}/${_article.relations?[0][RepoSetUp.coverImageKey]}",
      // "articles/qui_est_laure_sabes/hero_header_image.jpg",
    );
    final String url = await heroHeaderImageRef.getDownloadURL();

    return url;
  }

  Future<Uint8List?> getHeroHeaderImage() async {
    final heroHeaderImageRef = storage.child(
      "articles/${_article.id}/${_article.relations?[0][RepoSetUp.coverImageKey]}",
      // "articles/qui_est_laure_sabes/hero_header_image.jpg",
    );
    final Uint8List? data = await heroHeaderImageRef.getData();
    return data;
  }

  Future<http.Response?> getContent() async {
    final contentRef = storage.child(
      "articles/${_article.id}/${_article.contentPath}",
      // "articles/qui_est_laure_sabes/hero_header_image.jpg",
    );
    final String url = await contentRef.getDownloadURL();

    final response = await http.get(Uri.parse(url));

    return response;
  }

  void goToReadingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ArticleContentPage(article: _article);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle? titleTheme = resolveHeadlineTextThemeForBreakPoints(
      MediaQuery.of(context).size.width,
      context,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        // padding: const EdgeInsets.all(Paddings.big),
        // clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BorderSizes.big),
        ),
        child: Material(
          borderOnForeground: true,
          child: InkWell(
            onTap: goToReadingPage,
            child: Container(
              // margin: const EdgeInsets.symmetric(
              //   horizontal: Margins.mobileMedium,
              // ),
              constraints: const BoxConstraints(
                maxWidth: 1130,
                minWidth: 350,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_article.title != null)
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: Paddings.big, top: Paddings.small),
                      child: Text(
                        _article.title!,
                        style: titleTheme,
                      ),
                    ),
                  SizedBox(
                    height: 135,
                    // maxHeight: 232,
                    width: constraints.maxWidth,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 135,
                              maxHeight: 232,
                            ),
                            child: (_article.relations
                                        ?.first[RepoSetUp.coverImageKey] !=
                                    null)
                                ? FutureBuilder(
                                    future:
                                        getHeroHeaderImageUrl(), //getHeroHeaderImage(),
                                    builder: (context, snapshot) {
                                      switch (snapshot.connectionState) {
                                        case ConnectionState.done:
                                          if (snapshot.hasData) {
                                            return Container(
                                              constraints: const BoxConstraints(
                                                maxHeight: 135,
                                                maxWidth: 185,
                                                minWidth: 107,
                                              ),
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: NetworkImage(
                                                      snapshot.data!),
                                                ),
                                              ),
                                            ).animate().fadeIn(
                                                  curve: Curves.easeInOutBack,
                                                );
                                          } else {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        BorderSizes.small),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .errorContainer,
                                              ),
                                              child: Text(
                                                'Error getting image: ${snapshot.error}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                    ),
                                              ).animate().fadeIn(),
                                            );
                                          }
                                        case ConnectionState.waiting:
                                          return Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      BorderSizes.small),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                            ),
                                            child: SizedBox.square(
                                              dimension: 50,
                                              child: CircularProgressIndicator(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          );
                                        default:
                                          return Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      BorderSizes.small),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                            ),
                                            child: SizedBox.square(
                                              dimension: 50,
                                              child: CircularProgressIndicator(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                          );
                                      }
                                    },
                                  )
                                : Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            BorderSizes.small),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          left: Paddings.big,
                                          right: Paddings.medium),
                                      color: AhlTheme.yellowRelax,
                                      constraints: const BoxConstraints.expand(
                                        width: 25,
                                        // height: 85,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: FutureBuilder(
                                        future: Future.value(_article.relations
                                                ?.first[RepoSetUp.previewKey]
                                            as String),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Container(
                                              alignment: Alignment.topCenter,
                                              child: Text(
                                                snapshot.data!,
                                                maxLines: 4,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                              ),
                                            );
                                          } else if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        BorderSizes.small),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer,
                                              ),
                                              child: SizedBox.square(
                                                dimension: 50,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            );
                                          } else {
                                            return Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        BorderSizes.small),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .errorContainer,
                                              ),
                                              child: Text(
                                                'Error getting content: ${snapshot.error}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .error,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    goToReadingPage();
                                  },
                                  child: Text('Lire'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class HighlightArticleTile extends StatelessWidget {
  const HighlightArticleTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return BlocProvider(
          create: (BuildContext context) => ArticleBloc(
            repo: ArticlesRepository(
              firestoreInstance: firestore,
              collection: 'articles',
            ),
          )..add(
              const GetHighlightArticleEvent(),
            ),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ContentSize.maxWidth(
                  MediaQuery.of(context).size.width,
                ),
              ),
              child: const HighlightArticleTileView(),
            ),
          ),
        );
      },
    );
  }
}

class HighlightArticleTileView extends StatefulWidget {
  const HighlightArticleTileView({
    super.key,
  });

  @override
  State<HighlightArticleTileView> createState() => _HighlightArticleTileView();
}

class _HighlightArticleTileView extends State<HighlightArticleTileView> {
  @override
  void initState() {
    super.initState();
  }

  void goToReadingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ArticleContentPage(
            article: context.read<ArticleBloc>().state.highlightArticle,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleBloc, ArticleState<Article>>(
      builder: (context, state) {
        switch (state.status) {
          case ArticleStatus.failed:
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Margins.medium,
              ),
              alignment: Alignment.center,
              child: Text('${state.error}'),
            );
          case ArticleStatus.succeed:
            String releaseMonth = DateTimeUtils.localMonth(
              DateTimeUtils.parseReleaseDate(
                      state.articles![0]!.releaseDate ?? '2024-04-28')
                  .month,
              context,
            );
            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Margins.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthTextResolve(
                      context,
                      releaseMonth,
                    ).toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  ArticleTile(article: state.articles![0]!),
                  Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: Margins.medium),
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // todo: go to articles page
                      },
                      child: const Text("Tous les articles"),
                    ),
                  ),
                ],
              ),
            );
          default:
            return Container(
              height: 310,
              margin: const EdgeInsets.symmetric(
                horizontal: Margins.medium,
              ),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
        }
      },
    );
  }
}
