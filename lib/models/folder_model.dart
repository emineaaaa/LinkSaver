import 'package:hive/hive.dart';

part 'folder_model.g.dart';

@HiveType(typeId: 1)
class FolderModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late bool isFavorite;

  FolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isFavorite = false,
  });
}