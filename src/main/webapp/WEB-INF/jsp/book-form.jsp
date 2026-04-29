<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Library - Book Form</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 600px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; margin-bottom: 20px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input[type="text"], input[type="number"], select { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; }
        .btn { display: inline-block; padding: 10px 15px; color: #fff; background-color: #3498db; text-decoration: none; border-radius: 5px; transition: background 0.3s; border: none; cursor: pointer; font-size: 16px; }
        .btn:hover { background-color: #2980b9; }
        .btn-cancel { background-color: #95a5a6; margin-left: 10px; }
        .btn-cancel:hover { background-color: #7f8c8d; }
        .error { color: #e74c3c; font-size: 14px; margin-top: 5px; }
        .alert { padding: 15px; margin-bottom: 20px; border: 1px solid transparent; border-radius: 4px; }
        .alert-danger { color: #a94442; background-color: #f2dede; border-color: #ebccd1; }
    </style>
</head>
<body>
    <div class="container">
        <h1>${empty book.id ? 'Add New Book' : 'Edit Book'}</h1>

        <c:if test="${not empty errorMessage}">
            <div class="alert alert-danger">${errorMessage}</div>
        </c:if>

        <form action="<c:url value='/books/save' />" method="post">
            <input type="hidden" name="id" value="${book.id}">

            <div class="form-group">
                <label for="title">Title:</label>
                <input type="text" id="title" name="title" value="${book.title}" required>
            </div>

            <div class="form-group">
                <label for="author">Author:</label>
                <select id="author" name="author.id" required>
                    <option value="">-- Select Author --</option>
                    <c:forEach var="author" items="${authors}">
                        <option value="${author.id}" ${book.author != null && book.author.id == author.id ? 'selected' : ''}>
                            ${author.name}
                        </option>
                    </c:forEach>
                </select>
            </div>

            <div class="form-group">
                <label for="isbn">ISBN:</label>
                <input type="text" id="isbn" name="isbn" value="${book.isbn}" required>
            </div>

            <div class="form-group">
                <label for="publicationYear">Publication Year:</label>
                <input type="number" id="publicationYear" name="publicationYear" value="${book.publicationYear}" required>
            </div>

            <div class="form-group">
                <button type="submit" class="btn">Save</button>
                <a href="<c:url value='/books' />" class="btn btn-cancel">Cancel</a>
            </div>
        </form>
    </div>
</body>
</html>
