namespace Admin {
	class Links : Object {
		public string text { public get; public set; }
		public bool selected { public get; public set; }
		public string link { public get; public set; }
		public Links (string text, string link) {
			this.text = text;
			this.link = link;
		}
		public string render () {
			var selected = "";
			if (this.selected) {
				selected = "selected";
			}
			var link = this.link;
			var text = this.text;
			return @"<a href='$link' class='$selected'>$text</a>";
		}
	}
}
