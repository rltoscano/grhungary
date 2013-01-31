part of grhungary;

class MainWidget {
  void decorate() {
    queryAll("#nav-bar li").forEach((Element el) {
      el.on.click.add(_onLinkClick);
    });

    queryAll(".page").forEach((Element pageEl) {
      pageEl.on.transitionEnd.add((Event _) {
        if (pageEl.classes.contains("transparent")) {
          pageEl.hidden = true;
        }
      });
    });

    Element loadingOverlay = query("#loading-overlay");
    loadingOverlay.hidden = true;
    // Stop loading dots animation to preserve CPU.
    loadingOverlay.query(".dots").classes.remove("dots");

    Element mainContent = query("#main-content");
    mainContent.hidden = false;
    window.setTimeout(() { mainContent.classes.remove("transparent"); }, 0);

    window.on.hashChange.add(_navigateToHash);
    _navigateToHash(null);
  }

  void _navigateToHash(Event _) {
    String hash = window.location.hash.replaceAll("#", "");
    bool alreadySelected = queryAll("#nav-bar li").any((Element el) {
      return el.dataAttributes["page-id"] == hash &&
             el.classes.contains("active");
    });
    if (alreadySelected) {
      return;
    }
    if (!hash.isEmpty && query("#$hash") != null) {
      _showPage(hash);
    } else {
      String defaultPageSelector =
          query("#nav-bar").children[0].dataAttributes["page-id"];
      window.location.hash = defaultPageSelector;
    }
  }

  /**
   * Shows a top-level page and scrolls to the top.
   *
   * @param pageSelector CSS selector of the page to show
   */
  void _showPage(String pageSelector) {
    js.scoped(() {
      js.context["_gaq"].push(js.array(['_trackEvent', 'PageView', pageSelector]));
    });

    // Deactivate previously active link.
    Element activeEl = query("#nav-bar li.active");
    if (activeEl != null) {
      activeEl.classes.remove("active");
    }

    // Hide all non-transparent pages.
    queryAll(".page").forEach((Element el) {
      if (!el.classes.contains("transparent")) {
        el.classes.add("transparent");
      }
    });

    // Activate selected link and page.
    queryAll("#nav-bar li").forEach((Element el) {
      if (el.dataAttributes["page-id"] == pageSelector) {
        el.classes.add("active");
      }
    });
    Element shownPage = query("#$pageSelector");
    shownPage.hidden = false;
    window.scrollTo(0, 0);
    window.setTimeout(() { shownPage.classes.remove("transparent"); }, 0);
  }

  void _onLinkClick(Event e) {
    Element clickedLink = e.target as Element;
    window.location.hash = clickedLink.dataAttributes["page-id"];
  }
}
