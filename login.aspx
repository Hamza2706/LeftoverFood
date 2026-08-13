<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="login.aspx.cs" Inherits="LeftoverFood.login" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Login / Register – FoodBridge</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet" />
    <link href="assets/css/style.css" rel="stylesheet" />

</head>
<body style="background: var(--cream)">
    <form  runat="server">
        <div class="auth-wrap">

            <!-- LEFT PANEL -->
            <div class="auth-left">
                <div style="max-width: 400px">
                    <a href="index.html" style="color: rgba(255,255,255,.7); font-size: .88rem; display: flex; align-items: center; gap: .4rem; margin-bottom: 2.5rem"><i class="bi bi-arrow-left"></i>Back to Home</a>
                    <div style="font-family: 'DM Serif Display',serif; font-size: 1.8rem; color: #fff; margin-bottom: .5rem"><i class="bi bi-basket2-fill me-2"></i>Food<span style="color: #fbb350">Bridge</span></div>
                    <h2 style="color: #fff; font-size: clamp(1.6rem,3vw,2.2rem); margin: 1.5rem 0 1rem">Fighting hunger,<br>
                        <em>one meal at a time.</em></h2>
                    <p style="color: rgba(255,255,255,.72); font-size: .97rem; line-height: 1.75; margin-bottom: 2rem">Join our platform connecting food donors, NGOs, and volunteers to reduce food waste and feed communities across Pakistan.</p>
                    <div class="d-flex flex-column gap-3">
                        <div style="display: flex; align-items: center; gap: 1rem; color: rgba(255,255,255,.8); font-size: .9rem">
                            <div style="width: 36px; height: 36px; background: rgba(255,255,255,.15); border-radius: 8px; display: flex; align-items: center; justify-content: center"><i class="bi bi-check2"></i></div>
                            Free to join & use
                        </div>
                        <div style="display: flex; align-items: center; gap: 1rem; color: rgba(255,255,255,.8); font-size: .9rem">
                            <div style="width: 36px; height: 36px; background: rgba(255,255,255,.15); border-radius: 8px; display: flex; align-items: center; justify-content: center"><i class="bi bi-shield-check"></i></div>
                            Verified NGOs & donors
                        </div>
                        <div style="display: flex; align-items: center; gap: 1rem; color: rgba(255,255,255,.8); font-size: .9rem">
                            <div style="width: 36px; height: 36px; background: rgba(255,255,255,.15); border-radius: 8px; display: flex; align-items: center; justify-content: center"><i class="bi bi-graph-up"></i></div>
                            Real-time donation tracking
                        </div>
                    </div>
                    <div style="margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(255,255,255,.15)">
                        <div style="color: rgba(255,255,255,.6); font-size: .8rem; margin-bottom: .75rem">TRUSTED BY</div>
                        <div class="d-flex gap-3 flex-wrap">
                            <span style="background: rgba(255,255,255,.12); color: #fff; border-radius: 6px; padding: .3rem .8rem; font-size: .8rem; font-weight: 600">Edhi Foundation</span>
                            <span style="background: rgba(255,255,255,.12); color: #fff; border-radius: 6px; padding: .3rem .8rem; font-size: .8rem; font-weight: 600">Saylani Welfare</span>
                            <span style="background: rgba(255,255,255,.12); color: #fff; border-radius: 6px; padding: .3rem .8rem; font-size: .8rem; font-weight: 600">Al-Khidmat</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- RIGHT PANEL -->
            <div class="auth-right">
                <div class="auth-card">
                    <h3 style="font-size: 1.6rem; margin-bottom: .3rem">Welcome Back</h3>
                    <p style="color: var(--text-muted); font-size: .9rem; margin-bottom: 1.5rem">Sign in to your account or create a new one</p>

                    <!-- TABS -->
                    <div class="auth-tabs">
                        <div class="auth-tab active" data-tab="loginPanel">Login</div>
                        <div class="auth-tab" data-tab="registerPanel">Register</div>
                    </div>

                     <asp:Label ID="lblMessage" runat="server" Visible="false" CssClass="alert"></asp:Label>

                    <!-- LOGIN PANEL -->
                    <div id="loginPanel" class="auth-panel">
                        <div class="fb-form-group">
                            <label for="txtEmail">Email Address</label>
                            <%--<input type="email" class="fb-input" placeholder="you@example.com"/>--%>
                            <asp:TextBox ID="txtEmail" runat="server" TextMode="Email"  class="fb-input"></asp:TextBox>
                              <asp:RequiredFieldValidator ID="rfvEmail" runat="server"
                              ControlToValidate="txtEmail"
                              ErrorMessage="Email is required"
                              CssClass="validator-msg"
                              Display="Dynamic" 
                                   ValidationGroup="LoginGroup" />
                        </div>
                        <div class="fb-form-group">
                            <label for="txtPassword">Password</label>
                            <div style="position: relative">
                                <%--<input type="password" id="loginPass" class="fb-input" placeholder="Enter your password" style="padding-right: 2.8rem" />
                                <i class="bi bi-eye" id="toggleLoginPass" style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); cursor: pointer; color: var(--text-muted)"></i>--%>
                                 <asp:TextBox  CssClass="fb-input" ID="txtPassword" runat="server" TextMode="Password" />
                                 <asp:RequiredFieldValidator ID="rfvPass" runat="server"
                                     ControlToValidate="txtPassword"
                                     ErrorMessage="Password is required"
                                     CssClass="validator-msg"
                                     Display="Dynamic"  ValidationGroup="LoginGroup"  />
                            </div>


                        </div>
                        <div class="d-flex justify-content-between align-items-center mb-3">
                            <label style="display: flex; align-items: center; gap: .5rem; font-size: .87rem; cursor: pointer">
                                <input type="checkbox" class="form-check-input m-0" />
                                Remember me</label>
                            <a href="#" style="font-size: .85rem; color: var(--green); font-weight: 600">Forgot Password?</a>
                        </div>
                        <%--<button class="btn-green w-100 py-2" style="border-radius: var(--radius-sm)" onclick="fbToast('Login successful! Redirecting...')">Sign In</button>--%>
                        <%--Error label--%>
                        <div>
                            <asp:Label ID="lblError" runat="server" ForeColor="Red" CssClass="mb-3"></asp:Label>
                        </div>
                        <asp:Button  ValidationGroup="LoginGroup"  class="btn-green w-100 py-2" Style="border-radius: var(--radius-sm)" runat="server" OnClick="btnLogin_Click" Text="Sign In"></asp:Button>
                        <div class="divider">or continue with</div>
                        <div class="d-flex gap-2">
                            <button class="btn-sm-outline w-100 py-2" style="border-radius: var(--radius-sm)"><i class="bi bi-google me-1"></i>Google</button>
                            <button class="btn-sm-outline w-100 py-2" style="border-radius: var(--radius-sm)"><i class="bi bi-facebook me-1"></i>Facebook</button>
                        </div>
                        <p class="text-center mt-3" style="font-size: .85rem; color: var(--text-muted)">Don't have an account? <a href="#" class="text-success fw-600" style="font-weight: 600" onclick="document.querySelector('[data-tab=registerPanel]').click()">Register here</a></p>
                    </div>
                            <asp:Label ID="lblMessage2" runat="server" Visible="false" CssClass="alert"></asp:Label>

                    <!-- REGISTER PANEL -->
                    <div id="registerPanel" class="auth-panel d-none">
                        <div class="fb-form-group">
                            <label  for="txtFullName">Full Name</label>
                            <%--<input type="text" class="fb-input" placeholder="Your full name" />--%>
                             <asp:TextBox ID="txtFullName" runat="server" placeholder="Ahmed Khan" class="fb-input" />
                             <asp:RequiredFieldValidator ID="rfvName" runat="server"
                                 ControlToValidate="txtFullName"
                                 ErrorMessage="Name is required"
                                 CssClass="validator-msg"
                                 Display="Dynamic" ValidationGroup="RegisterGroup"  />
                        </div>
                        <div class="fb-form-group">
                            <label for="txtEmailReg">Email Address</label>
                            <%--<input type="email" class="fb-input" placeholder="you@example.com" />--%>
                              <asp:TextBox class="fb-input" ID="txtEmailReg" runat="server" TextMode="Email" placeholder="you@example.com" />
                              <asp:RequiredFieldValidator ID="RequiredFieldValidator1" runat="server"
                                  ControlToValidate="txtEmailReg"
                                  ErrorMessage="Email is required"
                                  CssClass="validator-msg"
                                  Display="Dynamic"  ValidationGroup="RegisterGroup"/>
                              <asp:RegularExpressionValidator ID="revEmail" runat="server"
                                  ControlToValidate="txtEmailReg"
                                  ValidationExpression="^[^@\s]+@[^@\s]+\.[^@\s]+$"
                                  ErrorMessage="Enter a valid email"
                                  CssClass="validator-msg"
                                  Display="Dynamic"  ValidationGroup="RegisterGroup" />
                        </div>
                        <div class="fb-form-group">
                            <label for="txtPhone">Phone Number</label>
                            <%--<input type="tel" class="fb-input" placeholder="+92 300 0000000" />--%>
                              <asp:TextBox ID="txtPhone" runat="server" class="fb-input" placeholder="0300-1234567" />
                        </div>
                        <div class="fb-form-group">
                            <label  for="ddlRole">Register As</label>
                         <%--   <select class="fb-input fb-select">
                                <option value="">Select your role...</option>
                                <option>Food Donor (Individual)</option>
                                <option>Food Donor (Restaurant / Business)</option>
                                <option>NGO / Charity Organization</option>
                                <option>Volunteer</option>
                            </select>--%>
                             <asp:DropDownList CssClass="fb-input fb-select" ID="ddlRole" runat="server">
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
                                Display="Dynamic" ValidationGroup="RegisterGroup" />
                        </div>
                        <div class="fb-form-group" id="orgField" style="display: none">
                            <label>Organization Name</label>
                            <input type="text" class="fb-input" placeholder="Your NGO or organization name" />
                        </div>
                     <%--   <div class="fb-form-group">
                            <label>City</label>
                            <select class="fb-input fb-select">
                                <option value="">Select city...</option>
                                <option>Karachi</option>
                                <option>Lahore</option>
                                <option>Islamabad</option>
                                <option>Rawalpindi</option>
                                <option>Peshawar</option>
                                <option>Quetta</option>
                            </select>
                        </div>--%>
                        <div class="fb-form-group">
                            <label for="txtAddress">Address</label>
                                       <asp:TextBox CssClass="fb-input" ID="txtAddress" runat="server" placeholder="Street, Area, City" />

                        </div>
                        <div class="fb-form-group">
                            <label for="txtPasswordReg">Password</label>
                            <%-- <div style="position:relative">
            <input type="password" id="regPass" class="fb-input" placeholder="Create a strong password" style="padding-right:2.8rem"/>
            <i class="bi bi-eye" id="toggleRegPass" style="position:absolute;right:1rem;top:50%;transform:translateY(-50%);cursor:pointer;color:var(--text-muted)"></i>

          </div>--%>
                           <%-- <div style="position: relative">

                                <asp:TextBox
                                    ID="password"
                                    runat="server"
                                    CssClass="fb-input"
                                    TextMode="Password"
                                    placeholder="Create a strong password"
                                    Style="padding-right: 2.8rem;">
                                </asp:TextBox>

                                <i class="bi bi-eye"
                                    id="toggleRegPass"
                                    style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); cursor: pointer; color: var(--text-muted)"></i>

                            </div>--%>
                            <asp:TextBox  CssClass="fb-input" ID="txtPasswordReg" runat="server" TextMode="Password" placeholder="Min. 6 characters" />
    <asp:RequiredFieldValidator ID="rfvPassReg" runat="server"
     ControlToValidate="txtPasswordReg"
     ErrorMessage="Password is required"
     CssClass="validator-msg"
     Display="Dynamic" ValidationGroup="RegisterGroup" />
 <asp:RegularExpressionValidator ID="revPassReg" runat="server"
     ControlToValidate="txtPasswordReg"
     ValidationExpression=".{6,}"
     ErrorMessage="Min. 6 characters"
     CssClass="validator-msg"
     Display="Dynamic"  ValidationGroup="RegisterGroup"/>
                        </div>

                                      <div class="fb-form-group">
                  <label for="txtConfirmPass">Confirm Password</label>
                  <%-- <div style="position:relative">
  <input type="password" id="regPass" class="fb-input" placeholder="Create a strong password" style="padding-right:2.8rem"/>
  <i class="bi bi-eye" id="toggleRegPass" style="position:absolute;right:1rem;top:50%;transform:translateY(-50%);cursor:pointer;color:var(--text-muted)"></i>

