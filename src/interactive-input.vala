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

using Readline;

namespace RunSql {

internal class InteractiveInput : GLib.Object, Input {

	private static int instance_count = 0;

	public InteractiveInput () {
		if (instance_count != 0) {
			assert_not_reached ();
		}
		instance_count++;
		Readline.readline_name = "runsql";
		Readline.bind_key ('\r', eol_func);
		Readline.bind_key ('\n', eol_func);
		Readline.History.using ();
	}
	
	private static int eol_func (int count, int key) {
		if (Readline.line_buffer.chomp ().up ().has_suffix ("\nGO")) {
			Readline.done = 1;
		}
		else {
			insert (count, '\n');
		}
		return 0;
	}

	public string? get_statement () {
		string? s = readline ("SQL> ");
		GLib.stdout.printf ("\n");
		if (s == null) {
			return null;
		}
		// Remove trailing whitespace
		string s2 = ((!)s).chomp ();
		s2 = s2.slice (0, s2.length - 2);
		if (s2.strip () != "") {
			Readline.History.add ((!)s);
		}
		return s2 + "\n";
	}
}

}