import 'package:meyn_lbh_simulation/domain/area/direction.dart';
import 'package:meyn_lbh_simulation/domain/area/module.dart';
import 'package:meyn_lbh_simulation/domain/area/module_drawer_row_unloader.dart';
import 'package:meyn_lbh_simulation/domain/area/system.dart';
import 'package:meyn_lbh_simulation/gui/area/module_conveyor.dart';
import 'package:meyn_lbh_simulation/gui/area/shape.dart';
import 'package:meyn_lbh_simulation/gui/theme.dart';

class ModuleDrawerRowUnloaderPainter extends ShapePainter {
  ModuleDrawerRowUnloaderPainter(
      ModuleDrawerRowUnloader deStacker, LiveBirdsHandlingTheme theme)
      : super(shape: deStacker.shape, theme: theme);
}

class ModuleDrawerRowUnloaderShape extends CompoundShape {
  static const double feedOutConveyorLengthInMeters = 3.4;
  static const double drawerHandlingLengthInMeters = 2.5;
  late final OffsetInMeters centerToConveyorCenter;
  late final OffsetInMeters centerToDrawersOutLink;
  late final CompassDirection centerToFeedOutConveyorInLink;
  late final CompassDirection drawersOutLinkDirectionToOtherLink;
  late final OffsetInMeters centerToModuleGroupOutLink =
      centerToConveyorCenter.addY(feedOutConveyorLengthInMeters * -0.5);
  late final OffsetInMeters centerToModuleGroupInLink =
      centerToConveyorCenter.addY(feedOutConveyorLengthInMeters * 0.5);
  late final List<OffsetInMeters> centerToLiftConveyorDrawerCenters = [];

  ModuleDrawerRowUnloaderShape(ModuleDrawerRowUnloader unloader) {
    var northEastLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var southEastLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var southWestLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var northWestLeg = Box(xInMeters: 0.3, yInMeters: 0.3);
    var liftFrame =
        Box(xInMeters: 1.661, yInMeters: feedOutConveyorLengthInMeters);
    var westConveyorFrame = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: feedOutConveyorLengthInMeters);
    var conveyor = Box(
        xInMeters: ModuleConveyorShape.conveyorWidthInMeters,
        yInMeters: feedOutConveyorLengthInMeters);
    var eastConveyorFrame = Box(
        xInMeters: ModuleConveyorShape.frameWidthInMeters,
        yInMeters: feedOutConveyorLengthInMeters);
    var pusher = Box(xInMeters: 2.15, yInMeters: drawerHandlingLengthInMeters);

    link(liftFrame.centerCenter, conveyor.centerCenter);
    link(liftFrame.topRight, northEastLeg.topLeft);
    link(liftFrame.bottomRight, southEastLeg.bottomLeft);
    link(liftFrame.bottomLeft, southWestLeg.bottomRight);
    link(liftFrame.topLeft, northWestLeg.topRight);
    link(conveyor.centerLeft, westConveyorFrame.centerRight);
    link(conveyor.centerRight, eastConveyorFrame.centerLeft);
    if (unloader.drawersToLeft) {
      link(liftFrame.centerRight, pusher.centerLeft);
      centerToDrawersOutLink =
          topLefts[liftFrame]! + liftFrame.centerLeft - centerCenter;
      drawersOutLinkDirectionToOtherLink = const CompassDirection.west();
    } else {
      link(liftFrame.centerLeft, pusher.centerRight);
      centerToDrawersOutLink =
          topLefts[liftFrame]! + liftFrame.centerRight - centerCenter;
      drawersOutLinkDirectionToOtherLink = const CompassDirection.east();
    }

    centerToConveyorCenter =
        topLefts[conveyor]! + conveyor.centerCenter - centerCenter;
    var yDrawers = GrandeDrawerModuleType.drawerOutSideLengthInMeters *
        unloader.drawersPerRow *
        1.1;
    var yFromCenterInMeters = yDrawers /
        unloader.drawersPerRow *
        0.5 *
        (unloader.drawersToLeft ? 1 : -1);
    var yDistanceBetweenDrawersInMeters =
        yDrawers / unloader.drawersPerRow * (unloader.drawersToLeft ? -1 : 1);
    for (int i = 0; i < unloader.drawersPerRow; i++) {
      centerToLiftConveyorDrawerCenters.add(centerToConveyorCenter
          .addY(yFromCenterInMeters)
          .addY(yDistanceBetweenDrawersInMeters * i));
    }
  }
}

