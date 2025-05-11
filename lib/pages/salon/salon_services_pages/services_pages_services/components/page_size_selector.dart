import 'package:flutter/material.dart';

class PageSizeSelector extends StatelessWidget {
  final int currentSize;
  final List<int> options;
  final void Function(int) onChanged;
  final Color color;

  const PageSizeSelector({
    super.key,
    required this.currentSize,
    required this.onChanged,
    this.options = const [5, 10, 20],
    this.color = const Color(0xFF7B61FF),
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.format_list_numbered),
      tooltip: "Nombre de services par page",
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Services par page",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: options.map((size) {
                      final isSelected = size == currentSize;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? color : Colors.grey[200],
                          foregroundColor: isSelected ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (size != currentSize) onChanged(size);
                        },
                        child: Text(
                          "$size",
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
