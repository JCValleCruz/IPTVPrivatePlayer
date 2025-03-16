import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class Channel {
  final String id;
  final String name;
  final String url;
  final String? logoUrl;
  final String? groupTitle;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logoUrl,
    this.groupTitle,
  });
}

class IPTVService with ChangeNotifier {
  List<Channel> _channels = [];
  bool _isLoading = false;
  String? _error;

  List<Channel> get channels => _channels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChannels(User user) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('⚠️ Cargando canales desde: ${user.m3uUrl}');

      if (user.m3uUrl.isEmpty) {
        throw Exception('La URL de la lista M3U está vacía');
      }

      final response = await http.get(Uri.parse(user.m3uUrl));

      if (response.statusCode == 200) {
        final content = response.body;
        _channels = _parseM3U(content);
        print('⚠️ Canales analizados: ${_channels.length}');
      } else {
        throw Exception('No se pudo cargar la lista M3U: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      print('⚠️ Error al cargar canales: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Channel> _parseM3U(String content) {
    List<Channel> channels = [];
    List<String> lines = content.split('\n');

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentUrl;
    int id = 0;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();

      if (line.isEmpty || line == '#EXTM3U') continue;

      if (line.startsWith('#EXTINF')) {
        final nameMatch = RegExp(r'#EXTINF:-1.*,(.*)').firstMatch(line);
        currentName = nameMatch?.group(1)?.trim() ?? 'Canal sin nombre';

        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        currentLogo = logoMatch?.group(1);

        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        currentGroup = groupMatch?.group(1);
      }
      else if (currentName != null && (line.startsWith('http') || line.startsWith('rtmp'))) {
        currentUrl = line;

        channels.add(Channel(
          id: (++id).toString(),
          name: currentName,
          url: currentUrl,
          logoUrl: currentLogo,
          groupTitle: currentGroup,
        ));

        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentUrl = null;
      }
    }

    return channels;
  }
}