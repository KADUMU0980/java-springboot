package com.example.libraryapp.controller;

import com.example.libraryapp.entity.Book;
import com.example.libraryapp.service.AuthorService;
import com.example.libraryapp.service.BookService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/")
public class LibraryController {

    private final BookService bookService;
    private final AuthorService authorService;

    @Autowired
    public LibraryController(BookService bookService, AuthorService authorService) {
        this.bookService = bookService;
        this.authorService = authorService;
    }

    @GetMapping
    public String index() {
        return "redirect:/books";
    }

    // Read Operation
    @GetMapping("/books")
    public String listBooks(Model model) {
        model.addAttribute("books", bookService.findAllBooks());
        return "book-list";
    }

    // Show Create Form
    @GetMapping("/books/add")
    public String showAddForm(Model model) {
        model.addAttribute("book", new Book());
        model.addAttribute("authors", authorService.findAllAuthors());
        return "book-form";
    }

    // Show Update Form
    @GetMapping("/books/edit/{id}")
    public String showUpdateForm(@PathVariable("id") Long id, Model model) {
        Book book = bookService.findById(id);
        model.addAttribute("book", book);
        model.addAttribute("authors", authorService.findAllAuthors());
        return "book-form";
    }

    // Create / Update Operation
    @PostMapping("/books/save")
    public String saveBook(@Valid @ModelAttribute("book") Book book, 
                           BindingResult result, 
                           Model model, 
                           RedirectAttributes redirectAttributes) {
        if (result.hasErrors()) {
            model.addAttribute("authors", authorService.findAllAuthors());
            return "book-form";
        }
        
        try {
            bookService.saveBook(book);
            redirectAttributes.addFlashAttribute("successMessage", "Book saved successfully!");
        } catch (RuntimeException e) {
            model.addAttribute("errorMessage", e.getMessage());
            model.addAttribute("authors", authorService.findAllAuthors());
            return "book-form";
        }
        
        return "redirect:/books";
    }
}
