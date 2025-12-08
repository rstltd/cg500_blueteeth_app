import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

// Re-export utilities for convenient single import
export '../utils/responsive_utils.dart';
export '../utils/app_colors.dart';

/// A responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// A responsive container that adjusts its constraints based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BoxConstraints? constraints;
  final Color? color;
  final Decoration? decoration;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.constraints,
    this.color,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      margin: margin ?? ResponsiveUtils.getResponsiveMargin(context),
      constraints: constraints ?? ResponsiveUtils.getResponsiveConstraints(context),
      color: color,
      decoration: decoration,
      child: child,
    );
  }
}

/// A responsive card widget that adapts its width and padding
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveUtils.getCardMaxWidth(context);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context);
    final responsiveMargin = ResponsiveUtils.getResponsiveMargin(context);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: margin ?? responsiveMargin,
      child: Card(
        elevation: elevation ?? 2.0,
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: color,
        child: Padding(
          padding: padding ?? responsivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// A responsive grid view that adapts column count based on screen size
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveUtils.getGridColumns(context);
    final responsivePadding = ResponsiveUtils.getResponsivePadding(context);

    return GridView.builder(
      padding: padding ?? responsivePadding,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive text widget that adjusts font size based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextStyle? style;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = ResponsiveUtils.getResponsiveFontSize(context, fontSize);
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

/// A responsive icon widget that adjusts size based on screen size
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = ResponsiveUtils.getResponsiveIconSize(context, size);
    
    return Icon(
      icon,
      size: responsiveSize,
      color: color,
    );
  }
}

/// A responsive column that adjusts its children layout based on screen size
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    final canShowSideBySide = ResponsiveUtils.canShowSideBySideLayout(context);
    
    // For large landscape screens, consider showing children in rows
    if (canShowSideBySide && children.length <= 3) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children.map((child) => Expanded(child: child)).toList(),
      );
    }
    
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}

/// A responsive safe area widget that handles notches and safe areas
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

// === Phase 5: Enhanced Responsive Components ===

/// A content wrapper that limits max width for better readability on large screens.
///
/// Centers content and constrains it to a maximum width on desktop/tablet screens
/// while allowing full width on mobile devices.
///
/// Example:
/// ```dart
/// MaxWidthContent(
///   maxWidth: 1200,
///   child: MyContent(),
/// )
/// ```
class MaxWidthContent extends StatelessWidget {
  /// The child content to constrain
  final Widget child;

  /// Maximum width on large screens (default: 1200)
  final double maxWidth;

  /// Padding on the sides when constrained
  final double sidePadding;

  /// Whether to center the content
  final bool center;

  /// Background color outside the content area
  final Color? backgroundColor;

  const MaxWidthContent({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.sidePadding = 16,
    this.center = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen is narrower than maxWidth, use full width
        if (constraints.maxWidth <= maxWidth) {
          return child;
        }

        // Otherwise, constrain to maxWidth with optional centering
        return ColoredBox(
          color: backgroundColor ?? Colors.transparent,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A two-panel layout for tablet landscape mode.
///
/// Shows two panels side by side when in landscape on larger screens,
/// and stacks them vertically on mobile or portrait.
///
/// Example:
/// ```dart
/// SideBySideLayout(
///   primaryPanel: DeviceList(),
///   secondaryPanel: DeviceDetails(),
///   primaryRatio: 0.4,
/// )
/// ```
class SideBySideLayout extends StatelessWidget {
  /// The main/primary panel (typically a list)
  final Widget primaryPanel;

  /// The secondary panel (typically details)
  final Widget secondaryPanel;

  /// Ratio of width for primary panel (0.0 to 1.0)
  final double primaryRatio;

  /// Divider width between panels
  final double dividerWidth;

  /// Whether to show divider
  final bool showDivider;

  /// Minimum width for primary panel
  final double minPrimaryWidth;

  /// Minimum width for secondary panel
  final double minSecondaryWidth;

  /// Whether to force side by side (ignore screen size)
  final bool forceSideBySide;

  const SideBySideLayout({
    super.key,
    required this.primaryPanel,
    required this.secondaryPanel,
    this.primaryRatio = 0.35,
    this.dividerWidth = 1,
    this.showDivider = true,
    this.minPrimaryWidth = 280,
    this.minSecondaryWidth = 320,
    this.forceSideBySide = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowSideBySide = forceSideBySide ||
            ResponsiveUtils.canShowSideBySideLayout(context);
        final hasEnoughWidth =
            constraints.maxWidth >= (minPrimaryWidth + minSecondaryWidth);

        if (canShowSideBySide && hasEnoughWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: (constraints.maxWidth * primaryRatio)
                    .clamp(minPrimaryWidth, constraints.maxWidth - minSecondaryWidth),
                child: primaryPanel,
              ),
              if (showDivider)
                VerticalDivider(
                  width: dividerWidth,
                  thickness: dividerWidth,
                  color: Theme.of(context).dividerColor,
                ),
              Expanded(
                child: secondaryPanel,
              ),
            ],
          );
        }

        // Stack vertically on smaller screens
        return primaryPanel;
      },
    );
  }
}

