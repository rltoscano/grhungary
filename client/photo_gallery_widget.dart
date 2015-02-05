part of grhungary;

class PhotoGalleryWidget extends PageWidget {
  static RegExp _HASH_IMG_ID_REGEXP = new RegExp(r"#photo-gallery/(\d+)");
  static const int _TOTAL_IMAGES = 69;

  Element _lightBox;
  KeyboardEventController _keyboardEventController;
  GalleryImage _prevImg;
  GalleryImage _currImg;
  GalleryImage _nextImg;

  void set isVisible(bool isVisible) {
    super.isVisible = isVisible;
    if (isVisible) {
      Iterable<Match> matches =
          _HASH_IMG_ID_REGEXP.allMatches(window.location.hash);
      if (matches.length == 0) {
        return;
      }
      int activatedImgId = int.parse(matches.first.group(1));
      showImage(activatedImgId);
    }
  }

  void decorate(Element e) {
    super.decorate(e);
    _lightBox = query("#photo-gallery-light-box");
    _lightBox.onTransitionEnd.listen(_onLightBoxTransitionEnd);
    queryAll(".gallery-thumb > div").forEach((Element img) {
      img.onClick.listen(_onThumbClick);
    });
    query("#light-box-close-button").onClick.listen(
        (_) => window.location.hash = "photo-gallery");
    query("#light-box-right-button").onClick.listen(
        (_) => showImage(_currImg.id + 1));
    query("#light-box-left-button").onClick.listen(
        (_) => showImage(_currImg.id - 1));
    window.onResize.listen(_onWindowResize);
    window.onHashChange.listen(_onHashChange);
    _onWindowResize(null);
    _keyboardEventController = new KeyboardEventController.keydown(window);
    _keyboardEventController.add(_onWindowKeyPress);
  }

  void showImage(int imgId) {
    if (imgId < 0 || imgId >= _TOTAL_IMAGES) {
      imgId = imgId % _TOTAL_IMAGES;
    }
    if (_lightBox.hidden || _lightBox.classes.contains("transparent")) {
      _setLightBoxVisible(true);
    }
    if (_currImg == null) {
      _currImg = _createLightBoxImage(imgId, 0);
      _currImg.load();
      _prevImg = _createLightBoxImage(imgId - 1, -_lightBox.offsetWidth);
      _nextImg = _createLightBoxImage(imgId + 1, _lightBox.offsetWidth);
    } else if (_nextImg.id == imgId) {
      _prevImg.dispose();
      _prevImg = _currImg;
      _currImg = _nextImg;
      _nextImg = _createLightBoxImage(imgId + 1, _lightBox.offsetWidth);
      _nextImg.load();
      _prevImg.setLeftPosition(-_lightBox.offsetWidth);
      _currImg.setLeftPosition(0);
    } else if (_prevImg.id == imgId) {
      _nextImg.dispose();
      _nextImg = _currImg;
      _currImg = _prevImg;
      _prevImg = _createLightBoxImage(imgId - 1, -_lightBox.offsetWidth);
      _prevImg.load();
      _currImg.setLeftPosition(0);
      _nextImg.setLeftPosition(_lightBox.offsetWidth);
    } else if (_currImg.id != imgId) {
      _clearCache();
      _currImg = _createLightBoxImage(imgId, 0);
      _currImg.load();
      _prevImg = _createLightBoxImage(imgId - 1, -_lightBox.offsetWidth);
      _nextImg = _createLightBoxImage(imgId + 1, _lightBox.offsetWidth);
    }
    window.location.hash = "photo-gallery/$imgId";
  }

  void _setLightBoxVisible(bool isVisible) {
    if (isVisible) {
      _lightBox.hidden = false;
      window.setImmediate(() {_lightBox.classes.remove("transparent");});
    } else {
      _lightBox.classes.add("transparent");
    }
  }

  GalleryImage _createLightBoxImage(int imgId, int leftPosition) {
    if (imgId < 0 || imgId >= _TOTAL_IMAGES) {
      imgId = imgId % _TOTAL_IMAGES;
    }
    js.scoped(() {
      js.context["_gaq"].push(js.array(
          ["_trackEvent", "Gallery", "LoadOriginal", imgId]));
    });
    GalleryImage img = new GalleryImage(imgId, leftPosition);
    img.onLoad.listen(_onImgLoad);
    img.resize(_lightBox.offsetWidth, _lightBox.offsetHeight);
    _lightBox.children.add(img.getElement());
    return img;
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
    int imgId = int.parse((e.target as Element).dataset["gallery-id"]);
    showImage(imgId);
    js.scoped(() {
      js.context["_gaq"].push(
          js.array(["_trackEvent", "Gallery", "ThumbnailClick", imgId]));
    });
  }

  void _onImgLoad(Event e) {
    if (e.target == _currImg.img) {
      _prevImg.load();
      _nextImg.load();
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

  void _onWindowKeyPress(KeyboardEvent e) {
    if (_lightBox.hidden) {
      return;
    }
    switch (e.keyCode) {
      case KeyCode.ESC:
        window.location.hash = "photo-gallery";
        break;
      case KeyCode.LEFT:
        showImage(_currImg.id - 1);
        break;
      case KeyCode.RIGHT:
        showImage(_currImg.id + 1);
        break;
    }
  }

  _onHashChange(_) {
    Iterable<Match> matches =
        _HASH_IMG_ID_REGEXP.allMatches(window.location.hash);
    if (matches.length == 0) {
      _setLightBoxVisible(false);
      return;
    }
    int activatedImgId = int.parse(matches.first.group(1));
    if (_currImg == null || _currImg.id != activatedImgId) {
      showImage(activatedImgId);
    }
  }
}