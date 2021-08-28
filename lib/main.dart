import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_radarchart/data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: new ThemeData(scaffoldBackgroundColor: Colors.white),
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
  // int nodes = 5;
  // int segments = 4;
  // List<double> data = [0.7, 0.6, 0.5, 0.8, 0.75];
  // List<String> labels = ['A', 'B', 'C', 'D', 'E'];

  late final AnimationController _controller = AnimationController(
    duration: Duration(seconds: 3), // ANITIME
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
        // child: RadarChartTransition(_controller, nodes, segments, data, labels),
        child: RadarChartTransition(_controller, radarChartData),
      ),
    );
  }
}

class RadarChartTransition extends AnimatedWidget {
  final AnimationController controller;
  final int nodes;
  final int segments;
  final List<double> data;
  final List<String> labels;

  // CONSTRUCTOR
  RadarChartTransition(
    this.controller,
    RadarChartData radarChartData,
  )   : this.nodes = radarChartData.nodes,
        this.segments = radarChartData.segments,
        this.data = radarChartData.data,
        this.labels = radarChartData.labels,
        super(listenable: controller);

  // GETTER
  AnimationController get _animationController =>
      listenable as AnimationController;

  // TWEEN
  // tween sequence for popping effect
  final TweenSequence<double> poppingTweenSeq = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.5, end: 1)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 70,
      ),
    ],
  );

  // tween for fast to slow effect
  final Tween<double> easeOutTween = Tween(begin: 0, end: 1);

  // function which returns the tween sequence as a part of the animation progress
  Animation<double> _tweenSeqVal(start, end) {
    return poppingTweenSeq.animate(
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

  // function which returns the tween as part of the animation progress
  Animation<double> _tweenVal(start, end) {
    return easeOutTween.animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          start,
          end,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    if (data.length != nodes) {
      throw ('Data length and number of nodes are not equal!');
    }

    // half the time for branches, half the time for nodes and segments
    int totalSegments = segments * nodes;

    double branchPhaseProgress = 0.5 / nodes;
    double nodePhaseProgress = 0.5 / nodes;
    double segPhaseProgress = 0.5 / totalSegments;
    double polyPhaseProgress = 0.2 / totalSegments;
    double branchStartProg = 0;
    double nodeStartProg = 0.2;
    double segStartProg = 0.4;
    double polyStartProg = 0.8;

    // List of tween values for branches
    List<double> branchTweenVal = [];
    for (var i = 0; i < nodes; i++) {
      double startProgress = branchStartProg + branchPhaseProgress * i;
      double endProgress = branchStartProg + branchPhaseProgress * (i + 1);
      double tweenValueTemp = _tweenSeqVal(startProgress, endProgress).value;
      branchTweenVal.add(tweenValueTemp);
    }
    // List of tween values for nodes
    List<double> nodeTweenVal = [];
    for (var i = 0; i < nodes; i++) {
      double startProgress = nodeStartProg + nodePhaseProgress * i;
      double endProgress = nodeStartProg + nodePhaseProgress * (i + 1);
      double tweenValueTemp = _tweenSeqVal(startProgress, endProgress).value;
      nodeTweenVal.add(tweenValueTemp);
    }
    // List of tween values for segments
    // needs to be repeated for each layer of segment, for each branch

    List<double> segTweenVal = [];
    for (var j = 0; j < totalSegments; j++) {
      double startProgress = segStartProg + segPhaseProgress * j;
      double endProgress = segStartProg + segPhaseProgress * (j + 1);
      double tweenValueTemp = _tweenSeqVal(startProgress, endProgress).value;
      segTweenVal.add(tweenValueTemp);
    }

    double polyTweenVal =
        _tweenVal(polyStartProg, (polyStartProg + polyPhaseProgress)).value;

    return CustomPaint(
      painter: RadarChartPainter(branchTweenVal, nodeTweenVal, segTweenVal,
          polyTweenVal, nodes, segments, data, labels),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> branchAniProgress;
  final List<double> nodeAniProgress;
  final List<double> segAniProgress;
  final double polyAniProgress;
  final int nodes;
  final int segments;
  final List<double> data;
  final List<String> labels;

  RadarChartPainter(
    this.branchAniProgress,
    this.nodeAniProgress,
    this.segAniProgress,
    this.polyAniProgress,
    this.nodes,
    this.segments,
    this.data,
    this.labels,
  );

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Offset centerPoint = Offset(0, 0);

    // math for each branch
    final angle = 360 / nodes;
    // list of branch end points (x,y)
    List<List<double>> points = [];
    // for each branch
    for (int i = 0; i < nodes; i++) {
      final double lineLength = 100 * branchAniProgress[i];
      // paint styles
      // branch
      final lineStyle = Paint()
        ..strokeWidth = 3 * branchAniProgress[i]
        ..color = Colors.black;

      // node
      final nodeRadius = 5 * nodeAniProgress[i];
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

    // draw segments
    int totalSegments = segments * nodes;
    int i = 0;
    for (var j = 0; j < totalSegments; j++) {
      if (j >= 0 && j < nodes) {
        i++;
        if (i >= nodes) {
          i = 0;
        }
        continue; // skip nodes at center
      }
      // segment
      final segRadius = 2.5 * segAniProgress[j];
      // segment coord = offset branch (i) * segment no. (0, 1, 2, 3)
      final segStyle = Paint()..color = Colors.black;
      var segNo = (j / nodes).floor() / segments;
      Offset segPoint = Offset(points[i][0], points[i][1]) * segNo.toDouble();
      canvas.drawCircle(segPoint, segRadius, segStyle);
      i++;
      if (i >= nodes) {
        i = 0;
      }
    }

    // draw poly
    final polyStyle = Paint()
      ..strokeWidth = 2
      ..color = Colors.grey.withAlpha(100);
    List<Offset> dataOffsets = [];
    for (var i = 0; i < nodes; i++) {
      var temp = Offset(points[i][0], points[i][1]) * data[i] * polyAniProgress;
      dataOffsets.add(temp);
    }
    Path polyPath = Path();
    polyPath.addPolygon(dataOffsets, true);
    canvas.drawPath(polyPath, polyStyle);

    // draw labels
    double fontHeight = 12.0;
    TextStyle style = TextStyle(
      color: Colors.grey.withAlpha((255 * polyAniProgress).toInt()),
      fontSize: fontHeight,
      fontStyle: FontStyle.normal,
      fontWeight: FontWeight.normal,
      fontFamily: 'Open Sans',
    );

    for (var i = 0; i < nodes; i++) {
      final paraBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: style.fontSize,
        fontFamily: style.fontFamily,
        fontStyle: style.fontStyle,
        fontWeight: style.fontWeight,
        textAlign: TextAlign.center,
      ))
        ..pushStyle(style.getTextStyle());
      paraBuilder.addText(labels[i]);
      final ui.Paragraph labelPara = paraBuilder.build()
        ..layout(ui.ParagraphConstraints(width: size.width));
      var temp =
          Offset(points[i][0] - fontHeight / 4, points[i][1] - fontHeight / 2) *
              1.2;
      canvas.drawParagraph(labelPara, temp);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // hook called when CustomPainter is rebuilt
    // when to repaint, set to true if necessary
    return true;
  }
}
