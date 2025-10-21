class Item {
  final String bhajanName;
  final String artistName;
  final int identifier;
  final String url;

  Item(
      {required this.bhajanName,
        required this.artistName,
        required this.identifier,
        required this.url});
}

class Book {
  final String lyricsName;
  final String lyricsPath;
  Book({required this.lyricsName, required this.lyricsPath});
}
