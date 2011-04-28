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
	}
}
