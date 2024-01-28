import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_masonry_view/flutter_masonry_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ymage/api.dart';

class ResultsScreen extends StatefulWidget {
  ResultsScreen({
    super.key,
    required this.url,
    required this.image,
    required this.isLink,
  });
  final XFile? image;
  final String url;
  final bool isLink;
  final Api api = Api();
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  int _page = 0;
  bool _isLoadingImages = false;
  bool _isLoadingSites = false;
  List _imageResults = [];
  List _siteResults = [];
  Timer? _showDialogTimer;
  bool _dialogVisible = false;
  bool _dialogBottomSheetVisible = false;
  late Map _item;
  String _imageShard = '';
  String _imageID = '';
  bool _isSite = true;
  bool _isUploadingImage = true;
  double? _uploadingProgress;
  String _uploadingState = '';
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _urlController = TextEditingController();

  void _callbackUploadingProgress(progress) {
    setState(() {
      _uploadingProgress = progress;
    });
  }

  void _callbackUploadingState(state) {
    setState(() {
      _uploadingState = state;
    });
  }

  Future<void> _loadSites() async {
    setState(() => _isLoadingSites = true);
    var sites = await widget.api.imageSite(_imageShard, _imageID);
    setState(() {
      _siteResults.addAll(sites["sites"]);
      _isLoadingSites = false;
    });
  }

  Future<void> _uploadImage(bool isLink, XFile? image, String url) async {
    _siteResults = [];
    _imageResults = [];
    setState(() {
      _isUploadingImage = true;
      _uploadingState = 'Resizing';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final (String imageShard, String imageID) =
          await widget.api.imagedownload(isLink, image, url, _callbackUploadingProgress, _callbackUploadingState);
      setState(() {
        _uploadingProgress = null;
        _uploadingState = '';
        _imageShard = imageShard;
        _imageID = imageID;
        _isUploadingImage = false;
      });
      _loadSites();
      _loadMoreImages();
    });
  }

