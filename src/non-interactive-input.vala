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

namespace RunSql {

internal class NonInteractiveInput : GLib.Object, Input {

	string? get_statement () {
		StringBuilder statement = new StringBuilder();
		string? nline;
		while ((nline = GLib.stdin.read_line ()) != null) {
			string line = (!)nline;
			if (line.chomp ().up () == "GO")
				return statement.str;
			else {
				statement.append (line);
				statement.append_c ('\n');
			}
		}
		string result = statement.str;
		return result.chomp ().length == 0 ? (string?)null : result;
	}

	/*
	 string? get_statement () {
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
		string result = statement.str;
		if (GLib.stdin.eof () && result.chomp ().length == 0)
			return null;
		else
			return result;
	}
	*/
}

}