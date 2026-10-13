/// NewsAPI headline categories, business first since this is a
/// business-intelligence app.
enum NewsCategory {
  business,
  technology,
  general,
  science,
  health,
  entertainment,
  sports;

  String get label => name[0].toUpperCase() + name.substring(1);

  /// Value sent to the API's `category` parameter.
  String get apiValue => name;
}
