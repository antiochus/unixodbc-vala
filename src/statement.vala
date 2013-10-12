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
using Gee;
using UnixOdbcLL;

namespace UnixOdbc {

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
			// Binding to DataType.CHAR will use the ANSI codepage of the ODBC driver
			// For drivers supporting UTF-8 this is fine, since Vala uses UTF-8 internally
			// TODO: For other drivers there should be GLib.IConv support
			if (!succeeded (statement.handle.bind_column ((ushort) i, CDataType.CHAR, (void *) field.data, field.data.length, &field.length_or_indicator))) {
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
	public ArrayList<Parameter> parameters { get; private set; }

	public Statement (Connection connection) throws UnixOdbcError {
		parameters = new ArrayList<Parameter> ();
		this.connection = connection;
		if (!succeeded (StatementHandle.allocate (connection.handle, out handle))) {
			throw new UnixOdbcError.ALLOCATE_HANDLE ("Could not allocate statement handle");
		}
	}

	internal string get_diagnostic_text () {
		return UnixOdbc.get_diagnostic_record (handle.get_diagnostic_record);
	}

	public void execute () throws UnixOdbcError {
		if (parameters.is_empty) {
			Return retval = handle.execute_direct ((uint8[]) text.data);
			if (! (succeeded (retval) || (retval == Return.NO_DATA))) {
				throw new UnixOdbcError.EXECUTE_DIRECT ("Could not directly execute statement: " + get_diagnostic_text());
			}
		}
		else {
			if (!succeeded (handle.prepare ((uint8[]) text.data))) {
				throw new UnixOdbcError.PREPARE ("Could not prepare statement: " + get_diagnostic_text());
			}
			for (int i = 0; i < parameters.size; i++) {
				var parameter = parameters[i];
				if (parameter is IntParameter) {
					handle.bind_parameter ((ushort) i + 1, InputOutputType.INPUT,
						CDataType.LONG, DataType.INTEGER, 0, 0,
						&((IntParameter) parameter).value, 0,
						&parameter.length_or_indicator);
				}
				else if (parameter is DoubleParameter) {
					handle.bind_parameter ((ushort) i + 1, InputOutputType.INPUT,
						CDataType.DOUBLE, DataType.FLOAT, 0, 0,
						&((DoubleParameter) parameter).value, 0,
						&parameter.length_or_indicator);
				}
				else if (parameter is StringParameter) {
					handle.bind_parameter ((ushort) i + 1, InputOutputType.INPUT,
						CDataType.CHAR, DataType.CHAR, ((StringParameter) parameter).value.data.length, 0,
						((StringParameter) parameter).value.data, ((StringParameter) parameter).value.data.length,
						&parameter.length_or_indicator);
				}
				else if (parameter is DateTimeParameter) {
					handle.bind_parameter ((ushort) i + 1, InputOutputType.INPUT,
						CDataType.CHAR, DataType.TYPE_TIMESTAMP, 0, 3,
						((DateTimeParameter) parameter).value.data, ((DateTimeParameter) parameter).value.data.length,
						&parameter.length_or_indicator);
				}
				else if (parameter is BytesParameter) {
					handle.bind_parameter ((ushort) i + 1, InputOutputType.INPUT,
						CDataType.BINARY, DataType.BINARY, ((BytesParameter) parameter).value.length, 0,
						((BytesParameter) parameter).value, ((BytesParameter) parameter).value.length,
						&parameter.length_or_indicator);
				}
				else {
					assert_not_reached ();
				}
			}
			Return retval = handle.execute ();
			if (! (succeeded (retval) || (retval == Return.NO_DATA))) {
				throw new UnixOdbcError.EXECUTE ("Could not execute statement: " + get_diagnostic_text());
			}
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

	public IntParameter add_int_parameter (string name, int? value) {
		var parameter = new IntParameter (name, value);
		parameters.add (parameter);
		return parameter;
	}

	public DoubleParameter add_double_parameter (string name, double? value) {
		var parameter = new DoubleParameter (name, value);
		parameters.add (parameter);
		return parameter;
	}

	public StringParameter add_string_parameter (string name, string? value) {
		var parameter = new StringParameter (name, value);
		parameters.add (parameter);
		return parameter;
	}

	public BytesParameter add_bytes_parameter (string name, uchar[]? value) {
		var parameter = new BytesParameter (name, value);
		parameters.add (parameter);
		return parameter;
	}

	public DateTimeParameter add_datetime_parameter (string name, DateTime? value) {
		var parameter = new DateTimeParameter (name, value);
		parameters.add (parameter);
		return parameter;
	}
}

}