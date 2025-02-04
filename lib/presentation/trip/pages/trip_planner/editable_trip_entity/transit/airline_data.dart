class AirlineData {
  String? airLineName, airLineCode, airLineNumber;

  AirlineData.empty();

  AirlineData(String transitCarrier) {
    var splitOptions = transitCarrier.split(' ');
    airLineNumber = splitOptions.last;
    airLineCode = splitOptions[splitOptions.length - 2];
    airLineName = splitOptions.sublist(0, splitOptions.length - 2).join(' ');
  }

  @override
  String toString() {
    return '$airLineName $airLineCode $airLineNumber';
  }
}
