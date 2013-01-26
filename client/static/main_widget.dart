part of grhungary;

class MainWidget {
  void decorate() {
    queryAll("#page-links li").forEach((Element el) {
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

    Element mainContent = query("#main-content");
    mainContent.hidden = false;
    window.setTimeout(() { mainContent.classes.remove("transparent"); }, 0);

    window.on.hashChange.add(_navigateToHash);
    _navigateToHash(null);
  }

  void _navigateToHash(Event _) {
    String hash = window.location.hash.replaceAll("#", "");
    bool alreadySelected = queryAll("#page-links li").some((Element el) {
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
          query("#page-links").children[0].dataAttributes["page-id"];
      window.location.hash = defaultPageSelector;
    }
  }

  /**
   * Shows a top-level page and scrolls to the top.
   *
   * @param pageSelector CSS selector of the page to show
   */
  void _showPage(String pageSelector) {
    // Deactivate previously active link.
    Element activeEl = query("#page-links li.active");
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
    queryAll("#page-links li").forEach((Element el) {
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