/// A responsive scaffold that adapts its layout for different screen sizes.
///
/// Features:
/// - Navigation rail for desktop/tablet landscape
/// - Bottom navigation for mobile
/// - Drawer for additional navigation
///
/// Example:
/// ```dart
/// ResponsiveScaffold(
///   currentIndex: selectedIndex,
///   destinations: [
///     ResponsiveDestination(icon: Icons.home, label: 'Home'),
///     ResponsiveDestination(icon: Icons.settings, label: 'Settings'),
///   ],
///   body: currentPage,
///   onDestinationSelected: (index) => setState(() => selectedIndex = index),
/// )
/// ```
class ResponsiveScaffold extends StatelessWidget {
  /// Current selected destination index
  final int currentIndex;

  /// Navigation destinations
  final List<ResponsiveDestination> destinations;

  /// Main body content
  final Widget body;

  /// Callback when destination is selected
  final ValueChanged<int> onDestinationSelected;

  /// App bar (optional)
  final PreferredSizeWidget? appBar;

  /// Floating action button (optional)
  final Widget? floatingActionButton;

  /// FAB location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Drawer widget (optional)
  final Widget? drawer;

  /// End drawer widget (optional)
  final Widget? endDrawer;

  /// Whether to show the navigation rail on desktop
  final bool showNavigationRail;

  /// Navigation rail extended state
  final bool extendedNavigationRail;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.body,
    required this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.showNavigationRail = true,
    this.extendedNavigationRail = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final useNavigationRail =
        showNavigationRail && (deviceType != DeviceType.mobile || isLandscape);

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      body: Row(
        children: [
          if (useNavigationRail)
            NavigationRail(
              selectedIndex: currentIndex,
              extended: extendedNavigationRail,
              onDestinationSelected: onDestinationSelected,
              labelType: extendedNavigationRail
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon ?? d.icon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: useNavigationRail
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon ?? d.icon),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// A destination for ResponsiveScaffold navigation.
class ResponsiveDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const ResponsiveDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });
}

/// A widget that displays content in different layouts based on screen size.
///
/// Useful for showing list/detail views where:
/// - Mobile: Single view (list or detail)
/// - Tablet/Desktop: Master-detail split view
///
/// Example:
/// ```dart
/// MasterDetailLayout(
///   masterBuilder: (context) => DeviceList(),
///   detailBuilder: (context, selectedItem) => DeviceDetails(item: selectedItem),
///   isDetailSelected: selectedDevice != null,
/// )
/// ```
class MasterDetailLayout extends StatelessWidget {
  /// Builder for the master (list) view
  final WidgetBuilder masterBuilder;

  /// Builder for the detail view, receives selected state
  final Widget Function(BuildContext context, bool hasSelection) detailBuilder;

  /// Whether a detail item is currently selected
  final bool isDetailSelected;

  /// Placeholder widget when no detail is selected (split view only)
  final Widget? emptyDetailPlaceholder;

  /// Ratio of master panel width (0.0 to 1.0)
  final double masterRatio;

  /// Breakpoint for switching to split view
  final double splitBreakpoint;

  const MasterDetailLayout({
    super.key,
    required this.masterBuilder,
    required this.detailBuilder,
    this.isDetailSelected = false,
    this.emptyDetailPlaceholder,
    this.masterRatio = 0.4,
    this.splitBreakpoint = 720,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplitView = constraints.maxWidth >= splitBreakpoint;

        if (useSplitView) {
          // Split view mode
          return Row(
            children: [
              SizedBox(
                width: constraints.maxWidth * masterRatio,
                child: masterBuilder(context),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: isDetailSelected
                    ? detailBuilder(context, true)
                    : (emptyDetailPlaceholder ??
                        Center(
                          child: Text(
                            'Select an item to view details',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )),
              ),
            ],
          );
        }

        // Single view mode
        return isDetailSelected
            ? detailBuilder(context, true)
            : masterBuilder(context);
      },
    );
  }
}

/// An adaptive padding widget that adjusts based on screen size.
///
/// Example:
/// ```dart
/// AdaptivePadding(
///   mobile: EdgeInsets.all(8),
///   tablet: EdgeInsets.all(16),
///   desktop: EdgeInsets.all(24),
///   child: MyContent(),
/// )
/// ```
class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const AdaptivePadding({
    super.key,
    required this.child,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final EdgeInsets padding;

    switch (deviceType) {
      case DeviceType.mobile:
        padding = mobile;
        break;
      case DeviceType.tablet:
        padding = tablet ?? mobile;
        break;
      case DeviceType.desktop:
        padding = desktop ?? tablet ?? mobile;
        break;
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// A breakpoint-aware builder widget.
///
/// Rebuilds when screen size crosses a breakpoint.
///
/// Example:
/// ```dart
/// BreakpointBuilder(
///   builder: (context, deviceType, isLandscape) {
///     return Text('Device: $deviceType, Landscape: $isLandscape');
///   },
/// )
/// ```
class BreakpointBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    DeviceType deviceType,
    bool isLandscape,
  ) builder;

  const BreakpointBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return builder(context, deviceType, isLandscape);
  }
}