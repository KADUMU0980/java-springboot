# Library App — A Spring Boot Project for Managing Books and Authors

## About This Document

This write-up walks through my approach to building a full-stack web application using the Spring Boot framework. I picked **Books** and **Authors** as my two domain objects because libraries are something most people intuitively understand, and the parent-child dynamic between a writer and their published works maps naturally to a relational database schema.

---

## How I Designed the Data Model

Before writing any code, I sketched out what information each table should hold and how they connect.

**Authors table** stores three columns:

| Column      | Type           | Notes                        |
|-------------|----------------|------------------------------|
| `id`        | BIGINT (auto)  | Surrogate primary key        |
| `name`      | VARCHAR        | Cannot be left blank         |
| `biography` | VARCHAR(1000)  | Optional short bio           |

**Books table** stores five columns:

| Column             | Type           | Notes                                  |
|--------------------|----------------|----------------------------------------|
| `id`               | BIGINT (auto)  | Surrogate primary key                  |
| `title`            | VARCHAR        | Cannot be left blank                   |
| `isbn`             | VARCHAR        | Must be unique across all rows         |
| `publication_year` | INT            | Validated to be ≥ 1000                 |
| `author_id`        | BIGINT (FK)    | Points back to the authors table       |

The cardinality is straightforward: a single author may have written several books, but every book row references exactly one author. In database terms this is a classic **one-to-many** association, with the foreign key living on the "many" side (books).

```
┌─────────────────────┐         ┌───────────────────────────────┐
│      AUTHORS        │         │           BOOKS               │
├─────────────────────┤         ├───────────────────────────────┤
│ id          (PK)    │───┐     │ id               (PK)        │
│ name                │   │     │ title                        │
│ biography           │   │     │ isbn             (UNIQUE)    │
└─────────────────────┘   │     │ publication_year              │
                          └────▶│ author_id        (FK)        │
                        1    N  └───────────────────────────────┘
```

---

## Setting Up the Project

I bootstrapped the skeleton through Spring Initializr, requesting the following starter modules:

* **spring-boot-starter-web** — gives me an embedded Tomcat and Spring MVC
* **spring-boot-starter-data-jpa** — wires up Hibernate as the JPA provider
* **spring-boot-starter-validation** — enables `@NotBlank`, `@Min`, etc.
* **h2** — lightweight in-memory database, great for demos
* **tomcat-embed-jasper** plus the Jakarta JSTL jars — needed so that `.jsp` files actually compile and render

My `application.properties` ended up looking like this:

```properties
spring.application.name=library-app

spring.datasource.url=jdbc:h2:mem:librarydb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=password
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect

spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

spring.jpa.hibernate.ddl-auto=create-drop
spring.sql.init.mode=always
spring.jpa.defer-datasource-initialization=true

spring.mvc.view.prefix=/WEB-INF/jsp/
spring.mvc.view.suffix=.jsp
```

Two lines deserve special attention. `ddl-auto=create-drop` tells Hibernate to recreate the schema every time the app boots — perfect during development. And `defer-datasource-initialization=true` makes sure my seed data script (`data.sql`) runs *after* the tables exist, not before.

---

## Writing the Entity Classes

### Author.java

I annotated this class so Hibernate knows to map it to the `authors` table. The `@OneToMany` annotation on the `books` field tells JPA that the inverse side of the relationship lives here, while `Book.author` is the owning side.

```java
@Entity
@Table(name = "authors")
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Name is mandatory")
    @Column(nullable = false)
    private String name;

    @Column(length = 1000)
    private String biography;

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL,
               fetch = FetchType.LAZY)
    private List<Book> books;

    public Author() {}

    public Author(String name, String biography) {
        this.name = name;
        this.biography = biography;
    }

    // getters and setters follow
}
```

### Book.java

On this side I used `@ManyToOne` together with `@JoinColumn` to declare the foreign key. The ISBN column carries a uniqueness constraint so that two books can never share the same ISBN, and the year field has a `@Min` guard.

```java
@Entity
@Table(name = "books")
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Title is mandatory")
    @Column(nullable = false)
    private String title;

    @NotBlank(message = "ISBN is mandatory")
    @Column(unique = true, nullable = false)
    private String isbn;

    @NotNull(message = "Publication year is mandatory")
    @Min(value = 1000, message = "Invalid year")
    @Column(name = "publication_year")
    private Integer publicationYear;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "author_id", nullable = false)
    private Author author;

    public Book() {}

    public Book(String title, String isbn,
                Integer publicationYear, Author author) {
        this.title = title;
        this.isbn = isbn;
        this.publicationYear = publicationYear;
        this.author = author;
    }

    // getters and setters follow
}
```

---

## Repository Interfaces

Spring Data JPA generates the boilerplate CRUD logic at runtime — I only need to declare interfaces.

