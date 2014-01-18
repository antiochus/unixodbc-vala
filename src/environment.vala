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

using Gee;
using UnixOdbcLL;

namespace UnixOdbc {

public class Environment {
	internal EnvironmentHandle handle;
	public string error_encoding { get; set; default = "UTF-8"; }
	public string sql_encoding { get; set; default = "UTF-8"; }
	public bool verbose_errors { get; set; default = false; }
	
	public Environment () throws Error {
		if (!succeeded (EnvironmentHandle.allocate (out handle))) {
			throw new Error.ALLOCATE_HANDLE ("Could not allocate environment handle");
		}
		set_odbc_version (OdbcVersion.ODBC3);
	}

	internal string get_diagnostic_text (string function_name) {
		return UnixOdbc.get_diagnostic_record (function_name, error_encoding, verbose_errors, handle.get_diagnostic_record);
	}

	// Split a '\0' delimited list of "key=value" pairs (e.g. "key1=value1\0key1=value2\0\0")
	private static void char_array_to_attributes (uint8[] input, Map<string, string> output) {
		StringBuilder sb = new StringBuilder("");
		for (int i = 0; i < input.length; i++) {
			if (input[i] == '\0') {
				if (sb.data.length == 0) {
					break;
				}
				string s = (string) sb.data;
				var e = s.split ("=");
				output[e[0]] = e[1];
				sb = new StringBuilder("");
			}
			else {
				sb.append_c ((char) input[i]);
			}
		}
	}

	public ArrayList<Driver> get_drivers () {
		ArrayList<Driver> result = new ArrayList<Driver> ();

		FetchDirection direction = FetchDirection.FIRST;
		Return ret;
		uint8[] driver = new uint8[256];
		uint8[] attr   = new uint8[4096];
		short driver_ret;
		short attr_ret;
		while (succeeded (ret = handle.get_drivers (direction, driver, out driver_ret, attr, out attr_ret))) {
			direction = FetchDirection.NEXT;

			Map<string, string> attributes = new HashMap<string, string>();
			char_array_to_attributes (attr, attributes);

			result.add (new Driver ((string) driver, attributes));
			/*
			if (ret == Return.SUCCESS_WITH_INFO) {
				stdout.printf ("\tdata truncation\n");
			}
			*/
		}
		return result;
	}
	
	private void set_odbc_version (OdbcVersion value) throws Error {
		if (!succeeded (handle.set_attribute (Attribute.ODBC_VERSION, (void *) value, 0))) {
			throw new Error.SET_ENVIRONMENT_ATTRIBUTE (get_diagnostic_text ("SQLSetEnvAttr"));
		}
	} 
}

}