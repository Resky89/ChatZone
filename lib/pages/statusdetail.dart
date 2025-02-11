import 'package:flutter/material.dart';
import 'dart:async';
import '../services/status_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' show min;

class StatusDetail extends StatefulWidget {
  final List<dynamic> statuses;
  final int initialIndex;
  final bool isMyStatus;

  const StatusDetail({
    super.key,
    required this.statuses,
    required this.initialIndex,
    required this.isMyStatus,
  });

  @override
  State<StatusDetail> createState() => _StatusDetailState();
}

class _StatusDetailState extends State<StatusDetail>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  double _progress = 0.0;
  late int _currentIndex;
  late PageController _pageController;
  final StatusService _statusService = StatusService();
  VideoPlayerController? _videoController;
  bool _isMediaLoading = true;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _progressController.addListener(() {
      setState(() {
        _progress = _progressController.value;
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStatus();
      }
    });

    print('Status data: ${widget.statuses[_currentIndex]}');

    _initializeVideo(widget.statuses[_currentIndex]);
  }

  Future<void> _initializeVideo(dynamic status) async {
    _timer?.cancel();
    _videoController?.dispose();
    setState(() {
      _progress = 0.0;
      _isMediaLoading = true;
    });

    final mediaUrl = status['Media URL'];
    final isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
        mediaUrl.toLowerCase().endsWith('.mov');

    if (isVideo) {
      try {
        final videoUrl = 'http://10.0.2.2:3000/media/statuses/$mediaUrl';
        print('Loading video from: $videoUrl');

        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        _videoController!.addListener(() {
          final playerValue = _videoController!.value;
          if (playerValue.hasError) {
            print('Video player error: ${playerValue.errorDescription}');
          }
        });

        await _videoController!.initialize().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Video initialization timeout');
          },
        );

        if (!mounted) return;

        if (_videoController!.value.isInitialized) {
          setState(() {
            _isMediaLoading = false;
          });

          await _videoController!.play();
          _startVideoTimer();
        } else {
          throw Exception('Video initialization failed');
        }
      } catch (e) {
        print('Error playing video: $e');
        if (mounted) {
          setState(() {
            _isMediaLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memutar video. Silakan coba lagi nanti.'),
              duration: Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            _goToNextStatus();
          });
        }
      }
    } else {
      setState(() {
        _isMediaLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    if (_isMediaLoading) return;

    _progressController.stop();
    _progressController.reset();

    // Set durasi standar untuk image
    _progressController.duration = const Duration(seconds: 30);

    // Mulai animasi
    _progressController.forward().whenComplete(() {
      if (mounted) {
        if (_currentIndex == widget.statuses.length - 1) {
          // Jika ini status terakhir, kembali ke menu status
          Navigator.of(context).pushReplacementNamed('/status');
        } else {
          _goToNextStatus();
        }
      }
    });
  }

  void _startVideoTimer() {
    if (_isMediaLoading ||
        _videoController == null ||
        !_videoController!.value.isInitialized) return;

    _progressController.stop();
    _progressController.reset();

    // Set durasi sesuai panjang video
    _progressController.duration = _videoController!.value.duration;

    // Mulai animasi dan video
    _progressController.forward();
    _videoController!.play();

    _videoController!.addListener(() {
      if (_videoController!.value.position >=
          _videoController!.value.duration) {
        _videoController!.pause();
        _goToNextStatus();
      }
    });
  }

  void _pauseProgress() {
    _progressController.stop();
    _videoController?.pause();
  }

  void _resumeProgress() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.play();
      _progressController.forward();
    } else {
      _progressController.forward();
    }
  }

  void _goToNextStatus() {
    if (_currentIndex < widget.statuses.length - 1) {
      _currentIndex++;
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _cleanupAndNavigateBack();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _timer?.cancel();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String getTimeAgo(String createdAt) {
    try {
      // Parse format "MM-DD-YYYY HH:mm:ss" ke DateTime
      final parts = createdAt.split(' ');
      final dateParts = parts[0].split('-');
      final timePart = parts[1];

      final formattedDate =
          '${dateParts[2]}-${dateParts[0]}-${dateParts[1]} $timePart';
      final dateTime = DateTime.parse(formattedDate.replaceAll(' ', 'T'));

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just Now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} Minutes Ago';
      } else {
        return '${difference.inHours} Hours Ago';
      }
    } catch (e) {
      print('Error parsing date: $e');
      return 'Just Now';
    }
  }

  Future<void> _deleteStatus(String statusId) async {
    try {
      _timer?.cancel(); // Pause the timer while deleting
      await _statusService.deleteStatus(statusId);

      if (mounted) {
        // If this was the last status, pop back to previous screen
        if (widget.statuses.length <= 1) {
          Navigator.pop(context, true);
          return;
        }

        // Remove the deleted status and show next/previous
        setState(() {
          widget.statuses.removeAt(_currentIndex);
          if (_currentIndex >= widget.statuses.length) {
            _currentIndex = widget.statuses.length - 1;
          }
        });

        _pageController.jumpToPage(_currentIndex);
        _startTimer();
      }
    } catch (e) {
      print('Error deleting status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus status. Silakan coba lagi.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    _pauseProgress();

    if (tapPosition < screenWidth * 0.3) {
      // Tap kiri (previous)
      if (_currentIndex > 0) {
        _currentIndex--;
        _videoController?.dispose();
        _videoController = null;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else if (tapPosition > screenWidth * 0.7) {
      // Tap kanan (next)
      if (_currentIndex < widget.statuses.length - 1) {
        _goToNextStatus();
      } else {
        // Jika sudah tidak ada status selanjutnya, kembali ke menu
        _cleanupAndNavigateBack();
      }
    }
  }

  // Tambahkan method baru untuk membersihkan resources dan navigasi
  void _cleanupAndNavigateBack() {
    // Cleanup semua resources
    _progressController.stop();
    _timer?.cancel();
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    // Kembali ke menu status dengan pop (instead of pushReplacementNamed)
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _resumeProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onLongPressStart: (_) => _pauseProgress(),
        onLongPressEnd: (_) => _resumeProgress(),
        child: Stack(
          children: [
            // Content (PageView)
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.statuses.length,
              onPageChanged: (index) async {
                _progressController.stop();
                _videoController?.dispose();
                _videoController = null;

                setState(() {
                  _currentIndex = index;
                  _progress = 0.0;
                  _isMediaLoading = true;
                });

                await _initializeVideo(widget.statuses[index]);
              },
              itemBuilder: (context, index) {
                final status = widget.statuses[index];
                final mediaUrl = status['Media URL'];
                final isVideo = mediaUrl.toLowerCase().endsWith('.mp4') ||
                    mediaUrl.toLowerCase().endsWith('.mov');

                if (isVideo) {
                  if (_videoController?.value.isInitialized ?? false) {
                    _isMediaLoading = false;
                    return Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    );
                  } else {
                    _isMediaLoading = true;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                } else {
                  return Center(
                    child: Image.network(
                      'http://10.0.2.2:3000/media/statuses/$mediaUrl',
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          if (_isMediaLoading) {
                            setState(() {
                              _isMediaLoading = false;
                            });
                            // Mulai timer setelah image selesai loading
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _startTimer();
                            });
                          }
                          return child;
                        }
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        _isMediaLoading = false;
                        return const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 50,
                        );
                      },
                    ),
                  );
                }
              },
            ),

            // Overlay container with progress bar and header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.2],
                ),
              ),
              child: Column(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        children: List.generate(
                          widget.statuses.length,
                          (index) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: index < _currentIndex
                                      ? 1.0
                                      : index == _currentIndex
                                          ? _progress
                                          : 0.0,
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Header with user info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            _timer?.cancel();
                            Navigator.pop(context);
                          },
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.primaries[
                              widget.statuses[_currentIndex]['user_id'] %
                                  Colors.primaries.length],
                          backgroundImage: widget.statuses[_currentIndex]
                                          ['Profile Picture'] !=
                                      null &&
                                  widget.statuses[_currentIndex]
                                          ['Profile Picture']
                                      .toString()
                                      .isNotEmpty
                              ? NetworkImage(
                                  'http://10.0.2.2:3000/media/profile_pictures/${widget.statuses[_currentIndex]['Profile Picture']}')
                              : null,
                          child: (widget.statuses[_currentIndex]
                                          ['Profile Picture'] ==
                                      null ||
                                  widget.statuses[_currentIndex]
                                          ['Profile Picture']
                                      .toString()
                                      .isEmpty)
                              ? Text(
                                  widget.statuses[_currentIndex]['Username']
                                      .split(' ')
                                      .map((word) => word[0].toUpperCase())
                                      .join('')
                                      .substring(
                                          0,
                                          min<int>(
                                              2,
                                              widget.statuses[_currentIndex]
                                                      ['Username']
                                                  .split(' ')
                                                  .length)),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.isMyStatus
                                    ? 'Status saya'
                                    : widget.statuses[_currentIndex]
                                        ['Username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                getTimeAgo(widget.statuses[_currentIndex]
                                    ['Created At']),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isMyStatus)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Hapus Status'),
                                  content: const Text(
                                      'Apakah Anda yakin ingin menghapus status ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        final statusId = widget
                                            .statuses[_currentIndex]
                                                ['status_id']
                                            .toString();
                                        print(
                                            'Trying to delete status with ID: $statusId'); // Debug print
                                        print(
                                            'Full status object: ${widget.statuses[_currentIndex]}'); // Debug print
                                        _deleteStatus(statusId);
                                      },
                                      child: const Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Caption at bottom
            if (widget.statuses[_currentIndex]['Caption'] != null &&
                widget.statuses[_currentIndex]['Caption'].toString().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    widget.statuses[_currentIndex]['Caption'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
