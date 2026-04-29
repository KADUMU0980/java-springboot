# My Spring Boot Project — Managing a Library of Books and Authors

## What This Project Is About

For this assignment I built a web application that lets users manage a catalog of books and their respective authors. I went with a library theme because the relationship between writers and their publications is intuitive and maps cleanly to a relational schema. The tech stack includes Spring Boot on the backend, JSP pages for the front end, an H2 in-memory database for storage, and JPA/Hibernate as the persistence layer.

---

## Designing the Database Tables

I started by deciding what columns each table should contain. My goal was to keep things simple but realistic.

The **authors** table has three fields: an auto-generated numeric ID that serves as the primary key, a mandatory name column, and an optional biography column capped at 1000 characters.

The **books** table has five fields: its own auto-generated ID, a mandatory title, a unique ISBN (to prevent accidental duplicates), a publication year that must be at least 1000, and a foreign key pointing to the author who wrote it.

The connection between the two tables follows a one-to-many pattern — each author can be linked to multiple books, but each book belongs to exactly one author. The foreign key (`author_id`) sits on the books table because that is the "many" side of the relationship.

Below is a visual representation I drew during the planning phase:

```
 ┌────────────────────┐         ┌────────────────────────────┐
 │     AUTHORS        │         │         BOOKS              │
 ├────────────────────┤         ├────────────────────────────┤
 │ id          (PK)   │───┐     │ id              (PK)      │
 │ name               │   │     │ title                     │
 │ biography          │   │     │ isbn            (UNIQUE)  │
 └────────────────────┘   │     │ publication_year           │
                          └────▶│ author_id       (FK)      │
                         1   N  └────────────────────────────┘
```

---

## How I Configured the Project

I generated the initial project skeleton using Spring Initializr with modules for web, data-jpa, validation, and the H2 database. After that, I had to manually add three extra dependencies to the Maven POM file because Spring Boot does not include JSP support out of the box: the Tomcat Jasper engine (which compiles `.jsp` files into servlets at runtime) and two Jakarta JSTL libraries (which provide the `<c:forEach>`, `<c:if>`, and `<c:url>` tags I use in my views).

In my properties file I configured the H2 datasource URL, turned on the browser-based H2 console for debugging, told Hibernate to recreate the schema on every restart, and deferred the execution of my seed-data script so it runs only after the tables are built. I also pointed the Spring MVC view resolver at `WEB-INF/jsp/` so it knows where to find my JSP templates.

---

## Building the Entity Classes

### The Author class

I placed `@Entity` and `@Table(name = "authors")` annotations on this class so Hibernate maps it to the right database table. The primary key uses an identity generation strategy, meaning the database itself assigns incrementing IDs. I put a `@NotBlank` validation constraint on the name field because an author without a name does not make sense. On the `books` field I declared a `@OneToMany` relationship with `mappedBy = "author"`, which tells JPA that the `Book` entity owns the foreign key — this class is just the inverse side.

### The Book class

This entity mirrors the books table. The ISBN column carries both `unique = true` and `nullable = false` constraints to enforce data integrity at the database level. For the publication year I used a `@Min(1000)` validation so users cannot accidentally type something nonsensical. The `@ManyToOne` annotation on the `author` field, paired with `@JoinColumn(name = "author_id")`, establishes the owning side of the relationship.

---

## The Repository Layer

Both repository interfaces extend `JpaRepository`, which gives me methods like `findAll()`, `findById()`, `save()`, and `deleteById()` for free.

The interesting part is the custom method I added to `BookRepository`:

```java
@Query("SELECT b FROM Book b JOIN FETCH b.author")
List<Book> findAllBooksWithAuthors();
```

This hand-written JPQL performs an inner join between the books and authors tables and eagerly loads the associated author for each book — all in a single database round trip. Without it, accessing `book.getAuthor()` inside a loop would fire a separate query for every single row, which is terribly inefficient on larger datasets.

---

## The Service Layer

I created two service classes, one per entity, each annotated with `@Service` and injected with its corresponding repository through constructor-based dependency injection.

`BookService` exposes three main methods: one that delegates to my custom join query to retrieve the full book list, one that looks up a single book by its ID (throwing an `IllegalArgumentException` if no match is found), and one that persists a new or updated book. The save method wraps the repository call in a try-catch block — if the database rejects the operation (for example, because of a duplicate ISBN), my code catches the exception and rethrows it with a human-readable message instead of letting a raw stack trace reach the user.

`AuthorService` is simpler since I only need to list all authors (for the dropdown menu) and occasionally look one up by ID.

---

## The Controller — Connecting URLs to Logic

My `LibraryController` is annotated with `@Controller` and maps five endpoints:

