import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar Chart',
      home: MyHomePage(title: 'Radar Chart Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int nodes = 5;
  int segments = 4;

  late final AnimationController _controller = AnimationController(
    duration: Duration(seconds: 3),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // child: CustomPaint(
        //   painter: RadarChartPainter(_controller.value),
        // ),
        child: RadarChartTransition(_controller, nodes, segments),
      ),
    );
  }
}

class RadarChartTransition extends AnimatedWidget {
  final AnimationController controller;
  final int nodes;
  final int segments;

  // CONSTRUCTOR
  RadarChartTransition(
    this.controller,
    this.nodes,
    this.segments,
  ) : super(listenable: controller);

  // GETTER
  AnimationController get _animationController =>
      listenable as AnimationController;

  // TWEEN
  // tween sequence for popping effect
  TweenSequence<double> tweenSequence = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.1, end: 1)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ],
  );

  // function which returns the tween sequence as a part of the animation progress
  Animation<double> _tweenValue(start, end) {
    return tweenSequence.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          start,
          end,
          curve: Curves.ease,
        ),
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    // TODO: staggered animations with list of tweenSequences
    // Animation<double> tweenValueStaggered = tweenSequence.animate(
    //   CurvedAnimation(
    //     parent: _animationController,
    //     curve: Interval(
    //       0.33,
    //       0.66,
    //       curve: Curves.ease,
    //     ),
    //   ),
    // );
    // final tweenValueStaggered = _tweenValue(0.33, 0.66);
    // TODO: split progress (0-1) into phases
    // half the time for branches, half the time for nodes
    double phaseProgress = 1 / nodes;
    double branchPhaseProgress = 0.5 / nodes;
    double nodePhaseProgress = 0.5 / nodes;
    List<double> tweenValue = [];
    for (var i = 0; i < nodes; i++) {
      print(i);
      double startProgress = phaseProgress * i;
      double endProgress = phaseProgress * (i + 1);
      double tweenValueTemp = _tweenValue(startProgress, endProgress).value;
      tweenValue.add(tweenValueTemp);
    }

    // double tweenValue = tweenSequence.evaluate(_animationController);
    // double tweenValue1 = _tweenValue(0.33, 0.66).value;
    // double tweenValue2 = _tweenValue(0.67, 0.99).value;

    // tweenValue.add(tweenValue1);
    // tweenValue.add(tweenValue2);

    return CustomPaint(
      painter: RadarChartPainter(tweenValue, nodes, segments),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> animationProgress;
  // final double animationProgress;
  final int nodes;
  final int segments;

  RadarChartPainter(
    this.animationProgress,
    this.nodes,
    this.segments,
  );

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // List<TweenSequence<double>> tweenSequenceList = [];
    // for (int i = 0; i < nodes; i++) {
    //   tweenSequenceList.add(
    //     TweenSequence<double>(
    //       <TweenSequenceItem<double>>[
    //         TweenSequenceItem<double>(
    //           tween: Tween<double>(begin: 0, end: 1.1)
    //               .chain(CurveTween(curve: Curves.easeIn)),
    //           weight: 50,
    //         ),
    //         TweenSequenceItem<double>(
    //           tween: Tween<double>(begin: 1.1, end: 1)
    //               .chain(CurveTween(curve: Curves.bounceOut)),
    //           weight: 50,
    //         ),
    //       ],
    //     ),
    //   );
    // }
    final Offset centerPoint = Offset(0, 0);
    // print(animationProgress);
    // final double lineLength = 100 * animationProgress[0];
    // // paint styles
    // final lineStyle = Paint()
    //   ..strokeWidth = 3 * animationProgress[0]
    //   ..color = Colors.black;

    // math for each branch
    final angle = 360 / nodes;
    // list of branch end points (x,y)
    List<List<double>> points = [];
    // for each branch
    for (int i = 0; i < nodes; i++) {
      final double lineLength = 100 * animationProgress[i];
      // paint styles
      final lineStyle = Paint()
        ..strokeWidth = 3 * animationProgress[i]
        ..color = Colors.black;
      final nodeRadius = 5 * animationProgress[i];
      final nodeStyle = Paint()..color = Colors.black;

      if (i == 0) {
        // start at 12 o clock
        points.add([0, -lineLength]);
      } else {
        // everything else
        final currentAngle = i * angle * pi / 180;
        final x = lineLength * sin(currentAngle); // x
        final y = -lineLength * cos(currentAngle); // y
        points.add([x, y]);
      }
      // draw branch
      Offset endPoint = Offset(points[i][0], points[i][1]);
      canvas.drawLine(centerPoint, endPoint, lineStyle);
      // draw node
      canvas.drawCircle(endPoint, nodeRadius, nodeStyle);
    }

    // points

    // final endPoint = Offset(0, lineLength);
    // var endPoint = Offset(points[0][0], points[0][1]);

    // paint commands
    // canvas.drawLine(centerPoint, endPoint, lineStyle);
    // for (int i = 0; i < nodes; i++) {
    //   Offset endPoint = Offset(points[i][0], points[i][1]);
    //   canvas.drawLine(centerPoint, endPoint, lineStyle);
    // }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // hook called when CustomPainter is rebuilt
    // when to repaint, set to true if necessary
    return true;
  }
}
