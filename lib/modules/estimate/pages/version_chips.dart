import 'package:flutter/material.dart';

class VersionChips extends StatefulWidget {
  final List<int> versions;
  final Function(int) onVersionSelected;

  const VersionChips(
      {required this.versions, required this.onVersionSelected, super.key});

  @override
  _VersionChipsState createState() => _VersionChipsState();
}

class _VersionChipsState extends State<VersionChips> {
  int? selectedVersion;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.versions.map((version) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text('V$version'),
              selected: selectedVersion == version,
              selectedColor: Colors.blue,
              onSelected: (bool selected) {
                setState(() {
                  selectedVersion = selected ? version : null;
                });
                widget.onVersionSelected(version);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