### AuthorRepository.java

```java
@Repository
public interface AuthorRepository extends JpaRepository<Author, Long> {
}
```

Nothing fancy here; the built-in `findAll()` and `findById()` methods are sufficient for authors.

### BookRepository.java — with a custom join query

```java
@Repository
public interface BookRepository extends JpaRepository<Book, Long> {

    @Query("SELECT b FROM Book b JOIN FETCH b.author")
    List<Book> findAllBooksWithAuthors();
}
```

I wrote this JPQL by hand because the default `findAll()` would lazily load each author one at a time (the so-called N+1 trap). By adding `JOIN FETCH`, Hibernate emits a single SQL statement that inner-joins both tables and hydrates every `Book` object with its corresponding `Author` in one round trip.

---

## Service Layer

### AuthorService.java

```java
@Service
public class AuthorService {

    private final AuthorRepository authorRepository;

    @Autowired
    public AuthorService(AuthorRepository authorRepository) {
        this.authorRepository = authorRepository;
    }

    public List<Author> findAllAuthors() {
        return authorRepository.findAll();
    }

    public Author findById(Long id) {
        return authorRepository.findById(id)
            .orElseThrow(() ->
                new IllegalArgumentException("Invalid author Id:" + id));
    }

    @Transactional
    public Author saveAuthor(Author author) {
        return authorRepository.save(author);
    }
}
```

### BookService.java

```java
@Service
public class BookService {

    private final BookRepository bookRepository;

    @Autowired
    public BookService(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    public List<Book> findAllBooks() {
        return bookRepository.findAllBooksWithAuthors();
    }

    public Book findById(Long id) {
        return bookRepository.findById(id)
            .orElseThrow(() ->
                new IllegalArgumentException("Invalid book Id:" + id));
    }

    @Transactional
    public Book saveBook(Book book) {
        try {
            return bookRepository.save(book);
        } catch (Exception e) {
            throw new RuntimeException(
                "Could not save book. Please ensure ISBN is unique "
                + "and data is valid.", e);
        }
    }
}
```

I wrapped the `save()` call inside a try-catch specifically to intercept situations where a user tries to insert a duplicate ISBN. Rather than letting a raw Hibernate exception bubble up to the browser, the service re-throws a friendlier message that the controller can display on the form page.

---

## Controller — Routing HTTP Requests

```java
@Controller
@RequestMapping("/")
public class LibraryController {

    private final BookService bookService;
    private final AuthorService authorService;

    @Autowired
    public LibraryController(BookService bookService,
                             AuthorService authorService) {
        this.bookService = bookService;
        this.authorService = authorService;
    }

    @GetMapping
    public String index() {
        return "redirect:/books";
    }

    @GetMapping("/books")
    public String listBooks(Model model) {
        model.addAttribute("books", bookService.findAllBooks());
        return "book-list";
    }

    @GetMapping("/books/add")
    public String showAddForm(Model model) {
        model.addAttribute("book", new Book());
        model.addAttribute("authors", authorService.findAllAuthors());
        return "book-form";
    }

    @GetMapping("/books/edit/{id}")
    public String showUpdateForm(@PathVariable("id") Long id,
                                 Model model) {
        Book book = bookService.findById(id);
        model.addAttribute("book", book);
        model.addAttribute("authors", authorService.findAllAuthors());
        return "book-form";
    }

    @PostMapping("/books/save")
    public String saveBook(
            @Valid @ModelAttribute("book") Book book,
            BindingResult result,
            Model model,
            RedirectAttributes redirectAttributes) {

        if (result.hasErrors()) {
            model.addAttribute("authors",
                               authorService.findAllAuthors());
            return "book-form";
        }

        try {
            bookService.saveBook(book);
            redirectAttributes.addFlashAttribute(
                "successMessage", "Book saved successfully!");
        } catch (RuntimeException e) {
            model.addAttribute("errorMessage", e.getMessage());
            model.addAttribute("authors",
                               authorService.findAllAuthors());
            return "book-form";
        }

        return "redirect:/books";
    }
}
```

A quick summary of each endpoint:

| Verb | Path               | What it does                                    |
|------|--------------------|-------------------------------------------------|
| GET  | `/`                | Redirects the user straight to the book listing |
| GET  | `/books`           | Fetches every book (with authors) and renders the list view |
| GET  | `/books/add`       | Serves a blank form for creating a new book     |
| GET  | `/books/edit/{id}` | Serves a pre-filled form for modifying a book   |
| POST | `/books/save`      | Validates and persists the submitted book data  |

---

## JSP Views

### book-list.jsp

This page pulls the `books` collection out of the model and iterates over it with JSTL's `<c:forEach>`. Each row shows the book's title, its author's name (accessed through `${book.author.name}`), the ISBN, and the publication year. An "Edit" link on every row lets the user jump to the update form.

