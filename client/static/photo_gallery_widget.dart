part of grhungary;

class PhotoGalleryWidget {
  static RegExp _IMAGE_IDX_REGEXP =
      new RegExp(r"images/(\d+)_original\.jpg");

  Element _lightBox;
  KeyboardEventController _keyboardEventController;
  GalleryImage _prevImg;
  GalleryImage _currImg;
  GalleryImage _nextImg;

  static String _getImageUrl(String currentUrl, int offset) {
    Iterator<Match> matchesIt =
        _IMAGE_IDX_REGEXP.allMatches(currentUrl).iterator;
    matchesIt.moveNext();
    int currentIdx = int.parse(matchesIt.current.group(1));
    int newIdx = (currentIdx+ offset) % 69;
    String newIdxStr = "$newIdx";
    if (newIdxStr.length < 2) {
      newIdxStr = "0$newIdx";
    }
    return currentUrl.replaceAll(
        _IMAGE_IDX_REGEXP, "images/${newIdxStr}_original.jpg");
  }

  void decorate() {
    _lightBox = query("#photo-gallery-light-box");
    _lightBox.on.transitionEnd.add(_onLightBoxTransitionEnd);
    queryAll("#photo-gallery-page img").forEach((Element img) {
      img.on.click.add(_onThumbClick);
    });
    query("#light-box-close-button").on.click.add((Event _) {
      _setLightBoxVisible(false);
    });
    query("#light-box-right-button").on.click.add((Event _) { _navNext(); });
    query("#light-box-left-button").on.click.add((Event _) { _navPrev(); });
    window.on.resize.add(_onWindowResize);
    window.on.scroll.add(_onWindowScroll, true);
    _onWindowResize(null);
    _keyboardEventController = new KeyboardEventController.keydown(window);
    _keyboardEventController.add(_onWindowKeyPress);
  }

  void _setLightBoxVisible(bool isVisible) {
    if (isVisible) {
      _lightBox.hidden = false;
      window.setTimeout(() {_lightBox.classes.remove("transparent");}, 0);
    } else {
      _lightBox.classes.add("transparent");
    }
  }

  GalleryImage _createLightBoxImage(String src, int leftPosition) {
    js.scoped(() {
      js.context["_gaq"].push(js.array(["_trackEvent", "Gallery", "LoadOriginal", src]));
    });
    GalleryImage img = new GalleryImage(src, leftPosition);
    img.on.load.add(_onImgLoad);
    img.resize(_lightBox.offsetWidth, _lightBox.offsetHeight);
    _lightBox.children.add(img.getElement());
    return img;
  }

  void _loadProxImages() {
    String nextUrl = _getImageUrl(_currImg.getSrc(), 1);
    String prevUrl = _getImageUrl(_currImg.getSrc(), -1);
    if (_nextImg == null) {
      _nextImg = _createLightBoxImage(nextUrl, _lightBox.offsetWidth);
    }
    if (_prevImg == null) {
      _prevImg = _createLightBoxImage(prevUrl, -_lightBox.offsetWidth);
    }
  }

  void _clearCache() {
    if (_prevImg != null) {
      _prevImg.dispose();
      _prevImg = null;
    }
    if (_currImg != null) {
      _currImg.dispose();
      _currImg = null;
    }
    if (_nextImg != null) {
      _nextImg.dispose();
      _nextImg = null;
    }
  }

  void _onThumbClick(Event e) {
    String originalSrc = (e.target as ImageElement).src;
    originalSrc = originalSrc.replaceAll("\.jpg", "_original.jpg");
    _setLightBoxVisible(true);
    _currImg = _createLightBoxImage(originalSrc, 0);
    js.scoped(() {
      js.context["_gaq"].push(
          js.array(["_trackEvent", "Gallery", "ThumbnailClick", originalSrc]));
    });
  }

  void _onImgLoad(Event e) {
    if (e.target as ImageElement == _currImg.getImg()) {
      _loadProxImages();
    }
  }

  void _onLightBoxTransitionEnd(Event _) {
    if (_lightBox.classes.contains("transparent")) {
      _lightBox.hidden = true;
      _clearCache();
    }
  }

  void _onWindowResize(Event _) {
    _lightBox.style.width = "${query("html").offsetWidth}px";
    _lightBox.style.height = "${window.innerHeight}px";
    int buttonTop = window.innerHeight ~/ 2;
    queryAll(".light-box-nav-button").forEach((Element button) {
      button.style.top = "${buttonTop}px";
    });
    if (_currImg != null) {
      _currImg.resize(_lightBox.offsetWidth, _lightBox.offsetHeight);
      _currImg.setLeftPosition(0);
    }
    if (_nextImg != null) {
      _nextImg.resize(_lightBox.offsetWidth, _lightBox.offsetHeight);
      _nextImg.setLeftPosition(_lightBox.offsetWidth);
    }
    if (_prevImg != null) {
      _prevImg.resize(_lightBox.offsetWidth, _lightBox.offsetHeight);
      _prevImg.setLeftPosition(-_lightBox.offsetWidth);
    }
  }

  void _onWindowScroll(Event _) {
    Element html = query("html");
    _lightBox.style.top = "${window.scrollY}px";
    _lightBox.style.left = "${html.scrollLeft}px";
  }

  void _onWindowKeyPress(KeyboardEvent e) {
    if (_lightBox.hidden) {
      return;
    }
    switch (e.keyCode) {
      case KeyCode.ESC:
        _setLightBoxVisible(false);
        break;
      case KeyCode.LEFT:
        _navPrev();
        break;
      case KeyCode.RIGHT:
        _navNext();
        break;
    }
  }

  void _navNext() {
    _prevImg.dispose();
    _prevImg = _currImg;
    _currImg = _nextImg;
    _nextImg = null;
    _prevImg.setLeftPosition(-_lightBox.offsetWidth);
    _currImg.setLeftPosition(0);
    _loadProxImages();
  }

  void _navPrev() {
    _nextImg.dispose();
    _nextImg = _currImg;
    _currImg = _prevImg;
    _prevImg = null;
    _currImg.setLeftPosition(0);
    _nextImg.setLeftPosition(_lightBox.offsetWidth);
    _loadProxImages();
  }
}