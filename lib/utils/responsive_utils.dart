import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design/design_tokens.dart';

/// Device type classification based on screen size
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Screen orientation
enum ScreenOrientation {
  portrait,
  landscape,
}

/// Responsive layout utility class
class ResponsiveUtils {
  /// Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Padding and margin constants - now derived from DesignTokens
  static double get mobilePadding => DesignTokens.spacingM;
  static double get tabletPadding => DesignTokens.spacingL;
  static double get desktopPadding => DesignTokens.spacingXL;

  /// Card width constraints
  static const double mobileCardMaxWidth = double.infinity;
  static const double tabletCardMaxWidth = 400.0;
  static const double desktopCardMaxWidth = 480.0;

  /// Tablet-specific breakpoints for better layout optimization
  static const double tabletSmallBreakpoint = 600;
  static const double tabletLargeBreakpoint = 840;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Get screen orientation
  static ScreenOrientation getOrientation(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait 
        ? ScreenOrientation.portrait 
        : ScreenOrientation.landscape;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == ScreenOrientation.landscape;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == ScreenOrientation.portrait;
  }

  /// Get responsive padding based on device type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    double padding;
    
    switch (deviceType) {
      case DeviceType.mobile:
        padding = mobilePadding;
        break;
      case DeviceType.tablet:
        padding = tabletPadding;
        break;
      case DeviceType.desktop:
        padding = desktopPadding;
        break;
    }
    
