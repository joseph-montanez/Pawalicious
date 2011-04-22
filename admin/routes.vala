namespace Admin {
	class Routes : Object {
		public Soup.Server server { public get; public set; }
		public Soup.Message msg { public get; public set; }
		public string path { public get; public set; }
		public GLib.HashTable? query { public get; public set; }
		public unowned Soup.ClientContext client { public get; public set; }
		public Pawalicous application { public get; public set; }
		
		public Routes (
			Soup.Server server, Soup.Message msg, string path,
			GLib.HashTable? query, Soup.ClientContext client, 
			Pawalicous application
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
				return;
			}
			
			if (path == "/admin/" || path == "/admin") {
				unowned Soup.MessageHeaders headers = this.msg.response_headers;
				headers.append("Location", "/admin/dashboard");
				this.msg.set_status (301);
			} else if (path == "/admin/dashboard/" || path == "/admin/dashboard") {
				var dashboard = new Dashboard (this, session, sid);
				dashboard.run ();
				return;
			}  else if (path == "/admin/item/edit/" || path == "/admin/item/edit") {
				var edit = new Item.Edit (this, session, sid);
				edit.run ();
				return;
			} else {
				/*
				var cmd = """xsltproc simple.xsl "<bugs>     <bug id=\"3\" severity=\"1\" title=\"Hello Wold has bugs in it\">        <owner>nobody</owner>        <sa id=\"10\" owner=\"george\"/>        <entry date=\"2007-10-25\">            The bug was formed from a service assist ticket.        </entry>        <entry date=\"2007-10-27\">            This is an entry in the future. Ohhhh....        </entry>    </bug></bugs>";""";
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
				*/
			}
	  	}
	}
}