class ModuleDrawerRowUnloaderReceiverPainter extends ShapePainter {
  ModuleDrawerRowUnloaderReceiverPainter(
      ModuleDrawerRowUnloaderReceiver receiver, LiveBirdsHandlingTheme theme)
      : super(shape: receiver.shape, theme: theme);
}

class ModuleDrawerRowUnloaderReceiverShape extends CompoundShape {
  static const double widthInMeters = 2.5;
//  static const double moduleConveyorLengthInMeters = ;
  final double feedOutConveyorLengthInMeters = widthInMeters + 0.2 + 0.9;

  late final OffsetInMeters centerToConveyorCenter;

  // late final OffsetInMeters centerToModuleGroupOutLink =
  //     centerToConveyorCenter.addY(conveyorLengthInMeters * -0.5);
  // late final OffsetInMeters centerToModuleGroupInLink =
  //     centerToConveyorCenter.addY(conveyorLengthInMeters * 0.5);

  late final CompassDirection drawerOutLinkDirectionToOtherLink;
  late final OffsetInMeters centerToDrawersInLink;
  final CompassDirection drawersInLinkDirectionToOtherLink =
      const CompassDirection.south();
  late final List<OffsetInMeters> centerToReceivingConveyorDrawerCenters = [];
  late final List<OffsetInMeters> centerToCrossOverConveyorDrawerCenters = [];
  late final OffsetInMeters centerToFeedOutConveyorOutLink;
  late final OffsetInMeters centerToFeedOutConveyorInLink;

  ModuleDrawerRowUnloaderReceiverShape(
      ModuleDrawerRowUnloaderReceiver receiver) {
    var cover1 = Box(xInMeters: widthInMeters, yInMeters: 0.79);
    var cover2 = Box(xInMeters: widthInMeters, yInMeters: 1.5);
    var drawerConveyor = InvisibleBox(
        xInMeters: feedOutConveyorLengthInMeters,
        yInMeters: GrandeDrawerModuleType.drawerOutSideLengthInMeters);
    var platform = Box(xInMeters: widthInMeters, yInMeters: 0.975);

    link(cover1.topCenter, cover2.bottomCenter);
    link(cover2.topCenter, platform.bottomCenter);

    if (receiver.drawersToLeft) {
      link(cover2.topLeft.addX(-0.9), drawerConveyor.topLeft);
      centerToFeedOutConveyorInLink =
          topLefts[drawerConveyor]! + drawerConveyor.centerRight - centerCenter;
      centerToFeedOutConveyorOutLink =
          topLefts[drawerConveyor]! + drawerConveyor.centerLeft - centerCenter;
      drawerOutLinkDirectionToOtherLink = const CompassDirection.west();
    } else {
      link(cover2.topRight.addX(0.9), drawerConveyor.topRight);
      centerToFeedOutConveyorInLink =
          topLefts[drawerConveyor]! + drawerConveyor.centerLeft - centerCenter;
      centerToFeedOutConveyorOutLink =
          topLefts[drawerConveyor]! + drawerConveyor.centerRight - centerCenter;
      drawerOutLinkDirectionToOtherLink = const CompassDirection.east();
    }
    centerToDrawersInLink =
        topLefts[cover1]! + cover1.bottomCenter - centerCenter;

    var drawerOutSideLengthInMeters =
        GrandeDrawerModuleType.drawerOutSideLengthInMeters;
    var drawerSpacingInMeters = drawerOutSideLengthInMeters * 0.1;
    var drawerPitch = drawerSpacingInMeters + drawerOutSideLengthInMeters;
    var xDelta = drawerPitch * (receiver.drawersPerRow - 1);
    var xCenter = (topLefts[cover1]! + cover1.centerCenter).xInMeters;
    var xStart = xCenter - xDelta * 0.5;

    var yDrawerCenterStart = size.yInMeters - drawerOutSideLengthInMeters * 0.5;

    for (int i = 0; i < receiver.drawersPerRow; i++) {
      var x = xStart + drawerPitch * i;
      centerToReceivingConveyorDrawerCenters.add(OffsetInMeters(
            xInMeters: x,
            yInMeters: yDrawerCenterStart,
          ) -
          centerCenter);
      centerToCrossOverConveyorDrawerCenters.add(OffsetInMeters(
            xInMeters: x,
            yInMeters: (topLefts[drawerConveyor]! + drawerConveyor.centerCenter)
                .yInMeters,
          ) -
          centerCenter);
    }
  }
}