    return EdgeInsets.all(padding);
  }

  /// Get responsive margin based on device type
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final deviceType = getDeviceType(context);
    double margin;
    
    switch (deviceType) {
      case DeviceType.mobile:
        margin = mobilePadding * 0.75;
        break;
      case DeviceType.tablet:
        margin = tabletPadding * 0.75;
        break;
      case DeviceType.desktop:
        margin = desktopPadding * 0.75;
        break;
    }
    
    return EdgeInsets.all(margin);
  }

  /// Get card maximum width based on device type
  static double getCardMaxWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobileCardMaxWidth;
      case DeviceType.tablet:
        return tabletCardMaxWidth;
      case DeviceType.desktop:
        return desktopCardMaxWidth;
    }
  }

  /// Get number of columns for grid layout
  static int getGridColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscapeMode = isLandscape(context);
    
    if (screenWidth < mobileBreakpoint) {
      return isLandscapeMode ? 2 : 1;
    } else if (screenWidth < tabletBreakpoint) {
      return isLandscapeMode ? 3 : 2;
    } else {
      return isLandscapeMode ? 4 : 3;
    }
  }

  /// Get responsive font size for the current device type.
  ///
  /// Only the device-size multiplier is applied here. The user's text-scale
  /// preference is deliberately NOT applied: the returned value is assigned to
  /// [TextStyle.fontSize], and Flutter's `Text`/`RichText` already scale that
  /// by `MediaQuery.textScalerOf(context)` at paint time. Multiplying it in
  /// here would apply the user scale twice (base x device x scale^2) and would
  /// also defeat `MediaQuery.withNoTextScaling` / `TextScaler.noScaling`.
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final deviceType = getDeviceType(context);

    double multiplier;
    switch (deviceType) {
      case DeviceType.mobile:
        multiplier = 1.0;
        break;
      case DeviceType.tablet:
        multiplier = 1.1;
        break;
      case DeviceType.desktop:
        multiplier = 1.2;
        break;
    }
    
    return baseFontSize * multiplier;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return baseIconSize;
      case DeviceType.tablet:
        return baseIconSize * 1.2;
      case DeviceType.desktop:
        return baseIconSize * 1.4;
    }
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  /// Calculate responsive height based on screen percentage
  static double getResponsiveHeight(BuildContext context, double percentage) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (percentage / 100);
  }

  /// Calculate responsive width based on screen percentage
  static double getResponsiveWidth(BuildContext context, double percentage) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (percentage / 100);
  }

  /// Get app bar height based on device type
  static double getAppBarHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return kToolbarHeight;
      case DeviceType.tablet:
        return kToolbarHeight + 8;
      case DeviceType.desktop:
        return kToolbarHeight + 16;
    }
  }

  /// Get minimum button size for touch targets
  static double getMinButtonSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 44.0; // iOS Human Interface Guidelines
      case DeviceType.tablet:
        return 48.0; // Material Design Guidelines
      case DeviceType.desktop:
        return 40.0; // Desktop can be smaller due to precise cursor
    }
  }

  /// Get layout constraints for responsive design
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return BoxConstraints(
          maxWidth: screenWidth,
          minWidth: 0,
        );
      case DeviceType.tablet:
        return BoxConstraints(
          maxWidth: math.min(screenWidth * 0.9, 800),
          minWidth: 400,
        );
      case DeviceType.desktop:
        return BoxConstraints(
          maxWidth: math.min(screenWidth * 0.8, 1200),
          minWidth: 600,
        );
    }
  }

  /// Check if the screen size allows for side-by-side layout
  static bool canShowSideBySideLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= tabletBreakpoint && isLandscape(context);
  }

  /// Get crossAxisCount for StaggeredGridView
  static int getStaggeredGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      return 1;
    } else if (screenWidth < 900) {
      return 2;
    } else if (screenWidth < 1200) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get responsive icon size based on device type and base size
  static double getIconSize(BuildContext context, {required double base}) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return base;
      case DeviceType.tablet:
        return base * 1.15;
      case DeviceType.desktop:
        return base * 1.3;
    }
  }

  // --- Tablet-specific optimization methods ---

  /// Check if tablet is in small configuration (600-840px)
  static bool isTabletSmall(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= tabletSmallBreakpoint &&
        screenWidth < tabletLargeBreakpoint;
  }

  /// Check if tablet is in large configuration (840-1024px)
  static bool isTabletLarge(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= tabletLargeBreakpoint &&
        screenWidth < tabletBreakpoint;
  }

  /// Get sidebar width optimized for tablet layouts
  static double getTabletSidebarWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscapeMode = isLandscape(context);

    if (screenWidth >= tabletLargeBreakpoint) {
      return isLandscapeMode ? 360.0 : 320.0;
    } else {
      return isLandscapeMode ? 280.0 : 260.0;
    }
  }

  /// Get optimal content width for tablets
  static double getTabletContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscapeMode = isLandscape(context);

    if (isLandscapeMode) {
      // Leave room for sidebar
      return screenWidth - getTabletSidebarWidth(context) - desktopPadding;
    } else {
      // Full width with padding
      return screenWidth - (tabletPadding * 2);
    }
  }

  /// Get number of columns optimized for tablet grid layouts
  static int getTabletGridColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscapeMode = isLandscape(context);

    if (screenWidth >= tabletLargeBreakpoint) {
      return isLandscapeMode ? 3 : 2;
    } else {
      return isLandscapeMode ? 2 : 1;
    }
  }

  /// Get the optimal list item height for tablet
  static double getTabletListItemHeight(BuildContext context) {
    final isLandscapeMode = isLandscape(context);
    return isLandscapeMode ? 72.0 : 80.0;
  }

  /// Get gap between items in tablet layouts
  static double getTabletItemGap(BuildContext context) {
    return isTabletLarge(context) ? DesignTokens.spacingM : DesignTokens.spacingS;
  }

  /// Check if tablet should use split-view layout
  static bool shouldUseSplitView(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscapeMode = isLandscape(context);

    // Use split view in landscape on larger tablets
    return isLandscapeMode && screenWidth >= tabletLargeBreakpoint;
  }

  /// Get optimal aspect ratio for cards on tablet
  static double getTabletCardAspectRatio(BuildContext context) {
    final isLandscapeMode = isLandscape(context);
    return isLandscapeMode ? 1.6 : 1.2;
  }
}