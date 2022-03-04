enum DomTag {
  div,
  span,
}

/// Units of measurement
///
/// [MeasuringUnit.pixel] means values will be translated to px
/// [MeasuringUnit.percent] means values will be translated to %
///
enum MeasuringUnit {
  pixel,
  percent,
}

/// Defines [GestureDetector] behaviour
enum HitTestBehavior {
  /// Child gesture detectors will receive events and won't let them propagate to parents
  deferToChild,

  /// Receive events and prevent child gesture detectors from receiving events.
  opaque,

  /// All detectors that are hit will receive events.
  translucent,
}

/// Type of margin.
///
/// Setting margin to zero can be problem in some layouts. Therefore
/// we try to set only side whos values are provided by the user. Remaining
/// sides are ignored.
///
enum MarginType {
  only,
  symmetric,
  allSame,
  allDifferent,
}

/// Type of padding.
///
enum PaddingType {
  only,
  symmetric,
  allSame,
  allDifferent,
}

/// Type of route entry.
///
enum RouterStackEntryType {
  push,
}
