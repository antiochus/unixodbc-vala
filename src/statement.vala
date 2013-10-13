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

	private void bind_parameter (Parameter parameter, ushort number) throws UnixOdbcError {
		if (!succeeded (handle.bind_parameter (number, InputOutputType.INPUT, 
			parameter.get_c_data_type (), parameter.get_sql_data_type (),
			parameter.get_column_size (), parameter.get_decimal_digits (),
			parameter.get_data_pointer (), parameter.get_data_length (), 
			&parameter.length_or_indicator))) {
			throw new UnixOdbcError.BIND_PARAMETER ("Could not bind parameter: " + get_diagnostic_text());
		}
	}

	private void bind_parameters () throws UnixOdbcError {
		for (int i = 0; i < parameters.size; i++) {
			bind_parameter(parameters[i], (ushort) i + 1);
		}
	}

	private void execute_direct (string text) throws UnixOdbcError {
		Return retval = handle.execute_direct ((uint8[]) text.data);
		if (! (succeeded (retval) || (retval == Return.NO_DATA))) {
			throw new UnixOdbcError.EXECUTE_DIRECT ("Could not directly execute statement: " + get_diagnostic_text());
		}
	}

	/* TODO: Provide public prepare and reexecute prepared API
	private void execute_prepared () throws UnixOdbcError {
		Return retval = handle.execute ();
		if (! (succeeded (retval) || (retval == Return.NO_DATA))) {
			throw new UnixOdbcError.EXECUTE ("Could not execute statement: " + get_diagnostic_text());
		}
	}

	private void prepare () throws UnixOdbcError {
		if (!succeeded (handle.prepare ((uint8[]) text.data))) {
			throw new UnixOdbcError.PREPARE ("Could not prepare statement: " + get_diagnostic_text());
		}
	}
	*/

	public void execute () throws UnixOdbcError {
		bind_parameters ();
		execute_direct (text);
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