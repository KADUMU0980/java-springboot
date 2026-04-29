package com.example.libraryapp.service;

import com.example.libraryapp.entity.Author;
import com.example.libraryapp.entity.Book;
import com.example.libraryapp.repository.BookRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class BookServiceTest {

    @Mock
    private BookRepository bookRepository;

    @InjectMocks
    private BookService bookService;

    private Book book;
    private Author author;

    @BeforeEach
    void setUp() {
        author = new Author("Test Author", "Bio");
        author.setId(1L);
        book = new Book("Test Title", "12345", 2023, author);
        book.setId(1L);
    }

    @Test
    void testFindAllBooks() {
        when(bookRepository.findAllBooksWithAuthors()).thenReturn(Arrays.asList(book));
        
        List<Book> books = bookService.findAllBooks();
        
        assertNotNull(books);
        assertEquals(1, books.size());
        assertEquals("Test Title", books.get(0).getTitle());
        verify(bookRepository, times(1)).findAllBooksWithAuthors();
    }

    @Test
    void testFindById() {
        when(bookRepository.findById(1L)).thenReturn(Optional.of(book));
        
        Book found = bookService.findById(1L);
        
        assertNotNull(found);
        assertEquals("12345", found.getIsbn());
    }

    @Test
    void testSaveBook() {
        when(bookRepository.save(any(Book.class))).thenReturn(book);
        
        Book savedBook = bookService.saveBook(book);
        
        assertNotNull(savedBook);
        assertEquals("Test Title", savedBook.getTitle());
        verify(bookRepository, times(1)).save(book);
    }
}
