import 'package:flutter_test/flutter_test.dart';
import 'package:mini_news_intelligence/shared/data/models/article_model.dart';
import 'package:mini_news_intelligence/shared/domain/entities/article.dart';

void main() {
  group('Article', () {
    test('cleanContent strips the NewsAPI truncation marker', () {
      const article = Article(
        url: 'u',
        title: 't',
        sourceName: 's',
        content: 'Markets rallied on Tuesday… [+2140 chars]',
      );
      expect(article.cleanContent, 'Markets rallied on Tuesday…');
      expect(article.isContentTruncated, isTrue);
    });

    test('readingMinutes accounts for hidden characters', () {
      const short = Article(url: 'u', title: 't', sourceName: 's', content: 'Short text.');
      const long = Article(url: 'u', title: 't', sourceName: 's', content: 'Intro [+6000 chars]');
      expect(short.readingMinutes, 1);
      expect(long.readingMinutes, greaterThan(4));
    });

    test('equality is based on url', () {
      const a = Article(url: 'same', title: 'A', sourceName: 'x');
      const b = Article(url: 'same', title: 'B', sourceName: 'y');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('ArticleModel.fromJson', () {
    test('parses NewsAPI json and strips " - Source" from title', () {
      final model = ArticleModel.fromJson({
        'source': {'id': null, 'name': 'Reuters'},
        'author': '  ',
        'title': 'Stocks climb - Reuters',
        'description': 'desc',
        'url': 'https://reuters.com/x',
        'urlToImage': 'https://img',
        'publishedAt': '2026-10-13T08:00:00Z',
        'content': 'body',
      });
      expect(model.title, 'Stocks climb');
      expect(model.sourceName, 'Reuters');
      expect(model.author, isNull);
      expect(model.publishedAt, DateTime.utc(2026, 10, 13, 8));
      expect(model.isValid, isTrue);
    });

    test('marks removed articles as invalid', () {
      final model = ArticleModel.fromJson({
        'source': {'name': '[Removed]'},
        'title': '[Removed]',
        'url': 'https://removed.com',
      });
      expect(model.isValid, isFalse);
    });

    test('json round trip keeps data', () {
      final original = ArticleModel.fromJson({
        'source': {'name': 'FT'},
        'title': 'Rates on hold',
        'url': 'https://ft.com/a',
        'publishedAt': '2026-10-13T08:00:00.000Z',
      });
      final copy = ArticleModel.fromJson(original.toJson());
      expect(copy.toEntity(), original.toEntity());
      expect(copy.title, original.title);
      expect(copy.publishedAt, original.publishedAt);
    });
  });
}
