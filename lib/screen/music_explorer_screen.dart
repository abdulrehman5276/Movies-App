import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/media_model.dart';
import '../services/media_provider.dart';
import 'music_player_screen.dart';

class MusicExplorerScreen extends StatefulWidget {
  const MusicExplorerScreen({super.key});

  @override
  State<MusicExplorerScreen> createState() => _MusicExplorerScreenState();
}

class _MusicExplorerScreenState extends State<MusicExplorerScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          final musicList = provider.mediaList
              .where((m) => m.category == 'Songs')
              .toList();

          final filteredList = musicList.where((m) {
            final query = _searchQuery.toLowerCase();
            return m.title.toLowerCase().contains(query) ||
                (m.description?.toLowerCase().contains(query) ?? false);
          }).toList();

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (filteredList.isEmpty)
                _buildEmptyState()
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _MusicListItem(
                        song: filteredList[index],
                        playlist: filteredList,
                        index: index,
                      ),
                      childCount: filteredList.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'MUSIC BOX',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 22,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Using signup_bg for music aesthetic consistency
            Image.asset('assets/images/signup_bg.png', fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.black],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            Text(
              'No music found',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusicListItem extends StatelessWidget {
  final MediaModel song;
  final List<MediaModel> playlist;
  final int index;

  const _MusicListItem({
    required this.song,
    required this.playlist,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.redAccent,
                Colors.redAccent.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          song.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          song.description ?? 'No Artist Info',
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.redAccent.withValues(alpha: 0.8),
          size: 35,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MusicPlayerScreen(playlist: playlist, initialIndex: index),
          ),
        ),
      ),
    );
  }
}
