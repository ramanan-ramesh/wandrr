abstract class AirlinesDataServiceFacade {
  Future<List<(String airlineName, String airlineCode)>> queryAirlinesData(
      String airlineNameToSearch);
}
