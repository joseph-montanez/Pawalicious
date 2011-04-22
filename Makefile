all: server.vala admin/template.vala admin/links.vala admin/routes.vala admin/dashboard.vala admin/item/edit.vala admin/login.vala db.vala
	find . -type f -name "*.c" -exec rm -f {} \;
	valac \
		-g \
		--save-temps \
		--pkg gee-1.0 \
		--pkg gio-2.0 \
		--pkg gnet-2.0 \
		--pkg json-glib-1.0 \
		--pkg libsoup-2.4 \
		--pkg libxml-2.0 \
		--pkg=mysql --pkg libxml-2.0 --Xcc='-lmysqlclient' \
		--main=Pawalicous.main -o server \
		--thread \
		admin/template.vala  \
		admin/links.vala \
		admin/dashboard.vala \
		admin/item/edit.vala \
		admin/routes.vala \
		admin/login.vala \
		db.vala \
		server.vala
clean:
	find . -type f -name "*.c" -exec rm -f {} \;
	rm -f server;
	rm -f template;
