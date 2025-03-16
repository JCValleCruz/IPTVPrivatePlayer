import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/auth_service.dart';
import '../services/iptv_service.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class PlayerScreen extends StatefulWidget {
  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  Channel? _selectedChannel;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  String? _currentGroup;
  final List<String> _groups = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final iptvService = Provider.of<IPTVService>(context, listen: false);

    if (authService.currentUser != null) {
      try {
        await iptvService.loadChannels(authService.currentUser!);

        if (iptvService.channels.isNotEmpty) {
          setState(() {
            final allGroups = iptvService.channels
                .map((channel) => channel.groupTitle ?? 'Sin categoría')
                .toSet()
                .toList();

            _groups.clear();
            _groups.add('Todos');
            _groups.addAll(allGroups);
            _currentGroup = 'Todos';
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar canales: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playChannel(Channel channel) async {
    setState(() {
      _selectedChannel = channel;
    });

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(channel.url));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        placeholder: Container(
          color: Colors.black,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo reproducir este canal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Channel> _getFilteredChannels(IPTVService iptvService) {
    return iptvService.channels
        .where((channel) =>
    (_currentGroup == 'Todos' ||
        (channel.groupTitle ?? 'Sin categoría') == _currentGroup) &&
        (channel.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final iptvService = Provider.of<IPTVService>(context);

    if (!authService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
      return Container();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.search, color: AppColors.text),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar canales...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: AppColors.text),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: AppColors.text),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChannels,
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedChannel != null && _chewieController != null)
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Chewie(controller: _chewieController!),
            ),
          if (_selectedChannel != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _selectedChannel!.name,
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
            ),
          if (_groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: _currentGroup,
                  dropdownColor: AppColors.card,
                  isExpanded: true,
                  underline: SizedBox(),
                  style: TextStyle(color: AppColors.text),
                  items: _groups.map((String group) {
                    return DropdownMenuItem<String>(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentGroup = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
          Expanded(
            child: iptvService.isLoading
                ? Center(child: CircularProgressIndicator())
                : iptvService.error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${iptvService.error}',
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadChannels,
                    child: Text('Intentar de nuevo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
                : _getFilteredChannels(iptvService).isEmpty
                ? Center(
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No se encontraron canales con "${_searchQuery}"'
                    : 'No hay canales disponibles',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: _getFilteredChannels(iptvService).length,
              itemBuilder: (context, index) {
                final channel = _getFilteredChannels(iptvService)[index];
                return Card(
                  color: AppColors.card,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(channel.logoUrl!),
                      backgroundColor: Colors.transparent,
                      onBackgroundImageError: (_, __) {},
                    )
                        : CircleAvatar(
                      child: Icon(Icons.tv),
                      backgroundColor: AppColors.primary,
                    ),
                    title: Text(
                      channel.name,
                      style: TextStyle(color: AppColors.text),
                    ),
                    subtitle: Text(
                      channel.groupTitle ?? 'Sin categoría',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    onTap: () => _playChannel(channel),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}