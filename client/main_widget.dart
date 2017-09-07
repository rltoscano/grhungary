part of grhungary;

class MainWidget {
  static RegExp _PAGE_ID_REGEXP = new RegExp(r"#([^/]+)");
  static Pattern _LANG_PATTERN = new RegExp(r"lang\=[a-zA-Z]+");

  Map<String, PageWidget> _pageWidgets;
  String _defaultPageId;

  MainWidget() {
    _pageWidgets = new Map<String, PageWidget>();
    _pageWidgets["welcome"] = new PageWidget();
    _pageWidgets["photo-gallery"] = new PhotoGalleryWidget();
    _pageWidgets["travel"] = new PageWidget();
    _pageWidgets["rsvp"] = new RsvpWidget();
    _pageWidgets["gift-registry"] = new PageWidget();
    _pageWidgets["contact"] = new PageWidget();
  }

  void decorate() {
    query("#bird").onClick.listen((_) {
      AudioElement audio = query("#hu-theme-song");
      if (audio.ended || audio.paused) {
        if (audio.ended) {
          audio.load();
        }
        audio.play();
        query("#bird-link").classes.remove("transparent");
      } else {
        audio.pause();
        query("#bird-link").classes.add("transparent");
      }
    });

    _defaultPageId = query("#nav-bar").children[0].dataset["page-id"];
    queryAll("#nav-bar li").forEach((Element el) {
      el.onClick.listen(_onLinkClick);
    });

    _pageWidgets.forEach((String id, PageWidget pageWidget) {
      pageWidget.decorate(query("#$id"));
    });

    Element loadingOverlay = query("#loading-overlay");
    loadingOverlay.hidden = true;
    // Stop loading dots animation to preserve CPU.
    loadingOverlay.query(".dots").classes.remove("dots");

    Element mainContent = query("#main-content");
    mainContent.hidden = false;
    window.setImmediate(() { mainContent.classes.remove("transparent"); });

    window.onHashChange.listen(_navigateToHash);
    _navigateToHash(null);
  }

  void _navigateToHash(Event _) {
    Iterable<Match> matches = _PAGE_ID_REGEXP.allMatches(window.location.hash);
    if (matches.length == 0) {
      window.location.hash = _defaultPageId;
      return;
    }

    String pageId = matches.first.group(1);
    if (!_pageWidgets.containsKey(pageId)) {
      window.location.hash = _defaultPageId;
      return;
    }

    if (!_pageWidgets[pageId].isVisible) {
      _showPage(pageId);
    }
  }

  /**
   * Shows a top-level page and scrolls to the top.
   *
   * @param pageSelector CSS selector of the page to show
   */
  void _showPage(String pageId) {
    js.scoped(() {
      js.context["_gaq"].push(js.array(['_trackEvent', 'PageView', pageId]));
    });

    // Deactivate previously active link.
    Element activeEl = query("#nav-bar li.active");
    if (activeEl != null) {
      activeEl.classes.remove("active");
    }

    // Hide all non-transparent pages.
    _pageWidgets.values.forEach((PageWidget pageWidget) {
      if (pageWidget.isVisible) {
        pageWidget.isVisible = false;
      }
    });

    // Activate selected link and page.
    queryAll("#nav-bar li").forEach((Element el) {
      if (el.dataset["page-id"] == pageId) {
        el.classes.add("active");
      }
    });
    _pageWidgets[pageId].isVisible = true;
    window.scrollTo(0, 0);
  }

  void _onLinkClick(Event e) {
    Element clickedLink = e.target as Element;
    window.location.hash = clickedLink.dataset["page-id"];
  }
}
