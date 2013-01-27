part of grhungary;

class RsvpInsertRequest {
  String id;
  List<String> partyMembers;
  String dietaryRestrictions;
  bool isStayingOvernight;
  String durationDaysCount;

  Object toJson() {
    Map map = new Map();
    map["Id"] = id;
    map["PartyMembers"] = partyMembers;
    map["DietaryRestrictions"] = dietaryRestrictions;
    map["IsStayingOvernight"] = isStayingOvernight;
    map["DurationDaysCount"] = durationDaysCount;
    return map;
  }
}

class RsvpWidget {
  HttpRequest _reqInProgress;
  Element _infoEl;

  void decorate() {
    query("#rsvp-send-button").on.click.add(_onSendClick);
    query("#rsvp-add-name-button").on.click.add(_onAddNameClick);
    _infoEl = query("#rsvp-info-element");
    _infoEl.on.transitionEnd.add(_onInfoElTransitionEnd);
  }

  void _showMessage(String type, String msg) {
    _infoEl.innerHtml = msg;
    _infoEl.classes.remove("info");
    _infoEl.classes.remove("error");
    _infoEl.classes.add(type);
    _infoEl.hidden = false;
    window.setTimeout(() { _infoEl.classes.remove("transparent"); }, 0);
    if (type == "info") {
      window.setTimeout(() {
        _infoEl.classes.add("transparent");
      }, 6000);
    }
  }

  void _setSendButtonState(bool isInProgress) {
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

  void _onSendClick(Event e) {
    _setSendButtonState(true);

    RsvpInsertRequest rsvp = new RsvpInsertRequest();
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

    _reqInProgress = new HttpRequest();
    _reqInProgress.on.load.add(_onRsvpUpsertSuccess);
    _reqInProgress.on.error.add(_onRsvpUpsertFail);
    _reqInProgress.open("POST", "/api/rsvp/create");
    _reqInProgress.send(json.stringify(rsvp));
    js.scoped(() {
      js.context["_gaq"].push(js.array(["_trackEvent", "Rsvp", "start"]));
    });
  }

  void _onRsvpUpsertSuccess(Event e) {
    if (_reqInProgress.status == 200) {
      _showMessage(
          "info",
          query("#rsvp-info-element").dataAttributes["success-message"]);
      _setSendButtonState(false);
      js.scoped(() {
        js.context["_gaq"].push(js.array(["_trackEvent", "Rsvp", "success"]));
      });
    } else {
      _onRsvpUpsertFail(e);
    }
  }

  void _onRsvpUpsertFail(Event e) {
    js.scoped(() {
      js.context["_gaq"].push(js.array(["_trackEvent", "Rsvp", "error"]));
    });
    _showMessage(
        "error", query("#rsvp-info-element").dataAttributes["fail-message"]);
    _setSendButtonState(false);
  }

  void _onAddNameClick(Event e) {
    TextInputElement child = new TextInputElement();
    child.classes.add("rsvp-name");
    Element rsvpNames = query("#rsvp-names");
    rsvpNames.children.add(new BRElement());
    rsvpNames.children.add(child);
  }

  void _onInfoElTransitionEnd(Event _) {
    if (_infoEl.classes.contains("transparent")) {
      _infoEl.hidden = true;
    }
  }
}
