/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * unixodbc-vala - Vala Bindings for unixODBC
 * Copyright (C) 2013 Jens Mühlenhoff <j.muehlenhoff@gmx.de>
 * 
 * unixodbc-vala is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * unixodbc-vala is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using UnixOdbc;
using UnixOdbcLL;
using Posix;
using Readline;

bool interactive;

int eol_func (int count, int key) {
	if (Readline.line_buffer.chomp ().up ().has_suffix ("\nGO")) {
		Readline.done = 1;
	}
	else {
		insert (count, '\n');
	}
	return 0;
}

string? get_statement () {
	if (interactive) {
		string? s = readline ("SQL> ");
		if (s == null) {
			return null;
		}
		// Remove trailing whitespace and "GO"
		string s2 = (!)s.chomp ();
		s2 = s2.slice (0, s2.length - 2);
		if (s2.strip () != "") {
			Readline.History.add ((!)s);
		}
		GLib.stdout.printf ("\n");
		return s2 + "\n";
	}
	else {
		StringBuilder statement = new StringBuilder();
		var buffer = new char[1024];
		string? s = null;
		while ((!GLib.stdin.eof ()) && ((s = GLib.stdin.gets (buffer)) != null)) {
			string line = (!)s;
			if (line.chomp ().up () != "GO") {
				statement.append (line);
				statement.append_c ('\n');
			}
		}
		return statement.str;
	}
}

void show_records (Statement statement) throws UnixOdbc.Error {
	if (!statement.has_result ()) {
		return;
	}
	foreach (var record in statement) {
		GLib.stdout.printf ("---\n");
		foreach (var field in record.fields) {
			GLib.stdout.printf ("??? : %s\n", (string)field.data);
		}
	}
}

void run_statements (Connection connection) throws UnixOdbc.Error {
	string? text;
	while ((text = get_statement ()) != null) {
		try {
			// GLib.stdout.printf ((!)statement);
			var statement = new Statement (connection);
			statement.text = (!)text;
			statement.execute ();
			if (interactive) {
				show_records (statement);
			}
		}
		catch (UnixOdbc.Error e) {
			GLib.stderr.printf (@"\n$(e.message)\n");
			if (!interactive) {
				break;
			}
		}
	}
}


int main (string args[]) {

	interactive = isatty (STDIN_FILENO);

	if (interactive) {
		Readline.readline_name = "runsql";
		Readline.startup_hook = () => {
			Readline.bind_key ('\r', eol_func);
			Readline.bind_key ('\n', eol_func);
			return 0;
		};
		Readline.History.using ();
	}

	try {
		UnixOdbc.Environment environment = new UnixOdbc.Environment ();

		Connection connection = new Connection (environment);
		connection.connection_string = "DSN=MyDatabase;UID=MyUser;PWD=MyPassword";
		connection.open ();

		run_statements (connection);
	}
	catch (UnixOdbc.Error e) {
		GLib.stderr.printf (@"$(e.message)\n");
		return 1;
	}

	return 0;
}
