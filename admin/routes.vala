namespace Admin {
	class Routes : Object {
		public Soup.Server server { public get; public set; }
		public Soup.Message msg { public get; public set; }
		public string path { public get; public set; }
		public GLib.HashTable? query { public get; public set; }
		public unowned Soup.ClientContext client { public get; public set; }
		public WebApplication application { public get; public set; }
		
		public Routes (
			Soup.Server server, Soup.Message msg, string path,
			GLib.HashTable? query, Soup.ClientContext client, 
			WebApplication application
		) {
			this.server = server;
			this.msg = msg;
			this.path = path;
			this.query = query;
			this.client = client;
			this.application = application;
	  	}
	  	
	  	public void run () {
			var sid = this.application.get_session_id (msg);
			var session = this.application.sessions[sid];
			var id = (int64) 0;
			
			if (session.has_member ("admin")) {
				stderr.printf ("looking for admin\n");
				var admin = session.get_object_member ("admin");
				if (admin.has_member ("id")) {
					stderr.printf ("found id\n");
					id = admin.get_int_member ("id");
				}
			}
			
			if (id > 0) {
				//stderr.printf ("Adlready logged in ?");
			} else {
				var login = new Login (this, session, sid);
				login.run ();
				this.application.save_session (sid);
				return;
			}
			
			if (path == "/admin/" || path == "/admin") {
				unowned Soup.MessageHeaders headers = this.msg.response_headers;
				headers.append("Location", "/admin/dashboard");
				this.msg.set_status (301);
			} else if (path == "/admin/dashboard/" || path == "/admin/dashboard") {
				var dashboard = new Dashboard (this, session, sid);
				dashboard.run ();
			}  else if (path.index_of("/admin/item/edit") > -1) {
				var edit = new Item.Edit (this, session, sid);
				edit.run ();
			}   else if (path.index_of("/admin/item") > -1) {
				stderr.printf ("Item listing\n");
				var list = new Item.Listing (this, session, sid);
				list.run ();
			} else {
			}
			this.application.save_session (sid);
	  	}
	}
}
