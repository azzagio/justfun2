import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:simple_dating_app/models/user_model.dart';

class ProfileCard extends StatefulWidget {
  final UserModel user;

  const ProfileCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _currentPhotoIndex = 0;

  void _nextPhoto() {
    if (widget.user.photos?.isNotEmpty ?? false) {
      setState(() {
        _currentPhotoIndex = (_currentPhotoIndex + 1) % (widget.user.photos!.length);
      });
    }
  }

  void _previousPhoto() {
    if (widget.user.photos?.isNotEmpty ?? false) {
      setState(() {
        _currentPhotoIndex = (_currentPhotoIndex - 1 + widget.user.photos!.length) % widget.user.photos!.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.user.photos?.isEmpty ?? true) // Simplifié avec ?? true
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 100, color: Colors.grey),
              )
            else
              GestureDetector(
                onTapDown: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < screenWidth / 2) {
                    _previousPhoto();
                  } else {
                    _nextPhoto();
                  }
                },
                child: CachedNetworkImage(
                  imageUrl: widget.user.photos![_currentPhotoIndex] ?? 'https://via.placeholder.com/150', // Gestion de null avec valeur par défaut
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 100, color: Colors.red),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.user.name}, ${widget.user.age}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.user.bio.isNotEmpty)
                      Text(
                        widget.user.bio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if ((widget.user.photos?.isNotEmpty ?? false) && (widget.user.photos!.length > 1))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.user.photos!.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _currentPhotoIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}