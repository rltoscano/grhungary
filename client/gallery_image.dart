part of grhungary;

class GalleryImage {
  const int _PADDING = 40; // Pixels.

  ElementEvents get on => _img.on;

  Element _container;
  Element _loadingMessage;
  Element _loadingDotsContainer;
  ImageElement _img;
  bool _isImgLoaded;
  bool _isDisposed;

  GalleryImage(String url, int leftPosition) {
    _isImgLoaded = false;
    _isDisposed = false;

    _container = new Element.tag("div");
    _container.classes.add("gallery-image");
    _container.style.left = "${leftPosition}px";

    _loadingMessage = query("#loading-message").clone(true);
    _loadingMessage.hidden = false;
    _loadingMessage.classes.add("gallery-image-loading-message");
    _loadingDotsContainer = _loadingMessage.query("span");
    _loadingDotsContainer.classes.add("dots");
    _container.children.add(_loadingMessage);

    _img = new ImageElement(src: url);
    _img.hidden = true;
    _img.classes.add("gallery-image-img transparent");
    _img.on.load.add(_onImgLoad);
    _container.children.add(_img);
  }

  String getSrc() {
    return _img.src;
  }

  Element getElement() {
    return _container;
  }

  ImageElement getImg() {
    return _img;
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _container.remove();
    _loadingDotsContainer.classes.remove("dots");
    _isDisposed = true;
  }

  void resize(int width, int height) {
    _container.style.width = "${width}px";
    _container.style.height = "${height}px";
    _loadingMessage.style.left =
        "${width ~/ 2 - _loadingMessage.offsetWidth ~/ 2}px";
    _loadingMessage.style.top =
        "${height ~/ 2 - _loadingMessage.offsetHeight ~/ 2}px";
    if (_isImgLoaded) {
      double scaleFactor = min(
          (_container.offsetWidth - _PADDING * 2) / _img.width,
          (_container.offsetHeight - _PADDING * 2) / _img.height);
      _img.width = (_img.width.toDouble() * scaleFactor).toInt();
      _img.height = (_img.height.toDouble() * scaleFactor).toInt();
      _img.style.left = "${_container.offsetWidth ~/ 2 - _img.width ~/ 2}px";
      _img.style.top = "${_container.offsetHeight ~/ 2 - _img.height ~/ 2}px";
    }
  }

  void setLeftPosition(int pos) {
    _container.style.left = "${pos}px";
  }

  void _onImgLoad(Event _) {
    if (_isDisposed) {
      return;
    }
    _isImgLoaded = true;
    resize(_container.offsetWidth, _container.offsetHeight);
    _img.hidden = false;
    window.setTimeout(() => _img.classes.remove("transparent"), 0);
    _loadingMessage.hidden = true;
    _loadingDotsContainer.classes.remove("dots");
  }
}