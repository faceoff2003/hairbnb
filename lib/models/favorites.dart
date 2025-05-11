class FavoriteModel {
  final int idTblFavorite;
  final int user;
  final int salon;
  final String addedAt;

  FavoriteModel({
    required this.idTblFavorite,
    required this.user,
    required this.salon,
    required this.addedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      idTblFavorite: json['idTblFavorite'],
      user: json['user'],
      salon: json['salon'],
      addedAt: json['added_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblFavorite': idTblFavorite,
      'user': user,
      'salon': salon,
      'added_at': addedAt,
    };
  }

  @override
  String toString() {
    return 'FavoriteModel(idTblFavorite: $idTblFavorite, user: $user, salon: $salon, addedAt: $addedAt)';
  }
}