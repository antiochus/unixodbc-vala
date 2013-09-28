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
using UnixOdbcLL;

// High level interface to UnixOdbcLL
namespace UnixOdbc {

public errordomain UnixOdbcError {
	ALLOCATE_HANDLE,
	FREE_HANDLE,
	SET_ENVIRONMENT_ATTRIBUTE,
	DRIVERS,
	DRIVER_CONNECT,
	EXECUTE_DIRECT,
	NUMBER_RESULT_COLUMNS
}

bool succeeded (Return ret) {
	return (ret == Return.SUCCESS || ret == Return.SUCCESS_WITH_INFO);
}

private static Handle allocate_handle_checked (HandleType type, Handle input_handle) throws UnixOdbcError {
	Handle result;
	if (!succeeded (allocate_handle (type, input_handle, out result))) {
		throw new UnixOdbcError.ALLOCATE_HANDLE ("Could not allocate handle");
	}
	return result;
}

private static void free_handle_checked (HandleType type, Handle handle) throws UnixOdbcError {
	if (!succeeded (free_handle (type, handle))) {
		throw new UnixOdbcError.FREE_HANDLE ("Could not free handle: " + get_diagnostic_text (type, handle));
	}
}

private static string get_diagnostic_text (HandleType type, Handle handle) {
	uint8[] state = new uint8[10];
	int native_error;
	uint8[] message_text = new uint8[4096];
	short text_len;
	// TODO: A function call can generate multiple diagnostic records
	if (succeeded (get_diagnostic_record (type, handle, 1, state, out native_error, message_text, out text_len))) {
		return "state = %s, native_error = %d, message = %s".printf ((string) state, native_error, (string) message_text);
	}
	else {
		return "get_diagnostic_record () failed";
	}
}


public class Driver {
	public string name { get; private set; }
	public Map<string, string> attributes { get; private set; }

	public Driver (string name, Map<string, string> attributes) {
		this.name = name;
		this.attributes = attributes;
	}
}

private void char_array_to_attributes (uint8[] input, Map<string, string> output) {
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

public class Environment {
	public Handle handle { get; private set; }
	
	public Environment () throws UnixOdbcError {
		handle = allocate_handle_checked (HandleType.ENV, 0);
		set_odbc_version (OdbcVersion.ODBC3);
	}

	~Environment () {
		if (handle != 0) {
			free_handle_checked (HandleType.ENV, handle);
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
		while (succeeded (ret = UnixOdbcLL.get_drivers (handle, direction, driver, out driver_ret, attr, out attr_ret))) {
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
	
	private void set_odbc_version (OdbcVersion value) throws UnixOdbcError {
		if (!succeeded (set_environment_attribute (handle, Attribute.ODBC_VERSION, (void *) value, 0))) {
			throw new UnixOdbcError.SET_ENVIRONMENT_ATTRIBUTE ("Could not set environment attribute");
		}
	} 
}

public class Connection {
	public bool connected { get; private set; }
	public Handle handle { get; private set; }
	public Environment environment { get; private set; }
	public string connection_string { get; set; }
	public Connection (Environment environment) throws UnixOdbcError {
		this.environment = environment;
		handle = allocate_handle_checked (HandleType.DBC, environment.handle);
	}
	~Connection () {
		if (handle != 0) {
			close ();
			free_handle_checked (HandleType.DBC, handle);
		}
	}
	public void open () throws UnixOdbcError {
		uchar[] connstr = (uchar[]) connection_string.data;
		if (!succeeded (driver_connect (handle, 0, connstr, null, null, DriverCompletion.COMPLETE))) {
			throw new UnixOdbcError.DRIVER_CONNECT ("Could not open connection: " + get_diagnostic_text (HandleType.DBC, handle));
		}
		connected = true;
	}
	public void close () throws UnixOdbcError {
		if (connected) {
			disconnect (handle);
		}
	}
}

public class Statement {
	public Handle handle { get; private set; }
	public Connection connection { get; private set; }
	public string text { get; set; }
	public Statement (Connection connection) throws UnixOdbcError {
		this.connection = connection;
		handle = allocate_handle_checked (HandleType.STMT, connection.handle);
	}
	~Statement () {
		if (handle != 0) {
			free_handle_checked (HandleType.STMT, handle);
		}
	}
	public void execute () throws UnixOdbcError {
		if (!succeeded (UnixOdbcLL.execute_direct (handle, (uint8[]) text.data))) {
			throw new UnixOdbcError.EXECUTE_DIRECT ("Could not execute statement: " + get_diagnostic_text(HandleType.STMT, handle));
		}
	}
	public int get_column_count () throws UnixOdbcError {
		short count;
		if (!succeeded (number_result_columns (handle, out count))) {
			throw new UnixOdbcError.NUMBER_RESULT_COLUMNS ("Could not get number of result columns");
		}
		return count;
	}
}

}