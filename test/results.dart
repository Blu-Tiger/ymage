import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ymage/api.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.url,
    required this.image,
    required this.isLink,
  });
  final XFile? image;
  final String url;
  final bool isLink;
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _page = 1;
  bool _isLoading = false;
  final List _results = [];
  Timer? _showDialogTimer;
  bool _dialogVisible = false;
  bool _dialogBottomSheetVisible = false;
  int _index = 0;

  Future<void> _loadMoreImages() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final (String imageShard, String imageID) = await Api().imagedownload(widget.isLink, widget.image, widget.url);
    if (imageShard == '' || imageID == '') {
      Navigator.pop(context);
    }
    final response = await Api().imagelike(imageShard, imageID, _page);
    // final newResults = response;
    setState(() {
      _results.addAll(response);
      _page++;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMoreImages();
  }

  @override
  void dispose() {
    _showDialogTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _showDialogTimer = Timer(const Duration(seconds: 1), _showDialog);
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
      layers.add(_buildDialog());
    }
    if (_dialogBottomSheetVisible) {
      layers.add(_buildDialogBottomSheet());
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

  Widget _buildPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        SizedBox(
          height: 200.0,
          width: double.infinity,
          child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              // style: style(
              //     shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(20),
              // ))),
              child: widget.isLink == true
                  ? Image.network(widget.url)
                  : Image.file(
                      File(widget.image!.path),
                    )),
        ),
        Expanded(
            child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    _loadMoreImages();
                  }
                  return true;
                },
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          addAutomaticKeepAlives: true,
                          childCount: _results.length,
                          (BuildContext context, int index) {
                            return GestureDetector(
                              onLongPressStart: (details) {
                                setState(() {
                                  _dialogVisible = true;
                                  _index = index;
                                });
                                _showDialogTimer = Timer(const Duration(milliseconds: 500), () {});
                              },
                              onLongPressEnd: (details) {
                                _showDialogTimer?.cancel();
                                _showDialogTimer = null;
                              },
                              onTap: () => {
                                // showDialog(
                                //   context: context,
                                //   builder: (BuildContext context) {
                                //     return GestureDetector(
                                //       child: Center(
                                //         child: InteractiveViewer(
                                //           child: Image.network(
                                //             _results[index]['imgUrl'],
                                //             errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                //               // print('Failed to load image: $_imageUrls[index]');
                                //               return const Center(child: Text('Error'));
                                //             },
                                //           ),
                                //         ),
                                //       ),
                                //     );
                                //   },
                                // ),
                                setState(() {
                                  _index = index;
                                  _dialogBottomSheetVisible = true;
                                })
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    ),
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    clipBehavior: Clip.hardEdge,
                                    child: Image.network(
                                      _results[index]['imgUrl'],
                                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                        // print('Failed to load image: $_imageUrls[index]');
                                        return const Center(child: Text('Error'));
                                      },
                                    )),
                              ),
                            );
                          },
                        )),
                    SliverList(
                      delegate: SliverChildListDelegate(
                        addAutomaticKeepAlives: true,
                        [
                          if (_isLoading)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(),
                            )),
                        ],
                      ),
                    ),
                  ],
                  physics: const BouncingScrollPhysics(),
                  controller: ScrollController(),
                  reverse: false,
                  shrinkWrap: false,
                  dragStartBehavior: DragStartBehavior.start,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                  restorationId: "scroll_view",
                ))),
      ]),
    );
  }

  Widget _buildDialogBottomSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet<dynamic>(
          isScrollControlled: true,
          isDismissible: true,
          elevation: 0,
          barrierColor: Colors.transparent,
          context: context,
          builder: (BuildContext context) {
            return SizedBox(
              width: double.infinity,
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                      onPressed: () {
                        Share.share(_results[_index]['imgUrl']);
                      },
                      icon: const Icon(Icons.share)),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _results[_index]['imgUrl']));
                    },
                    icon: const Icon(Icons.link),
                  ),
                  IconButton(
                      onPressed: () async {
                        Uri _url = Uri.parse(_results[_index]['snippet']["url"]);
                        if (!await launchUrl(_url)) {
                          throw Exception('Could not launch $_url');
                        }
                      },
                      icon: const Icon(Icons.web))
                ],
              ),
            );
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
                      SizedBox(
                          height: 30.0,
                          width: 100,
                          child: Card(child: Center(child: Text("${_results[_index]["origWidth"]} x ${_results[_index]["origHeight"]}")))),
                      Image.network(
                        _results[_index]['imgUrl'],
                        errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                          // print('Failed to load image: $_imageUrls[index]');
                          return const Center(child: Text('Error'));
                        },
                      )
                    ])))));
  }

  Widget _buildDialog() {
    return SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: DecoratedBox(
            decoration: const BoxDecoration(color: Color.fromARGB(103, 0, 0, 0)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(height: 60.0, width: 200, child: Card(child: Text("${_results[_index]["origWidth"]} x ${_results[_index]["origHeight"]}"))),
              Image.network(
                _results[_index]['imgUrl'],
                errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  // print('Failed to load image: $_imageUrls[index]');
                  return const Center(child: Text('Error'));
                },
              )
            ])));
  }
}