```jsp
<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<html>
<head><title>Library - Book List</title></head>
<body>
  <div class="container">
    <h1>Library Management System</h1>
    <c:if test="${not empty successMessage}">
      <div class="alert alert-success">${successMessage}</div>
    </c:if>
    <a href="<c:url value='/books/add' />" class="btn">Add New Book</a>
    <table>
      <thead>
        <tr>
          <th>ID</th><th>Title</th><th>Author</th>
          <th>ISBN</th><th>Year</th><th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <c:forEach var="book" items="${books}">
          <tr>
            <td>${book.id}</td>
            <td>${book.title}</td>
            <td>${book.author.name}</td>
            <td>${book.isbn}</td>
            <td>${book.publicationYear}</td>
            <td><a href="<c:url value='/books/edit/${book.id}'/>"
                   class="btn btn-edit">Edit</a></td>
          </tr>
        </c:forEach>
      </tbody>
    </table>
  </div>
</body>
</html>
```

### book-form.jsp

I reused one JSP for both "add" and "edit" modes. The Expression Language snippet `${empty book.id ? 'Add New Book' : 'Edit Book'}` dynamically switches the page heading. A hidden field carries the book's ID so that Hibernate can distinguish between an INSERT (id is null) and an UPDATE (id exists).

```jsp
<%@ page language="java" contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<html>
<head><title>Library - Book Form</title></head>
<body>
  <div class="container">
    <h1>${empty book.id ? 'Add New Book' : 'Edit Book'}</h1>
    <c:if test="${not empty errorMessage}">
      <div class="alert alert-danger">${errorMessage}</div>
    </c:if>
    <form action="<c:url value='/books/save' />" method="post">
      <input type="hidden" name="id" value="${book.id}">
      <div class="form-group">
        <label>Title:</label>
        <input type="text" name="title"
               value="${book.title}" required>
      </div>
      <div class="form-group">
        <label>Author:</label>
        <select name="author.id" required>
          <option value="">-- Pick an author --</option>
          <c:forEach var="a" items="${authors}">
            <option value="${a.id}"
              ${book.author != null && book.author.id == a.id
                ? 'selected' : ''}>${a.name}</option>
          </c:forEach>
        </select>
      </div>
      <div class="form-group">
        <label>ISBN:</label>
        <input type="text" name="isbn"
               value="${book.isbn}" required>
      </div>
      <div class="form-group">
        <label>Publication Year:</label>
        <input type="number" name="publicationYear"
               value="${book.publicationYear}" required>
      </div>
      <button type="submit" class="btn">Save</button>
      <a href="<c:url value='/books'/>"
         class="btn btn-cancel">Cancel</a>
    </form>
  </div>
</body>
</html>
```

---

## Populating the Database with Sample Rows

I placed a file called `data.sql` inside `src/main/resources`. Spring Boot picks it up automatically after Hibernate finishes creating the tables.

```sql
INSERT INTO authors (name, biography) VALUES
  ('J.K. Rowling',        'British author, best known for the Harry Potter series.'),
  ('George R.R. Martin',  'American novelist in the fantasy genre.'),
  ('J.R.R. Tolkien',      'English writer behind The Hobbit and The Lord of the Rings.'),
  ('Agatha Christie',     'English writer known for her detective novels.'),
  ('Stephen King',        'American author of horror and suspense novels.'),
  ('Isaac Asimov',        'American writer and professor known for science fiction.'),
  ('Jane Austen',         'English novelist of the late 18th century.'),
  ('Charles Dickens',     'English writer and social critic.'),
  ('Mark Twain',          'American writer and humorist.'),
  ('Arthur Conan Doyle',  'British writer who created Sherlock Holmes.');

INSERT INTO books (title, isbn, publication_year, author_id) VALUES
  ('Harry Potter and the Sorcerers Stone', '978-0590353403', 1997, 1),
  ('A Game of Thrones',                    '978-0553103540', 1996, 2),
  ('The Fellowship of the Ring',           '978-0618346257', 1954, 3),
  ('Murder on the Orient Express',         '978-0007119318', 1934, 4),
  ('The Shining',                          '978-0385121675', 1977, 5),
  ('Foundation',                           '978-0553293357', 1951, 6),
  ('Pride and Prejudice',                  '978-0141439518', 1813, 7),
  ('A Tale of Two Cities',                 '978-0141439600', 1859, 8),
  ('The Adventures of Tom Sawyer',         '978-0143039563', 1876, 9),
  ('The Hound of the Baskervilles',        '978-0140437867', 1902, 10);
```

That gives me exactly 10 rows in each table right out of the gate.

---

## How I Tested the Code

### Service-level tests with Mockito

I isolated `BookService` from the database by mocking `BookRepository`. This way, the tests verify my business logic without depending on a running data store.

