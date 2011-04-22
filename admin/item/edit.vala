namespace Admin {
	namespace Item {
		class Edit : Object {
			public Routes route { public get; public set; }	
			public Json.Object session { public get; public set; }	
			public string session_id { public get; public set; }	
		
			public Edit (Routes route, Json.Object session, string session_id) {
				this.route = route;
				this.session = session;
				this.session_id = session_id;
			}
			
			public void run () {
				unowned Soup.MessageHeaders headers = this.route.msg.response_headers;
				unowned Soup.MessageHeaders request_headers = this.route.msg.request_headers;
				unowned Soup.MessageBody request_body = this.route.msg.request_body;
				HashTable<string, string>? post = Soup.Form.decode ((string) request_body.data);
				HashTable<string, string>? get = this.route.query;
				var multipart = new Soup.Multipart.from_message (request_headers, request_body);
				var image = new Application.Upload (request_headers, request_body, "image");
				if (image.filename != "" && image.filename != null) {
					stderr.printf ("writing to file...\n");
					image.write ("image.png");
					//-- Scale Image
					var cmd = "convert 'image.png' -quality 75 -resize 120x120 image-120x120.jpg";
					var standard_output = ""; 
					var standard_error = ""; 
					var exit_status = 0;
					try {
						Process.spawn_command_line_sync (cmd, out standard_output, out standard_error, out exit_status);
						stderr.printf (standard_output + "\n");
						stderr.printf (standard_error + "\n");
					} catch (SpawnError e) {
						stderr.printf ("Error: " + e.message);
					}
				}
				
				string? item_id = null;
				string? category_id = null;
				var error = true;
				var error_msg = "";
				if (post != null) {
					item_id = post.lookup ("id");
					category_id = post.lookup ("category_id");
				} else if (get != null) {
					item_id = get.lookup ("id");
					category_id = get.lookup ("category_id");
				}
			
				string? item_name = null;
				string? item_description = null;
				/*
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
							if (admin_id != "") {
								if (!this.session.has_member ("admin")) {
									this.session.set_object_member ("admin", new Json.Object());
								}
								var admin = this.session.get_object_member ("admin");
								admin.set_int_member("id", int64.parse (admin_id));
								unowned Soup.MessageHeaders headers = this.route.msg.response_headers;
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
				*/
				var tpl = new Template();
			
				var html = tpl.header ("login") + """
				<div id="intro">
					<div id="intro-in">
						<h2>Add / Edit an Item</h2>
						<form action="" method="post" enctype="multipart/form-data">
							<input id="item_id" type="hidden" name="item_id" value='""" + Application.encode_attr(item_id) + """' />
							<strong style="color:red">""" + error_msg + """</strong><br />
							<label for="item_name">Item Name</label>
							<input id="item_name" type="text" name="item_name" value='""" + Application.encode_attr(item_name) + """' /><br />
							<label for="item_description">Description</label>
							<textarea name="item_description" id="item_description">""" + Application.encode_attr(item_description) + """</textarea><br />
							<input type="file" name="image" value="" />
							<input type="submit" value="Save" />
						</form>
					</div>
				</div>
				""" + tpl.footer ();
			
				this.route.msg.set_status (200);
				this.route.msg.set_response ("text/html", Soup.MemoryUse.COPY, html.data);
			}
		}
	}
}
