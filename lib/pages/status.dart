import 'package:flutter/material.dart';
import 'profile.dart';
import '../app/register.dart';
import '../services/status_service.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'statusdetail.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import 'widgets/video_preview.dart';
import 'package:shimmer/shimmer.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final StatusService _statusService = StatusService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  List<dynamic> myStatuses = [];
  List<dynamic> otherStatuses = [];
  int currentUserId = 0;
  String? userPhoneNumber;
  Map<String, dynamic>? userData;

  // Ubah menjadi static untuk memastikan hanya ada satu flag untuk semua instance
  static bool _isPickerActive = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      currentUserId = await _authService.getCurrentUserId();

      // Load user data
      final prefs = await SharedPreferences.getInstance();
      userPhoneNumber = prefs.getString('phone_number');
      if (userPhoneNumber != null) {
        final userResponse =
            await _userService.getUserByPhoneNumber(userPhoneNumber!);
        userData = userResponse['data'];
      }

      // Load statuses
      final myStatusList =
          await _statusService.getMyStatuses(currentUserId.toString());
      final otherStatusList =
          await _statusService.getOtherStatuses(currentUserId.toString());

      setState(() {
        myStatuses = myStatusList;
        otherStatuses = otherStatusList;
      });
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleMediaPicker(ImageSource source) async {
    if (_isPickerActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon tunggu, picker sedang aktif')),
      );
      return;
    }

    setState(() {
      _isPickerActive = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      XFile? media;
      String? selectedMediaType;

      // Jika source adalah camera, langsung ambil gambar
      if (source == ImageSource.camera) {
        media = await _picker.pickImage(source: source);
        selectedMediaType = 'image';
      } else {
        // Untuk gallery, tetap tampilkan pilihan
        selectedMediaType = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Choose Media Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Image'),
                  onTap: () => Navigator.pop(context, 'image'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Video'),
                  onTap: () => Navigator.pop(context, 'video'),
                ),
              ],
            ),
          ),
        );

        if (selectedMediaType == null) {
          setState(() {
            _isPickerActive = false;
          });
          return;
        }

        if (selectedMediaType == 'image') {
          media = await _picker.pickImage(source: source);
        } else {
          media = await _picker.pickVideo(source: source);
        }
      }

      // Sisa kode preview dan upload tetap sama
      if (media != null) {
        print('Selected media path: ${media.path}');

        // Preview remains similar, just need to handle video preview
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Stack(
              children: [
                // Media Preview
                Positioned.fill(
                  child: selectedMediaType == 'image'
                      ? Center(
                          child: Image.file(
                            File(media!.path),
                            fit: BoxFit.contain,
                          ),
                        )
                      : VideoPreview(
                          videoPath: media!.path,
                        ),
                ),
                
                // Header controls
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            _captionController.clear();
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.crop_rotate, color: Colors.white),
                              onPressed: () {
                                // TODO: Implement crop feature
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white),
                              onPressed: () {
                                // TODO: Implement emoji picker
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Caption input at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _captionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: primaryPurple,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: () async {
                                final caption =
                                    _captionController.text.trim();
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(context);
                                final navigatorState =
                                    Navigator.of(context);

                                try {
                                  // Debug print untuk memeriksa nilai caption
                                  print(
                                      'Debug - Caption before sending: $caption');

                                  // Kirim status dengan caption
                                  await _statusService.postStatus(
                                    currentUserId.toString(),
                                    media!.path,
                                    caption:
                                        caption, // Langsung kirim caption tanpa pengecekan
                                  );

                                  // Debug print untuk konfirmasi pengiriman
                                  print(
                                      'Debug - Status posted with caption: $caption');

                                  if (!mounted) return;
                                  await _loadData();

                                  // Clear caption dan tutup modal setelah berhasil
                                  _captionController.clear();
                                  navigatorState.pop();

                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Status berhasil diupload')),
                                  );
                                } catch (e) {
                                  print('Debug - Error posting status: $e');
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Gagal mengunggah status')),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih media')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickerActive = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  final Color primaryPurple = const Color(0xFF6200EE);
  final Color lightPurple = const Color(0xFFBB86FC);

  @override
  Widget build(BuildContext context) {
    // Kelompokkan status berdasarkan Username
    final Map<String, List<dynamic>> groupedStatuses = {};
    for (var status in otherStatuses) {
      final username = status['Username'] as String;
      if (!groupedStatuses.containsKey(username)) {
        groupedStatuses[username] = [];
      }
      groupedStatuses[username]!.add(status);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryPurple,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfilePage(phoneNumber: 'userPhoneNumber'),
                  ),
                );
              } else if (value == 'logout') {
                await _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.grey[50],
              child: Text(
                'Status saya',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (isLoading)
              _buildShimmerLoading()
            else ...[
              _buildStatusItem(
                status: myStatuses.isNotEmpty
                    ? myStatuses.first
                    : {
                        'profile_picture':
                            userData?['profile_picture'] ?? 'default.jpg'
                      },
                isMyStatus: true,
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                color: Colors.grey[50],
                child: Text(
                  'Status terbaru',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ...groupedStatuses.entries.map((entry) => Column(
                    children: [
                      _buildStatusItem(
                        status: entry.value.first,
                        isMyStatus: false,
                      ),
                      const Divider(height: 1),
                    ],
                  )),
            ],
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'btn1',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: primaryPurple,
            onPressed: () => _handleMediaPicker(ImageSource.gallery),
            child: const Icon(Icons.edit, size: 20),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btn2',
            backgroundColor: primaryPurple,
            onPressed: () => _handleMediaPicker(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _authService.logout();
      if (!mounted) return;

      // Gunakan pushAndRemoveUntil untuk membersihkan stack navigasi
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RegisterPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Widget _buildStatusItem({required dynamic status, required bool isMyStatus}) {
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

    // Get total status count for the user
    final int statusCount = isMyStatus
        ? myStatuses.length
        : otherStatuses
            .where((s) => s['Username'] == status['Username'])
            .length;

    // Determine the image URL based on whether there are statuses
    final String imageUrl = isMyStatus && myStatuses.isEmpty
        ? 'http://10.0.2.2:3000/media/profile_pictures/${userData?['profile_picture'] ?? 'default.jpg'}'
        : statusCount > 0
            ? 'http://10.0.2.2:3000/media/statuses/${status['Media URL']}'
            : 'http://10.0.2.2:3000/media/profile_pictures/${status['Profile Picture']}';

    return InkWell(
      onTap: () {
        if (isMyStatus) {
          if (myStatuses.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatusDetail(
                  statuses: myStatuses,
                  initialIndex: 0,
                  isMyStatus: true,
                ),
              ),
            );
          } else {
            _handleMediaPicker(ImageSource.gallery);
          }
        } else {
          final userStatuses = otherStatuses
              .where((s) => s['Username'] == status['Username'])
              .toList();
          final initialIndex = userStatuses.indexOf(status);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StatusDetail(
                statuses: userStatuses,
                initialIndex: initialIndex,
                isMyStatus: false,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                children: [
                  // Status circles or profile picture border
                  if (isMyStatus && statusCount == 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                      ),
                    )
                  else if (statusCount > 0)
                    ...List.generate(statusCount, (index) {
                      return Positioned.fill(
                        child: Transform.rotate(
                          angle: (2 * 3.14 * index) / statusCount,
                          child: CustomPaint(
                            painter: StatusArcPainter(
                              color: primaryPurple,
                              strokeWidth: 2,
                              sweepAngle: (2 * 3.14) / statusCount,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Profile/Status Image
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Add icon for empty my status
                  if (isMyStatus && statusCount == 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMyStatus
                        ? 'Status saya'
                        : status['Username'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isMyStatus && myStatuses.isEmpty
                        ? 'Ketuk untuk menambahkan status'
                        : getTimeAgo(status['Created At']),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: [
        // Shimmer untuk "Status saya"
        _buildShimmerStatusItem(),

        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.grey[50],
          child: Text(
            'Status terbaru',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Shimmer untuk status terbaru (3 item)
        ...List.generate(
            3,
            (index) => Column(
                  children: [
                    _buildShimmerStatusItem(),
                    const Divider(height: 1),
                  ],
                )),
      ],
    );
  }

  Widget _buildShimmerStatusItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this custom painter class
class StatusArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepAngle;

  StatusArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
