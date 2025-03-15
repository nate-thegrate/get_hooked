import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Material Design app bar.
///
/// Functions just like a normal [AppBar] but with a `const` constructor.
class AppBarConst extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a Material Design app bar.
  ///
  /// If [elevation] is specified, it must be non-negative.
  ///
  /// Typically used in the [Scaffold.appBar] property.
  const AppBarConst({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.shadowColor,
    this.surfaceTintColor,
    this.shape,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.toolbarOpacity = 1.0,
    this.bottomOpacity = 1.0,
    this.toolbarHeight,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.actionsPadding,
  }) : assert(elevation == null || elevation >= 0.0);

  /// {@macro flutter.material.appbar.leading}
  ///
  /// {@tool snippet}
  ///
  /// The following code shows how the drawer button could be manually specified
  /// instead of relying on [automaticallyImplyLeading]:
  ///
  /// ```dart
  /// AppBar(
  ///   leading: Builder(
  ///     builder: (BuildContext context) {
  ///       return IconButton(
  ///         icon: const Icon(Icons.menu),
  ///         onPressed: () { Scaffold.of(context).openDrawer(); },
  ///         tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
  ///       );
  ///     },
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// The [Builder] is used in this example to ensure that the `context` refers
  /// to that part of the subtree. That way this code snippet can be used even
  /// inside the very code that is creating the [Scaffold] (in which case,
  /// without the [Builder], the `context` wouldn't be able to see the
  /// [Scaffold], since it would refer to an ancestor of that widget).
  ///
  /// See also:
  ///
  ///  * [Scaffold.appBar], in which an [AppBar] is usually placed.
  ///  * [Scaffold.drawer], in which the [Drawer] is usually placed.
  final Widget? leading;

  /// {@macro flutter.material.appbar.automaticallyImplyLeading}
  final bool automaticallyImplyLeading;

  /// {@macro flutter.material.appbar.title}
  ///
  /// The [title]'s width is constrained to fit within the remaining space
  /// between the toolbar's [leading] and [actions] widgets. Its height is
  /// _not_ constrained. The [title] is vertically centered and clipped to fit
  /// within the toolbar, whose height is [toolbarHeight]. Typically this
  /// isn't noticeable because a simple [Text] [title] will fit within the
  /// toolbar by default. On the other hand, it is noticeable when a
  /// widget with an intrinsic height that is greater than [toolbarHeight]
  /// is used as the [title]. For example, when the height of an Image used
  /// as the [title] exceeds [toolbarHeight], it will be centered and
  /// clipped (top and bottom), which may be undesirable. In cases like this
  /// the height of the [title] widget can be constrained. For example:
  ///
  /// ```dart
  /// const MaterialApp(
  ///   home: Scaffold(
  ///     appBar: AppBarConst(
  ///       title: SizedBox(
  ///         height: _myToolbarHeight,
  ///         child: Image.asset(_logoAsset),
  ///       ),
  ///       toolbarHeight: _myToolbarHeight,
  ///     ),
  ///   ),
  /// )
  /// ```
  final Widget? title;

  /// {@macro flutter.material.appbar.actions}
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// Scaffold(
  ///   body: CustomScrollView(
  ///     primary: true,
  ///     slivers: <Widget>[
  ///       SliverAppBar(
  ///         title: const Text('Hello World'),
  ///         actions: <Widget>[
  ///           IconButton(
  ///             icon: const Icon(Icons.shopping_cart),
  ///             tooltip: 'Open shopping cart',
  ///             onPressed: () {
  ///               // handle the press
  ///             },
  ///           ),
  ///         ],
  ///       ),
  ///       // ...rest of body...
  ///     ],
  ///   ),
  /// )
  /// ```
  /// {@end-tool}
  final List<Widget>? actions;

  /// {@macro flutter.material.appbar.flexibleSpace}
  final Widget? flexibleSpace;

  /// {@macro flutter.material.appbar.bottom}
  ///
  /// See also:
  ///
  ///  * [PreferredSize], which can be used to give an arbitrary widget a preferred size.
  final PreferredSizeWidget? bottom;

  /// {@macro flutter.material.appbar.elevation}
  ///
  /// See also:
  ///
  ///  * [scrolledUnderElevation], which will be used when the app bar has
  ///    something scrolled underneath it.
  ///  * [shadowColor], which is the color of the shadow below the app bar.
  ///  * [surfaceTintColor], which determines the elevation overlay that will
  ///    be applied to the background of the app bar.
  ///  * [shape], which defines the shape of the app bar's [Material] and its
  ///    shadow.
  final double? elevation;

  /// {@macro flutter.material.appbar.scrolledUnderElevation}
  ///
  /// See also:
  ///  * [elevation], which will be used if there is no content scrolled under
  ///    the app bar.
  ///  * [shadowColor], which is the color of the shadow below the app bar.
  ///  * [surfaceTintColor], which determines the elevation overlay that will
  ///    be applied to the background of the app bar.
  ///  * [shape], which defines the shape of the app bar's [Material] and its
  ///    shadow.
  final double? scrolledUnderElevation;

  /// A check that specifies which child's [ScrollNotification]s should be
  /// listened to.
  ///
  /// By default, checks whether `notification.depth == 0`. Set it to something
  /// else for more complicated layouts.
  final ScrollNotificationPredicate notificationPredicate;

  /// {@macro flutter.material.appbar.shadowColor}
  ///
  /// See also:
  ///
  ///  * [elevation], which defines the size of the shadow below the app bar.
  ///  * [shape], which defines the shape of the app bar and its shadow.
  final Color? shadowColor;

  /// {@macro flutter.material.appbar.surfaceTintColor}
  ///
  /// See also:
  ///   * [Material.surfaceTintColor], which described this feature in more detail.
  final Color? surfaceTintColor;

  /// {@macro flutter.material.appbar.shape}
  ///
  /// {@tool dartpad}
  /// This sample demonstrates how to implement a custom app bar shape for the
  /// [shape] property.
  ///
  /// ** See code in examples/api/lib/material/app_bar/app_bar.4.dart **
  /// {@end-tool}
  /// See also:
  ///
  ///  * [elevation], which defines the size of the shadow below the app bar.
  ///  * [shadowColor], which is the color of the shadow below the app bar.
  final ShapeBorder? shape;

  /// {@macro flutter.material.appbar.backgroundColor}
  ///
  /// See also:
  ///
  ///  * [foregroundColor], which specifies the color for icons and text within
  ///    the app bar.
  ///  * [Theme.of], which returns the current overall Material theme as
  ///    a [ThemeData].
  ///  * [ThemeData.colorScheme], the thirteen colors that most Material widget
  ///    default colors are based on.
  ///  * [ColorScheme.brightness], which indicates if the overall [Theme]
  ///    is light or dark.
  final Color? backgroundColor;

  /// {@macro flutter.material.appbar.foregroundColor}
  ///
  /// See also:
  ///
  ///  * [backgroundColor], which specifies the app bar's background color.
  ///  * [Theme.of], which returns the current overall Material theme as
  ///    a [ThemeData].
  ///  * [ThemeData.colorScheme], the thirteen colors that most Material widget
  ///    default colors are based on.
  ///  * [ColorScheme.brightness], which indicates if the overall [Theme]
  ///    is light or dark.
  final Color? foregroundColor;

  /// {@macro flutter.material.appbar.iconTheme}
  ///
  /// See also:
  ///
  ///  * [actionsIconTheme], which defines the appearance of icons in
  ///    the [actions] list.
  final IconThemeData? iconTheme;

  /// {@macro flutter.material.appbar.actionsIconTheme}
  ///
  /// See also:
  ///
  ///  * [iconTheme], which defines the appearance of all of the toolbar icons.
  final IconThemeData? actionsIconTheme;

  /// {@macro flutter.material.appbar.primary}
  final bool primary;

  /// {@macro flutter.material.appbar.centerTitle}
  final bool? centerTitle;

  /// {@macro flutter.material.appbar.excludeHeaderSemantics}
  final bool excludeHeaderSemantics;

  /// {@macro flutter.material.appbar.titleSpacing}
  final double? titleSpacing;

  /// {@macro flutter.material.appbar.toolbarOpacity}
  final double toolbarOpacity;

  /// {@macro flutter.material.appbar.bottomOpacity}
  final double bottomOpacity;

  /// {@macro flutter.material.appbar.toolbarHeight}
  final double? toolbarHeight;

  /// {@macro flutter.material.appbar.leadingWidth}
  final double? leadingWidth;

  /// {@macro flutter.material.appbar.toolbarTextStyle}
  ///
  /// See also:
  ///
  ///  * [titleTextStyle], which overrides the default text style for the [title].
  ///  * [DefaultTextStyle], which overrides the default text style for all of the
  ///    widgets in a subtree.
  final TextStyle? toolbarTextStyle;

  /// {@macro flutter.material.appbar.titleTextStyle}
  ///
  /// See also:
  ///
  ///  * [toolbarTextStyle], which is the default text style for the AppBar's
  ///    [title], [leading], and [actions] widgets, also known as the
  ///    AppBar's "toolbar".
  ///  * [DefaultTextStyle], which overrides the default text style for all of the
  ///    widgets in a subtree.
  final TextStyle? titleTextStyle;

  /// {@macro flutter.material.appbar.systemOverlayStyle}
  //
  /// See also:
  ///
  ///  * [AnnotatedRegion], for placing [SystemUiOverlayStyle] in the layer tree.
  ///  * [SystemChrome.setSystemUIOverlayStyle], the imperative API for setting
  ///    system overlays style.
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// {@macro flutter.material.appbar.forceMaterialTransparency}
  final bool forceMaterialTransparency;

  /// {@macro flutter.material.Material.clipBehavior}
  final Clip? clipBehavior;

  /// {@macro flutter.material.appbar.actionsPadding}
  final EdgeInsetsGeometry? actionsPadding;

  AppBar get _appBar => AppBar(
    key: key,
    actions: actions,
    actionsIconTheme: actionsIconTheme,
    actionsPadding: actionsPadding,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: backgroundColor,
    bottom: bottom,
    bottomOpacity: bottomOpacity,
    centerTitle: centerTitle,
    clipBehavior: clipBehavior,
    elevation: elevation,
    excludeHeaderSemantics: excludeHeaderSemantics,
    flexibleSpace: flexibleSpace,
    forceMaterialTransparency: forceMaterialTransparency,
    foregroundColor: foregroundColor,
    iconTheme: iconTheme,
    leading: leading,
    leadingWidth: leadingWidth,
    notificationPredicate: notificationPredicate,
    primary: primary,
    scrolledUnderElevation: scrolledUnderElevation,
    shadowColor: shadowColor,
    shape: shape,
    surfaceTintColor: surfaceTintColor,
    systemOverlayStyle: systemOverlayStyle,
    title: title,
    titleSpacing: titleSpacing,
    titleTextStyle: titleTextStyle,
    toolbarHeight: toolbarHeight,
    toolbarOpacity: toolbarOpacity,
    toolbarTextStyle: toolbarTextStyle,
  );

  /// {@macro flutter.material.appbar.preferredSize}
  @override
  Size get preferredSize => _appBar.preferredSize;

  @override
  Widget build(BuildContext context) => _appBar;
}
