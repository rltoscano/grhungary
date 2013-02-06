library grhungary;

import "dart:async";
import "dart:html";
import "dart:math";
import "dart:json" as json;
import "package:js/js.dart" as js;

part "page_widget.dart";
part "decoration.dart";
part "rsvp_widget.dart";
part "gallery_image.dart";
part "photo_gallery_widget.dart";
part "main_widget.dart";

void main() {
  new MainWidget().decorate();
}
