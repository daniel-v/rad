import 'dart:html';

import 'package:meta/meta.dart';
import 'package:rad/src/core/classes/debug.dart';
import 'package:rad/src/core/classes/framework.dart';
import 'package:rad/src/core/classes/router.dart';
import 'package:rad/src/core/constants.dart';
import 'package:rad/src/core/enums.dart';
import 'package:rad/src/core/objects/render_object.dart';
import 'package:rad/src/core/objects/build_context.dart';
import 'package:rad/src/core/objects/widget_object.dart';
import 'package:rad/src/core/types.dart';
import 'package:rad/src/widgets/abstract/widget.dart';
import 'package:rad/src/widgets/route.dart';

/// Navigator widget.
///
/// Navigators basic usage is to allow navigating between pages. But Rad's Navigator
/// is bit different. It also carries out three big tasks for you,
///
/// - Routing
/// - Deep linking
/// - Single page experience (no page reloads when user hit forward/back buttons)
///
/// ![Deep linking and Single page experience in action](https://github.com/erlage/rad/raw/main/example/routing/routing.gif)
///
/// And all three tasks are carried out without any special configuration or management from
/// developer side. That is, Framework will automatically deep link your Navigators, and
/// route requests to the correct ones when requested no matter how deeply nested your
/// Navigators are.
///
/// Let's talk about Navigator's syntax:
///
/// ```dart
/// Navigator(
///
///     // required
///
///     routes: [
///         ...
///     ],
///
///
///     // both are optional
///
///     onInit: (NavigatorState state) {
///
///     }
///
///     onRouteChange: (String name) {
///
///     }
/// )
/// ```
///
/// ### routes:[]
///
/// This property takes list of Routes. What is a Route? in simplified view, a Route consists of two things,
///
/// 1. Name of the route e.g 'home', 'settings'
///
/// 2. Contents to show on route e.g some widget
///
/// To declare a route, there's actually a `Route` widget which simply wraps both parts of route into a single
/// widget that Navigator can manage.
///
/// ```dart
/// routes: [
///
///     Route(name: "home", page: HomePage()),
///
///     Route(name: "edit", page: SomeOtherWidget())
///
///     ...
/// ]
/// ```
/// Above, we've defined two routes, home and edit.
///
/// ### Navigator basic Understanding
///
/// Since Navigator's route is basically a widget that have a name attached to it, those routes will be treated as child
/// widgets of Navigator just like Span can have its childs. Difference being, Navigator's childs(Route widgets) are built
/// in a lazy fashion(only when requested). This also means that Navigator do not stack duplicate pages. All Route widgets
/// are built only once. That is when you open a route, if route widget doesn't exists, it'll create it else it'll use the
/// Route widget that's already built.
///
/// ### NavigatorState
///
/// Navigator widget creates a state object. State object provides methods which you can use to jump between routes, open
/// routes and things like that. To access a Navigator's state object, there are two methods:
///
/// 1. If widget from where you accessing NavigatorState is in child tree of Navigator then use `Navigator.of(context)`. This method will return NavigatorState of the nearest ancestor Navigator from the given `BuildContext`.
///
/// 2. For accessing state in parent widget of Navigator, use `onInit` hook of Navigator:
///     ```dart
///     class SomeWidget extends StatelessWidget
///     {
///         @override
///         build(context)
///         {
///             return Navigator(
///                 onInit: _onInit,
///                 ...
///             )
///         }
///
///         _onInit(NavigatorState state)
///         {
///             // do something with state
///         }
///     }
///     ```
///
/// ### Jumping to a Route
///
/// To go to a route, use `open` method of Navigator state. We could've named it `push` but `open` conveys what exactly
/// Navigator do when you jump to a route. When you call `open`, Navigator will build route widget if it's not already
/// created. Once ready, it'll bring it to the top simply by hiding all other Route widgets that this Navigator is
/// managing.
///
/// ```dart
/// Navigator.of(context).open(name: "home");
/// ```
///
/// ### Going back
///
/// Going back means, going to the Route that's previously visited.
///
/// ```dart
///
/// Navigator.of(context).open(name: "home")
/// Navigator.of(context).open(name: "profile")
/// Navigator.of(context).open(name: "home")
///
/// Navigator.of(context).back() // ->  go to profile
/// Navigator.of(context).back() // ->  go to home
/// Navigator.of(context).back() // ->  error, no previous route!
///
/// // helper method to prevent above case:
///
/// Navigator.of(context).canGoBack() // ->  false, since no previous route
///
/// ### Passing values between routes
///
/// Values can be passed to a route while opening that route:
///
/// ```dart
/// Navigator.of(context).open(name: "home", values: "/somevalue"); // leading slash is important
///
/// ```
///
/// Then on homepage, value can be accessed using `getValue`:
///
/// ```dart
/// var value = Navigator.of(context).getValue("home");
/// // "somevalue"
/// ```
///
/// Passing multiple values:
///
/// ```dart
/// Navigator.of(context).open(name: "home", values: "/somevalue/profile/123");
/// ```
///
/// On homepage,
///
/// ```dart
/// var valueOne = Navigator.of(context).getValue("home"); // -> "somevalue"
/// var valueTwo = Navigator.of(context).getValue("profile"); // -> "123"
/// ```
///
/// Cool thing about Navigator is that values passed to a route will presist
/// during browser reloads. If you've pushed some values while opening a route,
/// those will presist in browser history too. This means you don't have to parameterize
/// your page content, instead pass values on `open`:
///
/// ```dart
/// // rather than doing this
/// Route(name: "profile", page: Profile(key: 123));
///
/// // do this
/// Route(name: "profile", page: Profile());
///
/// // and when opening profile route
/// Navigator.of(context).open(name: "profile", value: "/123");
///
/// // on profile page
/// var key = Navigator.of(context).getValue("profile");
/// ```
///
/// ### onRouteChange hook:
///
/// This hooks gets called when Navigator opens a route. This allows Navigator's parent
/// to do something when Navigator that it's enclosing has changed. for example, you
/// could've a header and you can change active tab when Navigator's route has changed.
///
/// ```dart
/// Navigator(
///     onRouteChange: (name) => print("changed to $name");
///     ...
/// );
/// ```
///
class Navigator extends Widget {
  /// Routes that this Navigator instance handles.
  ///
  final List<Route> routes;

