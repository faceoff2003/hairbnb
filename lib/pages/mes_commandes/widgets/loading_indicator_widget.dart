import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;
  final double size;
  final Color color;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.message = 'Chargement...',
    this.size = 40.0,
    this.color = const Color(0xFFAB47BC), // Purple
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: strokeWidth,
          ),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }
}

// Variante qui montre une animation plus fluide pour le "pull to refresh"
class PullToRefreshIndicator extends StatelessWidget {
  final double value;
  final Color color;

  const PullToRefreshIndicator({
    super.key,
    required this.value,
    this.color = const Color(0xFFAB47BC),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          value: value,
          color: color,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

// Variante pour indiquer le chargement de plus d'éléments en bas de la liste
class LoadMoreIndicator extends StatelessWidget {
  final Color color;
  final String? message;

  const LoadMoreIndicator({
    super.key,
    this.color = const Color(0xFFAB47BC),
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: color,
              strokeWidth: 2,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}