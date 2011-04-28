namespace Admin {
	class Login : Object {
		public Routes route { public get; public set; }	
		public Json.Object session { public get; public set; }	
		public string session_id { public get; public set; }	
		
		public Login (Routes route, Json.Object session, string session_id) {
			this.route = route;
			this.session = session;
			this.session_id = session_id;
		}
		
		public bool is_logged_in() {
			var logged_in = false;
			if (this.session.has_member ("admin")) {
				var admin = this.session.get_object_member ("admin");
				if (admin.has_member ("id")) {
					var id = admin.get_int_member ("id");
					if (id > 0) {
						logged_in = true;
					} 
				}
			}
			
			return logged_in;
		}
		
		public void run () {
			unowned Soup.MessageHeaders headers = this.route.msg.response_headers;
			// Check to see if they are already logged in
			if (is_logged_in()) {
				headers.append("Location", "/admin/dashboard");
				this.route.msg.set_response ("text/html", Soup.MemoryUse.COPY, "".data);
				return;
			}
			
		
			HashTable<string, string>? post = Soup.Form.decode ((string) this.route.msg.request_body.data);
			string? username = null;
			string? passwd = null;
			var error = true;
			var error_msg = "";
			if (post != null) {
				username = post.lookup ("username");
				passwd = post.lookup ("passwd");
			}
			
			
			if (username != null && passwd != null) {
				unichar[] username_escaped = new unichar[username.length * 2 + 1];
				unichar[] passwd_escaped = new unichar[username.length * 2 + 1];
				
				var dbh = new Application.Db ();
				unowned Mysql.Database? db = dbh.get_db ();
				
				db.real_escape_string ((string) username_escaped, username, username.length);
				db.real_escape_string ((string) passwd_escaped, passwd, passwd.length);
				var query = "SELECT * FROM zoey_admins WHERE username = '" + (string) username_escaped + "' AND passwd = '" + (string) passwd_escaped + "'";
				var error_no = db.query (query);
				
				if (error_no == 0) {
					var result = db.use_result ();
					if (result != null) {
						error = false;
						var admin_id = dbh.get_row_value (result, "id");
						stderr.printf ("Admin: " + admin_id + "\n");
						if (admin_id != "") {
							if (!this.session.has_member ("admin")) {
								this.session.set_object_member ("admin", new Json.Object());
							}
							var admin = this.session.get_object_member ("admin");
							admin.set_int_member("id", int64.parse (admin_id));
							stderr.printf ("Redirecting... \n");
							headers.append("Location", "/admin/dashboard");
							this.route.msg.set_status (301);
							return;
						} else {
							error_msg = "Invalid Username or Password";
						}
						// TODO: add to session
					} else {
						error_msg = "Invalid Username or Password";
					}
				} else {
					error_msg = "Sorry having problems accessing the database";
					stderr.printf (db.error () + "\n");
				}
			}
			stderr.printf ("Error: " + error_msg + "\n");
			
			var tpl = new Template();
			
			var html = tpl.header ("login") + """
			<div id="intro">
				<div id="intro-in">
					<h2>Welcome to our site</h2>
					<p class="intro">
						Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.
					</p>
					<form action="" method="post" data-dojo-type="dijit.form.Form" data-dojo-props='method:"post"'>
						<strong style="color:red">""" + error_msg + """</strong><br />
						<label for="username">Username</label><br />
						<input id="username" type="text" name="username" value='""" + Application.encode_attr(username) + """' data-dojo-id="username" data-dojo-type="dijit.form.TextBox" data-dojo-props='name:"username"' /><br />
						<label for="passwd">Password</label><br />
						<input id="passwd" name="passwd" value='""" + Application.encode_attr(passwd) + """' data-dojo-id="passwd" data-dojo-type="dijit.form.TextBox" type="password" data-dojo-props='name: "passwd", type:"password"' /><br />
						<input type="submit" label="Login" dojoType="dijit.form.Button" />
					</form>
				</div>
			</div>
			<script type="text/javascript">
				dojo.require("dijit.form.Button");
				dojo.require("dijit.form.TextBox");
				dojo.require("dijit.form.Form");
			</script>
			""" + tpl.footer ();
			
			this.route.msg.set_status (200);
			this.route.msg.set_response ("text/html", Soup.MemoryUse.COPY, html.data);
		}
	}
}
