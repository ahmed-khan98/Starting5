class MatchModel {
  final String time;
  final String opponent;
  final String address;

  MatchModel({required this.time, required this.opponent, required this.address});

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      time: json['time'] ?? "",
      opponent: json['location'] ?? "",
      // Cleans <p> and <strong> tags from the API response
      address: json['full_address'].toString().replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '').trim(),
    );
  }
}