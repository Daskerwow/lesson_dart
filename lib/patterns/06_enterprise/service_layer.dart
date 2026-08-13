/// ============================================================================
/// ПАТТЕРН: SERVICE LAYER (Слой сервисов)
/// Категория: Корпоративный (Fowler, PoEAA)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет границу приложения через набор доступных операций и
/// координирует ответ на каждый запрос: делегирует работу доменным
/// объектам, но сам инкапсулирует оркестрацию транзакций, авторизацию
/// и координацию между несколькими репозиториями/доменными сервисами.
/// Controller (UI) вызывает Service Layer, не работая с репозиториями
/// или доменными объектами напрямую.
///
/// ОТЛИЧИЕ ОТ USE CASE (Clean Architecture): Service Layer обычно шире —
/// один сервис объединяет НЕСКОЛЬКО связанных операций (как класс с
/// методами), тогда как Use Case — обычно один класс на одну операцию.
/// Оба паттерна решают одну и ту же задачу — их выбор дело вкуса команды.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Backend-приложения с чёткой бизнес-логикой "выше" простого CRUD:
///   сервис координирует несколько репозиториев и внешних систем
///   (платежи, email, файловое хранилище) в рамках одной операции.
library;

class Book {
  final String isbn;
  final String title;
  int availableCopies;
  Book(this.isbn, this.title, this.availableCopies);
}

class Loan {
  final String id;
  final String isbn;
  final String memberId;
  final DateTime dueDate;
  bool isReturned;
  Loan(
    this.id,
    this.isbn,
    this.memberId,
    this.dueDate, {
    this.isReturned = false,
  });
}

/// Репозитории — низкоуровневый доступ к данным, без бизнес-правил.
class BookRepository {
  final Map<String, Book> _books = {
    '978-1': Book('978-1', 'Чистая архитектура', 2),
    '978-2': Book('978-2', 'Паттерны проектирования', 1),
  };
  Book? findByIsbn(String isbn) => _books[isbn];
  void save(Book book) => _books[book.isbn] = book;
}

class LoanRepository {
  final Map<String, Loan> _loans = {};
  final List<Loan> _activeLoans = [];
  void save(Loan loan) {
    _loans[loan.id] = loan;
    if (!loan.isReturned) _activeLoans.add(loan);
  }

  List<Loan> findActiveByMember(String memberId) =>
      _activeLoans.where((l) => l.memberId == memberId).toList();
  Loan? findById(String id) => _loans[id];
}

/// Внешняя система уведомлений (email/push) — сервис координирует
/// вызов к ней как часть бизнес-операции.
class NotificationGateway {
  void sendDueDateReminder(
    String memberId,
    String bookTitle,
    DateTime dueDate,
  ) {
    print('[Notify] $memberId: не забудьте вернуть "$bookTitle" до $dueDate');
  }
}

/// SERVICE LAYER: единая точка входа для операций библиотеки. Контроллер
/// (UI/API-роут) работает ИСКЛЮЧИТЕЛЬНО через LibraryService, не трогая
/// репозитории напрямую — это и есть определяемая сервисом граница приложения.
class LibraryService {
  final BookRepository bookRepo;
  final LoanRepository loanRepo;
  final NotificationGateway notificationGateway;

  static const int maxActiveLoans = 3;
  static const int loanPeriodDays = 14;

  LibraryService(this.bookRepo, this.loanRepo, this.notificationGateway);

  /// Одна операция сервиса координирует ДВА репозитория и бизнес-правила,
  /// которые не принадлежат ни Book, ни Loan по отдельности.
  Loan checkoutBook(String isbn, String memberId) {
    final book = bookRepo.findByIsbn(isbn);
    if (book == null) {
      throw ArgumentError('Книга с ISBN $isbn не найдена');
    }
    if (book.availableCopies <= 0) {
      throw StateError('Нет доступных экземпляров книги "${book.title}"');
    }

    final activeLoans = loanRepo.findActiveByMember(memberId);
    if (activeLoans.length >= maxActiveLoans) {
      throw StateError('Превышен лимит активных займов ($maxActiveLoans)');
    }

    book.availableCopies--;
    bookRepo.save(book);

    final loan = Loan(
      'loan_${DateTime.now().millisecondsSinceEpoch}',
      isbn,
      memberId,
      DateTime.now().add(const Duration(days: loanPeriodDays)),
    );
    loanRepo.save(loan);

    print(
      '[Service] Книга "${book.title}" выдана участнику $memberId '
      'до ${loan.dueDate.toIso8601String().split("T").first}',
    );

    return loan;
  }

  void returnBook(String loanId) {
    final loan = loanRepo.findById(loanId);
    if (loan == null || loan.isReturned) {
      throw ArgumentError('Займ $loanId не найден или уже закрыт');
    }
    loan.isReturned = true;
    final book = bookRepo.findByIsbn(loan.isbn);
    if (book != null) {
      book.availableCopies++;
      bookRepo.save(book);
    }
    print('[Service] Книга по займу $loanId возвращена');
  }

  void sendDueDateReminders(String memberId) {
    final loans = loanRepo.findActiveByMember(memberId);
    for (final loan in loans) {
      final book = bookRepo.findByIsbn(loan.isbn);
      if (book != null) {
        notificationGateway.sendDueDateReminder(
          memberId,
          book.title,
          loan.dueDate,
        );
      }
    }
  }
}

void main() {
  final service = LibraryService(
    BookRepository(),
    LoanRepository(),
    NotificationGateway(),
  );

  final loan = service.checkoutBook('978-1', 'member_42');
  service.sendDueDateReminders('member_42');
  service.returnBook(loan.id);

  try {
    service.checkoutBook('978-2', 'member_42');
    service.checkoutBook('978-2', 'member_42'); // второй экземпляр уже занят
  } on StateError catch (e) {
    print('Ошибка бизнес-правила: $e');
  }
}
