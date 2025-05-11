import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/mes_commandes.dart';

class PaginationService {
  // Paramètres de pagination
  static const int kInitialItemsPerPage = 5;  // Nombre d'éléments à afficher initialement
  static const int kItemsPerPageIncrement = 5;  // Incrément lors du chargement de plus d'éléments
  static const int kMaxItemsPerPage = 20;  // Maximum d'éléments par page

  // Paginer les commandes avec un système intelligent
  static List<Commande> paginerCommandes({
    required List<Commande> commandes,
    required int page,
    required int itemsPerPage,
  }) {
    if (commandes.isEmpty) return [];

    final startIndex = 0;
    final endIndex = page * itemsPerPage;

    if (startIndex >= commandes.length) return [];

    return commandes.sublist(
        startIndex,
        endIndex > commandes.length ? commandes.length : endIndex
    );
  }
}

// Mixin à utiliser dans la page de commandes pour gérer la pagination
mixin CommandesPaginationMixin<T extends StatefulWidget> on State<T> {
  // Nombre d'éléments à afficher par page
  int _itemsPerPage = PaginationService.kInitialItemsPerPage;

  // Page actuelle
  int _currentPage = 1;

  // Contrôleur pour la liste déroulante
  final ScrollController _scrollController = ScrollController();

  // Liste complète des commandes
  List<Commande> _fullCommandesList = [];

  // Liste paginée des commandes à afficher
  List<Commande> _paginatedCommandes = [];

  // État de chargement des pages supplémentaires
  bool _isLoadingMore = false;

  // Flag si toutes les commandes sont chargées
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();

    // Ajouter un listener pour détecter quand l'utilisateur atteint le bas de la liste
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Méthode pour définir la liste complète des commandes
  void setFullCommandesList(List<Commande> commandes) {
    setState(() {
      _fullCommandesList = commandes;
      _updatePaginatedList();
    });
  }

  // Listener de défilement pour détecter quand charger plus de commandes
  void _scrollListener() {
    // Si on est au bas de la liste et qu'on n'est pas en train de charger
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd) {
      _loadMoreItems();
    }
  }

  // Charger plus d'éléments
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simuler un chargement réseau
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentPage++;
      _updatePaginatedList();
      _isLoadingMore = false;
    });
  }

  // Rafraîchir la liste (pour les cas où l'utilisateur tire vers le bas)
  Future<void> refreshList() async {
    setState(() {
      _currentPage = 1;
      _itemsPerPage = PaginationService.kInitialItemsPerPage;
      _hasReachedEnd = false;
    });

    // Appliquer la pagination à nouveau
    _updatePaginatedList();
  }

  // Mettre à jour la liste paginée
  void _updatePaginatedList() {
    final paginatedList = PaginationService.paginerCommandes(
      commandes: _fullCommandesList,
      page: _currentPage,
      itemsPerPage: _itemsPerPage,
    );

    // Vérifier si on a atteint la fin des commandes
    if (paginatedList.length == _fullCommandesList.length) {
      _hasReachedEnd = true;
    }

    setState(() {
      _paginatedCommandes = paginatedList;
    });
  }

  // Getter pour la liste paginée des commandes
  List<Commande> get paginatedCommandes => _paginatedCommandes;

  // Getter pour le contrôleur de défilement
  ScrollController get scrollController => _scrollController;

  // Getter pour savoir si on charge plus d'éléments
  bool get isLoadingMore => _isLoadingMore;
}