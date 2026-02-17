import 'package:hive/hive.dart';

part 'link_model.g.dart';

@HiveType(typeId: 0)
class LinkModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String url;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String? faviconUrl;

  @HiveField(5)
  late DateTime savedAt;

  @HiveField(6)
  late List<String> tags;

  LinkModel({
    required this.id,
    required this.url,
    this.title,
    this.description,
    this.faviconUrl,
    required this.savedAt,
    List<String>? tags,
  }) : tags = tags ?? [];
}
