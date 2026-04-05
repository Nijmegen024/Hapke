import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/videos_controller.dart';
import '../../models/restaurant.dart';
import '../../models/menu_item.dart';
import '../../models/video.dart';

class VideosTab extends StatefulWidget {
  final List<Restaurant> restaurants;
  final bool isActive;
  final double? userLat;
  final double? userLng;
  final void Function(Restaurant restaurant)? onOpenRestaurant;
  final void Function(Restaurant restaurant, MenuItem item)? onAddMenuItem;
  const VideosTab({
    super.key,
    required this.restaurants,
    required this.isActive,
    this.userLat,
    this.userLng,
    this.onOpenRestaurant,
    this.onAddMenuItem,
  });

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  late VideosController controller;
  final PageController _pageController = PageController();
  VideoPlayerController? _videoController;
  Future<void>? _videoInit;
  String? _videoInitError;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VideosController(
      restaurants: widget.restaurants,
      userLat: widget.userLat,
      userLng: widget.userLng,
    ));

    // Listen to changes in the active video index
    ever(controller.activeIndex.obs, (index) {
      _prepareVideoAtIndex(index, autoplay: widget.isActive);
    });

    // Initial video preparation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.allVideos().isNotEmpty) {
        _prepareVideoAtIndex(controller.activeIndex, autoplay: widget.isActive);
      }
    });
    
    // Listen for data load to prepare first video
    ever(controller.videos.obs, (videos) {
       if (videos.isNotEmpty && _videoController == null) {
          _prepareVideoAtIndex(controller.activeIndex, autoplay: widget.isActive);
       }
    });
  }

  @override
  void didUpdateWidget(covariant VideosTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive && !widget.isActive) {
      _videoController?.pause();
    } else if (!oldWidget.isActive && widget.isActive) {
      _autoplayActiveVideoIfReady();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Restaurant? _findRestaurant(String id) {
    try {
      return widget.restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _disposeVideoController() async {
    final vCtrl = _videoController;
    _videoController = null;
    _videoInit = null;
    _videoInitError = null;
    if (vCtrl != null) {
      try {
        await vCtrl.pause();
      } catch (_) {}
      await vCtrl.dispose();
    }
  }

  Future<void> _prepareVideoAtIndex(int index, {required bool autoplay}) async {
    final videos = controller.allVideos();
    if (index < 0 || index >= videos.length) return;

    final url = videos[index].videoUrl.trim();
    final uri = Uri.tryParse(url);
    await _disposeVideoController();

    if (uri == null) {
      if (mounted) {
        setState(() {
          _videoInitError = 'Ongeldige video-URL';
        });
      }
      return;
    }

    final vCtrl = VideoPlayerController.networkUrl(uri);
    _videoController = vCtrl;
    _videoInitError = null;
    _videoInit = vCtrl.initialize().then((_) async {
      await vCtrl.setLooping(true);
      await vCtrl.setVolume(controller.muted ? 0 : 1);
      if (!mounted) return;
      if (autoplay) {
        try {
          await vCtrl.play();
        } catch (_) {}
      }
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _videoInitError = 'Video kan niet starten: $e';
      });
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _autoplayActiveVideoIfReady() async {
    final vCtrl = _videoController;
    if (vCtrl == null) return;
    if (_videoInitError != null) return;
    final init = _videoInit;
    if (init != null) {
      try {
        await init;
      } catch (_) {
        return;
      }
    }
    if (!mounted) return;
    if (!vCtrl.value.isInitialized) return;
    await vCtrl.setVolume(controller.muted ? 0 : 1);
    await vCtrl.play();
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    controller.toggleMute();
    final vCtrl = _videoController;
    if (vCtrl != null && vCtrl.value.isInitialized) {
      await vCtrl.setVolume(controller.muted ? 0 : 1);
    }
    if (mounted) setState(() {});
  }

  Future<void> _togglePlayPause() async {
    final vCtrl = _videoController;
    if (vCtrl == null || !vCtrl.value.isInitialized) return;
    if (vCtrl.value.isPlaying) {
      await vCtrl.pause();
    } else {
      await vCtrl.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _openCommentsSheet(VideoItem v) async {
    List<VideoComment> comments = const [];
    String? error;
    bool loading = true;
    final inputCtrl = TextEditingController();
    try {
      comments = await controller.fetchComments(v.id);
    } catch (e) {
      error = 'Comments laden mislukt: $e';
    } finally {
      loading = false;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> submit() async {
              try {
                final newComment = await controller.postComment(v.id, inputCtrl.text.trim());
                if (newComment != null) {
                  setModal(() {
                    comments = [...comments, newComment];
                    inputCtrl.clear();
                  });
                }
              } catch (e) {
                Get.snackbar('Fout', 'Plaatsen mislukt: $e', snackPosition: SnackPosition.BOTTOM);
              }
            }
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(height: 1),
                    if (loading) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                    else if (error != null) Padding(padding: const EdgeInsets.all(16), child: Text(error, style: const TextStyle(color: Colors.red)))
                    else SizedBox(
                      height: 280,
                      child: comments.isEmpty
                          ? const Center(child: Text('Nog geen comments'))
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (_, i) {
                                final c = comments[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(c.userName),
                                  subtitle: Text(c.text),
                                  trailing: Text('${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12)),
                                );
                              },
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: inputCtrl, decoration: const InputDecoration(hintText: 'Typ een reactie...'))),
                        IconButton(onPressed: submit, icon: const Icon(Icons.send)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openShareSheet(VideoItem v) async {
    List<ShareFriend> friends = const [];
    bool loading = true;
    String? error;
    try {
      friends = await controller.fetchShareFriends();
    } catch (e) {
      error = 'Vrienden laden mislukt: $e';
    } finally {
      loading = false;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> copyLink() async {
              await Clipboard.setData(ClipboardData(text: v.videoUrl));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link gekopieerd')));
            }
            Future<void> sendTo(String userId, String name) async {
              setModal(() { loading = true; error = null; });
              try {
                await controller.sendVideoToFriend(videoId: v.id, toUserId: userId);
                Get.back();
                Get.snackbar('Succes', 'Versturd naar $name', snackPosition: SnackPosition.BOTTOM);
              } catch (e) {
                setModal(() { loading = false; error = 'Versturen mislukt: $e'; });
              }
            }
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Deel video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  ElevatedButton.icon(onPressed: copyLink, icon: const Icon(Icons.link), label: const Text('Kopieer link')),
                  const SizedBox(height: 12),
                  const Text('Stuur naar vriend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  if (loading) const Center(child: CircularProgressIndicator())
                  else if (error != null) Text(error!, style: const TextStyle(color: Colors.red))
                  else if (friends.isEmpty) const Text('Geen vrienden gevonden of niet ingelogd')
                  else SizedBox(
                    height: 240,
                    child: ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (_, i) {
                        final f = friends[i];
                        return ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(f.name), onTap: () => sendTo(f.id, f.name));
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTopInfo(Restaurant r) {
    return [
      Text(
        r.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${r.cuisine} • ${r.category}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          const Icon(Icons.star, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            r.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.timer_outlined, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            r.eta,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2AAAB3),
        title: const Text("Video's"),
        centerTitle: true,
        actions: [
          IconButton(tooltip: 'Ververs', onPressed: controller.loadFeed, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Obx(() {
        final videos = controller.allVideos();
        if (controller.loadingAll) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error!, textAlign: TextAlign.center),
                ElevatedButton.icon(onPressed: controller.loadFeed, icon: const Icon(Icons.refresh), label: const Text('Opnieuw proberen')),
              ],
            ),
          );
        }
        if (videos.isEmpty) {
          return const Center(child: Text('Nog geen video\'s beschikbaar'));
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (i) => controller.activeIndex = i,
          itemBuilder: (context, index) {
            final v = videos[index];
            final isItemActive = index == controller.activeIndex;
            if (!isItemActive) {
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.white70, size: 64),
                    Text(v.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(v.restaurantName, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            }
            final vCtrl = _videoController;
            final init = _videoInit;
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.black),
                if (_videoInitError != null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_videoInitError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(v.videoUrl);
                            if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open in browser'),
                        ),
                      ],
                    ),
                  )
                else if (vCtrl == null || init == null) 
                  const Center(child: CircularProgressIndicator())
                else 
                  FutureBuilder<void>(
                    future: init,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      if (!vCtrl.value.isInitialized) return const Center(child: Text('Video kan niet laden', style: TextStyle(color: Colors.white)));
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: vCtrl.value.aspectRatio == 0 ? 16 / 9 : vCtrl.value.aspectRatio,
                              child: VideoPlayer(vCtrl),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xAA000000), Colors.transparent, Color(0xAA000000)],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                Positioned(
                  left: 16, 
                  right: 160, 
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      if (_findRestaurant(v.restaurantId) != null) ..._buildTopInfo(_findRestaurant(v.restaurantId)!)
                      else Text(v.restaurantName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Positioned(
                  left: 16, 
                  right: 16, 
                  bottom: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(v.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      if (v.description.trim().isNotEmpty) 
                        Text(v.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                      if (v.price != null) 
                        Text('€${(v.price ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2AAAB3).withValues(alpha: 0.9), 
                                foregroundColor: Colors.white, 
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                final rest = _findRestaurant(v.restaurantId);
                                if (rest != null && widget.onOpenRestaurant != null) {
                                  widget.onOpenRestaurant!(rest);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant niet gevonden')));
                                }
                              },
                              icon: const Icon(Icons.store_mall_directory),
                              label: const Text('Restaurant'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white, 
                                side: const BorderSide(color: Colors.white, width: 1.2), 
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                final rest = _findRestaurant(v.restaurantId);
                                if (rest != null && widget.onAddMenuItem != null) {
                                  if (v.menuItemId != null && v.menuItemId!.isNotEmpty) {
                                    final item = rest.menu.firstWhere(
                                      (m) => m.id == v.menuItemId, 
                                      orElse: () => rest.menu.isNotEmpty ? rest.menu.first : MenuItem(id: '', name: '', description: '', priceCents: 0),
                                    );
                                    if (item.id.isNotEmpty) { 
                                      widget.onAddMenuItem!(rest, item); 
                                      return; 
                                    }
                                  }
                                }
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerecht niet gevonden bij dit restaurant')));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Toevoegen'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12, 
                  top: 12, 
                  child: IconButton(
                    tooltip: controller.muted ? 'Geluid aan' : 'Geluid uit', 
                    onPressed: _toggleMute, 
                    icon: Icon(controller.muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 12, 
                  bottom: 100, 
                  child: Column(
                    children: [
                      _ActionIconButton(
                        icon: v.likedByMe ? Icons.favorite : Icons.favorite_border, 
                        color: v.likedByMe ? Colors.pink : Colors.white, 
                        badgeCount: v.likesCount, 
                        onTap: () => controller.toggleLike(v),
                      ),
                      const SizedBox(height: 10),
                      _ActionIconButton(icon: Icons.comment, color: Colors.white, onTap: () => _openCommentsSheet(v)),
                      const SizedBox(height: 10),
                      _ActionIconButton(icon: Icons.send_rounded, color: Colors.white, onTap: () => _openShareSheet(v)),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center, 
                  child: FractionallySizedBox(
                    widthFactor: 0.6, 
                    heightFactor: 0.6, 
                    child: Material(
                      color: Colors.transparent, 
                      child: InkWell(onTap: _togglePlayPause, child: const SizedBox.expand()),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;
  const _ActionIconButton({required this.icon, required this.color, required this.onTap, this.badgeCount});
  @override
  Widget build(BuildContext context) {
    final hasBadge = (badgeCount ?? 0) > 0;
    return Stack(
      clipBehavior: Clip.none, 
      children: [
        Material(
          color: color.withValues(alpha: 0.85), 
          shape: const CircleBorder(), 
          child: InkWell(
            customBorder: const CircleBorder(), 
            onTap: onTap, 
            child: SizedBox(
              width: 48, 
              height: 48, 
              child: Icon(icon, color: icon == Icons.favorite ? Colors.white : Colors.black87),
            ),
          ),
        ),
        if (hasBadge) 
          Positioned(
            right: -4, 
            top: -4, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
              decoration: BoxDecoration(
                color: Colors.red, 
                borderRadius: BorderRadius.circular(10), 
                border: Border.all(color: Colors.white, width: 1),
              ), 
              child: Text(
                '${badgeCount ?? 0}', 
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
