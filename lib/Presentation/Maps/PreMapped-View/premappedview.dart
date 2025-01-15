import 'package:flutter/material.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/downloadedmapsscreen.dart';
import 'package:g9capstoneiotapp/Presentation/Maps/PreMapped-View/heatmapscreen.dart';
import 'package:g9capstoneiotapp/Storage/App%20Storage/Providers/premappedlist.dart';
import 'package:g9capstoneiotapp/Storage/Cloud%20Storage/readstorage_functions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreMappedRoutesScreen extends StatefulWidget {
  @override
  State<PreMappedRoutesScreen> createState() => _PreMappedRoutesScreenState();
}

class _PreMappedRoutesScreenState extends State<PreMappedRoutesScreen> {
  List<Map<String, dynamic>> locationMaps = [];
  List<String> downloadedMaps = [];

  @override
  void initState() {
    super.initState();
    _getMapsfromProvider();
    _loadDownloadedMaps();
  }

  Future<void> _refreshMaps() async {
    await listAndReadMaps();
    _getMapsfromProvider();
  }

  Future<void> _getMapsfromProvider() async {
    final provider = LocationMapProvider();
    setState(() {
      locationMaps = provider.getAllMaps();
    });
  }

  Future<void> _loadDownloadedMaps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      downloadedMaps = prefs.getStringList('downloaded_maps') ?? [];
    });
  }

  Future<void> _downloadMap(String mapName) async {
    final prefs = await SharedPreferences.getInstance();
    downloadedMaps.add(mapName);
    await prefs.setStringList('downloaded_maps', downloadedMaps);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Mapped Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_rounded),
            onPressed: _refreshMaps,
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DownloadedMapsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: locationMaps.isEmpty
          ? const Center(child: Text('No maps available.'))
          : ListView.builder(
              itemCount: locationMaps.length,
              itemBuilder: (context, index) {
                String mapName = Provider.of<LocationMapProvider>(context, listen: false)
                    .getMapName(index);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HeatMapScreen(
                          locationList: Provider.of<LocationMapProvider>(context, listen: false)
                              .getLocationList(index),
                          mapName: mapName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map, color: Colors.white),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            mapName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            downloadedMaps.contains(mapName)
                                ? Icons.download_done
                                : Icons.download,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (!downloadedMaps.contains(mapName)) {
                              _downloadMap(mapName);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}