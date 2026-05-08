<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Register.aspx.cs" Inherits="LeftoverFood.TestRegLogin.Register" %>

<!DOCTYPE html>


<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Register - Leftover Food System</title>
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

        .page-wrapper {
            display: flex;
            width: 100%;
            max-width: 960px;
            background: #fff;
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 20px 60px rgba(0,0,0,0.1);
        }

        /* Left decorative panel */
        .side-panel {
            width: 340px;
            flex-shrink: 0;
            background: #1a3c2e;
            padding: 3rem 2.5rem;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .side-panel .brand {
            font-family: 'DM Serif Display', serif;
            font-size: 1.8rem;
            color: #a8d5b5;
            line-height: 1.2;
        }

        .side-panel .tagline {
            font-size: 0.85rem;
            color: #6a9e7f;
            margin-top: 0.5rem;
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .side-panel .illustration {
            text-align: center;
            font-size: 5rem;
            margin: 2rem 0;
        }

        .side-panel .stats {
            display: flex;
            flex-direction: column;
            gap: 1.2rem;
        }

        .stat-item {
            border-left: 3px solid #a8d5b5;
            padding-left: 1rem;
        }

        .stat-item .number {
            font-size: 1.4rem;
            font-weight: 600;
            color: #ffffff;
        }

        .stat-item .label {
            font-size: 0.78rem;
            color: #6a9e7f;
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        /* Right form panel */
        .form-panel {
            flex: 1;
            padding: 3rem 2.5rem;
            overflow-y: auto;
        }

        .form-panel h2 {
            font-family: 'DM Serif Display', serif;
            font-size: 2rem;
            color: #1a3c2e;
            margin-bottom: 0.4rem;
        }

        .form-panel .subtitle {
            color: #888;
            font-size: 0.9rem;
            margin-bottom: 2rem;
        }

        .form-panel .subtitle a {
            color: #2d7a4f;
            text-decoration: none;
            font-weight: 500;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
        }

        .form-group {
            margin-bottom: 1.2rem;
        }

        .form-group label {
            display: block;
            font-size: 0.82rem;
            font-weight: 500;
            color: #444;
            margin-bottom: 0.4rem;
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .form-group input,
        .form-group select {
            width: 100%;
            padding: 0.75rem 1rem;
            border: 1.5px solid #e0e0e0;
            border-radius: 10px;
            font-family: 'DM Sans', sans-serif;
            font-size: 0.95rem;
            color: #222;
            background: #fafafa;
            transition: border-color 0.2s, box-shadow 0.2s;
            outline: none;
        }

        .form-group input:focus,
        .form-group select:focus {
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

        .btn-register {
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
            letter-spacing: 0.03em;
            transition: background 0.2s, transform 0.1s;
            margin-top: 0.5rem;
        }

        .btn-register:hover  { background: #2d7a4f; }
        .btn-register:active { transform: scale(0.98); }

        .validator-msg {
            font-size: 0.78rem;
            color: #e74c3c;
            margin-top: 0.25rem;
            display: block;
        }

        @media (max-width: 700px) {
            .page-wrapper { flex-direction: column; }
            .side-panel { width: 100%; padding: 2rem; }
            .side-panel .stats { flex-direction: row; flex-wrap: wrap; }
            .form-panel { padding: 2rem 1.5rem; }
            .form-row { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<form id="form1" runat="server">
<div class="page-wrapper">

    <!-- Left panel -->
    <div class="side-panel">
        <div>
            <div class="brand">Food<br/>Share</div>
            <div class="tagline">Reducing waste, feeding hope</div>
        </div>
        <div class="illustration">🥘</div>
        <div class="stats">
            <div class="stat-item">
                <div class="number">2,400+</div>
                <div class="label">Meals redistributed</div>
            </div>
            <div class="stat-item">
                <div class="number">140+</div>
                <div class="label">Active donors</div>
            </div>
            <div class="stat-item">
                <div class="number">30+</div>
                <div class="label">Partner NGOs</div>
            </div>
        </div>
    </div>

    <!-- Right form -->
    <div class="form-panel">
        <h2>Create Account</h2>
        <p class="subtitle">Already have an account? <a href="Login.aspx">Sign in</a></p>

        <asp:Label ID="lblMessage" runat="server" Visible="false" CssClass="alert"></asp:Label>

        <div class="form-row">
            <div class="form-group">
                <label for="txtFullName">Full Name</label>
                <asp:TextBox ID="txtFullName" runat="server" placeholder="Ahmed Khan" />
                <asp:RequiredFieldValidator ID="rfvName" runat="server"
                    ControlToValidate="txtFullName"
                    ErrorMessage="Name is required"
                    CssClass="validator-msg"
                    Display="Dynamic" />
            </div>
            <div class="form-group">
                <label for="txtPhone">Phone Number</label>
                <asp:TextBox ID="txtPhone" runat="server" placeholder="0300-1234567" />
            </div>
        </div>

        <div class="form-group">
            <label for="txtEmail">Email Address</label>
            <asp:TextBox ID="txtEmail" runat="server" TextMode="Email" placeholder="you@example.com" />
            <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
                ControlToValidate="txtEmail"
                ErrorMessage="Email is required"
                CssClass="validator-msg"
                Display="Dynamic" />
            <asp:RegularExpressionValidator ID="revEmail" runat="server"
                ControlToValidate="txtEmail"
                ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$"
                ErrorMessage="Enter a valid email"
                CssClass="validator-msg"
                Display="Dynamic" />
        </div>

        <div class="form-group">
            <label for="ddlRole">I am joining as</label>
            <asp:DropDownList ID="ddlRole" runat="server">
                <asp:ListItem Value="">-- Select Role --</asp:ListItem>
                <asp:ListItem Value="Donor">Donor (Restaurant / Individual)</asp:ListItem>
                <asp:ListItem Value="NGO">NGO / Welfare Organization</asp:ListItem>
                <asp:ListItem Value="Volunteer">Volunteer (Delivery)</asp:ListItem>
            </asp:DropDownList>
            <asp:RequiredFieldValidator ID="rfvRole" runat="server"
                ControlToValidate="ddlRole"
                InitialValue=""
                ErrorMessage="Please select a role"
                CssClass="validator-msg"
                Display="Dynamic" />
        </div>

        <div class="form-group">
            <label for="txtAddress">Address</label>
            <asp:TextBox ID="txtAddress" runat="server" placeholder="Street, Area, City" />
        </div>

        <div class="form-row">
            <div class="form-group">
                <label for="txtPassword">Password</label>
                <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" placeholder="Min. 6 characters" />
                <asp:RequiredFieldValidator ID="rfvPass" runat="server"
                    ControlToValidate="txtPassword"
                    ErrorMessage="Password is required"
                    CssClass="validator-msg"
                    Display="Dynamic" />
                <asp:RegularExpressionValidator ID="revPass" runat="server"
                    ControlToValidate="txtPassword"
                    ValidationExpression=".{6,}"
                    ErrorMessage="Min. 6 characters"
                    CssClass="validator-msg"
                    Display="Dynamic" />
            </div>
            <div class="form-group">
                <label for="txtConfirmPass">Confirm Password</label>
                <asp:TextBox ID="txtConfirmPass" runat="server" TextMode="Password" placeholder="Repeat password" />
                <asp:CompareValidator ID="cvPass" runat="server"
                    ControlToValidate="txtConfirmPass"
                    ControlToCompare="txtPassword"
                    ErrorMessage="Passwords do not match"
                    CssClass="validator-msg"
                    Display="Dynamic" />
            </div>
        </div>

        <asp:Button ID="btnRegister" runat="server"
            Text="Create Account"
            CssClass="btn-register"
            OnClick="btnRegister_Click" />
    </div>

</div>
</form>
</body>
</html>
