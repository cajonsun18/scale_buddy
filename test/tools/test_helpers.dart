import 'package:flutter/gestures.dart';

TapUpDetails createTapUpDetails(Offset offset) {
  return TapUpDetails(
    localPosition: offset,
    globalPosition: offset,
    kind: PointerDeviceKind.touch,
  );
}

DragStartDetails createDragStartDetails(Offset offset) {
  return DragStartDetails(localPosition: offset, globalPosition: offset);
}

DragUpdateDetails createDragUpdateDetails(
  Offset delta, {
  Offset localPosition = Offset.zero,
}) {
  return DragUpdateDetails(
    delta: delta,
    primaryDelta: null,
    globalPosition: localPosition,
    localPosition: localPosition,
  );
}
