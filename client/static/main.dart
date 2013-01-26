library grhungary;

import 'dart:html';
import "dart:math";
import 'dart:json';

part "decoration.dart";
part "rsvp_widget.dart";
part "photo_gallery_widget.dart";
part "main_widget.dart";

void main() {
  new RsvpWidget().decorate();
  new PhotoGalleryWidget().decorate();
  new MainWidget().decorate();
  //new Decoration().start();
}
