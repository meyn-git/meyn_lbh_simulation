import 'package:collection/collection.dart';

enum LiftPosition {
  // conveyor with a single module is in top position of destacker
  // to put the module on the supports or to get the module from the supports
  singleModuleAtSupports,
  // conveyor with two stacked modules is in the middule position of destacker
  // to put the top module on the supports or to get the top module from the supports
  topModuleAtSupport,
  inFeed,
  outFeed,
}

class DefaultLiftPositionHeights extends DelegatingMap<LiftPosition, double> {
  static const double inAndOutFeedHeightInMeters = 1.0;
  static const double containerHeightInMeters = 1.5;
  static const double clearanceHeightInMeters = 0.5;

  const DefaultLiftPositionHeights()
    : super(const {
        LiftPosition.inFeed: inAndOutFeedHeightInMeters,
        LiftPosition.outFeed: inAndOutFeedHeightInMeters,
        LiftPosition.topModuleAtSupport:
            inAndOutFeedHeightInMeters + clearanceHeightInMeters,
        LiftPosition.singleModuleAtSupports:
            inAndOutFeedHeightInMeters +
            clearanceHeightInMeters +
            containerHeightInMeters,
      });
}