```java
@ExtendWith(MockitoExtension.class)
public class BookServiceTest {

    @Mock  private BookRepository bookRepository;
    @InjectMocks  private BookService bookService;

    private Book book;

    @BeforeEach
    void setUp() {
        Author author = new Author("Test Author", "Bio");
        author.setId(1L);
        book = new Book("Test Title", "12345", 2023, author);
        book.setId(1L);
    }

    @Test
    void findAllBooks_returnsNonEmptyList() {
        when(bookRepository.findAllBooksWithAuthors())
            .thenReturn(Arrays.asList(book));

        List<Book> result = bookService.findAllBooks();

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Test Title", result.get(0).getTitle());
        verify(bookRepository, times(1)).findAllBooksWithAuthors();
    }

    @Test
    void findById_returnsCorrectBook() {
        when(bookRepository.findById(1L))
            .thenReturn(Optional.of(book));

        Book found = bookService.findById(1L);

        assertNotNull(found);
        assertEquals("12345", found.getIsbn());
    }

    @Test
    void saveBook_persistsAndReturnsEntity() {
        when(bookRepository.save(any(Book.class))).thenReturn(book);

        Book saved = bookService.saveBook(book);

        assertNotNull(saved);
        assertEquals("Test Title", saved.getTitle());
        verify(bookRepository, times(1)).save(book);
    }
}
```

### Repository-level tests with @DataJpaTest

Here I spun up a thin application context backed by an embedded H2 instance. `TestEntityManager` lets me persist sample data, and then I verify that my custom JPQL query actually joins the two tables properly.

```java
@DataJpaTest
public class BookRepositoryTest {

    @Autowired private TestEntityManager entityManager;
    @Autowired private BookRepository bookRepository;

    @Test
    public void findAllBooksWithAuthors_joinsCorrectly() {
        Author author = new Author("Sample Writer", "Bio");
        entityManager.persist(author);

        entityManager.persist(new Book("Book A", "111", 2000, author));
        entityManager.persist(new Book("Book B", "222", 2001, author));
        entityManager.flush();

        List<Book> books = bookRepository.findAllBooksWithAuthors();

        assertThat(books).hasSizeGreaterThanOrEqualTo(2);
        assertThat(books.get(0).getAuthor().getName())
            .isEqualTo("Sample Writer");
    }
}
```

---

## Screenshots of the Running Application

### Listing all books (Read)

![Book List Page](screenshots/book_list.png)

### Adding a new book (Create)

![Add Book Form](screenshots/book_form.png)

### Editing an existing book (Update)

![Edit Book Form](screenshots/book_edit.png)

---

## Problems I Ran Into and How I Fixed Them

**1. Getting JSP pages to render at all**
Spring Boot ships with Thymeleaf support out of the box but has no built-in JSP compiler. I had to manually pull in `tomcat-embed-jasper` plus the two Jakarta JSTL jars, and point the view resolver at `WEB-INF/jsp/`. Without those dependencies, every request to a JSP returned a 404.

**2. Seed data running before the tables existed**
My initial attempt crashed on startup because `data.sql` fired before Hibernate had a chance to generate the schema. Setting `spring.jpa.defer-datasource-initialization` to `true` fixed the ordering: Hibernate builds the tables first, then Spring runs my INSERT statements.

**3. Excessive database queries when displaying the book list**
Calling `findAll()` and then accessing each book's author one by one generated N+1 SELECT statements. I replaced the default method with a hand-written JPQL that uses `JOIN FETCH`, collapsing everything into a single query.

**4. Wiring the author dropdown back to the Book entity**
When the form posts, the author dropdown only sends an ID. I had to name the select element `author.id` so that Spring MVC's data binder would automatically look up the corresponding `Author` entity and attach it to the `Book` object before saving.

---

## Source Code

**GitHub:** [https://github.com/KADUMU0980/java-springboot](https://github.com/KADUMU0980/java-springboot)

---

## File Layout

```
library-app/
├── pom.xml
├── src/main/
│   ├── java/com/example/libraryapp/
│   │   ├── LibraryAppApplication.java
│   │   ├── controller/LibraryController.java
│   │   ├── entity/Author.java
│   │   ├── entity/Book.java
│   │   ├── repository/AuthorRepository.java
│   │   ├── repository/BookRepository.java
│   │   ├── service/AuthorService.java
│   │   └── service/BookService.java
│   ├── resources/
│   │   ├── application.properties
│   │   └── data.sql
│   └── webapp/WEB-INF/jsp/
│       ├── book-list.jsp
│       └── book-form.jsp
├── src/test/java/com/example/libraryapp/
│   ├── repository/BookRepositoryTest.java
│   └── service/BookServiceTest.java
└── screenshots/
    ├── book_list.png
    ├── book_form.png
    └── book_edit.png
```
