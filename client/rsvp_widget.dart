part of grhungary;

class RsvpInsertRequest {
  String id;
  List<String> partyMembers;
  String dietaryRestrictions;
  bool isStayingOvernight;
  String interestedInSightseeing;
  bool isAccepted;

  Object toJson() {
    Map map = new Map();
    map["Id"] = id;
    map["PartyMembers"] = partyMembers;
    map["DietaryRestrictions"] = dietaryRestrictions;
    map["IsStayingOvernight"] = isStayingOvernight;
    map["InterestedInSightseeing"] = interestedInSightseeing;
    map["IsAccepted"] = isAccepted;
    return map;
  }
}

class RsvpWidget extends PageWidget {
  HttpRequest _reqInProgress;
  Element _infoEl;
  Element _moreInfo;

  void decorate(Element e) {
    super.decorate(e);
    query("#rsvp-send-button").onClick.listen(_onSendClick);
    query("#rsvp-add-name-button").onClick.listen(_onAddNameClick);
    query("#accept-button").onClick.listen(_onAcceptClick);
    query("#reject-button").onClick.listen(_onRejectClick);
    query("#rsvp-cancel-button").onClick.listen(_onCancelClick);
    _moreInfo = query("#rsvp-more-info");
    _moreInfo.onTransitionEnd.listen(_onMoreInfoTransitionEnd);
    _infoEl = query("#rsvp-info-element");
    _infoEl.onTransitionEnd.listen(_onInfoElTransitionEnd);
  }

  void _showMessage(String type, String msg, [int duration = 10000]) {
    _infoEl.innerHtml = msg;
    _infoEl.classes.remove("info");
    _infoEl.classes.remove("error");
    _infoEl.classes.add(type);
    _infoEl.hidden = false;
    window.setImmediate(() { _infoEl.classes.remove("transparent"); });
    if (type == "info") {
      new Timer(
          new Duration(milliseconds: duration),
          () { _infoEl.classes.add("transparent"); });
    }
  }

  void _setSendButtonState(bool isInProgress) {
    ButtonElement sendButton = query("#rsvp-send-button");
    if (isInProgress) {
      sendButton.text = sendButton.dataset["label-in-progress"];
    } else {
      sendButton.text = sendButton.dataset["label"];
    }

    ButtonElement rejectButton = query("#reject-button");
    if (isInProgress) {
      rejectButton.text = rejectButton.dataset["label-in-progress"];
    } else {
      rejectButton.text = rejectButton.dataset["label"];
    }

    sendButton.disabled = isInProgress;
    rejectButton.disabled = isInProgress;
    (query("#rsvp-cancel-button") as ButtonElement).disabled = isInProgress;
    (query("#accept-button") as ButtonElement).disabled = isInProgress;
  }

  void _sendRsvp() {
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
    rsvp.interestedInSightseeing =
        (query("#rsvp-interested-in-sightseeing") as SelectElement)
        .selectedOptions[0].dataset["value"];
    rsvp.isAccepted = query("#reject-button").hidden;

    _reqInProgress = new HttpRequest();
    _reqInProgress.onLoad.listen(_onRsvpUpsertSuccess);
    _reqInProgress.onError.listen(_onRsvpUpsertFail);
    _reqInProgress.open("POST", "/api/rsvp/create");
    _reqInProgress.send(json.stringify(rsvp));
    js.scoped(() {
      js.context["_gaq"].push(js.array(["_trackEvent", "Rsvp", "start"]));
    });
  }

  void _onSendClick(Event e) {
    _setSendButtonState(true);
    _sendRsvp();
  }

  void _onRsvpUpsertSuccess(Event e) {
    if (_reqInProgress.status == 200) {
      if (query("#reject-button").hidden) {
        _showMessage(
            "info",
            query("#rsvp-info-element").dataset["success-message"]);
      } else {
        _showMessage(
            "info",
            query("#rsvp-info-element")
                .dataset["success-reject-message"],
            12000);
      }
      js.scoped(() {
        js.context["_gaq"].push(js.array(["_trackEvent", "Rsvp", "success"]));
      });
    } else {
      _onRsvpUpsertFail(e);
    }
    _setSendButtonState(false);
  }

  void _onRsvpUpsertFail(Event e) {
    js.scoped(() {
      js.context["_gaq"].push(js.array(["_trackEvent", "Rsvp", "error"]));
    });
    _showMessage(
        "error", query("#rsvp-info-element").dataset["fail-message"]);
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

  void _onAcceptClick(Event _) {
    _moreInfo.hidden = false;
    int height = query("#rsvp-more-info-height-wrapper").offsetHeight;
    _moreInfo.style.height = "${height}px";
    query("#accept-button").hidden = true;
    query("#reject-button").hidden = true;
    query("#rsvp-send-button").hidden = false;
    query("#rsvp-cancel-button").hidden = false;
  }

  void _onRejectClick(Event _) {
    _setSendButtonState(true);
    _sendRsvp();
  }

  void _onCancelClick(Event _) {
    int height = query("#rsvp-more-info-height-wrapper").offsetHeight;
    _moreInfo.style.height = "${height}px";
    window.setImmediate(() {
      _moreInfo.classes.add("height-transition");
      _moreInfo.style.height = "0";
    });
    query("#accept-button").hidden = false;
    query("#reject-button").hidden = false;
    query("#rsvp-send-button").hidden = true;
    query("#rsvp-cancel-button").hidden = true;
  }

  void _onMoreInfoTransitionEnd(Event _) {
    if (_moreInfo.offsetHeight == 0) {
      _moreInfo.hidden = true;
    } else {
      _moreInfo.classes.remove("height-transition");
      _moreInfo.style.height = "auto";
    }
  }
}
