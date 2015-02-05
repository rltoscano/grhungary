part of grhungary;

class PageWidget {
  Element _element;

  bool get isVisible => !_element.classes.contains("transparent");
  void set isVisible(bool isVisible) {
    if (isVisible) {
      _element.hidden = false;
      window.setImmediate(() => _element.classes.remove("transparent"));
    } else {
      _element.classes.add("transparent");
    }
  }

  void decorate(Element element) {
    _element = element;
    _element.onTransitionEnd.listen(_onTransitionEnd);
  }

  void _onTransitionEnd(TransitionEvent e) {
    if (e.propertyName != "opacity") {
      return;
    }
    if (_element.classes.contains("transparent")) {
      _element.hidden = true;
    }
  }
}

