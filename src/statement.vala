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
using Gee;
using UnixOdbcLL;

namespace UnixOdbc {

public class Statement {
	private bool result;
	internal StatementHandle handle;
	public Connection connection { get; private set; }
	public string text { get; set; }
	public ArrayList<Parameter> parameters { get; private set; }
	public ArrayList<Field> fields { get; private set; }
	public string error_encoding { get; set; default = "UTF-8"; }
	public string sql_encoding { get; set; default = "UTF-8"; }
	// public string field_encoding { get; set; default = "UTF-8"; }
	public bool verbose_errors { get; set; default = false; }

	public Statement (Connection connection) throws Error {
		parameters = new ArrayList<Parameter> ();
		fields = new ArrayList<Field> ();
		this.connection = connection;
		this.error_encoding = connection.error_encoding;
		this.sql_encoding = connection.sql_encoding;
		if (!succeeded (StatementHandle.allocate (connection.handle, out handle))) {
			throw new Error.ALLOCATE_HANDLE ("SQLAllocHandle (SQL_HANDLE_STMT), could not allocate statement handle");
		}
	}

	internal string get_diagnostic_text (string function_name) throws Error, GLib.ConvertError {
		return UnixOdbc.get_diagnostic_record (function_name, error_encoding, verbose_errors, handle.get_diagnostic_record);
	}

	private void bind_parameters () throws Error, GLib.ConvertError {
		for (int i = 0; i < parameters.size; i++) {
			parameters[i].bind (this, (ushort) i + 1);
		}
	}

	private void bind_columns () throws Error, GLib.ConvertError {
		int count = get_column_count ();
		for (int i = 0; i < count; i++) {
			StringField field = new StringField ();
			uint8 name_buffer[2048];
			if (!succeeded (handle.column_string_attribute (i + 1, ColumnDescriptorString.NAME, name_buffer))) {
				throw new Error.COLUMN_ATTRIBUTE (get_diagnostic_text ("SQLColAttribute"));
			}
			field.name = (string)name_buffer;
			fields.add (field);
			// Binding to DataType.CHAR will use the ANSI codepage of the ODBC driver
			// For drivers supporting UTF-8 this is fine, since Vala uses UTF-8 internally
			// TODO: For other drivers there should be GLib.IConv support
			if (!succeeded (handle.bind_string_column (i + 1, field.data, &field.length_or_indicator))) {
				throw new Error.BIND_COLUMN (get_diagnostic_text ("SQLBindCol"));
			}
		}
	}

	private void execute_direct (string text) throws Error, GLib.ConvertError {
		if (text.strip ().length == 0) {
			throw new Error.EMPTY_STATEMENT_TEXT ("The statement text must be non empty");
		}
		string target_text;
		if (sql_encoding == "UTF-8") {
			target_text = text;
		}
		else {
			target_text = GLib.convert(text, text.length, sql_encoding, "UTF-8");
		}
		Return retval = handle.execute_direct ((uint8[]) target_text.data);
		if (! (succeeded (retval) || (retval == Return.NO_DATA))) {
			throw new Error.EXECUTE_DIRECT (get_diagnostic_text ("SQLExecDirect"));
		}
		result = retval != Return.NO_DATA;
		if (result) {
			bind_columns ();
		}
	}

	public bool has_result () {
		return result;
	}

	/* TODO: Provide public prepare and reexecute prepared API
	private void execute_prepared () throws Error {
		Return retval = handle.execute ();
		if (! (succeeded (retval) || (retval == Return.NO_DATA))) {
			throw new UnixOdbcError.EXECUTE (get_diagnostic_text ("SQLExecute"));
		}
	}

	private void prepare () throws Error {
		string target_text;
		if (sql_encoding == "UTF-8") {
			target_text = text;
		}
		else {
			target_text = GLib.convert(text, text.length, sql_encoding, "UTF-8");
		}
		if (!succeeded (handle.prepare ((uint8[]) target_text.data))) {
			throw new UnixOdbcError.PREPARE (get_diagnostic_text ("SQLPrepare"));
		}
	}
	*/

	public void execute () throws Error, GLib.ConvertError {
		bind_parameters ();
		execute_direct (text);
	}

	public int get_column_count () throws Error, GLib.ConvertError {
		short count;
		if (!succeeded (handle.number_of_result_columns (out count))) {
			throw new Error.NUMBER_RESULT_COLUMNS (get_diagnostic_text ("SQLNumResultCols"));
		}
		return count;
	}

	public RecordIterator iterator () throws Error, GLib.ConvertError {
		return new RecordIterator (this);
	}

	public IntParameter add_int_parameter (int? value) {
		var parameter = new IntParameter (value);
		parameters.add (parameter);
		return parameter;
	}

	public DoubleParameter add_double_parameter (double? value) {
		var parameter = new DoubleParameter (value);
		parameters.add (parameter);
		return parameter;
	}

	public StringParameter add_string_parameter (string? value) {
		var parameter = new StringParameter (value);
		parameters.add (parameter);
		return parameter;
	}

	public BytesParameter add_bytes_parameter (uchar[]? value) {
		var parameter = new BytesParameter (value);
		parameters.add (parameter);
		return parameter;
	}

	public DateTimeParameter add_datetime_parameter (DateTime? value) {
		var parameter = new DateTimeParameter (value);
		parameters.add (parameter);
		return parameter;
	}
}

}