  /// Called when Navigator state is created.
  ///
  final NavigatorStateCallback? onInit;

  /// Called when Navigator's route changes.
  ///
  final NavigatorRouteChangeCallback? onRouteChange;

  const Navigator({
    required this.routes,
    this.onInit,
    this.onRouteChange,
    String? key,
  }) : super(key);

  /// Navigator's state from the closest instance of this class
  /// that encloses the given context.
  ///
  static NavigatorState of(BuildContext context) {
    var widgetObject =
        Framework.findAncestorWidgetObjectOfType<Navigator>(context);

    if (null == widgetObject) {
      throw "Navigator operation requested with a context that does not include a Navigator.\n"
          "The context used to push or pop routes from the Navigator must be that of a "
          "widget that is a descendant of a Navigator widget.";
    }

    var renderObject = widgetObject.renderObject as NavigatorRenderObject;

    renderObject.addDependent(context);

    return renderObject.state;
  }

  /*
  |--------------------------------------------------------------------------
  | widget internals
  |--------------------------------------------------------------------------
  */

  @nonVirtual
  @override
  get concreteType => "$Navigator";

  @nonVirtual
  @override
  get correspondingTag => DomTag.division;

  @nonVirtual
  @override
  createConfiguration() => const WidgetConfiguration();

  @nonVirtual
  @override
  isConfigurationChanged(oldConfiguration) => true;

  @override
  createRenderObject(context) => NavigatorRenderObject(context, this);
}

/*
|--------------------------------------------------------------------------
| render object
|--------------------------------------------------------------------------
*/

class NavigatorRenderObject extends RenderObject {
  final NavigatorState state;

  /// currentPage => {widgetKey => widgetContext}
  ///
  final dependents = <String, Map<String, BuildContext>>{};

  NavigatorRenderObject(BuildContext context, Navigator widget)
      : state = NavigatorState(context, widget),
        super(context);

  void addDependent(BuildContext dependentContext) {
    var dependentsOnCurrentPage = dependents[state.currentRouteName];

    if (null == dependentsOnCurrentPage) {
      dependents[state.currentRouteName] = {
        dependentContext.key: dependentContext
      };

      return;
    }

    if (!dependentsOnCurrentPage.containsKey(dependentContext.key)) {
      dependentsOnCurrentPage[dependentContext.key] = dependentContext;
    }
  }

  void _updateHook() {
    var dependentsOnCurrentPage = dependents[state.currentRouteName];

    if (null != dependentsOnCurrentPage) {
      var unavailableWidgetKeys = <String>[];

      dependentsOnCurrentPage.forEach((widgetKey, widgetContext) {
        var isUpdated = Framework.updateWidgetHavingContext(widgetContext);

        if (!isUpdated) {
          unavailableWidgetKeys.add(widgetContext.key);
        }
      });

      if (unavailableWidgetKeys.isNotEmpty) {
        if (Debug.widgetLogs) {
          print("Following dependents of Inherited widget($context) are lost.");

          unavailableWidgetKeys.forEach(print);
        }

        unavailableWidgetKeys.forEach(dependents.remove);
      }
    }
  }

