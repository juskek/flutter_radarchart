class RadarChartData {
  int nodes, segments;
  List<double> data;
  List<String> labels;

  RadarChartData(
    this.nodes,
    this.segments,
    this.data,
    this.labels,
  );
}

RadarChartData radarChartData = RadarChartData(
  5,
  4,
  [0.7, 0.6, 0.5, 0.8, 0.75],
  ['A', 'B', 'C', 'D', 'E'],
);
