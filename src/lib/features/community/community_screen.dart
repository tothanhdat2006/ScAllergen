import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ScAllergen/core/constants/colors.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ScAllergen/features/community/community_result_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[100];
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final foregroundColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Forum", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: appBarColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: foregroundColor,
      ),
      backgroundColor: backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("No posts yet.\nScan a product to share!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildPostCard(context, data, docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> data, String postId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[500];

    final Timestamp? ts = data['timestamp'];
    final DateTime date = ts?.toDate() ?? DateTime.now();

    final String postUserId = data['userId'] ?? '';
    final String fallbackEmail = data['userEmail'] ?? 'Anonymous';
    String fallbackName = 'User';
    if (fallbackEmail.contains('@')) fallbackName = fallbackEmail.split('@').first;

    final bool isRisky = data['hasAllergyRisk'] ?? false;
    final List<dynamic> ingredients = data['ingredients'] ?? [];
    final String imageUrl = data['imageUrl'] ?? '';

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isOwner = currentUid == postUserId;

    final List<dynamic> likes = data['likes'] ?? [];
    final int commentCount = data['commentCount'] ?? 0;
    final bool isLiked = likes.contains(currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isRisky ? AppColors.error.withOpacity(0.5) : AppColors.success.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(postUserId).get(),
              builder: (context, snapshot) {
                String displayName = fallbackName;
                String? avatarUrl;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  displayName = userData['name'] ?? userData['fullName'] ?? userData['display_name'] ?? fallbackName;
                  avatarUrl = userData['avatar_url'];
                }

                final String firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : "U";

                return Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showUserAllergies(context, postUserId, displayName),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? null
                            : Text(firstLetter, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          Text(timeago.format(date), style: TextStyle(color: subTextColor, fontSize: 11)),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRisky ? AppColors.error : AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isRisky ? "RISKY" : "SAFE",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),

                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openAnalysisForMe(context, imageUrl, ingredients),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Icon(Icons.person_search_rounded, size: 18, color: AppColors.primary),
                      ),
                    ),

                    if (isOwner)
                      InkWell(
                        onTap: () => _confirmDelete(context, postId, imageUrl),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Icon(Icons.delete_outline_rounded, size: 22, color: Colors.red[300]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () => _openAnalysisForMe(context, imageUrl, ingredients),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, loading) {
                              if (loading == null) return child;
                              return Container(color: isDark ? Colors.grey[800] : Colors.grey[100]);
                            },
                          ),
                        ),
                      ]
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(postId, currentUid, likes),
                  child: Row(
                    children: [
                      Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 26, color: isLiked ? Colors.red : textColor),
                      const SizedBox(width: 6),
                      Text("${likes.length}", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => _showCommentsBottomSheet(context, postId),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 24, color: textColor),
                      const SizedBox(width: 6),
                      Text("$commentCount", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAnalysisForMe(BuildContext context, String imageUrl, List<dynamic> ingredients) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityResultScreen(
          imageUrl: imageUrl,
          ingredients: ingredients,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String postId, String imageUrl) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("This action will permanently delete this post and its image."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (imageUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(imageUrl).delete();
            debugPrint("✅ Đã xoá ảnh khỏi Storage: $imageUrl");
          } catch (e) {
            debugPrint("⚠️ Lỗi xoá ảnh Storage (có thể bỏ qua): $e");
          }
        }

        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Post and image deleted"), backgroundColor: Colors.grey)
          );
        }
      } catch (e) {
        debugPrint("❌ Lỗi khi xoá bài viết: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error deleting post: $e"), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  Future<void> _toggleLike(String postId, String userId, List<dynamic> currentLikes) async {
    if (userId.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);
    if (currentLikes.contains(userId)) {
      await ref.update({'likes': FieldValue.arrayRemove([userId])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([userId])});
    }
  }

  void _showCommentsBottomSheet(BuildContext context, String postId) {
    final TextEditingController commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (ctx, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final comments = snapshot.data!.docs;
                    if (comments.isEmpty) return const Center(child: Text("No comments yet."));

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (ctx, i) {
                        final cData = comments[i].data() as Map<String, dynamic>;
                        final bool isMyComment = user != null && cData['userId'] == user.uid;

                        final String commentUserId = cData['userId'] ?? '';
                        final String commentUserNameFallback = cData['userName'] ?? 'Anonymous';

                        return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(commentUserId).get(),
                            builder: (context, userSnapshot) {
                              String displayName = commentUserNameFallback;
                              String? avatarUrl;

                              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                displayName = userData['name'] ?? userData['fullName'] ?? commentUserNameFallback;
                                avatarUrl = userData['avatar_url'];
                              }

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                                  child: (avatarUrl == null) ? Text(displayName[0].toUpperCase()) : null,
                                ),
                                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(cData['text'] ?? ''),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isMyComment)
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').doc(comments[i].id).delete();
                                          await FirebaseFirestore.instance.collection('posts').doc(postId).update({'commentCount': FieldValue.increment(-1)});
                                        },
                                      )
                                  ],
                                ),
                              );
                            }
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(child: TextField(controller: commentController, decoration: const InputDecoration(hintText: "Write a comment...", border: InputBorder.none))),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty || user == null) return;
                      final text = commentController.text.trim();
                      commentController.clear();
                      await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').add({
                        'text': text, 'userId': user.uid, 'userName': user.email?.split('@')[0] ?? 'User', 'timestamp': FieldValue.serverTimestamp()
                      });
                      await FirebaseFirestore.instance.collection('posts').doc(postId).update({'commentCount': FieldValue.increment(1)});
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showUserAllergies(BuildContext context, String userId, String userName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final List<dynamic> allergies = userData?['allergies'] ?? [];
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$userName's Allergies", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (allergies.isEmpty)
                  const Text("This user hasn't listed any allergies.")
                else
                  Wrap(spacing: 8, children: allergies.map((e) => Chip(label: Text(e.toString()), backgroundColor: AppColors.error.withOpacity(0.1))).toList()),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}