**GET /** — simply redirects to the book list page so users land somewhere useful.

**GET /books** — asks the service for all books (via the join query) and puts the resulting list into the model under the key `books`, then forwards to the `book-list` JSP template.

**GET /books/add** — creates an empty `Book` object and fetches the author list for the dropdown, then renders the `book-form` template in "create" mode.

**GET /books/edit/{id}** — loads an existing book by its path variable, adds it (along with all authors) to the model, and renders the same `book-form` template — but this time the fields come pre-filled because the book object already has data in it.

**POST /books/save** — receives the form submission. If the bean validation annotations flag any problems, the form is re-displayed with the errors shown. Otherwise, the controller delegates to `bookService.saveBook()`. On success a flash attribute carries a confirmation message to the redirect. On failure (say, a duplicate ISBN), the caught exception message is displayed on the form.

---

## The JSP Pages

### Listing books (book-list.jsp)

This page shows a table with columns for ID, title, author name, ISBN, publication year, and an action column containing an "Edit" link for each row. A JSTL `<c:forEach>` tag loops through the books collection. The author name is accessed via the expression `${book.author.name}`, which works because my join query pre-loads the author association. At the top of the page, a conditional block checks for a success flash message and displays a green banner if one exists. There is also a prominent "Add New Book" button that links to the creation form.

### The book form (book-form.jsp)

I used a single JSP for both creating and editing books. The page title dynamically switches between "Add New Book" and "Edit Book" based on whether the book object has an ID or not. A hidden input field stores the book ID so that when the form posts to `/books/save`, Hibernate knows whether to issue an INSERT or an UPDATE statement. The author field is rendered as a `<select>` dropdown populated from the authors list, with the current author pre-selected during edits.

Both pages include embedded CSS for a polished appearance: a card-style white container on a light gray background, a blue accent color for buttons and headings, rounded corners, subtle shadows, and hover effects on table rows and buttons.

---

## Seeding the Database

I placed a file called `data.sql` in the resources folder. Spring Boot automatically executes it after Hibernate finishes generating the tables (thanks to the deferred initialization property I mentioned earlier). The script inserts ten authors — ranging from J.K. Rowling to Arthur Conan Doyle — and ten well-known books, each linked to its real-world author through the foreign key.

---

## Automated Testing

### Testing the service in isolation

In `BookServiceTest` I used the Mockito framework to substitute a fake repository implementation. This means the tests never touch a real database — they only verify that `BookService` calls the right repository methods and handles the results correctly. I wrote three test methods: one confirming that `findAllBooks()` delegates to the custom join query and returns the expected list, one confirming that `findById()` returns the correct entity, and one confirming that `saveBook()` persists the entity and returns it.

### Testing the repository against a real database

In `BookRepositoryTest` I used the `@DataJpaTest` annotation, which spins up a minimal Spring context with an embedded H2 database. I used `TestEntityManager` to manually insert an author and two books, then called my custom `findAllBooksWithAuthors()` method and verified that the returned list contains at least two entries and that the author object attached to each book is fully populated (not null or lazy-loaded).

---

## Screenshots of the Working Application

### The main book list showing all ten pre-loaded entries

![Book listing page](screenshots/book_list.png)

### The form for adding a brand new book

![Book creation form](screenshots/book_form.png)

### The same form pre-filled for editing an existing record

![Book edit form](screenshots/book_edit.png)

---

## Difficulties I Encountered

**Getting JSP to work with modern Spring Boot** was my first hurdle. The framework strongly favors Thymeleaf nowadays, so there is almost no built-in JSP support. I had to research which Maven artifacts to add (`tomcat-embed-jasper` plus the JSTL API and implementation jars) and configure the view resolver prefix and suffix manually.

**Seed data executing too early** caused crashes during startup. The INSERT statements in `data.sql` were running before Hibernate had created the tables, leading to "table not found" errors. After digging through the Spring Boot documentation, I discovered the `defer-datasource-initialization` property, which reverses the execution order.

**Too many database queries on the listing page** was a performance issue I noticed in the Hibernate SQL logs. Each book triggered a separate SELECT to fetch its author. Replacing the default `findAll()` with a JPQL query containing `JOIN FETCH` collapsed all those round trips into one.

**Binding a dropdown selection to a nested object** was tricky. The author dropdown sends a plain numeric ID, but the `Book` entity expects a full `Author` object. Naming the select element `author.id` lets Spring MVC's data binder resolve this automatically — it takes the ID, looks up the author, and attaches it to the book before the save method runs.

---

## Project Repository

The full source code is hosted at: [https://github.com/KADUMU0980/java-springboot](https://github.com/KADUMU0980/java-springboot)

---

## Directory Structure

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
```
