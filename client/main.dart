library grhungary;

import 'dart:html';
import "dart:math";
import 'dart:json';

part "decoration.dart";

class RsvpPayload {
  String id;
  List<String> partyMembers;
  String dietaryRestrictions;
  bool isStayingOvernight;
  String durationDaysCount;

  Object toJson() {
    Map map = new Map();
    map["Id"] = this.id;
    map["PartyMembers"] = this.partyMembers;
    map["DietaryRestrictions"] = this.dietaryRestrictions;
    map["IsStayingOvernight"] = this.isStayingOvernight;
    map["DurationDaysCount"] = this.durationDaysCount;
    return map;
  }
}

class RsvpWidget {
  HttpRequest reqInProgress_;

  void decorate() {
    query("#rsvp-send-button").on.click.add(this.onRsvpSendButtonClick_);
    query("#rsvp-add-name-button").on.click.add(this.onAddNameClick_);
  }

  void showMessage_(String type, String msg) {
    Element infoEl = query("#rsvp-info-element");
    infoEl.innerHtml = msg;
    infoEl.classes.clear();
    infoEl.classes.add(type);
    infoEl.classes.add("shown");
    if (type == "info") {
      window.setTimeout(() {
        infoEl.classes.remove("shown");
      }, 6000);
    }
  }

  void setSendButtonState_(bool isInProgress) {
    ButtonElement sendButton = query("#rsvp-send-button");
    String label;
    if (isInProgress) {
      label = sendButton.dataAttributes["label-send-in-progress"];
    } else {
      label = sendButton.dataAttributes["label-send"];
    }
    sendButton.text = label;
    sendButton.disabled = isInProgress;
  }

  void onRsvpSendButtonClick_(Event e) {
    this.setSendButtonState_(true);

    RsvpPayload rsvp = new RsvpPayload();
    rsvp.id = (query("#rsvp-id") as TextInputElement).value;
    rsvp.partyMembers = new List<String>();
    queryAll("#rsvp-names > .rsvp-name").forEach((Element nameEl) {
      String name = (nameEl as TextInputElement).value;
      if (name != "") {
        rsvp.partyMembers.add(name);
      }
    });
    rsvp.dietaryRestrictions =
        (query("#rsvp-dietary-restrictions") as TextAreaElement).value;
    rsvp.isStayingOvernight =
        (query("#rsvp-is-staying-overnight") as CheckboxInputElement).checked;
    rsvp.durationDaysCount =
        (query("#rsvp-duration-days-count") as TextInputElement).value;

    reqInProgress_ = new HttpRequest();
    reqInProgress_.on.load.add(this.onRsvpUpsertSuccess_);
    reqInProgress_.on.error.add(this.onRsvpUpsertFail_);
    reqInProgress_.open("POST", "/api/rsvp/upsert");
    reqInProgress_.send(JSON.stringify(rsvp));
  }

  void onRsvpUpsertSuccess_(Event e) {
    if (this.reqInProgress_.status == 200) {
      this.showMessage_(
          "info",
          query("#rsvp-info-element").dataAttributes["success-message"]);
      this.setSendButtonState_(false);
    } else {
      this.onRsvpUpsertFail_(e);
    }
  }

  void onRsvpUpsertFail_(Event e) {
    this.showMessage_(
      "error", query("#rsvp-info-element").dataAttributes["fail-message"]);
    this.setSendButtonState_(false);
  }

  void onAddNameClick_(Event e) {
    TextInputElement child = new TextInputElement();
    child.classes.add("rsvp-name");
    Element rsvpNames = query("#rsvp-names");
    rsvpNames.children.add(new BRElement());
    rsvpNames.children.add(child);
  }
}

void main() {
  queryAll("#page-links li").forEach((Element el) {
    el.on.click.add((Event e) {
      showPage(el.dataAttributes["page-id"]);
    });
  });
  String hash = window.location.hash.replaceAll("#", "");
  if (!hash.isEmpty && query("#$hash") != null) {
    showPage(hash);
  } else {
    showPage(query("#page-links").children[0].dataAttributes["page-id"]);
  }
  new RsvpWidget().decorate();
  //new Decoration().start();
}

void showPage(String pageSelector) {
  Element activeEl = query("li.active");
  if (activeEl != null) {
    activeEl.classes.remove("active");
  }
  queryAll(".page").forEach((Element el) {
    if (!el.classes.contains("transparent")) {
      el.classes.add("transparent");
      el.on.transitionEnd.add((e) {
        if (el.classes.contains("transparent")) {
          el.hidden = true;
        }
      });
    }
  });

  queryAll("#page-links li").forEach((Element el) {
    if (el.dataAttributes["page-id"] == pageSelector) {
      el.classes.add("active");
    }
  });
  Element shownPage = query("#$pageSelector");
  shownPage.hidden = false;
  window.setTimeout(() { shownPage.classes.remove("transparent"); }, 0);

  window.location.hash = pageSelector;
  window.scrollTo(0, 0);
}
