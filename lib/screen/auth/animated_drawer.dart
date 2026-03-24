import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:testers/constants/app_routes.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/widgets/badge/coin_badge.dart';
import 'package:testers/widgets/badge/notification_badge.dart';

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isDestructive = false,
    this.isPush = false,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isDestructive;
  final bool isPush;
}

const List<_DrawerItem> _navItems = [
  _DrawerItem(
    icon:       Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label:      'Discovery',
    route:      AppRoutes.discovery,
  ),
  _DrawerItem(
    icon:       Icons.group_outlined,
    activeIcon: Icons.group,
    label:      'Room',
    route:      AppRoutes.room,
  ),
  _DrawerItem(
    icon:       Icons.add_circle_outline,
    activeIcon: Icons.add_circle,
    label:      'Recharge',
    route:      AppRoutes.recharge,
    isPush:     false,
  ),
  _DrawerItem(
    icon:       Icons.notifications_none_rounded,
    activeIcon: Icons.notifications_rounded,
    label:      'Notifications',
    route:      AppRoutes.notification,
    isPush:     false,
  ),
  _DrawerItem(
    icon:       Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label:      'Profile',
    route:      AppRoutes.profile,
  ),
  _DrawerItem(
    icon:       Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label:      'Settings',
    route:      AppRoutes.settings,
  ),
];





class AnimatedDrawer extends StatefulWidget {
  const AnimatedDrawer({
    super.key,
    required this.child,
    required this.currentRoute,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.showCoinBadge = false,
    this.showNotificationBadge = false,
    this.leadingWidget,
  });

  final Widget child;
  final String currentRoute;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool showCoinBadge;
  final bool showNotificationBadge;
  final Widget? leadingWidget;

  @override
  State<AnimatedDrawer> createState() => _AnimatedDrawerScaffoldState();
}

