namespace Admin {
	class Dashboard : Object {
		public Routes route { public get; public set; }	
		public Json.Object session { public get; public set; }	
		public string session_id { public get; public set; }	
		
		public Dashboard (Routes route, Json.Object session, string session_id) {
			this.route = route;
			this.session = session;
			this.session_id = session_id;
		}
		
		public void run () {
			var tpl = new Template();
			
			var html = tpl.header ("dashboard") + """
			<div id="intro">
				<div id="intro-in">
					<h2>Dashboard</h2>
					<p class="intro">
						What do you want to do?
					</p>
					<ul>
						<li><a href="">See My Orders</a></li>
						<li><a href="/admin/item/edit">Create an Item</a></li>
						<li><a href="">Create a Category</a></li>
					</ul>
				</div>
			</div>
			""" + tpl.footer ();
			this.route.msg.set_status (200);
			this.route.msg.set_response ("text/html", Soup.MemoryUse.COPY, html.data);
		}
	}
}
