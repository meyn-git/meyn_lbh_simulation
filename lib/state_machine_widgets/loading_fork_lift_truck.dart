import 'package:flutter/material.dart' as material;
import 'package:meyn_lbh_simulation/state_machine_widgets/layout.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/module_conveyor.dart';
import 'package:meyn_lbh_simulation/state_machine_widgets/state_machine.dart';

/// Unloads module stacks from a truck and puts them onto a in feed conveyor
class LoadingForkLiftTruck extends StateMachineCell {
  final CardinalDirection outFeedDirection;
  final ModuleGroup Function() createModuleGroup;

  LoadingForkLiftTruck({
    required Layout layout,
    required Position position,
    int? seqNr,
    required this.outFeedDirection,
    required this.createModuleGroup,
    Duration gettingStackFromTruckDuration =
        const Duration(seconds: 5), //TODO 30s?
    Duration putStackOnConveyorDuration =
        const Duration(seconds: 5), //TODO 15s?
  }) : super(
            layout: layout,
            position: position,
            seqNr: seqNr,
            initialState: GettingStackFromTruck(),
            inFeedDuration: gettingStackFromTruckDuration,
            outFeedDuration: putStackOnConveyorDuration);

  @override
  bool almostOkToFeedOut(CardinalDirection direction) => false;

  @override
  bool isFeedIn(CardinalDirection direction) => false;

  @override
  bool okToFeedIn(CardinalDirection direction) => false;

  @override
  bool isFeedOut(CardinalDirection direction) => false;

  @override
  bool okToFeedOut(CardinalDirection direction) => false;

  @override
  material.Widget get widget => material.Tooltip(
    message: toolTipText(),
    child: material.RotationTransition(
      turns: material.AlwaysStoppedAnimation(paintDirection.degrees/360),
      child: material.CustomPaint(painter: LoadingForkLiftTruckPainter()),
    ),
  );

  CompassDirection get paintDirection {
    if (currentState is GettingStackFromTruck) {
      return outFeedDirection.opposite.toCompassDirection();
    } else {
      return outFeedDirection.toCompassDirection();
    }
  }
}

class LoadingForkLiftTruckPainter extends material.CustomPainter {
  @override
  void paint(material.Canvas canvas, material.Size size) {
     var paint = material.Paint();
    paint.color = material.Colors.black;
    paint.style = material.PaintingStyle.stroke;
    var path=material.Path();

    path.moveTo(size.width*0.30, size.height *0.90);
    path.lineTo(size.width*0.30, size.height *0.50);
    path.lineTo(size.width*0.35, size.height *0.50);
     path.lineTo(size.width*0.35, size.height *0.10);
     path.lineTo(size.width*0.40, size.height *0.10);
     path.lineTo(size.width*0.40, size.height *0.50);
     path.lineTo(size.width*0.60, size.height *0.50);
     path.lineTo(size.width*0.60, size.height *0.10);
     path.lineTo(size.width*0.65, size.height *0.10);
     path.lineTo(size.width*0.65, size.height *0.50);
     path.lineTo(size.width*0.70, size.height *0.50);
     path.lineTo(size.width*0.70, size.height *0.90);
     path.quadraticBezierTo(
         size.width / 2, size.height, size.width*0.3, size.height * 0.9);
    path.close();
    canvas.drawPath(path, paint);
  }


  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => true;
}

/// driving to truck
/// unloading stack
/// driving to in feed conveyor
class GettingStackFromTruck extends DurationState<LoadingForkLiftTruck> {
  GettingStackFromTruck()
      : super(
            duration: (loadingForkLiftTruck) =>
                loadingForkLiftTruck.inFeedDuration,
            onCompleted: (loadingForkLiftTruck) {
              var newModuleGroup = loadingForkLiftTruck.createModuleGroup();
              _verifyDirections(
                loadingForkLiftTruck,
                loadingForkLiftTruck.outFeedDirection,
                newModuleGroup.doorDirection.toCardinalDirection()!,
              );
              _verifyDestination(
                  loadingForkLiftTruck, newModuleGroup.destination);
              loadingForkLiftTruck.layout.moduleGroups.add(newModuleGroup);
            },
            nextState: (loadingForkLiftTruck) => WaitingForEmptyConveyor());

  static _verifyDirections(
    LoadingForkLiftTruck loadingForkLiftTruck,
    CardinalDirection direction1,
    CardinalDirection direction2,
  ) {
    if (direction1.isParallelTo(direction2)) {
      throw ArgumentError(
          "${loadingForkLiftTruck.name}: outFeedDirection and moduleDoorDirection must be perpendicular in layout configuration.");
    }
  }

  static void _verifyDestination(
    LoadingForkLiftTruck loadingForkLiftTruck,
    Position destinationPosition,
  ) {
    var layout = loadingForkLiftTruck.layout;
    var destination = layout.cellForPosition(destinationPosition);
    if (destination is! StateMachineCell) {
      throw ArgumentError("stack.destination must point to a none empty cell");
    }
    var route = layout.findRoute(
        source: loadingForkLiftTruck, destination: destination);
    if (route == null) {
      throw ArgumentError(
          "${loadingForkLiftTruck.name} can not reach destination: $destinationPosition in layout configuration.");
    }
  }
}

class WaitingForEmptyConveyor extends State<LoadingForkLiftTruck> {
  @override
  State? process(LoadingForkLiftTruck loadingForkLiftTruck) {
    var outFeedNeighbouringCell = loadingForkLiftTruck.layout.neighbouringCell(
        loadingForkLiftTruck, loadingForkLiftTruck.outFeedDirection);
    bool neighbourCanFeedIn = outFeedNeighbouringCell
        .okToFeedIn(loadingForkLiftTruck.outFeedDirection.opposite);
    if (neighbourCanFeedIn) {
      return PutStackOnConveyor();
    }
  }
}

/// Drive module stack above in feed conveyor
/// lower stack on in feed conveyor and adjust when needed
/// drive backward to clear lifting spoons
/// push button to feed in
class PutStackOnConveyor extends DurationState<LoadingForkLiftTruck> {
  PutStackOnConveyor()
      : super(
            duration: (loadingForkLiftTruck) =>
                loadingForkLiftTruck.outFeedDuration,
            onCompleted: (loadingForkLiftTruck) {
              var neighbour = loadingForkLiftTruck.layout.neighbouringCell(
                  loadingForkLiftTruck, loadingForkLiftTruck.outFeedDirection);
              if (neighbour is ModuleConveyor) {
                var moduleGroup = loadingForkLiftTruck.moduleGroup;
                moduleGroup!.position = ModulePosition.forCel(
                    neighbour); //TODO change to transition
              } else {
                throw ArgumentError(
                    'The layout configuration must have a ModuleConveyor ${loadingForkLiftTruck.outFeedDirection} of ${loadingForkLiftTruck.name}');
              }
            },
            nextState: (loadingForkLiftTruck) => GettingStackFromTruck());
}
