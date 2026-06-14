import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

/// Responsabilidad principal:
/// Mostrar el historial de notificaciones. Agrupa visualmente los elementos en: Hoy, Esta semana y Anteriormente. Provee enlaces directos a las publicaciones relevantes.
///
/// Flujo dentro de la app:
/// Llama a `loadNotifications` al iniciar y luego despacha la orden silenciosa de `markAllAsRead`. Escucha reactivamente a `NotificationProvider`.
///
/// Dependencias críticas:
/// - `NotificationProvider` (Gestión centralizada del historial y conteo no leído global).
///
/// Side Effects:
/// - Lectura Silenciosa: `provider.markAllAsRead()` muta el backend asíncronamente tan pronto la pantalla se abre, reseteando la "burbuja roja" en la barra de navegación del Home de inmediato.
///
/// Recordatorios técnicos y CQRS:
/// - Navegación Estática: La navegación hacia el contenido (`context.push('/post/id')`) viola ligeramente la separación de responsabilidades, asumiendo conocimiento directo del router local en vez de delegar en un `Command` o `NavigationService`.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      provider.loadNotifications().then((_) {
        if (mounted) _fadeController.forward();
      });
      provider.markAllAsRead();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: AppTheme.surface.withValues(alpha: 0.85),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.primaryText, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Notificaciones',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryText,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                if (provider.unreadCount > 0)
                  _UnreadBadge(count: provider.unreadCount),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(context, provider),
    );
  }

  Widget _buildBody(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (provider.status == NotifStatus.error) {
      return _ErrorState(
        message: provider.error ?? 'Error al cargar notificaciones',
        onRetry: () {
          _fadeController.reset();
          provider.refresh().then((_) {
            if (mounted) _fadeController.forward();
          });
        },
      );
    }

    if (provider.status == NotifStatus.empty) {
      return _EmptyState(fadeAnim: _fadeAnim);
    }

    final grouped = provider.grouped;
    final order = [
      NotificationGroup.today,
      NotificationGroup.thisWeek,
      NotificationGroup.earlier,
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () {
          _fadeController.reset();
          return provider.refresh().then((_) {
            if (mounted) _fadeController.forward();
          });
        },
        child: ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            bottom: 32,
          ),
          itemCount: _countItems(grouped, order),
          itemBuilder: (ctx, idx) => _buildItem(ctx, grouped, order, idx),
        ),
      ),
    );
  }

  // Cuenta total de ítems: encabezados + notificaciones
  int _countItems(
    Map<NotificationGroup, List<NotificationModel>> grouped,
    List<NotificationGroup> order,
  ) {
    int count = 0;
    for (final group in order) {
      final list = grouped[group];
      if (list != null && list.isNotEmpty) {
        count += 1 + list.length; // header + items
      }
    }
    return count;
  }

  // Construye cada ítem (header o notificación).
  // Las notificaciones son solo informativas, sin acciones de navegación.
  Widget _buildItem(
    BuildContext context,
    Map<NotificationGroup, List<NotificationModel>> grouped,
    List<NotificationGroup> order,
    int globalIndex,
  ) {
    int cursor = 0;
    for (final group in order) {
      final list = grouped[group];
      if (list == null || list.isEmpty) continue;

      if (globalIndex == cursor) {
        return _GroupHeader(label: group.label);
      }
      cursor++;

      for (int i = 0; i < list.length; i++) {
        if (globalIndex == cursor) {
          return _NotificationTile(notification: list[i]);
        }
        cursor++;
      }
    }
    return const SizedBox.shrink();
  }
}

// ─── Badge de no leídas ───────────────────────────────────────────────────────
class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Encabezado de grupo ──────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Tile de notificación ─────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<NotificationProvider>().markAsRead(notification.id);
        if (notification.publicacionId != null) {
          context.push('/post/${notification.publicacionId}');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: notification.leida
            ? Colors.transparent
            : AppTheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.emisorSnap?.fotoPerfil != null)
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(notification.emisorSnap!.fotoPerfil!),
                )
              else
                _TypeIcon(notification: notification),
              const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor(notification).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.tipoLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _typeColor(notification),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (!notification.leida)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.textoResumido,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.onSurface,
                      fontWeight: notification.leida ? FontWeight.w400 : FontWeight.w600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Color _typeColor(NotificationModel notif) {
    switch (notif.tipo) {
      case 'like':
        return Colors.red;
      case 'comentario':
        return Colors.blue;
      case 'respuesta_comentario':
        return Colors.teal;
      case 'strike':
        return (notif.mensajeTexto?.contains('suspendida') ?? false)
            ? Colors.red.shade700
            : Colors.orange.shade700;
      default:
        return AppTheme.primary;
    }
  }


}

// ─── Ícono del tipo de notificación ─────────────────────────────────────────
class _TypeIcon extends StatelessWidget {
  final NotificationModel notification;

  const _TypeIcon({required this.notification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (notification.tipo) {
      case 'like':
        icon = Icons.favorite_rounded;
        color = Colors.red;
        break;
      case 'comentario':
        icon = Icons.chat_bubble_rounded;
        color = Colors.blue;
        break;
      case 'respuesta_comentario':
        icon = Icons.reply_rounded;
        color = Colors.teal;
        break;
      case 'strike':
        icon = Icons.warning_amber_rounded;
        color = (notification.mensajeTexto?.contains('suspendida') ?? false)
            ? Colors.red.shade700
            : Colors.orange.shade700;
        break;
      default:
        icon = Icons.campaign_rounded;
        color = AppTheme.primary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: notification.leida ? 0.08 : 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Animation<double> fadeAnim;
  const _EmptyState({required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text('Sin notificaciones', style: AppTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Cuando alguien interactúe contigo,\naparecerá aquí.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 72, color: AppTheme.error),
            const SizedBox(height: 20),
            Text('No se pudieron cargar', style: AppTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
