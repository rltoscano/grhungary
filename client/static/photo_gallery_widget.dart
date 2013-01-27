part of grhungary;

class PhotoGalleryWidget {
  static const int _ORIGINAL_IMAGE_PADDING = 40; // pixels
  static RegExp _IMAGE_IDX_REGEXP =
      new RegExp(r"images/(\d+)_original\.jpg");

  Element _lightBox;
  KeyboardEventController _keyboardEventController;
  ImageElement _prevImg;
  ImageElement _currImg;
  ImageElement _nextImg;

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

  ImageElement _createLightBoxImage(String src) {
    js.scoped(() {
      js.context["_gaq"].push(js.array(["_trackEvent", "Gallery", "LoadOriginal", src]));
    });
    ImageElement img = new ImageElement(src: src);
    img.hidden = true;
    img.classes.add("light-box-image");
    img.on.load.add(_onImgLoad);
    _lightBox.children.add(img);
    return img;
  }

  void _loadProxImages() {
    String nextUrl = _getImageUrl(_currImg.src, 1);
    String prevUrl = _getImageUrl(_currImg.src, -1);
    if (_nextImg == null) {
      _nextImg = _createLightBoxImage(nextUrl);
      _nextImg.style.left = "${_lightBox.offsetWidth - 10}px";
    }
    if (_prevImg == null) {
      _prevImg = _createLightBoxImage(prevUrl);
      _prevImg.style.left = "${10 - _lightBox.offsetWidth + _ORIGINAL_IMAGE_PADDING * 2}px";
    }
  }

  void _clearCache() {
    _deleteImg(_prevImg);
    _prevImg = null;
    _deleteImg(_currImg);
    _currImg = null;
    _deleteImg(_nextImg);
    _nextImg = null;
  }

  void _deleteImg(ImageElement img) {
    if (img == null) {
      return;
    }
    img.remove();
    img.on.load.remove(_onImgLoad);
  }

  void _onThumbClick(Event e) {
    String originalSrc = (e.target as ImageElement).src;
    originalSrc = originalSrc.replaceAll("\.jpg", "_original.jpg");
    _clearCache();
    _setLightBoxVisible(true);
    _currImg = _createLightBoxImage(originalSrc);
    js.scoped(() {
      js.context["_gaq"].push(
          js.array(["_trackEvent", "Gallery", "ThumbnailClick", originalSrc]));
    });
  }

  void _onImgLoad(Event e) {
    ImageElement img = e.target as ImageElement;
    if (img.parent == null) {
      return;
    }
    int maxWidth = _lightBox.offsetWidth - _ORIGINAL_IMAGE_PADDING * 2;
    int maxHeight = _lightBox.offsetHeight - _ORIGINAL_IMAGE_PADDING * 2;
    if (img.width == 0) {
      img.width = 400;
      img.height = 400;
    } else {
      double scaleFactor = min(maxWidth / img.width, maxHeight / img.height);
      img.width = (img.width.toDouble() * scaleFactor).toInt();
      img.height = (img.height.toDouble() * scaleFactor).toInt();
    }
    int top = (maxHeight / 2 - img.height / 2).toInt();
    img.style.top = "${top + _ORIGINAL_IMAGE_PADDING}px";

    _setLeftPosition(img);

    if (img == _currImg) {
      _loadProxImages();
    }

    img.hidden = false;
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
    _deleteImg(_prevImg);
    _prevImg = _currImg;
    _currImg = _nextImg;
    _nextImg = null;
    _setLeftPosition(_prevImg);
    _setLeftPosition(_currImg);
    _loadProxImages();
  }

  void _navPrev() {
    _deleteImg(_nextImg);
    _nextImg = _currImg;
    _currImg = _prevImg;
    _prevImg = null;
    _setLeftPosition(_currImg);
    _setLeftPosition(_nextImg);
    _loadProxImages();
  }

  int _setLeftPosition(ImageElement img) {
    int left = 0;
    int centerPos = (_lightBox.offsetWidth / 2 - img.width / 2).toInt();
    if (img == _currImg) {
      left = centerPos;
    } else if (img == _prevImg) {
      left = centerPos - _lightBox.offsetWidth;
    } else if (img == _nextImg) {
      left = centerPos + _lightBox.offsetWidth;
    }
    img.style.left = "${left}px";
  }
}