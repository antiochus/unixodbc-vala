/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * unixodbc-vala - Vala Bindings for unixODBC
 * Copyright (C) 2013 Jens Mühlenhoff <j.muehlenhoff@gmx.de>
 * 
 * unixodbc-vala is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * dbdiadesign is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using Gee;

namespace UnixOdbc {

public errordomain UnixOdbcError {
	ALLOCATE_HANDLE,
	SET_ENVIRONMENT_ATTRIBUTE,
	DRIVERS,
	DRIVER_CONNECT,
	EXECUTE_DIRECT,
	NUMBER_RESULT_COLUMNS
}

bool succeeded (Return ret) {
	return (ret == Return.SUCCESS || ret == Return.SUCCESS_WITH_INFO);
}

private static Handle allocate_handle (HandleType type, Handle input_handle) throws UnixOdbcError {
	Handle result;
	if (!succeeded (allocate_handle_real (type, input_handle, out result))) {
		throw new UnixOdbcError.ALLOCATE_HANDLE ("Could not allocate handle");
	}
	if (result == 0) {
		throw new UnixOdbcError.ALLOCATE_HANDLE ("Got null handle from ODBC");
	}
	return result;
}

public class Driver {
	public string name { get; private set; }
	public Map<string, string> attributes { get; private set; }

	public Driver (string name, Map<string, string> attributes) {
		this.name = name;
		this.attributes = attributes;
	}
}

private void char_array_to_attributes (char[] input, Map<string, string> output) {
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
			sb.append_c (input[i]);
		}
	}
}

public class Environment {
	public Handle handle { get; private set; }
	
	public Environment () throws UnixOdbcError {
		handle = allocate_handle (HandleType.ENV, 0);
	}

	public ArrayList<Driver> get_drivers () {
		ArrayList<Driver> result = new ArrayList<Driver> ();

		FetchDirection direction = FetchDirection.FIRST;
		Return ret;
		char[] driver = new char[256];
		char[] attr   = new char[256];
		short driver_ret;
		short attr_ret;
		while (succeeded (ret = get_drivers_real (handle, direction, driver, out driver_ret, attr, out attr_ret))) {
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
	
	public void set_odbc_version (OdbcVersion value) throws UnixOdbcError {
		if (!succeeded (set_environment_attribute_real (handle, Attribute.ODBC_VERSION, (void *) value, 0))) {
			throw new UnixOdbcError.SET_ENVIRONMENT_ATTRIBUTE ("Could not set environment attribute");
		}
	} 
}

public class Connection {
	public Handle handle { get; private set; }
	public string connection_string { get; set; }
	public Connection (Environment environment) throws UnixOdbcError {
		handle = allocate_handle (HandleType.DBC, environment.handle);
	}
	public void open () throws UnixOdbcError {
		char[] connstr = (char[]) connection_string.data;
		if (!succeeded (driver_connect_real (handle, 0, connstr, null, null, DriverCompletion.COMPLETE))) {
			char[] state = new char[10];
			int native_error;
			char[] message_text = new char[2048];
			short text_len;
			get_diagnostic_record_real (HandleType.DBC, handle, 1, state, out native_error, message_text, out text_len);
			throw new UnixOdbcError.DRIVER_CONNECT ("Could not open connection: state = %s, native_error = %d, message = %s".printf ((string) state, native_error, (string) message_text));
		}
	}
}

public class Statement {
	public Handle handle { get; private set; }
	public Statement (Connection connection) throws UnixOdbcError {
		handle = allocate_handle (HandleType.STMT, connection.handle);
	}
	public void execute_direct (string text) throws UnixOdbcError {
		if (!succeeded (execute_direct_real (handle, (char[]) text.data))) {
			char[] state = new char[10];
			int native_error;
			char[] message_text = new char[2048];
			short text_len;
			get_diagnostic_record_real (HandleType.STMT, handle, 1, state, out native_error, message_text, out text_len);
			throw new UnixOdbcError.EXECUTE_DIRECT ("Could not open connection: state = %s, native_error = %d, message = %s".printf ((string) state, native_error, (string) message_text));
		}
	}
	public int get_column_count () throws UnixOdbcError {
		short count;
		if (!succeeded (number_result_columns_real (handle, out count))) {
			throw new UnixOdbcError.NUMBER_RESULT_COLUMNS ("Could not get number of result columns");
		}
		return count;
	}
}

}