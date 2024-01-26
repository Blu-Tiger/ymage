import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';

final dio = Dio();

class Api {
  Future<(String, String)> imagedownload(isLink, image, url) async {
    if (image == null && isLink == false) {
      Fluttertoast.showToast(
          msg: "No image selected", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
      return ('', '');
    }
    // ignore: avoid_init_to_null
    Response? response = null;
    if (isLink) {
      Options options = Options(headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0'});

      Response response = await dio.get(
          'https://yandex.com/images-apphost/image-download?url=$url&images_avatars_size=preview&images_avatars_namespace=images-cbir',
          options: options);

      if (response.statusCode == 200) {
        // print(response);
        String imageID = response.data['image_id'];
        String imageShard = response.data['image_shard'].toString();
        // print("$imageShard/$imageID");
        return (imageShard, imageID);
      }
    } else {
      Uint8List bytes = await image.readAsBytes();

      Options options = Options(
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0', 'Content-Type': 'image/jpeg'});

      Response response = await dio.post(
          'https://yandex.com/images-apphost/image-download?images_avatars_size=preview&images_avatars_namespace=images-cbir',
          data: bytes,
          options: options);

      if (response.statusCode == 200) {
        // print(response);
        String imageID = response.data['image_id'];
        String imageShard = response.data['image_shard'].toString();
        // print("$imageShard/$imageID");
        return (imageShard, imageID);
      }
    }
    // print("${response.statusCode} ${response.statusMessage}");
    if (response != null) {
      Fluttertoast.showToast(
          msg: "Error: ${response.statusCode} ${response.statusMessage}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: "Unknown API Error", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
    }
    return ('', '');
  }

  Future<Map> imageSite(String imageShard, String imageID) async {
    Options options = Options(headers: {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'en-US;q=0.7,en;q=0.3',
      'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 7.1.2; MI 5X; Flow) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/347.0.0.268 Mobile Safari/537.36',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      'Sec-GPC': '1',
      'sec-ch-ua-platform': '"Android"',
      'sec-ch-ua': '"Google Chrome";v="347", "Chromium";v="347", "Not=A?Brand";v="24"',
      'sec-ch-ua-mobile': '?1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'TE': 'trailers'
    });
    Map block = {
      "blocks": [
        {"block": "extra-content", "params": {}, "version": 2},
        {"block": "i-global__params:ajax", "params": {}, "version": 2},
        {"block": "serp-controller", "params": {}, "version": 2},
        {
          "block": "cbir-page-layout__main-content:ajax",
          "params": {"pageType": "cbir-sites"},
          "version": 2
        }
      ]
    };
    String stringBlock = jsonEncode(block);
    String url =
        'https://yandex.com/images/touch/search?cbir_id=$imageShard/$imageID&rpt=imageview&url=https://avatars.mds.yandex.net/get-images-cbir/$imageShard/$imageID/orig&cbir_page=sites&format=json&request=$stringBlock';
    Response response = await dio.get(url, options: options);
    if (response.statusCode == 200) {
      if (response.data == null) {
        Fluttertoast.showToast(
            msg: "Error: null blocks", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
        return {};
      }
      // print(response.data);
      String htmlString = response.data["blocks"][3]["html"];
      Document document = parse(htmlString);
      Element? root = document.querySelector('.Root');
      String? dataState = root?.attributes['data-state'];
      if (root?.attributes['data-state'] == null) {
        Fluttertoast.showToast(
            msg: "Error: null data-state", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
        return {};
      }
      Map<String, dynamic> jsonData = jsonDecode(dataState!);
      // print(jsonData);
      return jsonData;
    }
    // print("${response.statusCode} ${response.statusMessage}");
    Fluttertoast.showToast(
        msg: "Error: ${response.statusCode} ${response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);
    return {};
  }

  Future<List<Map>> imagelike(String imageShard, String imageID, int page) async {
    Options options = Options(headers: {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'it,en-US;q=0.7,en;q=0.3',
      'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-origin',
      'Sec-GPC': '1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'TE': 'trailers',
    });

    String block =
        '{"blocks":[{"block":"extra-content","params":{},"version":2},{"block":{"block":"i-react-ajax-adapter:ajax"},"params":{"type":"ImagesApp","ajaxKey":"serpList/fetch"},"version":2}]}';
    String url =
        'https://yandex.com/images/search?format=json&request=$block&cbir_id=$imageShard/$imageID&p=$page&rpt=imagelike&serpListType=horizontal&text=url:"avatars.mds.yandex.net/get-images-cbir/$imageShard/$imageID/orig"&url=https://avatars.mds.yandex.net/get-images-cbir/$imageShard/$imageID/orig';
    // print(url);
    Response response = await dio.get(url, options: options);
    // print(response);

    if (response.statusCode == 200) {
      if (response.data['blocks'] == null) {
        Fluttertoast.showToast(
            msg: "Error: null blocks", toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.CENTER, timeInSecForIosWeb: 1, fontSize: 16.0);
        return [];
      }
      var entitiesID = response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"].keys.toList();
      // print(entitiesID);
      List<Map> entities = [];
      for (var id in entitiesID) {
        entities.add({
          "snippet": response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"][id]["snippet"],
          "imgUrl": response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"][id]["origUrl"],
          "imgHref": response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"][id]["viewerData"]["img_href"],
          "preview": response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"][id]["viewerData"]["preview"],
          "origWidth": response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"][id]["origWidth"],
          "origHeight": response.data['blocks'][1]["params"]["adapterData"]["serpList"]["items"]["entities"][id]["origHeight"],
        });
      }
      // print(entities);
      return entities;
    }
    // print("${response.statusCode} ${response.statusMessage}");
    Fluttertoast.showToast(
        msg: "Error: ${response.statusCode} ${response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);
    return [];
  }
}