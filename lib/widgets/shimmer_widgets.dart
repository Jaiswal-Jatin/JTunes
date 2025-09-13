import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// Home screen shimmer for header and quick access buttons
class HomeHeaderShimmer extends StatelessWidget {
  const HomeHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [Colors.grey[850]!, Colors.grey[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Home screen shimmer for horizontal song section
class HomeSongSectionShimmer extends StatelessWidget {
  final String title;
  const HomeSongSectionShimmer({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            width: 140,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [Colors.grey[850]!, Colors.grey[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[700]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.09),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [Colors.grey[850]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 90,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [Colors.grey[850]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 60,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [Colors.grey[850]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Home screen shimmer for horizontal playlist section
class HomePlaylistSectionShimmer extends StatelessWidget {
  final String title;
  const HomePlaylistSectionShimmer({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Container(
            width: 140,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [Colors.grey[850]!, Colors.grey[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[700]!,
                child: Container(
                  width: 160,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [Colors.grey[850]!, Colors.grey[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// Playlist page shimmer for header
class PlaylistHeaderShimmer extends StatelessWidget {
  const PlaylistHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Match PlaylistHeader: image (square), then title, then song count, all centered
    final double imageSize = screenWidth / 2.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[900]!,
                highlightColor: Colors.grey[700]!,
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                    gradient: LinearGradient(
                      colors: [Colors.grey[850]!, Colors.grey[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 30),
            Column(
              children: [
                Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[900]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      width: 130,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [Colors.grey[850]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[900]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: [Colors.grey[850]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Playlist page shimmer for song list
class PlaylistSongListShimmer extends StatelessWidget {
  const PlaylistSongListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // Match playlist page: vertical list of song bars with image and text
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[900]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.grey[850]!, Colors.grey[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[900]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [Colors.grey[850]!, Colors.grey[800]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[900]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: [Colors.grey[850]!, Colors.grey[800]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
