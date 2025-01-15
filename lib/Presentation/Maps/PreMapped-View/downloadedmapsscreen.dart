import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedMapsScreen extends StatefulWidget {
  @override
  State<DownloadedMapsScreen> createState() => _DownloadedMapsScreenState();
}

class _DownloadedMapsScreenState extends State<DownloadedMapsScreen> {
  List<String> downloadedMaps = [];

  @override
  void initState() {
    super.initState();
    _loadDownloadedMaps();
  }

  Future<void> _loadDownloadedMaps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      downloadedMaps = prefs.getStringList('downloaded_maps') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Maps'),
      ),
      body: downloadedMaps.isEmpty
          ? const Center(child: Text('No downloaded maps available.'))
          : ListView.builder(
              itemCount: downloadedMaps.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(downloadedMaps[index]),
                  leading: const Icon(Icons.map),
                );
              },
            ),
    );
  }
}
