import 'dart:html';

class StylingProps {
  List<String> stylesList = [];

  StylingProps(String? styles) {
    stylesList.addAll(null != styles ? styles.split(" ") : []);
  }

  // application

  /// Apply props.
  ///
  /// if [updatedProps] is not null, it'll do a update
  ///
  void updateProps(HtmlElement element, [StylingProps? updatedProps]) {
    if (null == updatedProps) {
      return _applyProps(element, this);
    }

    if (_isChanged(updatedProps)) {
      _clearProps(element, this);
      _switchProps(updatedProps);
      _applyProps(element, this);
    }
  }

  bool _isChanged(StylingProps props) {
    return stylesList.join() != props.stylesList.join();
  }

  void _switchProps(StylingProps updatedProps) {
    stylesList = updatedProps.stylesList;
  }

  // statics

  static void _applyProps(HtmlElement element, StylingProps props) {
    if (props.stylesList.isNotEmpty) {
      element.classes.addAll(props.stylesList);
    }
  }

  static void _clearProps(HtmlElement element, StylingProps props) {
    if (props.stylesList.isNotEmpty) {
      element.classes.removeAll(props.stylesList);
    }
  }
}
