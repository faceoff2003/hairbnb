class Categorie {
  final int id;
  final String nom;
  final String description;

  Categorie({
    required this.id,
    required this.nom,
    required this.description,
  });

  factory Categorie.fromJson(Map<String, dynamic> json) {
    // print("🔍 DEBUG CATEGORIE: JSON brut reçu: $json");
    // print("🔍 DEBUG CATEGORIE: Type de json: ${json.runtimeType}");
    // print("🔍 DEBUG CATEGORIE: Clés disponibles: ${json.keys.toList()}");

    // ✅ Récupération de l'ID avec debug détaillé
    int categorieId = 0;
    try {
      final idValue = json['idTblCategorie'];
      //print("🔍 DEBUG CATEGORIE: Valeur idTblCategorie: $idValue (type: ${idValue.runtimeType})");

      if (idValue != null) {
        if (idValue is int) {
          categorieId = idValue;
        } else if (idValue is String) {
          categorieId = int.parse(idValue);
        } else {
          categorieId = int.parse(idValue.toString());
        }
        //print("✅ ID converti avec succès: $categorieId");
      } else {
        print("❌ idTblCategorie est null !");
      }
    } catch (e) {
      print("❌ ERREUR conversion ID catégorie: $e");
      print("❌ Valeur brute: ${json['idTblCategorie']}");
    }

    // ✅ Récupération du nom avec debug détaillé
    String nom = '';
    try {
      final nomValue = json['intitule_categorie'];
      //print("🔍 DEBUG CATEGORIE: Valeur intitule_categorie: $nomValue (type: ${nomValue.runtimeType})");

      if (nomValue != null) {
        nom = nomValue.toString();
        //print("✅ Nom converti avec succès: '$nom'");
      } else {
        nom = 'Catégorie sans nom';
        //print("⚠️ intitule_categorie est null, utilisation du nom par défaut");
      }
    } catch (e) {
      print("❌ ERREUR conversion nom catégorie: $e");
      nom = 'Erreur nom';
    }

    final description = json['description']?.toString() ?? '';

    //print("🎯 CATEGORIE CONSTRUITE: ID=$categorieId, Nom='$nom', Description='$description'");

    final categorie = Categorie(
      id: categorieId,
      nom: nom,
      description: description,
    );

    //print("🎯 VERIFICATION FINALE: categorie.id=${categorie.id}, categorie.nom='${categorie.nom}'");

    return categorie;
  }

  Map<String, dynamic> toJson() {
    return {
      'idTblCategorie': id,
      'intitule_categorie': nom,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'Categorie(id: $id, nom: "$nom", description: "$description")';
  }
}














// class Categorie {
//   final int id;
//   final String nom;
//   final String description;
//
//   Categorie({
//     required this.id,
//     required this.nom,
//     required this.description,
//   });
//
//   factory Categorie.fromJson(Map<String, dynamic> json) {
//     return Categorie(
//       id: json['idCategorie'] ?? 0,
//       nom: json['nom'] ?? '',
//       description: json['description'] ?? '',
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'idCategorie': id,
//       'nom': nom,
//       'description': description,
//     };
//   }
// }