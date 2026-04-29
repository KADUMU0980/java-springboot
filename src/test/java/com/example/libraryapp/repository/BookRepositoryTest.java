package com.example.libraryapp.repository;

import com.example.libraryapp.entity.Author;
import com.example.libraryapp.entity.Book;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
public class BookRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private BookRepository bookRepository;

    @Test
    public void testFindAllBooksWithAuthors() {
        // Setup mock data
        Author author = new Author("Test Author 2", "Bio");
        entityManager.persist(author);

        Book book1 = new Book("Book 1", "111", 2000, author);
        Book book2 = new Book("Book 2", "222", 2001, author);
        entityManager.persist(book1);
        entityManager.persist(book2);
        entityManager.flush();

        // Execute query
        List<Book> books = bookRepository.findAllBooksWithAuthors();

        // Verify
        assertThat(books).hasSizeGreaterThanOrEqualTo(2);
        // Verify that author is fetched (inner join)
        assertThat(books.get(0).getAuthor().getName()).isEqualTo("Test Author 2");
    }
}
