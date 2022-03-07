import 'dart:html';

import 'package:rad/src/core/constants.dart';
import 'package:rad/src/core/enums.dart';
import 'package:rad/src/core/objects/debug_options.dart';
import 'package:rad/src/core/objects/build_context.dart';
import 'package:rad/src/core/classes/abstract/widget.dart';
import 'package:rad/src/css/include/normalize.generated.dart';
import 'package:rad/src/css/main.generated.dart';
import 'package:rad/src/core/classes/framework.dart';
import 'package:rad/src/core/objects/render_object.dart';

abstract class AppWidget extends Widget {
  final String? key;

  final Widget child;
  final String targetId;

  final VoidCallback onInit;

  AppWidget({
    this.key,
    required this.child,
    required this.targetId,
    required this.onInit,
    required String routingPath,
    DebugOptions? debugOptions,
  }) {
    Framework.init(routingPath: routingPath, debugOptions: debugOptions);

    Framework.addGlobalStyles(GEN_STYLES_NORMALIZE_CSS, "Normalize");
    Framework.addGlobalStyles(GEN_STYLES_MAIN_CSS, "Main");

    onInit();

    Framework.buildChildren(
      widgets: [this],
      parentContext: BuildContext.bigBang(targetId),
    );
  }

  @override
  DomTag get tag => DomTag.div;

  @override
  String get type => "$AppWidget";

  @override
  String get initialKey => key ?? System.keyNotSet;

  @override
  createRenderObject(context) {
    context.parent;

    return AppWidgetRenderObject(
      child: child,
      context: context,
    );
  }
}

class AppWidgetRenderObject extends RenderObject {
  final Widget child;

  AppWidgetRenderObject({
    required this.child,
    required BuildContext context,
  }) : super(context);

  @override
  render(widgetObject) {
    var targetElement = widgetObject.element.parent;

    if (null == targetElement) {
      throw "Unable to locate target element in HTML document";
    }

    targetElement.dataset.addAll({
      System.attrType: "Target",
      System.attrClass: context.parent.widgetClassName,
    });

    Framework.buildChildren(widgets: [child], parentContext: context);
  }

  @override
  update(updateType, widgetObject, updatedRenderObject) {
    throw System.coreError;
  }
}
