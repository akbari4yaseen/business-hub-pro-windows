import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;

  const SearchFilterBar({
    Key? key,
    required this.onSearchChanged,
    required this.onFilterPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                // fillColor: Colors.grey[200],
              ),
              onChanged: onSearchChanged,
            ),
          ),

          SizedBox(width: 10),

          // Filter Button
          IconButton(
            icon: Icon(Icons.filter_list, size: 28, color: Colors.blue),
            onPressed: onFilterPressed,
          ),
        ],
      ),
    );
  }
}
