namespace Application {
	public string encode_attr (string? attr) {
		if (attr == null) {
			return attr;
		} else {
			var output = attr.dup();
			output = output.replace (">", "&gt;");
			output = output.replace ("<", "&lt;");
			output = output.replace ("\"", "&quot;");
			output = output.replace ("'", "&#39;");
		
			return output;
		}
	}
	
	class UploadFile : Object {
		public string filename { public get; public set; }
		public int64 filesize { public get; public set; }
		public Soup.Buffer data { public get; public set; }
		
		public UploadFile (string filename, int64 filesize, Soup.Buffer data) {
			this.filename = filename;
			this.filesize = filesize;
			this.data = data;
		}
		
		public void write (string path) {
			stderr.printf ("Writing: " + path + " :)\n");
			File f = File.new_for_commandline_arg(path);
			FileOutputStream fo_stream = null;
		
			try {
				if (f.query_exists(null)) {
				    f.delete(null);
		    	}
				fo_stream = f.create (FileCreateFlags.REPLACE_DESTINATION, null);
			} catch(Error e) {
				stderr.printf ("Cannot create file. %s\n", e.message);
				return;
			}
			
			try {
				fo_stream.write (this.data.data, null);
			} catch(GLib.IOError e) {
				stderr.printf ("%s\n", e.message);
				return;
			}
			return;
		}
	}
	
	class Upload : Object {
		public unowned Soup.MessageHeaders headers { public get; public set; }
		public unowned Soup.MessageBody body { public get; public set; }
		public string name { public get; public set; }
		public bool is_uploaded { get; set; default = false; }
		public bool is_multi { get; set; default = false; }
		public Gee.ArrayList<UploadFile> data { public get; public set; }
		public Upload (Soup.MessageHeaders headers, Soup.MessageBody body,
			string name) {
			this.headers = headers;
			this.body = body;
			this.name = name;
			this.data = new Gee.ArrayList<UploadFile> ();
			this.parse ();
		}
		
		public int number_of_files () {
			return this.data.size;
		}
		
		public void parse () {
			var multipart = new Soup.Multipart.from_message (
				this.headers, this.body
			);
			if (multipart != null) {
				for (var i = 0; i < multipart.get_length (); i++) {
					unowned Soup.MessageHeaders part_headers;
					unowned Soup.Buffer part_body;
					bool has_disposition;
					string disposition;
					HashTable<string, string>? params;
					bool has_part = multipart.get_part (
						i, out part_headers, out part_body
					);
					if (has_part) {
						var filesize = part_body.length;
						has_disposition = part_headers.get_content_disposition (
							out disposition, out params
						);
						if (has_disposition) {
							if (disposition != "form-data") {
								continue;
							}
							stderr.printf("name: %s\n", params.lookup ("name"));
							if (params.lookup ("name") == this.name) {
								var filename = params.lookup ("filename");
								stderr.printf ("%s: %s\n", filename, filesize.to_string ());
								var uploadfile = new UploadFile (
									filename, filesize, part_body
								);
								this.data.add(uploadfile);
								if (!this.is_uploaded) {
									this.is_uploaded = true;
								} else {
									this.is_multi = true;
								}
							}
						}
					}
				}
			}		
		}
	}
}
