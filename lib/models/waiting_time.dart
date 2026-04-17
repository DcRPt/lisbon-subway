class WaitingTime {
  final String destinationId;
  final List<int> arrivalsSeconds;

  const WaitingTime({
    required this.destinationId,
    required this.arrivalsSeconds,
  });

  List<int> get arrivalsMinutes =>
      arrivalsSeconds.map((s) => (s / 60).round()).toList();
}