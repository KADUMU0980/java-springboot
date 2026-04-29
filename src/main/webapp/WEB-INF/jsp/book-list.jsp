<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Library - Book List</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 1000px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; margin-bottom: 20px; }
        .btn { display: inline-block; padding: 10px 15px; color: #fff; background-color: #3498db; text-decoration: none; border-radius: 5px; transition: background 0.3s; margin-bottom: 15px; border: none; cursor: pointer; }
        .btn:hover { background-color: #2980b9; }
        .btn-edit { background-color: #f39c12; padding: 5px 10px; font-size: 14px; }
        .btn-edit:hover { background-color: #d68910; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #ecf0f1; color: #2c3e50; }
        tr:hover { background-color: #f5f5f5; }
        .alert { padding: 15px; margin-bottom: 20px; border: 1px solid transparent; border-radius: 4px; }
        .alert-success { color: #3c763d; background-color: #dff0d8; border-color: #d6e9c6; }
    </style>
</head>
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
                    <th>ID</th>
                    <th>Title</th>
                    <th>Author</th>
                    <th>ISBN</th>
                    <th>Publication Year</th>
                    <th>Actions</th>
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
                        <td>
                            <a href="<c:url value='/books/edit/${book.id}' />" class="btn btn-edit">Edit</a>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</body>
</html>