  @override
  render(element, configuration) => state
    ..frameworkInitState()
    ..frameworkRender(_updateHook);

  @override
  update({
    required element,
    required updateType,
    required oldConfiguration,
    required newConfiguration,
  }) {
    state.frameworkUpdate(updateType);
  }

  @override
  beforeUnMount() => state.frameworkDispose();
}

/*
|--------------------------------------------------------------------------
| Navigator's state
|--------------------------------------------------------------------------
*/

class NavigatorState {
  /// Routes that this Navigator instance handles.
  ///
  final routes = <Route>[];

  /// Route name to route path map.
  ///
  final nameToPathMap = <String, String>{};

  /// Route path to Route instance map.
  ///
  final pathToRouteMap = <String, Route>{};

  // Name of the active route. Route, that's currently on top of
  /// Navigator stack.
  ///
  String get currentRouteName => _currentName;
  var _currentName = '_';

  /// Navigator widget's instance.
  ///
  final Navigator widget;

  /// Navigator's context.
  ///
  final BuildContext context;

  // internal stack data

  final _activeStack = <String>[];
  final _historyStack = <String>[];

  NavigatorState(this.context, this.widget);

  /*
  |--------------------------------------------------------------------------
  | Methods available on Navigator's state
  |--------------------------------------------------------------------------
  */

  /// Open a page on Navigator's stack.
  ///
  /// Please note that if a Page with same name already exists, it'll bring that to top
  /// rather than creating new one.
  ///
  /// Will throw exception if Navigator doesn't have a route with the provided name.
  ///
  /// If [name] is prefixed with a forward slash '/', and if current navigator doesn't have
  /// a matching named route, then it'll delegate open call to a parent navigator(if exists).
  /// If there are no navigator in ancestors, it'll throw an exception.
  ///
  void open({
    String? values,
    required String name,
    bool updateHistory = true,
  }) {
    var traverseAncestors = name.startsWith("../");

    // clean traversal flag

    var cleanedName = traverseAncestors ? name.substring(3) : name;

    // if already on same page
    if (currentRouteName == cleanedName) {
      return;
    }

    // if current navigator doesn't have a matching '$name' route

    if (!nameToPathMap.containsKey(cleanedName)) {
      if (!traverseAncestors) {
        throw "Navigator: '$cleanedName' is not declared."
            "Named routes that are not registered in Navigator's routes are not allowed."
            "If you're trying to push to a parent navigator, add prefix '../' to name of the route. "
            "e.g Navgator.of(context).push(name: '../home')."
            "It'll first tries a push to current navigator, if it doesn't find a matching route, "
            "then it'll try push to a parent navigator and so on. If there are no navigators in ancestors, "
            "then it'll throw an exception";
      } else {
        // push to parent navigator.

        NavigatorState parent;

        try {
          parent = Navigator.of(context);
        } catch (_) {
          throw "Route named '$cleanedName' not defined. Make sure you've declared a named route '$cleanedName' in Navigator's routes.";
        }

        parent.open(name: name, values: values);

        return;
      }
    }

    // callbacks

    _updateCurrentName(cleanedName);

    // update global state

    if (updateHistory) {
      if (Debug.routerLogs) {
        print("${context.key}: Push entry: $name");
      }

      Router.pushEntry(
        name: name,
        values: values ?? '',
        navigatorKey: context.key,
        updateHistory: updateHistory,
      );
    }

    _historyStack.add(cleanedName);

    // if route is already in stack, bring it to the top of stack

    if (isPageStacked(name: cleanedName)) {
      Framework.manageChildren(
        parentContext: context,
        flagIterateInReverseOrder: true,
        updateTypeWhenNecessary: UpdateType.setState,
        widgetActionCallback: (WidgetObject widgetObject) {
          var routeName =
              widgetObject.element.dataset[System.attrRouteName] ?? "";

          if (name == routeName) {
            return [WidgetAction.showWidget];
          }

          return [WidgetAction.hideWidget];
        },
      );

      _updateHook!();
    } else {
      //
      // else build the route

      var page = pathToRouteMap[nameToPathMap[cleanedName]];

      if (null == page) throw System.coreError;

      _activeStack.add(name);

      // hide all existing widgets
      Framework.manageChildren(
        parentContext: context,
        flagIterateInReverseOrder: true,
        updateTypeWhenNecessary: UpdateType.setState,
        widgetActionCallback: (WidgetObject widgetObject) =>
            [WidgetAction.hideWidget],
      );

      Framework.buildChildren(
        widgets: [page],
        parentContext: context,
        flagCleanParentContents: 1 == _historyStack.length,
      );
    }
  }