</div>--%>

                                            <asp:TextBox CssClass="fb-input" ID="txtConfirmPass" runat="server" TextMode="Password" placeholder="Repeat password" />
  <asp:CompareValidator ID="cvPass" runat="server"
      ControlToValidate="txtConfirmPass"
      ControlToCompare="txtPasswordReg"
      ErrorMessage="Passwords do not match"
      CssClass="validator-msg"
      Display="Dynamic"   ValidationGroup="RegisterGroup"/>
                  <%--<div style="position: relative">

                      <asp:TextBox
                          ID="Con"
                          runat="server"
                          CssClass="fb-input"
                          TextMode="Password"
                          placeholder="Create a strong password"
                          Style="padding-right: 2.8rem;">
                      </asp:TextBox>

                      <i class="bi bi-eye"
                          id="toggleRegPass"
                          style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); cursor: pointer; color: var(--text-muted)"></i>

                  </div>--%>
              </div>
                        <div class="fb-form-group">
                            <label style="display: flex; align-items: flex-start; gap: .5rem; font-size: .85rem; cursor: pointer; font-weight: 400">
                                <input type="checkbox" class="form-check-input mt-0 flex-shrink-0" />
                                I agree to the <a href="#" style="color: var(--green)">Terms of Service</a> and <a href="#" style="color: var(--green)">Privacy Policy</a>
                            </label>
                        </div>
                       
                        <%--<button class="btn-green w-100 py-2" style="border-radius: var(--radius-sm)" onclick="fbToast('Account created! Please verify your email.')">Create Account</button>--%>
                        <asp:Button  ValidationGroup="RegisterGroup" runat="server"  OnClick="btnRegister_Click"  class="btn-green w-100 py-2" style="border-radius: var(--radius-sm)" Text="Create Account" />
                        <p class="text-center mt-3" style="font-size: .85rem; color: var(--text-muted)">Already have an account? <a href="#" style="color: var(--green); font-weight: 600" onclick="document.querySelector('[data-tab=loginPanel]').click()">Sign in</a></p>
                    </div>

                </div>
            </div>
        </div>
    </form>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="assets/js/main.js"></script>
    <script>
        // Toggle password visibility
        ['loginPass', 'regPass'].forEach(id => {
            const inp = document.getElementById(id);
            const btn = document.getElementById('toggle' + id.charAt(0).toUpperCase() + id.slice(1));
            if (btn) btn.addEventListener('click', () => {
                inp.type = inp.type === 'password' ? 'text' : 'password';
                btn.className = inp.type === 'password' ? 'bi bi-eye' : 'bi bi-eye-slash';
                btn.style.cssText = btn.style.cssText;
            });
        });
        // Show org field when NGO selected
        document.querySelector('select')?.addEventListener('change', function () {
            document.getElementById('orgField').style.display = this.value.includes('NGO') ? 'block' : 'none';
        });
    </script>
</body>
</html>
