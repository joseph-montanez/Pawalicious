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
		}
	}
}}
