part of grhungary;

class GalleryImage {
  static const EventStreamProvider<Event> loadEvent =
      const EventStreamProvider<Event>("load");
  const int _PADDING = 40; // Pixels.

  Stream<Event> get onLoad => loadEvent.forTarget(_img);

  Element _container;
  Element _loadingMessage;
  Element _loadingDotsContainer;
  ImageElement _img;
  int _imgId;
  bool _isImgLoaded;
  bool _isDisposed;

  GalleryImage(int imgId, int leftPosition) : _imgId = imgId {
    _isImgLoaded = false;
    _isDisposed = false;

    _container = new Element.tag("div");
    _container.classes.add("gallery-image");
    _container.style.left = "${leftPosition}px";

    _loadingMessage = query("#loading-message").clone(true);
    _loadingMessage.hidden = true;
    _loadingMessage.classes.add("gallery-image-loading-message");
    _loadingDotsContainer = _loadingMessage.query("span");
    _container.children.add(_loadingMessage);

    _img = new ImageElement();
    _img.hidden = true;
    _img.classes.add("gallery-image-img transparent");
    _img.onLoad.listen(_onImgLoad);
    _container.children.add(_img);
  }

  ImageElement get img => _img;

  int get id => _imgId;

  void load() {
    _loadingMessage.hidden = false;
    _loadingDotsContainer.classes.add("dots");
    _img.src = "/static/images/${_imgId}_original.jpg";
  }

  Element getElement() {
    return _container;
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