class _AnimatedDrawerScaffoldState extends State<AnimatedDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _drawerAnim;
  late final Animation<double> _radiusAnim;
  late final Animation<double> _overlayAnim;
  late final Animation<double> _drawerFadeAnim;
  late final Animation<double> _verticalPadAnim;

  bool   _isDrawerOpen = false;
  double _dragStartX   = 0;

  double get _maxSlide => MediaQuery.of(context).size.width * 0.65;
  static const double _vertShift = 40.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);

    _radiusAnim       = Tween<double>(begin: 0,    end: 24).animate(_drawerAnim);
    _overlayAnim      = Tween<double>(begin: 0,    end: 0.01).animate(_drawerAnim);
    _drawerFadeAnim   = Tween<double>(begin: 0,    end: 1).animate(_drawerAnim);
    _verticalPadAnim  = Tween<double>(begin: 0,    end: _vertShift).animate(_drawerAnim);

  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _openDrawer() {
    HapticFeedback.lightImpact();
    setState(() => _isDrawerOpen = true);
    _animCtrl.forward();
  }

  void _closeDrawer() {
    _animCtrl.reverse().then((_) {
      if (mounted) setState(() => _isDrawerOpen = false);
    });
  }

  void _toggleDrawer() => _isDrawerOpen ? _closeDrawer() : _openDrawer();

  void _onHorizontalDragStart(DragStartDetails d) =>
      _dragStartX = d.globalPosition.dx;

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (widget.leadingWidget != null) return;
    final velocity = d.primaryVelocity ?? 0;
    if (_animCtrl.value > 0.4 || velocity > 300) {
      setState(() => _isDrawerOpen = true);
      _animCtrl.forward();
    } else {
      _closeDrawer();
    }
  }

  Future<void> _navigateTo(_DrawerItem item) async {
    if (widget.currentRoute == item.route && !item.isPush) {
      _closeDrawer();
      return;
    }
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    if (item.isPush) {
      Navigator.pushNamed(context, item.route);
    } else {
      Navigator.pushReplacementNamed(context, item.route);
    }
  }

  String get _resolvedTitle {
    if (widget.title != null) return widget.title!;
    try {
      return _navItems.firstWhere((i) => i.route == widget.currentRoute).label;
    } catch (_) {
      return 'Testers';
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (widget.leadingWidget != null) return;
    final delta = d.globalPosition.dx - _dragStartX;
    if (!_isDrawerOpen && delta > 0 && _dragStartX < 40) {
      _animCtrl.value = (delta / _maxSlide).clamp(0.0, 1.0);
    } else if (_isDrawerOpen && delta < 0) {
      _animCtrl.value = (1.0 + (delta / _maxSlide)).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      body: GestureDetector(
        onHorizontalDragStart:  _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd:    _onHorizontalDragEnd,
        child: Stack(
          children: [
            
            if (widget.leadingWidget == null)
              _DrawerPanel(
                width:        _maxSlide,
                fadeAnim:     _drawerFadeAnim,
                currentRoute: widget.currentRoute,
                navItems:     _navItems,
                onNavigate:   _navigateTo,
              ),

            
            AnimatedBuilder(
              animation: _drawerAnim,
              builder: (context, child) {
                final slide  = _drawerAnim.value * _maxSlide;
                final vPad   = _verticalPadAnim.value;
                final radius = _radiusAnim.value;
                final scaleY = 1.0 - (vPad / screenHeight * 2);

                return Transform(
                  transform: Matrix4.identity()
                    ..translate(slide)
                    ..scale(1.0, scaleY),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        if (_isDrawerOpen)
                          BoxShadow(
                            color:      cs.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset:     const Offset(-10, 0),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: child,
                    ),
                  ),
                );
              },
              child: _MainContent(
                title:                 _resolvedTitle,
                actions:               widget.actions,
                floatingActionButton:  widget.floatingActionButton,
                backgroundColor:       widget.backgroundColor,
                isDrawerOpen:          _isDrawerOpen,
                overlayAnim:           _overlayAnim,
                radiusAnim:            _radiusAnim,
                onMenuTap:             _toggleDrawer,
                onOverlayTap:          _closeDrawer,
                animCtrl:              _animCtrl,
                showCoinBadge:         widget.showCoinBadge,
                showNotificationBadge: widget.showNotificationBadge,
                leadingWidget:         widget.leadingWidget,
                child:                 widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}





class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.title,
    required this.isDrawerOpen,
    required this.overlayAnim,
    required this.radiusAnim,
    required this.animCtrl,
    required this.onMenuTap,
    required this.onOverlayTap,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    this.showCoinBadge          = false,
    this.showNotificationBadge  = false,
    this.leadingWidget,
  });

  final String                title;
  final bool                  isDrawerOpen;
  final Animation<double>     overlayAnim;
  final Animation<double>     radiusAnim;
  final AnimationController   animCtrl;
  final VoidCallback          onMenuTap;
  final VoidCallback          onOverlayTap;
  final Widget                child;
  final List<Widget>?         actions;
  final Widget?               floatingActionButton;
  final Color?                backgroundColor;
  final bool                  showCoinBadge;
  final bool                  showNotificationBadge;
  final Widget?               leadingWidget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: radiusAnim,
      builder: (context, innerChild) => Container(
        decoration: BoxDecoration(color: backgroundColor ?? cs.surface),
        child: innerChild,
      ),
      child: Scaffold(
        backgroundColor:    backgroundColor ?? cs.surface,
        floatingActionButton: floatingActionButton,
        appBar: _MainAppBar(
          title:                 title,
          actions:               actions,
          onMenuTap:             onMenuTap,
          animCtrl:              animCtrl,
          showCoinBadge:         showCoinBadge,
          showNotificationBadge: showNotificationBadge,
          leadingWidget:         leadingWidget,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: baseScreenPadding),
            child: Stack(
              children: [
                child,
                if (isDrawerOpen)
                  AnimatedBuilder(
                    animation: overlayAnim,
                    builder: (_, __) => GestureDetector(
                      onTap: onOverlayTap,
                      child: Container(
                        color: Colors.black.withOpacity(overlayAnim.value),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





class _MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MainAppBar({
    required this.title,
    required this.onMenuTap,
    required this.animCtrl,
    required this.showCoinBadge,
    required this.showNotificationBadge,
    this.actions,
    this.leadingWidget,
  });

  final String              title;
  final VoidCallback        onMenuTap;
  final AnimationController animCtrl;
  final List<Widget>?       actions;
  final bool                showCoinBadge;
  final bool                showNotificationBadge;
  final Widget?             leadingWidget;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Widget leading = leadingWidget != null
        ? Padding(
      padding: const EdgeInsets.only(left: 4),
      child:   leadingWidget!,
    )
        : Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: AnimatedIcon(
          icon:     AnimatedIcons.menu_close,
          progress: animCtrl,
          color:    cs.primary,
        ),
        onPressed: onMenuTap,
        tooltip:   'Toggle menu',
      ),
    );

    return AppBar(
      backgroundColor:         cs.surface,
      surfaceTintColor:        Colors.transparent,
      scrolledUnderElevation:  1,
      elevation:               0,
      titleSpacing:            0,
      automaticallyImplyLeading: false,
      leading: leading,
      title: Text(
        title,
        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      actions: [
        if (actions != null) ...actions!,
        if (showCoinBadge) ...[const SizedBox(width: 4), CoinDisplay()],
        if (showNotificationBadge)
          NotificationBadge(uid: context.read<AuthProvider>().uid),
        const SizedBox(width: 12),
      ],
    );
  }
}






class _DrawerPanel extends StatelessWidget {
  const _DrawerPanel({
    required this.width,
    required this.fadeAnim,
    required this.currentRoute,
    required this.navItems,
    required this.onNavigate,
  });

  final double                   width;
  final Animation<double>        fadeAnim;
  final String                   currentRoute;
  final List<_DrawerItem>        navItems;
  final ValueChanged<_DrawerItem> onNavigate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: fadeAnim,
      builder: (context, child) =>
          Opacity(opacity: fadeAnim.value, child: child),
      child: Container(
        width: width,
        color: cs.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DrawerHeader(),
                SizedBox(height: bottomPadding + 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: navItems
                        .map(
                          (item) => _NavTile(
                        item:       item,
                        isSelected: item.route == currentRoute,
                        onTap:      () => onNavigate(item),
                        showBadge:  item.route == AppRoutes.notification,
                      ),
                    )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tt   = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _UserAvatar(
              photoURL:    auth.photoURL,
              displayName: auth.displayName,
              username:    auth.username,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Builder(
                builder: (_) {
                  final hasDisplayName = auth.displayName.trim().isNotEmpty;
                  final hasUsername    = auth.username.trim().isNotEmpty;
                  if (hasDisplayName && hasUsername) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auth.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@${auth.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    );
                  }
                  if (hasDisplayName) {
                    return Text(
                      auth.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  }
                  return Text(
                    auth.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(
          color:     Theme.of(context).colorScheme.outline,
          thickness: 1.5,
        ),
      ],
    );
  }
}





class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  });
  final _DrawerItem  item;
  final bool         isSelected;
  final VoidCallback onTap;
  final bool         showBadge;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final Color tileColor = widget.item.isDestructive
        ? Colors.red
        : Colors.blue.withOpacity(0.3);
    final Color bgColor = widget.isSelected
        ? tileColor
        : _pressed
        ? tileColor.withOpacity(0.1)
        : Colors.transparent;

    
    
    Widget iconWidget = Icon(
      widget.isSelected ? widget.item.activeIcon : widget.item.icon,
      color: cs.onSurface,
      size:  22,
    );



    return GestureDetector(
      onTap:       widget.onTap,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin:  const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft:    Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Text(
              widget.item.label,
              style: tt.titleMedium?.copyWith(
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.photoURL,
    required this.displayName,
    required this.username,
  });
  final String photoURL;
  final String displayName;
  final String username;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius:          35,
      backgroundColor: cs.surface,
      child: ClipOval(
        child: photoURL.isNotEmpty
            ? Image.network(
          photoURL,
          width:        70,
          height:       70,
          fit:          BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _InitialAvatar(displayName, cs, username),
        )
            : _InitialAvatar(displayName, cs, username),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar(this.name, this.cs, this.username);
  final String      name;
  final String      username;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
    width:     70,
    height:    70,
    color:     cs.surface,
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : username,
      style: TextStyle(
        fontSize:   26,
        fontWeight: FontWeight.bold,
        color:      cs.primary,
      ),
    ),
  );
}