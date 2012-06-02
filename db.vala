namespace Application {
	Mysql.Database db;
	bool connected = false;
	
	class Db : Object {
		public Db () {
			if (connected == false) {
				db = new Mysql.Database ();
				connected = db.real_connect (
					Config.DB_HOST, Config.DB_USER, 
					Config.DB_PASSWD, Config.DB_SCHEMA
				);
				stderr.printf (db.error () + "\n");
			}
		}
		
		public unowned Mysql.Database get_db () {
			return db;
		}
		
		public string get_row_value (Mysql.Result? result, string key) {
			var data = "";
			if (result != null) {
				var row_data = result.fetch_row ();
				var field_data = result.fetch_fields ();
				Mysql.Field field;
				for (var i = 0; i < field_data.length; i++) {
					field = field_data[i];
					if (key == field.name && row_data != null) {
						data = row_data[i];
						break;
					}
				}
			}
			
			return data;
		}
		
		public string get_value_by_row (Mysql.Result? result, string[]? row_data, string key) {
			var data = "";
			if (result != null) {
				var field_data = result.fetch_fields ();
				Mysql.Field field;
				for (var i = 0; i < field_data.length; i++) {
					field = field_data[i];
					if (key == field.name && row_data != null) {
						data = row_data[i];
						break;
					}
				}
			}
			
			return data;
		}
		
		public ulong insert (string table, Gee.HashMap<string, string> fields) {
			ulong last_id = 0;
			var dbh = new Application.Db ();
			unowned Mysql.Database? db = dbh.get_db ();
			var query = "INSERT INTO " + table + " (";
			var keys = new Gee.ArrayList<string> ();
			var values = new Gee.ArrayList<string> ();
			
			if (fields.size == 0) {
				return last_id;
			}
			
			foreach (var entry in fields.entries) {
				keys.add (entry.key);
				
				unichar[] value_escaped = new unichar[entry.value.length * 2 + 1];
				db.real_escape_string ((string) value_escaped, entry.value, entry.value.length);
				values.add ((string) value_escaped);
			}
			
			foreach (string key in keys) {
				query += key + ",";
			}
			stderr.printf ("Keys: " + query + "\n");
			query = query.substring (0, query.length - 1) + ") VALUES (";
			
			foreach (string val in values) {
				query += "\"" + val + "\",";
			}
			stderr.printf ("Values: " + query + "\n");
			query = query.substring (0, query.length - 1) + ")";
			
			stderr.printf ("Query: " + query + "\n");
			var error_no = db.query (query);
			
			if (error_no == 0) {
				last_id = db.insert_id ();
			}
			
			return last_id;
		}
	}
}
