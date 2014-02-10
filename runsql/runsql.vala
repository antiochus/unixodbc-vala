/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * unixodbc-vala - Vala Bindings for unixODBC
 * Copyright (C) 2013-2014 Jens Mühlenhoff <j.muehlenhoff@gmx.de>
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

namespace RunSql {

internal class Main {

	Input input;
	bool interactive;

	internal Main () {
		interactive = isatty (STDIN_FILENO);

		if (interactive) {
			input = new InteractiveInput ();
		}
		else {
			input = new NonInteractiveInput ();
		}
	}
	
	private void show_records (Statement statement) throws UnixOdbc.Error, GLib.ConvertError {
		if (!statement.has_result ()) {
			return;
		}
		foreach (var record in statement) {
			GLib.stdout.printf ("---\n");
			foreach (var field in record.fields) {
				GLib.stdout.printf ("%s : %s\n", field.name, field.get_as_string_default ("(null)"));
			}
		}
	}

	private void run_statements (Connection connection) throws UnixOdbc.Error, GLib.ConvertError {
		string? text;
		while ((text = input.get_statement ()) != null) {
			try {
				var statement = new Statement (connection);
				statement.text = (!)text;
				statement.execute ();
				// if (interactive) {
				show_records (statement);
				// }
			}
			catch (UnixOdbc.Error e) {
				GLib.stderr.printf (@"\n$(e.message)\n");
				if (!interactive) {
					break;
				}
			}
		}
	}

	public void run () throws UnixOdbc.Error, GLib.ConvertError {
		UnixOdbc.Environment environment = new UnixOdbc.Environment ();
		environment.error_encoding = "ISO_8859-1";
		environment.sql_encoding = "ISO_8859-1";
		environment.verbose_errors = false;

		Connection connection = new Connection (environment);
		connection.connection_string = "DSN=MyDatabase;UID=MyUser;PWD=MyPassword";
		connection.open ();
		connection.execute ("USE vorm");
		run_statements (connection);
	}
}

int main (string args[]) {

	try {
		Main main = new Main();
		main.run ();
	}
	catch (UnixOdbc.Error e) {
		GLib.stderr.printf (@"$(e.message)\n");
		return 1;
	}
	catch (GLib.ConvertError e) {
		GLib.stderr.printf (@"$(e.message)\n");
		return 1;
	}

	return 0;
}

}
