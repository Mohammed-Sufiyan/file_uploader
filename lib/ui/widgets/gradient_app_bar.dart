import 'package:flutter/material.dart';

/// Custom gradient AppBar widget for modern UI
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final Color? textColor;
  final double? titleSpacing;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.gradientColors = const [
      Color(0xFF667eea), // Blue
      Color(0xFF764ba2), // Purple
    ],
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.actions,
    this.leading,
    this.elevation = 4.0,
    this.textColor = Colors.white,
    this.titleSpacing,
  }) : super(key: key);

  /// Predefined gradient color schemes
  static const List<Color> blueGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static const List<Color> orangeGradient = [
    Color(0xFFf093fb),
    Color(0xFFf5576c),
  ];

  static const List<Color> greenGradient = [
    Color(0xFF4facfe),
    Color(0xFF00f2fe),
  ];

  static const List<Color> purpleGradient = [
    Color(0xFFa18cd1),
    Color(0xFFfbc2eb),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFffecd2),
    Color(0xFFfcb69f),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: gradientBegin,
          end: gradientEnd,
          colors: gradientColors,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: leading,
        actions: actions,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: titleSpacing,
        iconTheme: IconThemeData(color: textColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Animated gradient AppBar with wave effect
class AnimatedGradientAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Color> gradientColors;
  final List<Widget>? actions;
  final Widget? leading;
  final double elevation;
  final Color? textColor;

  const AnimatedGradientAppBar({
    Key? key,
    required this.title,
    this.gradientColors = const [
      Color(0xFF667eea),
      Color(0xFF764ba2),
    ],
    this.actions,
    this.leading,
    this.elevation = 4.0,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  State<AnimatedGradientAppBar> createState() => _AnimatedGradientAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AnimatedGradientAppBarState extends State<AnimatedGradientAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
              stops: [
                _animation.value * 0.5,
                0.5 + _animation.value * 0.5,
              ],
            ),
            boxShadow: widget.elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: widget.elevation,
                      offset: Offset(0, widget.elevation / 2),
                    ),
                  ]
                : null,
          ),
          child: AppBar(
            title: Text(
              widget.title,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            leading: widget.leading,
            actions: widget.actions,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: widget.textColor),
          ),
        );
      },
    );
  }
}

/// Simple gradient AppBar factory
class AppBarFactory {
  /// Create a gradient AppBar with preset styles
  static PreferredSizeWidget create({
    required String title,
    String style = 'blue',
    List<Widget>? actions,
    Widget? leading,
    bool animated = false,
  }) {
    List<Color> colors;

    switch (style.toLowerCase()) {
      case 'orange':
        colors = GradientAppBar.orangeGradient;
        break;
      case 'green':
        colors = GradientAppBar.greenGradient;
        break;
      case 'purple':
        colors = GradientAppBar.purpleGradient;
        break;
      case 'sunset':
        colors = GradientAppBar.sunsetGradient;
        break;
      case 'blue':
      default:
        colors = GradientAppBar.blueGradient;
        break;
    }

    if (animated) {
      return AnimatedGradientAppBar(
        title: title,
        gradientColors: colors,
        actions: actions,
        leading: leading,
      );
    } else {
      return GradientAppBar(
        title: title,
        gradientColors: colors,
        actions: actions,
        leading: leading,
      );
    }
  }
}