  /// Go back.
  ///
  void back() {
    var previousPage = _historyStack.removeLast();

    _updateCurrentName(_historyStack.last);

    Framework.manageChildren(
      parentContext: context,
      flagIterateInReverseOrder: true,
      widgetActionCallback: (WidgetObject widgetObject) {
        var name = widgetObject.element.dataset[System.attrRouteName] ?? "";

        if (previousPage == name) {
          return [WidgetAction.showWidget];
        }

        return [WidgetAction.hideWidget];
      },
    );

    _updateHook!();
  }

  /// Get value from URL following the provided segment.
  ///
  /// for example,
  ///
  /// if browser URI is pointing to: https://domain.com/profile/123/posts
  ///
  /// ```dart
  /// Navigator.of(context).getValue('profile'); //-> 123
  /// ```
  ///
  /// Please note that calling getValue on a Navigator who's context is
  /// enclosed on posts pages can only access values past its registration
  /// path.
  ///
  /// for example, if a Navigator is registered posts page it can
  /// only access parts of URI after posts pages.
  ///
  /// In `domain.com/profile/123/posts/456/edit/789`
  /// allowed part is `/posts/456/edit/789`
  ///
  /// ```dart
  /// Navigator.of(context).getValue('posts') // -> '456'
  /// Navigator.of(context).getValue('edit') // -> '789'
  ///
  /// // accessing protected values:
  /// Navigator.of(context).getValue('profile') // -> '', empty,
  /// // because current navigator is registered on posts page
  /// ```
  ///
  String getValue(String segment) => Router.getValue(context.key, segment);

  /// Whether current active stack contains a route with matching [name].
  ///
  bool isPageStacked({required String name}) => _activeStack.contains(name);

  /// Whether navigator can go back to a page.
  ///
  bool canGoBack() => _historyStack.length > 1;

  /*
  |--------------------------------------------------------------------------
  | internals
  |--------------------------------------------------------------------------
  */

  VoidCallback? _updateHook;

  frameworkInitState() {
    if (Debug.developmentMode) {
      if (widget.routes.isEmpty) {
        throw "Navigator instance must have at least one route.";
      }
    }

    routes.addAll(widget.routes);

    for (final route in routes) {
      if (Debug.developmentMode) {
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(route.path)) {
          if (route.path.isEmpty) {
            throw "Navigator's Route's path can't be empty."
                "\n Route: ${route.name} -> ${route.path} is not allowed";
          }

          throw "Navigator's Route can contains only alphanumeric characters and underscores"
              "\n Route: ${route.name} -> ${route.path} is not allowed";
        }

        var isDuplicate = nameToPathMap.containsKey(route.name) ||
            pathToRouteMap.containsKey(route.path);

        if (isDuplicate) {
          throw "Please remove Duplicate routes from your Navigator."
              "Part of your route, name: '${route.name}' => path: '${route.path}', already exists";
        }
      }

      nameToPathMap[route.name] = route.path;

      pathToRouteMap[route.path] = route;
    }

    Router.register(context, this);
  }

  void frameworkRender(VoidCallback updateHook) {
    _updateHook = updateHook;

    var name = Router.getPath(context.key);

    var needsReplacement = name.isEmpty;

    if (name.isEmpty) {
      name = widget.routes.first.name;
    }

    var onInitCallback = widget.onInit;
    if (null != onInitCallback) {
      onInitCallback(this);
    }

    if (needsReplacement && name.isNotEmpty) {
      if (Debug.routerLogs) {
        print("${context.key}: Push replacement: $name");
      }

      Router.pushReplacement(
        name: name,
        values: '',
        navigatorKey: context.key,
      );
    }

    open(name: name, updateHistory: false);
  }

  void frameworkUpdate(UpdateType updateType) {
    Framework.manageChildren(
      parentContext: context,
      flagIterateInReverseOrder: true,
      updateTypeWhenNecessary: updateType,
      widgetActionCallback: (WidgetObject widgetObject) {
        var name = widgetObject.element.dataset[System.attrRouteName] ?? "";

        if (currentRouteName == name) {
          return [WidgetAction.updateWidget];
        }

        return [];
      },
    );
  }

  void frameworkDispose() => Router.unRegister(context);

  /// Framework fires this when parent route changes.
  ///
  void frameworkOnParentRouteChange(String name) {
    var routeName = Router.getPath(context.key);

    if (routeName != currentRouteName) {
      if (Debug.routerLogs) {
        print("${context.key}: Push replacement: $routeName");
      }

      Router.pushReplacement(
        name: currentRouteName,
        values: '',
        navigatorKey: context.key,
      );
    }
  }

  void _updateCurrentName(String name) {
    _currentName = name;

    var onRouteChangeCallback = widget.onRouteChange;

    if (null != onRouteChangeCallback) {
      onRouteChangeCallback(_currentName);
    }
  }
}
