class PostModel {
  final String id;
  final String networkId;
  final String authorUsername;
  final String authorImageUrl;
  final bool isVerified;
  final String imageUrl;
  final int likesCount;
  final String content;
  final int commentsCount;
  final String timeAgo;

  PostModel({
    required this.id,
    required this.networkId,
    required this.authorUsername,
    required this.authorImageUrl,
    required this.isVerified,
    required this.imageUrl,
    required this.likesCount,
    required this.content,
    required this.commentsCount,
    required this.timeAgo,
  });
}
