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
	
	public void resize (string filename) {
		/* TODO: make this function safe for filenames with spaces */
		var cmd = "convert '" + filename + "' -quality 75 -resize 120x120 image-120x120.jpg";
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
	
	public uint64[] get_size (string filename) {
		uint64[] size = new uint64[2];
		size[0] = 0;
		size[1] = 0;
		/* TODO: make this function safe for filenames with spaces */
		var cmd = "identify -format \"%[fx:w]x%[fx:h]\" '" + filename + "'";
		var standard_output = ""; 
		var standard_error = ""; 
		var exit_status = 0;
		try {
			Process.spawn_command_line_sync (cmd, out standard_output, out standard_error, out exit_status);
			var sizes = standard_output.split("x", 2);
			size[0] = uint64.parse (sizes[0]);
			size[1] = uint64.parse (sizes[1]);
			stderr.printf (standard_output + "\n");
			stderr.printf (standard_error + "\n");
		} catch (SpawnError e) {
			stderr.printf ("Error: " + e.message);
		}
		
		return size;
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
	
	class UploadFileList : Object {
		public Gee.ArrayList<UploadFile> data { public get; public set; }
		public UploadFileList () {
			this.data = new Gee.ArrayList<UploadFile> ();
		}
		
		public string get_first () {
			var value = "";
			
			if (this.data.size > 0) {
				var first = this.data.get (0);
				if (first.data.length > 0) {
					/*
					var tmpstr = "";
					for (var i = 0; i < first.data.length; i++) {
						tmpstr += first.data.data[i].to_string ("%c");
					}
					stderr.printf ("Binary Value: " + tmpstr + "\n");
					*/
					value = (string) first.data.data;
					// WHY IS THIS NULL!?
					if (value == null) {
						value = "";
					}
				}
				stderr.printf (value + "\n");
			}
			
			return value;
		}
	}
	
	class Multipart : Object {
		public unowned Soup.MessageHeaders headers { public get; public set; }
		public unowned Soup.MessageBody body { public get; public set; }
		public Gee.HashMap<string, UploadFileList> data { public get; public set; }
		public Multipart (Soup.MessageHeaders headers, Soup.MessageBody body) {
			this.headers = headers;
			this.body = body;
			this.data = new Gee.HashMap<string, UploadFileList> ();
			this.decode ();
		}
		
		public bool has_key (string key) {
			return this.data.has_key (key);
		}
		
		public void decode () {
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
							var name = params.lookup ("name");
							stderr.printf("name: %s\n", params.lookup ("name"));
							stderr.printf("length: %s\n", filesize.to_string ());
							//stderr.printf("data: %s\nend data;\n\n", (string) part_body.data);
							var body_str = (string) part_body.data;
							var str_parts = body_str.split("\r\n");
							var post_val =  str_parts[0];
							
							UploadFileList filelist;
							// Get the exiting list if already there
							if (this.data.has_key (name)) {
								filelist = this.data[name];
							} else {
								filelist = new UploadFileList ();	
							}
							
							if (post_val.length == filesize) {
								stderr.printf ("%s is a post '%s'\n", name, post_val.strip ());
								// This is a post value, and not a file upload?
								var uploadfile = new UploadFile (
									"", filesize, new Soup.Buffer(Soup.MemoryUse.COPY, post_val.data)
								);
								filelist.data.add (uploadfile);
							} else {
								stderr.printf ("%s is a file\n", name);
								// this is a file?
								var filename = params.lookup ("filename");
								var uploadfile = new UploadFile (
									filename, filesize, part_body
								);
								filelist.data.add (uploadfile);
							}
							this.data[name] = filelist;
						}
					}
				}
			}		
		}
	}
}