  Future<void> _loadMoreImages() async {
    if (_isLoadingImages) return;
    setState(() => _isLoadingImages = true);
    final response = await widget.api.imagelike(_imageShard, _imageID, _page);

    setState(() {
      _imageResults.addAll(response);
      _page++;
      _isLoadingImages = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _uploadImage(widget.isLink, widget.image, widget.url));
  }

  @override
  void dispose() {
    _showDialogTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _showDialogTimer = Timer(const Duration(seconds: 1), _showDialog);
    if (_dialogVisible) _showDialog();
  }

  void _onPointerUp(PointerUpEvent event) {
    _showDialogTimer?.cancel();
    _showDialogTimer = null;
    setState(() {
      _dialogVisible = false;
    });
  }

  void _showDialog() {
    setState(() {
      _dialogVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final layers = <Widget>[];

    layers.add(_buildPage());

    if (_dialogVisible) {
      layers.add(_buildDialog(_isSite));
    }
    if (_dialogBottomSheetVisible) {
      layers.add(_buildDialogBottomSheet(_isSite));
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: Stack(
        fit: StackFit.expand,
        children: layers,
      ),
    );
  }

  Future<void> _pullRefreshSites() async {
    setState(() {
      _siteResults = [];
      _loadSites();
    });
  }

  Future<void> _pullRefreshImages() async {
    setState(() {
      _imageResults = [];
      _loadMoreImages();
    });
  }

  Future getGalleryImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    _uploadImage(false, image, '');
  }

  Future getCameraImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    _uploadImage(false, image, '');
  }

  void getLInk(uploadUrl) {
    if (uploadUrl == '') {
      Fluttertoast.showToast(msg: "No URL!", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
    }
    if (Uri.parse(uploadUrl).isAbsolute == false) {
      Fluttertoast.showToast(
          msg: "Invalid URL!", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
      return;
    }
    _uploadImage(true, null, uploadUrl);
  }

  Widget _buildPage() {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            body: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      title: const Text('Results'),
                      bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(250.0),
                          child: Column(children: [
                            SizedBox(
                                width: 300.0,
                                height: 200.0,
                                child: OutlinedButton(
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
                                                Padding(
                                                    padding: const EdgeInsets.all(10),
                                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                                                      SizedBox(
                                                          width: 300.0,
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
                                                          )),
                                                      FilledButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              getLInk(_urlController.text);
                                                            });

                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Icon(Icons.search))
                                                    ]))
                                              ],
                                            ),
                                          );
                                        }),
                                    style: ButtonStyle(
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ))),
                                    child: _isUploadingImage
                                        ? Center(
                                            child: Padding(
                                            padding: const EdgeInsets.all(30),
                                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              CircularProgressIndicator(value: _uploadingProgress),
                                              const SizedBox(height: 5),
                                              Text(_uploadingState)
                                            ]),
                                          ))
                                        : Image.network(
                                            "https://avatars.mds.yandex.net/get-images-cbir/$_imageShard/$_imageID/preview",
                                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                  child: Padding(
                                                padding: const EdgeInsets.all(30),
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              ));
                                            },
                                          ))),
                            const TabBar(tabs: [
                              Tab(
                                text: 'Sites',
                              ),
                              Tab(
                                text: 'Images',
                              )
                            ])
                          ])),
                    ),
                  ];
                },
                body: TabBarView(children: [
                  _isLoadingSites
                      ? const Center(
                          child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(),
                        ))
                      : RefreshIndicator(
                          onRefresh: _pullRefreshSites,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: _siteResults.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                  onLongPressStart: (details) {
                                    setState(() {
                                      _isSite = true;
                                      _dialogVisible = true;
                                      _item = _siteResults[index];
                                    });
                                    _showDialogTimer = Timer(const Duration(milliseconds: 500), () {});
                                  },
                                  onLongPressEnd: (details) {
                                    _dialogVisible = false;
                                    _showDialogTimer?.cancel();
                                    _showDialogTimer = null;
                                  },
                                  onTap: () => {
                                        setState(() {
                                          _isSite = true;
                                          _item = _siteResults[index];
                                          _dialogBottomSheetVisible = true;
                                        })
                                      },
                                  child: Card(
                                      elevation: 1,
                                      child: IntrinsicHeight(
                                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Center(
                                            child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: SizedBox(
                                                    width: 130,
                                                    child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        child: Image.network(
                                                          _siteResults[index]["originalImage"]['url'],
                                                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Center(
                                                                child: Padding(
                                                              padding: const EdgeInsets.all(30),
                                                              child: CircularProgressIndicator(
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                              ),
                                                            ));
                                                          },
                                                          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                                            return SizedBox(
                                                              height: 130 *
                                                                  _siteResults[index]["originalImage"]["width"] /
                                                                  _siteResults[index]["originalImage"]["height"],
                                                              width: 130,
                                                              child: Card(
                                                                  color: Theme.of(context).colorScheme.errorContainer,
                                                                  child: Center(
                                                                    child: Text("Error",
                                                                        style: TextStyle(
                                                                          fontSize: 24.0,
                                                                          color: Theme.of(context).colorScheme.error,
                                                                          fontWeight: FontWeight.bold,
                                                                        )),
                                                                  )),
                                                            );
                                                          },
                                                        ))))),
                                        Flexible(
                                            child: Container(
                                                padding: const EdgeInsets.all(4),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      TextScroll(_siteResults[index]['title'],
                                                          textAlign: TextAlign.left,
                                                          mode: TextScrollMode.bouncing,
                                                          velocity: const Velocity(pixelsPerSecond: Offset(150, 0)),
                                                          delayBefore: const Duration(milliseconds: 500),
                                                          numberOfReps: 5,
                                                          pauseBetween: const Duration(milliseconds: 50),
                                                          style: const TextStyle(
                                                            fontSize: 16.0,
                                                            fontWeight: FontWeight.bold,
                                                          )),
                                                      if (_siteResults[index]["description"] != '')
                                                        Text(
                                                          _siteResults[index]["description"],
                                                          textAlign: TextAlign.left,
                                                        ),
                                                      if (_siteResults[index]["domain"] != '')
                                                        Text(
                                                          _siteResults[index]["domain"],
                                                          textAlign: TextAlign.left,
                                                        ),
                                                      Text(
                                                          "${_siteResults[index]["originalImage"]["width"]} x ${_siteResults[index]["originalImage"]["height"]}")
                                                    ])))
                                      ]))));
                            },
                          )),
                  NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                          _loadMoreImages();
                        }
                        return true;
                      },
                      child: RefreshIndicator(
                          onRefresh: _pullRefreshImages,
                          child: SingleChildScrollView(
                              child: Column(children: [
                            MasonryView(
                              listOfItem: _imageResults,
                              numberOfColumn: 2,
                              //_imageResults.length,
                              itemBuilder: (item) {
                                return GestureDetector(
                                  onLongPressStart: (details) {
                                    setState(() {
                                      _isSite = false;
                                      _dialogVisible = true;
                                      _item = item;
                                    });
                                    _showDialogTimer = Timer(const Duration(milliseconds: 500), () {});
                                  },
                                  onLongPressEnd: (details) {
                                    _dialogVisible = false;
                                    _showDialogTimer?.cancel();
                                    _showDialogTimer = null;
                                  },
                                  onTap: () => {
                                    setState(() {
                                      _isSite = false;
                                      _item = item;
                                      _dialogBottomSheetVisible = true;
                                    })
                                  },
                                  child: Image.network(
                                    item['imgUrl'],
                                    fit: BoxFit.fill,
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(30),
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ));
                                    },
                                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                );
                              },
                            ),
                            if (_isLoadingImages)
                              const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(30),
                                child: CircularProgressIndicator(),
                              )),
                          ]))))
                ]))));
  }

  Widget _buildDialogBottomSheet(isSite) {
    int origWidth;
    int origHeight;
    String imgUrl;
    String url;
    if (isSite) {
      origWidth = _item["originalImage"]["width"];
      origHeight = _item["originalImage"]["height"];
      imgUrl = _item["originalImage"]['url'];
      url = _item['url'];
    } else {
      origWidth = _item["origWidth"];
      origHeight = _item["origHeight"];
      imgUrl = _item['imgUrl'];
      url = _item['snippet']['url'];
    }
    double aspectRatio = origWidth / origHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
            top: Radius.circular(15.0),
          )),
          isDismissible: true,
          elevation: 0,
          barrierColor: Colors.transparent,
          context: context,
          builder: (BuildContext context) {
            return Wrap(children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.all(Radius.circular(64.0)),
                ),
                margin: const EdgeInsets.only(left: 180.0, right: 180.0, bottom: 10.0, top: 3.0),
                height: 6.0,
              ),
              const Center(child: Text('Image')),
              SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                      onTap: () async => await Clipboard.setData(ClipboardData(text: imgUrl)),
                      child: Card(child: Center(child: Padding(padding: const EdgeInsets.all(7), child: Text(imgUrl)))))),
              const Center(child: Text('Website')),
              SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                      onTap: () async => await Clipboard.setData(ClipboardData(text: url)),
                      child: Card(child: Center(child: Padding(padding: const EdgeInsets.all(7), child: Text(url)))))),
              SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                          onPressed: () {
                            Share.share(imgUrl);
                          },
                          icon: const Icon(Icons.share)),
                      IconButton(
                          onPressed: () async {
                            Uri surl = Uri.parse(url);
                            if (!await launchUrl(surl)) {
                              throw Exception('Could not launch $surl');
                            }
                          },
                          icon: const Icon(Icons.web)),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () async {
                          downloadImage(imgUrl);
                          Navigator.of(context).pop();
                        },
                      ),
                      FilledButton(
                          onPressed: () {
                            setState(
                              () {
                                getLInk(imgUrl);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                          child: const Icon(Icons.search)),
                    ],
                  )),
            ]);
          }).whenComplete(
        () => setState(() {
          _dialogBottomSheetVisible = false;
        }),
      );
    });
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
            onTap: () => setState(() {
                  _dialogBottomSheetVisible = false;
                }),
            child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color.fromARGB(103, 0, 0, 0)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    FittedBox(
                        fit: BoxFit.contain,
                        child: Card(
                            child:
                                Center(child: Padding(padding: const EdgeInsets.only(left: 5, right: 5), child: Text("$origWidth x $origHeight"))))),
                    Image.network(
                      imgUrl,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                            child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ));
                      },
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        return SizedBox(
                          height: 300 * aspectRatio,
                          width: 300,
                          child: Card(
                              color: Theme.of(context).colorScheme.errorContainer,
                              child: Center(
                                child: Text("Error",
                                    style: TextStyle(
                                      fontSize: 24.0,
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    )),
                              )),
                        );
                      },
                    ),
                    const SizedBox(
                      height: 200,
                    )
                  ]),
                ))));
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (!Platform.isAndroid) {
        directory = await getDownloadsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      }
    } catch (err) {
      Fluttertoast.showToast(
          msg: "Cannot get download folder path",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
    }
    return directory?.path;
  }

  Future<void> downloadImage(url) async {
    var path = await getDownloadPath();
    await FlutterDownloader.enqueue(
      url: url,
      // headers: {},
      savedDir: path!,
      showNotification: true, // show download progress in status bar (for Android)
      openFileFromNotification: true, // click on notification to open downloaded file (for Android)
      saveInPublicStorage: true,
    );
    await FlutterDownloader.loadTasks();
    Fluttertoast.showToast(
        msg: "Downloaded  $url", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
  }

  Widget _buildDialog(isSite) {
    int origWidth;
    int origHeight;
    String imgUrl;
    String url;
    if (isSite) {
      origWidth = _item["originalImage"]["width"];
      origHeight = _item["originalImage"]["height"];
      imgUrl = _item["originalImage"]['url'];
      url = _item['url'];
    } else {
      origWidth = _item["origWidth"];
      origHeight = _item["origHeight"];
      imgUrl = _item['imgUrl'];
      url = _item['snippet']['url'];
    }
    double aspectRatio = origWidth / origHeight;
    return SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: DecoratedBox(
            decoration: const BoxDecoration(color: Color.fromARGB(103, 0, 0, 0)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              FittedBox(
                  fit: BoxFit.contain,
                  child: Card(
                      child: Center(child: Padding(padding: const EdgeInsets.only(left: 5, right: 5), child: Text("$origWidth x $origHeight"))))),
              Image.network(
                imgUrl,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ));
                },
                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  return SizedBox(
                    height: 300 * aspectRatio,
                    width: 300,
                    child: Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Center(
                          child: Text("Error",
                              style: TextStyle(
                                fontSize: 24.0,
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              )),
                        )),
                  );
                },
              ),
              SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                      onTap: () async => await Clipboard.setData(ClipboardData(text: imgUrl)),
                      child: Card(child: Center(child: Padding(padding: const EdgeInsets.all(7), child: Text(imgUrl)))))),
              SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                      onTap: () async => await Clipboard.setData(ClipboardData(text: url)),
                      child: Card(child: Center(child: Padding(padding: const EdgeInsets.all(7), child: Text(url)))))),
            ])));
  }
}
