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
	NUMBER_RESULT_COLUMNS,
	BIND_COLUMN
}

bool succeeded (Return ret) {
	return (ret == Return.SUCCESS || ret == Return.SUCCESS_WITH_INFO);
}

public class Driver {
	public string name { get; private set; }
	public Map<string, string> attributes { get; private set; }

	public Driver (string name, Map<string, string> attributes) {
		this.name = name;
		this.attributes = attributes;
	}
}

private delegate Return GetDiagnosticRecord (short record_number, uint8[] state, 
	out int native_error, uint8[] message_text, out short text_length);

private string get_diagnostic_record (GetDiagnosticRecord d) {
	uint8[] state = new uint8[10];
	int native_error;
	uint8[] message_text = new uint8[4096];
	short text_len;
	// TODO: A function call can generate multiple diagnostic records
	if (succeeded (d (1, state, out native_error, message_text, out text_len))) {
		return "state = %s, native_error = %d, message = %s".printf ((string) state, native_error, (string) message_text);
	}
	else {
		return "get_diagnostic_record () failed";
	}
}

public class Environment {
	internal EnvironmentHandle handle;
	
	public Environment () throws UnixOdbcError {
		if (!succeeded (EnvironmentHandle.allocate (out handle))) {
			throw new UnixOdbcError.ALLOCATE_HANDLE ("Could not allocate environment handle");
		}
		set_odbc_version (OdbcVersion.ODBC3);
	}

	private string get_diagnostic_text () {
		return UnixOdbc.get_diagnostic_record (handle.get_diagnostic_record);
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
	
	private void set_odbc_version (OdbcVersion value) throws UnixOdbcError {
		if (!succeeded (handle.set_attribute (Attribute.ODBC_VERSION, (void *) value, 0))) {
			throw new UnixOdbcError.SET_ENVIRONMENT_ATTRIBUTE ("Could not set environment attribute: " + get_diagnostic_text ());
		}
	} 
}

public class Connection {
	public bool connected { get; private set; }
	internal ConnectionHandle handle;
	public Environment environment { get; private set; }
	public string connection_string { get; set; }

	public Connection (Environment environment) throws UnixOdbcError {
		this.environment = environment;
		if (!succeeded (ConnectionHandle.allocate (environment.handle, out handle))) {
			throw new UnixOdbcError.ALLOCATE_HANDLE ("Could not allocate environment handle");
		}
	}

	~Connection () {
		close ();
	}

	private string get_diagnostic_text () {
		return UnixOdbc.get_diagnostic_record (handle.get_diagnostic_record);
	}

	public void open () throws UnixOdbcError {
		uchar[] connstr = (uchar[]) connection_string.data;
		if (!succeeded (handle.driver_connect (0, connstr, null, null, DriverCompletion.COMPLETE))) {
			throw new UnixOdbcError.DRIVER_CONNECT ("Could not open connection: " + get_diagnostic_text ());
		}
		connected = true;
	}

	public void close () {
		if (connected) {
			assert( succeeded (handle.disconnect ()));
		}
	}
}

public class Field {
	public char[] data = new char[256];
}

public class Record {
	public ArrayList<Field> fields;

	public Record (ArrayList<Field> fields) {
		this.fields = fields;
	}
}

public class RecordIterator {
	public Statement statement { get; private set; }
	private ArrayList<Field> fields;

	public RecordIterator (Statement statement) throws UnixOdbcError {
		this.statement = statement;
		int count = statement.get_column_count ();
		fields = new ArrayList<Field> ();
		for (int i = 1; i <= count; i++) {
			Field field = new Field ();
			fields.add (field);
			long str_len_or_ind;
			if (!succeeded (statement.handle.bind_column ((ushort) i, DataType.CHAR, (void *) field.data, field.data.length, out str_len_or_ind))) {
				throw new UnixOdbcError.BIND_COLUMN ("Could not bind colun: " + statement.get_diagnostic_text ());
			}
		}
	}

	public bool next () {
		return succeeded (statement.handle.fetch ());
	}

	public Record get () {
		return new Record (fields);
	}
}

public class Statement {
	internal StatementHandle handle;
	public Connection connection { get; private set; }
	public string text { get; set; }

	public Statement (Connection connection) throws UnixOdbcError {
		this.connection = connection;
		if (!succeeded (StatementHandle.allocate (connection.handle, out handle))) {
			throw new UnixOdbcError.ALLOCATE_HANDLE ("Could not allocate statement handle");
		}
	}

	internal string get_diagnostic_text () {
		return UnixOdbc.get_diagnostic_record (handle.get_diagnostic_record);
	}

	public void execute () throws UnixOdbcError {
		if (!succeeded (handle.execute_direct ((uint8[]) text.data))) {
			throw new UnixOdbcError.EXECUTE_DIRECT ("Could not execute statement: " + get_diagnostic_text());
		}
	}

	public int get_column_count () throws UnixOdbcError {
		short count;
		if (!succeeded (handle.number_of_result_columns (out count))) {
			throw new UnixOdbcError.NUMBER_RESULT_COLUMNS ("Could not get number of result columns");
		}
		return count;
	}

	public RecordIterator iterator () throws UnixOdbcError {
		return new RecordIterator (this);
	}
}

}