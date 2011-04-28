namespace Admin {
	class Template : Object {
		public Template () {
		
		}
		
		public string read (string location) {
			var file = File.new_for_path (location);
			string template = "";
			if (!file.query_exists ()) {
				stderr.printf ("File '%s' doesn't exist.\n", file.get_path ());
				template += "File '%s' doesn't exist.\n".printf (file.get_path ());
			}

			try {
				var dis = new DataInputStream (file.read ());
				string line;
				while ((line = dis.read_line (null)) != null) {
					template += line;
				}
			} catch (Error e) {
				error ("%s", e.message);
				//template += e.message;
			}
			
			return template;
		}
		
		public string parse (string template, Gee.HashMap<string, string> map) {
			var rendered = template;
			var with_this = "";
			var replace_this = "";
			foreach (var entry in map.entries) {
				replace_this = "{{ " + entry.key + " }}";
				/* Is this a bug? a null value with replace () skills the entire
				 * string ... :( 
				 */
				if (entry.value == null) {
					with_this = "";
				} else {
					with_this = entry.value;
				}

				rendered = rendered.replace (replace_this, with_this);
			}
			return rendered;
		}
		
		public string header (string selected) {
			
			var links = this.get_links (false);

			var html = """
			<!DOCTYPE html>
			<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="cs" lang="cs">
			  <head>
				<meta charset="utf-8">
				<meta http-equiv="content-language" content="cs" />
				<meta name="author" lang="cs" content="" />
				<meta name="copyright" lang="cs" content="" />
				<meta name="description" content="..." />
				<meta name="keywords" content="..." />
				<meta name="robots" content="all,follow" />
				<link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/dojo/1.6/dijit/themes/claro/claro.css" type="text/css"> 
				<link href="/static/css/screen.css" type="text/css" rel="stylesheet" media="screen,projection" />
				<script src="//ajax.googleapis.com/ajax/libs/dojo/1.6.0/dojo/dojo.xd.js" data-dojo-config="isDebug: true,parseOnLoad: true"></script>
				<!-- <link rel="stylesheet" media="print" type="text/css" href="/static/css/print.css" /> -->

				<title>Nature Theme</title>
			  </head>
			  <body id="body" class="claro">
				<div id="layout">
					<div id="header">

						<h1 id="logo"><a href="./" title="Nature Theme">""" + Config.SITE_NAME + """</a></h1>
						<hr class="noscreen" />   

						<p class="noscreen noprint">
							<em>Love pets: <a href="#obsah">simple</a>, <a href="#nav">clean</a>.</em>
						</p>
					</div>

					<hr class="noscreen" />

					<div id="nav" class="box">
						<ul>
			""";
			foreach (var link in links.values) {
				var id = "";
				if (link.selected) {
					id = "active";
				}
				var href = link.link;
				var text = link.text;
				html += @"<li id=\"$id\"><a href=\"$href\">$text</a></li>";
			}
			html += """
						</ul>
						<hr class="noscreen" />
					</div> 

					<div id="container" class="box">
			""";
			return html;
		}
		
		public string footer () {
			var html = """
					</div>

					<div id="footer" class="shadow">
						<div class="f-left">Copyright &copy; 2011 <a href="#">""" + Config.SITE_NAME + """</a></div>
						<div class="f-right"></div>

					</div>
				</div>
			</body>
			</html>
			""";
			return html;
		}
		
		public Gee.HashMap<string, Links> get_links (bool isLoggedIn) {
			var links = new Gee.HashMap<string, Links> ();
			links["dashboard"] = new Links("Dashboard", "/admin/dashboard");
			links["categories"] = new Links("Categories", "/admin/categories");
			links["items"] = new Links("Items", "/admin/items");
			if (isLoggedIn) {
				links["logout"] = new Links("Logout", "/admin/categories");
			} else {
				links["login"] = new Links("Login", "/admin/login");
			}
			
			return links;
		}
	}
}
