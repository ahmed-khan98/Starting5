class Booking {
  final String bookingId;
  final String bookingStatus;
  final String bookingPrice;
  final String serviceName;
  final String startDate;
  final String endDate;
  final String coachName;
  final String appointmentId;

  Booking({
    required this.bookingId,
    required this.bookingStatus,
    required this.bookingPrice,
    required this.serviceName,
    required this.startDate,
    required this.endDate,
    required this.coachName,
    required this.appointmentId
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json["booking_id"].toString(),
      bookingStatus: json["booking_status"] ?? "",
      bookingPrice: json["booking_price"].toString(),

      serviceName:
      json["service"]?["name"] ?? "",

      startDate:
      json["appointment"]?["start_date"] ?? "",

      endDate:
      json["appointment"]?["end_date"] ?? "",

      coachName:
      "${json["employee"]?["first_name"] ?? ""} "
          "${json["employee"]?["last_name"] ?? ""}",

      appointmentId:
      json["appointment"]?["appointment_id"] ?? "",
    );
  }
}