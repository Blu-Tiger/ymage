import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ymage/results.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      // debug: true,
      // ignoreSsl: true
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ymage',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 252, 63, 29),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ymage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  String _version = '';
  String _searchButton = 'Search';

  final _urlController = TextEditingController();

  Future<void> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ymage'),
      ),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 300.0,
            height: 200.0,
            child: FilledButton.tonal(
                onPressed: () => showModalBottomSheet(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15.0),
                    )),
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 13.0),
                        child: Wrap(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: const BorderRadius.all(Radius.circular(64.0)),
                              ),
                              margin: const EdgeInsets.only(left: 180.0, right: 180.0, bottom: 10.0, top: 3.0),
                              height: 6.0,
                            ),
                            ListTile(
                              onTap: () {
                                getGalleryImage();
                                Navigator.of(context).pop();
                              },
                              leading: const Icon(
                                Icons.photo,
                              ),
                              title: const Text(
                                'Upload an image',
                                style: TextStyle(fontWeight: FontWeight.w300),
                              ),
                            ),
                            ListTile(
                              onTap: () {
                                getCameraImage();
                                Navigator.of(context).pop();
                              },
                              leading: const Icon(
                                Icons.camera,
                              ),
                              title: const Text(
                                'Take a picture',
                                style: TextStyle(fontWeight: FontWeight.w300),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ))),
                child: _image == null
                    ? const Text('Select Image')
                    : Image.file(
                        File(_image!.path),
                      )),
          ),
          _image == null
              ? const Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text(
                    'OR',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ))
              : const SizedBox.shrink(),
          _image == null
              ? SizedBox(
                  width: 300.0,
                  height: 200.0,
                  child: TextField(
                    controller: _urlController,
                    onChanged: (text) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      labelText: 'Image URL',
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _urlController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.cancel))
                          : null,
                    ),
                  ))
              : IconButton(
                  onPressed: () {
                    setState(() {
                      _image = null;
                    });
                  },
                  icon: const Icon(Icons.cancel)),
        ])),
        Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 60),
            child: SizedBox(width: 200.0, height: 50.0, child: FilledButton(onPressed: search, child: Text(_searchButton)))),
        Text(
          "v$_version",
          style: TextStyle(color: Theme.of(context).colorScheme.surfaceVariant),
        )
      ])),
    );
  }

  Future getGalleryImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  Future getCameraImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
    });
  }

  void search() {
    setState(() {
      _searchButton = 'Loading Image';
    });

    String url = _urlController.text;
    bool isLink = false;
    if (_image == null && url == '') {
      Fluttertoast.showToast(
          msg: "Use one of the inputs!", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
      return;
    }
    if (Uri.parse(url).isAbsolute == false && _image == null) {
      Fluttertoast.showToast(
          msg: "Invalid URL!", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
      return;
    }
    if (_image == null) {
      isLink = true;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsScreen(url: url, image: _image, isLink: isLink)),
    ).then((value) {
      setState(() {
        _searchButton = 'Search';
      });
    });
  }
}
