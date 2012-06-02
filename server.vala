class WebApplication {
	public Gee.HashMap<string, Json.Object> sessions;
	
	public WebApplication ()
	{
		this.sessions = new Gee.HashMap<string, Json.Object> ();
	}
	
	public void save_session (string sid)
	{
		var node = new Json.Node (Json.NodeType.OBJECT);
		node.set_object (this.sessions[sid]);
		var generator = new Json.Generator ();
		generator.set_root (node);
		try {
			generator.to_file (sid + ".json");
		} catch (Error e) {}
	}
	
	public void create_session(string sid)
	{
		this.sessions[sid] = new Json.Object ();
	}
	
	public string get_session_id (Soup.Message msg)
	{
		unowned Soup.MessageHeaders headers = msg.response_headers;
		unowned Soup.MessageHeaders request_headers = msg.request_headers;
		
		string sid = "";

		request_headers.foreach ((key, name) => {
			if (key == "Cookie") {
				Soup.Cookie parsedCookie = Soup.Cookie.parse (
					key.replace ("Cookie:", "").strip () + ":" + name,
					new Soup.URI ("/")
				);
				if (parsedCookie.name == "Cookie:sid") {
					sid = parsedCookie.value;
				}
			}
		});
		
		if (sid == "") {
			// There is no session make one
			sid = Random.int_range (1, 1000000).to_string ();
			sid += new DateTime.now_local ().to_unix ().to_string ();
			
			var hash = new GNet.MD5.buf (sid.to_utf8 ());
			
			//sha.update (sid.to_utf8 ());
			sid = hash.get_string ();
		}
		
		if (!this.sessions.has_key (sid)) {
			// Check to see if this is on file
			var created_session = false;
			if (sid != "") {
				var file = File.new_for_path (sid + ".json");
				if (file.query_exists ()) {
					var json = "";
					try {
						var dis = new DataInputStream (file.read ());
						string line;
						while ((line = dis.read_line (null)) != null) {
							json += line;
						}
					} catch (Error e) {
						stderr.printf ("%s", e.message);
					}
					if (json != "") {
						try {
							var parser = new Json.Parser ();
							var loaded = parser.load_from_data (json);
							if (loaded) {
								this.sessions[sid] = parser.get_root ().get_object ();
								created_session = true;
							}
						} catch (Error e) {}
					}
				}
			}
			if (!created_session) {
				this.create_session (sid);
			}
			var cookie = new Soup.Cookie ("sid", sid, "127.0.0.1", "/", 12000);
			headers.append("Set-Cookie", cookie.to_set_cookie_header ());
		}
		
		return sid;
	}
	
	//Gee.HashMap<string, Soup.Cookie> cookies;
	public void default_handler (Soup.Server server, Soup.Message msg, string path,
						  GLib.HashTable? query, Soup.ClientContext client)
	{
		string sid = this.get_session_id (msg);
		//Json.Object session = this.sessions[sid];
		string response_text = """
			<html>
			  <body>
				<p>Comming Soon!</p>
			  </body>
			</html>""" + sid;

		msg.set_response ("text/html", Soup.MemoryUse.COPY,
						  response_text.data);
	}
	
	void admin_handler (Soup.Server server, Soup.Message msg, string path,
						  GLib.HashTable? query, Soup.ClientContext client)
	{
		//HashTable<string, string>? = Soup.form_decode(msg.request_body.data)
		//HashTable<string, string>? query = this.route.query;
		var admin = new Admin.Routes (server, msg, path, query, client, this);
		admin.run ();
	}
	
	void static_handler (Soup.Server server, Soup.Message msg, string path,
					  GLib.HashTable? query, Soup.ClientContext client)
	{
		var response_text = "";
		unowned uint8[] data;
		var file = File.new_for_path ("." + path);
		var mimetype = "text/html";

		if (!file.query_exists ()) {
			response_text += "File does not exist " + path +  "<br>";
			data = response_text.data;
		}
		try {
			int64 length;
			var basename = file.get_basename ();
			var parts = basename.split (".");
			var ext = parts[parts.length - 1];
			if (ext == "png") {
				mimetype = "image/png";
			} else if (ext == "css") {
				mimetype = "text/css";
			} else if (ext == "jpg") {
				mimetype = "image/jpeg";
			}
			var filestream = file.read ();
			var datastream = new DataInputStream (filestream);
			var info = filestream.query_info ("*", null);
			if(mimetype == "text/html" || mimetype == "text/css") {
				string line;
				while ((line = datastream.read_line (null)) != null) {
					response_text += line;
				}
				data = response_text.data;
			} else {
				length = info.get_size ();
				uchar[] list = new uchar[length];
				for (var i = 0; i < length; i++) {
					uchar byte = datastream.read_byte ();
					list[i] = byte;
				}
				data = list;
				
				unowned Soup.MessageHeaders headers = msg.response_headers;
				
				/* ETag */
				headers.append ("ETag", "\"" + info.get_etag () + "\"");
				/* Last-Modified */
				var modified = info.get_modification_time ();
				headers.append ("Last-Modified", modified.to_iso8601 ());
			}
			/* Status */
			msg.set_status (200);
		} catch (Error e) {
			response_text += e.message + "<br>";
			data = response_text.data;
		}
		
		msg.set_response (mimetype, Soup.MemoryUse.COPY, data);
	}

	public static int main(string[] args) {
		var webapplication = new WebApplication ();
		var server = new Soup.Server (
			Soup.SERVER_PORT, 8000
		);
		server.add_handler ("/", webapplication.default_handler);
		server.add_handler ("/static", webapplication.static_handler);
		server.add_handler ("/admin", webapplication.admin_handler);
		
		
		stdout.printf("Running...\n");

		server.run ();

		return 0;
	}
}
