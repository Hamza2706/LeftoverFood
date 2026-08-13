<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Error.aspx.cs" Inherits="LeftoverFood.ErrorPage" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Something Went Wrong - Leftover Food System</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=DM+Serif+Display&display=swap');

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'DM Sans', sans-serif;
            background: #f5f0e8;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem 1rem;
        }

        .panel {
            max-width: 520px;
            width: 100%;
            background: #fff;
            border-radius: 20px;
            padding: 3rem 2.5rem;
            text-align: center;
            box-shadow: 0 20px 60px rgba(0,0,0,0.1);
        }

        .icon { font-size: 3.5rem; margin-bottom: 1rem; }

        h1 {
            font-family: 'DM Serif Display', serif;
            font-size: 1.8rem;
            color: #1a3c2e;
            margin-bottom: 0.75rem;
        }

        p {
            color: #666;
            font-size: 0.95rem;
            line-height: 1.5;
            margin-bottom: 1.5rem;
        }

        .debug-detail {
            text-align: left;
            background: #fdecea;
            border: 1px solid #f5c6cb;
            color: #c0392b;
            border-radius: 10px;
            padding: 1rem;
            font-size: 0.8rem;
            font-family: monospace;
            white-space: pre-wrap;
            word-break: break-word;
            margin-bottom: 1.5rem;
        }

        a.btn {
            display: inline-block;
            padding: 0.85rem 2rem;
            background: #1a3c2e;
            color: #fff;
            text-decoration: none;
            font-weight: 600;
            border-radius: 12px;
            transition: background 0.2s;
        }

        a.btn:hover { background: #2d7a4f; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="panel">
            <div class="icon">⚠️</div>
            <h1>Something Went Wrong</h1>
            <p>An unexpected error occurred while processing your request. Please try again, and contact support if the problem continues.</p>
            <asp:Literal ID="litDebugDetail" runat="server" Visible="false" />
            <a class="btn" href="Login.aspx">Back to Login</a>
        </div>
    </form>
</body>
</html>
