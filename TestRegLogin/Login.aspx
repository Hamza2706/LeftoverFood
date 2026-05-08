<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="LeftoverFood.TestRegLogin.Login" %>

<!DOCTYPE 
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Login - Leftover Food System</title>
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

        .card {
            background: #fff;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 460px;
            overflow: hidden;
        }

        .card-header {
            background: #1a3c2e;
            padding: 2.5rem 2.5rem 2rem;
            text-align: center;
        }

        .card-header .brand {
            font-family: 'DM Serif Display', serif;
            font-size: 2rem;
            color: #a8d5b5;
        }

        .card-header .tagline {
            font-size: 0.8rem;
            color: #6a9e7f;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            margin-top: 0.3rem;
        }

        .card-body {
            padding: 2.5rem;
        }

        .card-body h2 {
            font-family: 'DM Serif Display', serif;
            font-size: 1.7rem;
            color: #1a3c2e;
            margin-bottom: 0.3rem;
        }

        .card-body .subtitle {
            font-size: 0.88rem;
            color: #888;
            margin-bottom: 2rem;
        }

        .card-body .subtitle a {
            color: #2d7a4f;
            text-decoration: none;
            font-weight: 500;
        }

        .form-group {
            margin-bottom: 1.3rem;
        }

        .form-group label {
            display: block;
            font-size: 0.8rem;
            font-weight: 500;
            color: #444;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            margin-bottom: 0.4rem;
        }

        .form-group input {
            width: 100%;
            padding: 0.8rem 1rem;
            border: 1.5px solid #e0e0e0;
            border-radius: 10px;
            font-family: 'DM Sans', sans-serif;
            font-size: 0.95rem;
            color: #222;
            background: #fafafa;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }

        .form-group input:focus {
            border-color: #2d7a4f;
            box-shadow: 0 0 0 3px rgba(45,122,79,0.1);
            background: #fff;
        }

        .alert {
            padding: 0.75rem 1rem;
            border-radius: 10px;
            font-size: 0.88rem;
            margin-bottom: 1.2rem;
        }

        .alert-danger  { background: #fdecea; color: #c0392b; border: 1px solid #f5c6cb; }
        .alert-success { background: #eafaf1; color: #1e7e34; border: 1px solid #c3e6cb; }
        .alert-warning { background: #fff8e1; color: #856404; border: 1px solid #ffc107; }

        .validator-msg {
            font-size: 0.78rem;
            color: #e74c3c;
            margin-top: 0.25rem;
            display: block;
        }

        .btn-login {
            width: 100%;
            padding: 0.85rem;
            background: #1a3c2e;
            color: #fff;
            font-family: 'DM Sans', sans-serif;
            font-size: 1rem;
            font-weight: 600;
            border: none;
            border-radius: 12px;
            cursor: pointer;
            transition: background 0.2s, transform 0.1s;
            letter-spacing: 0.03em;
        }

        .btn-login:hover  { background: #2d7a4f; }
        .btn-login:active { transform: scale(0.98); }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="card">

    <div class="card-header">
        <div class="brand">FoodShare</div>
        <div class="tagline">Reducing waste · Feeding hope</div>
    </div>

    <div class="card-body">
        <h2>Welcome back</h2>
        <p class="subtitle">New here? <a href="Register.aspx">Create an account</a></p>

        <asp:Label ID="lblMessage" runat="server" Visible="false" CssClass="alert"></asp:Label>

        <div class="form-group">
            <label for="txtEmail">Email Address</label>
            <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" placeholder="you@example.com" />
            <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
                ControlToValidate="txtEmail"
                ErrorMessage="Email is required"
                CssClass="validator-msg"
                Display="Dynamic" />
        </div>

        <div class="form-group">
            <label for="txtPassword">Password</label>
            <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" placeholder="Your password" />
            <asp:RequiredFieldValidator ID="rfvPass" runat="server"
                ControlToValidate="txtPassword"
                ErrorMessage="Password is required"
                CssClass="validator-msg"
                Display="Dynamic" />
        </div>

        <asp:Button ID="btnLogin" runat="server"
            Text="Sign In"
            CssClass="btn-login"
            OnClick="btnLogin_Click" />
    </div>

</div>
</form>
</body>
</html>
