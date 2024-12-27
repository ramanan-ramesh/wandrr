class AirlineData {
  String? airLineName, airLineCode, airLineNumber;

  AirlineData.empty();

  AirlineData(String transitCarrier) {
    var splitOptions = transitCarrier.split(' ');
    airLineName = splitOptions.first;
    airLineCode = splitOptions[1];
    airLineNumber = splitOptions[2];
  }

  @override
  String toString() {
    return '$airLineName $airLineCode $airLineNumber';
  }
}
