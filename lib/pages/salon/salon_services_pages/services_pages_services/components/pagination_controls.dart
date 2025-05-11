import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final String? previousPageUrl;
  final String? nextPageUrl;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Color color;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.previousPageUrl,
    required this.nextPageUrl,
    required this.onPrevious,
    required this.onNext,
    this.color = const Color(0xFF7B61FF),
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems <= pageSize) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: previousPageUrl != null ? onPrevious : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Précédent"),
          ),

          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "$currentPage / ${(totalItems / pageSize).ceil()}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Next button
          ElevatedButton.icon(
            onPressed: nextPageUrl != null ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Suivant"),
          ),
        ],
      ),
    );
  }
}
