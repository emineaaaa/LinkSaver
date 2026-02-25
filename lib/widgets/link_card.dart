import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme/app_theme.dart';
import '../models/link_model.dart';

/// Figma tasarımına sadık link kartı:
/// - Beyaz kart, 16px köşe yuvarlaması, hafif gölge
/// - Sol: platform ikonu (marka rengi, 46×46 yuvarlak kare)
/// - Sağ: başlık (koyu, kalın), URL (mavi-gri, küçük), tarih (mor, küçük)
/// - Sola kaydırma → sil
class LinkCard extends StatelessWidget {
  final LinkModel link;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRefresh;
  final VoidCallback? onToggleFavorite;

  const LinkCard({
    super.key,
    required this.link,
    required this.onTap,
    required this.onDelete,
    required this.onRefresh,
    this.onToggleFavorite,
  });

  // ─── Platform tanıma ──────────────────────────────────────────────────────

  _PlatformInfo _detectPlatform(String url) {
    if (url.contains('instagram.com')) {
      return const _PlatformInfo(
        color: Color(0xFFE1306C),
        icon: FontAwesomeIcons.instagram,
        gradient: LinearGradient(
          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      );
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return const _PlatformInfo(
        color: Color(0xFFFF0000),
        icon: FontAwesomeIcons.youtube,
      );
    }
    if (url.contains('twitter.com') || url.contains('x.com')) {
      return const _PlatformInfo(
        color: Color(0xFF111111),
        icon: FontAwesomeIcons.xTwitter,
      );
    }
    if (url.contains('facebook.com')) {
      return const _PlatformInfo(
        color: Color(0xFF1877F2),
        icon: FontAwesomeIcons.facebook,
      );
    }
    if (url.contains('tiktok.com')) {
      return const _PlatformInfo(
        color: Color(0xFF010101),
        icon: FontAwesomeIcons.tiktok,
      );
    }
    if (url.contains('reddit.com')) {
      return const _PlatformInfo(
        color: Color(0xFFFF4500),
        icon: FontAwesomeIcons.reddit,
      );
    }
    if (url.contains('github.com')) {
      return const _PlatformInfo(
        color: Color(0xFF181717),
        icon: FontAwesomeIcons.github,
      );
    }
    if (url.contains('linkedin.com')) {
      return const _PlatformInfo(
        color: Color(0xFF0A66C2),
        icon: FontAwesomeIcons.linkedin,
      );
    }
    if (url.contains('spotify.com')) {
      return const _PlatformInfo(
        color: Color(0xFF1DB954),
        icon: FontAwesomeIcons.spotify,
      );
    }
    if (url.contains('twitch.tv')) {
      return const _PlatformInfo(
        color: Color(0xFF9146FF),
        icon: FontAwesomeIcons.twitch,
      );
    }
    if (url.contains('pinterest.com')) {
      return const _PlatformInfo(
        color: Color(0xFFE60023),
        icon: FontAwesomeIcons.pinterest,
      );
    }
    return const _PlatformInfo(
      color: AppColors.primary,
      icon: FontAwesomeIcons.link,
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final platform = _detectPlatform(link.url);

    return Dismissible(
      key: Key(link.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Platform ikonu ─────────────────────────────────────────
              _buildPlatformIcon(platform),
              const SizedBox(width: 12),

              // ── İçerik ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      link.title?.isNotEmpty == true
                          ? link.title!
                          : _extractDomain(link.url),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // URL
                    Text(
                      link.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.urlColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Tarih
                    Text(
                      _formatDate(link.savedAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.dateColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Favori butonu ─────────────────────────────────────────
              if (onToggleFavorite != null)
                GestureDetector(
                  onTap: onToggleFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      link.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: link.isFavorite
                          ? Colors.amber.shade600
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Yardımcı widget'lar ──────────────────────────────────────────────────

  Widget _buildPlatformIcon(_PlatformInfo platform) {
    // Favicon varsa kullan, bilinen platformlar için marka ikonu tercih edilir
    final bool isKnownPlatform =
        platform.icon != FontAwesomeIcons.link;

    if (!isKnownPlatform &&
        link.faviconUrl != null &&
        link.faviconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          link.faviconUrl!,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildFallbackIcon(platform),
        ),
      );
    }
    return _buildFallbackIcon(platform);
  }

  Widget _buildFallbackIcon(_PlatformInfo platform) {
    if (platform.gradient != null) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: platform.gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: FaIcon(platform.icon, color: Colors.white, size: 20),
      );
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: platform.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: FaIcon(platform.icon, color: platform.color, size: 20),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
          SizedBox(height: 3),
          Text(
            'Sil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Yardımcı fonksiyonlar ────────────────────────────────────────────────

  String _extractDomain(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}

// ─── Yardımcı veri sınıfı ─────────────────────────────────────────────────────

class _PlatformInfo {
  final Color color;
  final IconData icon;
  final LinearGradient? gradient;

  const _PlatformInfo({
    required this.color,
    required this.icon,
    this.gradient,
  });
}