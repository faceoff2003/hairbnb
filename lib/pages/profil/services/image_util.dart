class ImageUtil {
  static const String baseUrl = "https://www.hairbnb.site";

  // Méthode pour construire une URL complète à partir d'un chemin relatif
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return "";
    }

    // Si le chemin commence déjà par http ou https, c'est déjà une URL complète
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }

    // Sinon, concaténer avec l'URL de base
    return baseUrl + relativePath;
  }
}