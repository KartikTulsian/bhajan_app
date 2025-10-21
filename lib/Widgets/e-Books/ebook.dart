import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:hive/hive.dart';

class Book {
  final String name;
  final String author;
  final int pageCount;
  final int yearOfPublish;
  final String language;
  final String coverImageUrl;
  final String bookPath;

  Book({
    required this.name,
    required this.author,
    required this.pageCount,
    required this.yearOfPublish,
    required this.language,
    required this.coverImageUrl,
    required this.bookPath,
  });
}

class ebook extends StatelessWidget {
  final List<Book> books = [
    Book(
      name: 'Shree Shree Bijoy Krishna Goswami Jivan Darshan',
      author: 'Shree Mahesh Seth, Srimati Gita Seth',
      pageCount: 456,
      yearOfPublish: 2010,
      language: 'Gujarati',
      coverImageUrl: 'assets/images/jivandarshangujarati.jpg',
      bookPath: 'assets/ebooks/jivandarshangujrati.pdf',
    ),
    Book(
      name: 'Shree Shree Sadguru Sangha (Part 2)',
      author: 'Shree Shree Kuldananda Ji Brahmachari',
      pageCount: 198,
      yearOfPublish: 2014,
      language: 'Hindi',
      coverImageUrl: 'assets/images/sadgurusanghhindi2.jpg',
      bookPath: 'assets/ebooks/sadgurusangh2.pdf',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Books for Reading'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: GestureDetector(
              onTap: () {
                _navigateToBookDetails(context, books[index]);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    books[index].name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('By: ${books[index].author}'),
                      Text('Pages: ${books[index].pageCount}'),
                      Text('Year: ${books[index].yearOfPublish}'),
                      Text('Language: ${books[index].language}'),
                    ],
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      books[index].coverImageUrl,
                      // width: 60,
                      // height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToBookDetails(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
    );
  }
}

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  Box? _bookmarksBox;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _initBookmarks();
  }

  Future<void> _initBookmarks() async {
    try {
      if (!Hive.isBoxOpen('bookmarks')) {
        _bookmarksBox = await Hive.openBox('bookmarks');
      } else {
        _bookmarksBox = Hive.box('bookmarks');
      }

      // Load saved bookmark for this book
      final savedPage = _bookmarksBox?.get(widget.book.bookPath, defaultValue: 1);
      if (savedPage != null && savedPage > 1) {
        // Jump to saved page after a short delay to ensure PDF is loaded
        Future.delayed(Duration(milliseconds: 500), () {
          _pdfViewerController.jumpToPage(savedPage);
        });
      }
    } catch (e) {
      debugPrint('Error initializing bookmarks: $e');
    }
  }

  void _saveBookmark(int pageNumber, {bool showMessage = false}) {
    try {
      _bookmarksBox?.put(widget.book.bookPath, pageNumber);
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark saved at page $pageNumber'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.brown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving bookmark: $e');
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          // Save bookmark button
          IconButton(
            icon: Icon(Icons.bookmark_add),
            onPressed: () => _saveBookmark(_currentPage, showMessage: true),
            tooltip: 'Save Bookmark',
          ),
          // Page info
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '$_currentPage / $_totalPages',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SfPdfViewer.asset(
        widget.book.bookPath,
        controller: _pdfViewerController,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          setState(() {
            _totalPages = details.document.pages.count;
          });
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
          // Auto-save bookmark on page change
          _saveBookmark(_currentPage, showMessage: false);
        },
      ),
    );
  }
}