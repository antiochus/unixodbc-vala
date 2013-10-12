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
using UnixOdbcLL;

namespace UnixOdbc {

private delegate Return GetDiagnosticRecord (short record_number, uint8[] state, 
	out int native_error, uint8[] message_text, out short text_length);

private string get_diagnostic_record (GetDiagnosticRecord d) {
	uint8[] state = new uint8[10];
	int native_error;
	uint8[] message_text = new uint8[4096];
	short text_len;
	StringBuilder sb = new StringBuilder("");
	// A function call can generate multiple diagnostic records
	short i = 1;
	while (succeeded (d (i++, state, out native_error, message_text, out text_len))) {
		sb.append ("state = %s, native_error = %d, message = %s\n".printf ((string) state, native_error, (string) message_text));
	}
	return sb.str;
}

}