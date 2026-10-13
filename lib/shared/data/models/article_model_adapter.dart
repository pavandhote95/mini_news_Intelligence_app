import 'package:hive/hive.dart';

import '../../../core/storage/hive_boxes.dart';
import 'article_model.dart';

/// Hand-written Hive adapter (equivalent to the generated one) so the project
/// builds without `build_runner`. Field indices must never be reused —
/// append new fields with new indices to stay backward compatible.
class ArticleModelAdapter extends TypeAdapter<ArticleModel> {
  @override
  final int typeId = HiveTypeIds.article;

  @override
  ArticleModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return ArticleModel(
      url: fields[0] as String,
      title: fields[1] as String,
      sourceName: fields[2] as String,
      author: fields[3] as String?,
      description: fields[4] as String?,
      content: fields[5] as String?,
      imageUrl: fields[6] as String?,
      publishedAt: fields[7] as DateTime?,
      savedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ArticleModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.sourceName)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.publishedAt)
      ..writeByte(8)
      ..write(obj.savedAt);
  }
}
