namespace Admin { namespace Item {
	class Listing : Object {
		public Routes route { public get; public set; }	
		public Json.Object session { public get; public set; }	
		public string session_id { public get; public set; }	
	
		public Listing (Routes route, Json.Object session, string session_id) {
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
			var dbh = new Application.Db ();
			unowned Mysql.Database? db = dbh.get_db ();
			var error = true;
			var error_msg = "";
			
			var query = "SELECT * FROM zoey_items ORDER BY title";
			var error_no = db.query (query);
			
			if (error_no == 0) {
				var result = db.use_result ();
				if (result != null) {
					for (var i = 0; i < result.num_rows (); i++) {
						var row = result.fetch_row ();
						if (row != null) {
							stderr.printf (row[0]);
						}
					}
					while (!result.eof ()) {
						var row = result.fetch_row ();
						if (row != null) {
							var id = dbh.get_value_by_row(result, row, "id");
							stderr.printf ("ID: %s\n", id);
						}
					}
					//stderr.printf ("No. Of Counts:" + result.eof ().to_string () + "\n");
					stderr.printf ("No. Of Results:" + result.num_rows ().to_string () + "\n");
					//dbh.get_row_value (result, "id");
				} else {
					stderr.printf ("Result is emtpy...?\n");
				}
			} else {
				error_msg = "Sorry having problems accessing the database";
				stderr.printf (db.error () + "\n");
			}
		}
	}
}}
