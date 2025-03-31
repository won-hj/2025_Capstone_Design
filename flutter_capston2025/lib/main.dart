import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '곤충 도감 앱',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  Color _themeColor = Colors.deepPurple;
  List<File> _images = [];
  int _previewColumns = 2;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');
    if (await photoDir.exists()) {
      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).contains("insect_"))
          .toList();
      setState(() {
        _images = files;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showPreviewSettingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: List.generate(6, (index) => index + 1).map((num) {
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _previewColumns = num;
                });
                Navigator.pop(context);
              },
              child: Text('$num개 보기'),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: _loadImages),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: () => _showPreviewSettingSheet(context),
        onImageDeleted: _loadImages,
      ),
      SearchPage(themeColor: _themeColor),
      SettingsPage(
        themeColor: _themeColor,
        onThemeChanged: (color) {
          setState(() {
            _themeColor = color;
          });
        },
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _themeColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '촬영'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '도감'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  final Color themeColor;
  final VoidCallback onPhotoTaken;
  const CameraPage({super.key, required this.themeColor, required this.onPhotoTaken});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${dir.path}/insect_photos');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }
      final fileName = 'insect_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(pickedFile.path).copy('${photoDir.path}/$fileName');
      widget.onPhotoTaken();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
        const Spacer(),
        Center(
          child: ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt, size: 40, color: Colors.white),
            label: const Text('촬영', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class CollectionPage extends StatelessWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const CollectionPage({super.key, required this.themeColor, required this.images, required this.previewColumns, required this.onPreviewSetting, required this.onImageDeleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: themeColor),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DictionaryPage()),
                    ),
                    child: Container(
                      color: Colors.deepPurple.shade200, // Light purple for Dictionary
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: const Text("도감", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GalleryPage(
                        themeColor: themeColor,
                        images: images,
                        previewColumns: previewColumns,
                        onPreviewSetting: onPreviewSetting,
                        onImageDeleted: onImageDeleted,
                      )),
                    ),
                    child: Container(
                      color: Colors.deepPurple.shade100, // Even lighter purple for Gallery
                      alignment: Alignment.center,
                      width: double.infinity,
                      child: const Text("갤러리", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DictionaryPage extends StatelessWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("도감")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: Theme.of(context).colorScheme.primary),
          const Expanded(
            child: Center(
              child: Text("추후 업데이트", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final Color themeColor;
  final ValueChanged<Color> onThemeChanged;

  const SettingsPage({super.key, required this.themeColor, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> colors = [
      {'color': Colors.deepPurple, 'name': 'Deep Purple'},
      {'color': Colors.red, 'name': 'Red'},
      {'color': Colors.green, 'name': 'Green'},
      {'color': Colors.blue, 'name': 'Blue'},
      {'color': Colors.orange, 'name': 'Orange'},
      {'color': Colors.pink, 'name': 'Pink'},
      {'color': Colors.brown, 'name': 'Brown'},
      {'color': Colors.teal, 'name': 'Teal'},
      {'color': Colors.indigo, 'name': 'Indigo'},
      {'color': Colors.amber, 'name': 'Amber'},
      {'color': Colors.cyan, 'name': 'Cyan'},
      {'color': Colors.grey, 'name': 'Grey'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: themeColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: colors.map((entry) {
                  return ElevatedButton(
                    onPressed: () => onThemeChanged(entry['color']),
                    style: ElevatedButton.styleFrom(backgroundColor: entry['color']),
                    child: Text(
                      entry['name'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  final Color themeColor;

  const SearchPage({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("검색")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: themeColor),
          const Expanded(
            child: Center(
              child: Text(
                "검색 기능은 추후 업데이트 예정입니다.",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  final Color themeColor;
  final List<File> images;
  final int previewColumns;
  final VoidCallback onPreviewSetting;
  final VoidCallback onImageDeleted;

  const GalleryPage({
    super.key,
    required this.themeColor,
    required this.images,
    required this.previewColumns,
    required this.onPreviewSetting,
    required this.onImageDeleted,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late int _columns;
  late List<File> _images;

  @override
  void initState() {
    super.initState();
    _columns = widget.previewColumns;
    _images = widget.images;
  }

  void _changePreviewColumns(int columns) {
    setState(() {
      _columns = columns;
    });
    Navigator.pop(context);
  }

  void _showPreviewSettingSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: List.generate(6, (index) => index + 1).map((num) {
            return ElevatedButton(
              onPressed: () => _changePreviewColumns(num),
              child: Text('$num개 보기'),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showImageDialog(File image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.file(image, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _deleteImage(File image) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("정말로 이 이미지를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("아니요"),
          ),
          TextButton(
            onPressed: () async {
              await image.delete();
              widget.onImageDeleted();
              setState(() {
                _images.remove(image);
              });
              Navigator.pop(context);
            },
            child: const Text("예"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("갤러리")),
      body: Column(
        children: [
          Container(height: kBottomNavigationBarHeight, color: widget.themeColor),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                return GestureDetector(
                  onTap: () => _showImageDialog(image),
                  onLongPress: () => _deleteImage(image),
                  child: Image.file(image, fit: BoxFit.cover),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPreviewSettingSheet,
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.grid_view),
      ),
    );
  }
}
