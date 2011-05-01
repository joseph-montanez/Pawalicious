namespace Admin { namespace Item {
		class Edit : Object {
			public Routes route { public get; public set; }	
			public Json.Object session { public get; public set; }	
			public string session_id { public get; public set; }	
		
			public Edit (Routes route, Json.Object session, string session_id) {
				this.route = route;
				this.session = session;
				this.session_id = session_id;
			}
			
			public ulong insert (string table, Gee.HashMap<string, string> fields) {
				ulong last_id = 0;
				var dbh = new Application.Db ();
				unowned Mysql.Database? db = dbh.get_db ();
				var query = "INSERT INTO " + table + " (";
				var keys = new Gee.ArrayList<string> ();
				var values = new Gee.ArrayList<string> ();
				
				if (fields.size == 0) {
					return last_id;
				}
				
				foreach (var entry in fields.entries) {
					keys.add (entry.key);
					
					unichar[] value_escaped = new unichar[entry.value.length * 2 + 1];
					db.real_escape_string ((string) value_escaped, entry.value, entry.value.length);
					values.add ((string) value_escaped);
				}
				
				foreach (string key in keys) {
					query += key + ",";
				}
				stderr.printf ("Keys: " + query + "\n");
				query = query.substring (0, query.length - 1) + ") VALUES (";
				
				foreach (string value in values) {
					query += "\"" + value + "\",";
				}
				stderr.printf ("Values: " + query + "\n");
				query = query.substring (0, query.length - 1) + ")";
				
				stderr.printf ("Query: " + query + "\n");
				var error_no = db.query (query);
				
				if (error_no == 0) {
					last_id = db.insert_id ();
				}
				
				return last_id;
			}
			
			public void run () {
				unowned Soup.MessageHeaders headers = this.route.msg.response_headers;
				unowned Soup.MessageHeaders request_headers = this.route.msg.request_headers;
				unowned Soup.MessageBody request_body = this.route.msg.request_body;
				HashTable<string, string>? post = Soup.Form.decode ((string) request_body.data);
				HashTable<string, string>? get = this.route.query;
				var multipart = new Soup.Multipart.from_message (request_headers, request_body);
				var post_multipart = new Application.Multipart (request_headers, request_body);
				string? item_id = null;
				string? title = null;
				string? description = null;
				string? category_id = null;
				var error = true;
				var error_msg = "";
				if (post != null) {
					var fields = new Gee.HashMap<string, string> ();
				
					if(post_multipart.has_key("title")) {
						var title_field = post_multipart.data["title"];
						title = title_field.get_first ();
						title = title.strip ();
						fields["title"] = title;
					}
					
					if(post_multipart.has_key("description")) {
						var description_field = post_multipart.data["description"];
						description = description_field.get_first ();
						description = description.strip ();
						fields["description"] = description;
					}
					
					var last_id = this.insert ("zoey_items", fields);
					
					if (last_id > 0) {
						if (post_multipart.has_key("uploadedfiles[]")) {
							var image = post_multipart.data["uploadedfiles[]"].data;
							stderr.printf ("is uploaded...\n");
							foreach (var file in image) {
								// Save image to file, yay!
								file.write (file.filename);
								
								var image_fields = new Gee.HashMap<string, string> ();
								image_fields["item_id"] = last_id.to_string ();
								image_fields["filename"] = file.filename;
								/* Get width and height */
								var size = Application.get_size (file.filename);
								image_fields["width"] = size[0].to_string ();
								image_fields["height"] = size[1].to_string ();
								/* Resize the image */
								this.insert ("zoey_items_images", image_fields);
								stderr.printf ("writing to file...\n");
							}
							this.route.msg.set_status (200);
							return;
						}
					}
				} else if (get != null) {
					item_id = get.lookup ("id");
					category_id = get.lookup ("category_id");
				}
				
				var tpl = new Template();
			
				string html = tpl.header ("login") + """
				<div id="intro">
					<div id="intro-in">
						<h2>Add / Edit an Item</h2>
						<form id="myForm" action="/admin/item/edit" method="post" enctype="multipart/form-data">
							<input id="item_id" type="hidden" name="item_id" value='""" + Application.encode_attr(item_id) + """' /> 
							<strong style="color:red">""" + error_msg + """</strong><br />
							<label for="title">Item Name</label><br />
							<input dojo-data-id="title" data-dojo-type="dijit.form.TextBox" id="title" type="text" name="title" value='""" + Application.encode_attr(title) + """' data-dojo-props='name:"title"' /><br />
							<label for="description">Description</label>
							<textarea id="description" name="description" style="display: none"></textarea>
							<div dojo-data-id="editor_description" dojo-data-name="editor_description" data-dojo-type="dijit.Editor" data-dojo-props='name:"description"'>""" + Application.encode_attr(description) + """</div><br />
							<h2>Images</h2>
							<input name="uploadedfile" multiple="true" type="file" id="uploader" dojoType="dojox.form.Uploader" url="/admin/item/edit" label="Select Some Files" >
							<div id="files" dojoType="dojox.form.uploader.FileList" uploaderId="uploader"></div>
							<input type="submit" id="submitter" label="Submit" dojoType="dijit.form.Button" />
						</form>
					</div>
				</div>
				
				<script type="text/javascript">
					dojo.require("dojo.data.ItemFileReadStore");
					dojo.require("dijit.form.TextBox");
					dojo.require("dijit.Editor");
					dojo.require("dijit.form.DateTextBox");
					dojo.require("dijit.form.FilteringSelect");
					dojo.require("dijit.form.Form");
					dojo.require("dijit.form.Button");
					dojo.require("dojox.form.Uploader");
					dojo.require("dojox.form.uploader.FileList");
					dojo.require("dojox.form.uploader.plugins.HTML5");
					
					dojo.ready(function () {
						dijit.byId('dijit_Editor_0').connect(dijit.byId('dijit_Editor_0'), 'onKeyUp', function (evt) {
							dojo.attr('description', 'value', dijit.byId('dijit_Editor_0').get('value'));
						});
					});
					/*
					dojo.connect(dojo.byId('submitter'), 'onclick', function (evt) {
						dojo.attr('description', 'value', dijit.byId('dijit_Editor_0').get('value'));
						dojo.attr('description', 'innerHTML', dijit.byId('dijit_Editor_0').get('value'));
					});
					*/
					/*
					dojo.byId('body').ondrop = function (e) {
						e.preventDefault();
						return false;
					};
					dojo.byId('body').dragend = function (e) {
						e.preventDefault();
						return false;
					}
					*/
				</script>
				""" + tpl.footer ();
			
				this.route.msg.set_status (200);
				this.route.msg.set_response ("text/html", Soup.MemoryUse.COPY, html.data);
			}
		}
}}
