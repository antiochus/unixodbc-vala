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

[CCode (cheader_filename = "sqlext.h,unixodbcll.h")]
// Low level adaption
namespace UnixOdbcLL {

[CCode (cname = "SQLRETURN", cprefix = "SQL_")]
public enum Return {
	SUCCESS,
	SUCCESS_WITH_INFO,
	ERROR,
	INVALID_HANDLE
}

// EnvironmentHandle -----------------------------------------------------------

[CCode (cname = "int", cprefix = "SQL_ATTR_")]
public enum Attribute {
	ODBC_VERSION
}

[CCode (cname = "unsigned long", cprefix = "SQL_OV_")]
public enum OdbcVersion {
	ODBC3
}

[CCode (cname = "SQLUSMALLINT", cprefix = "SQL_FETCH_")]
public enum FetchDirection {
	NEXT,
	FIRST,
	LAST,
	PRIOR,
	ABSOLUTE,
	RELATIVE
}

[CCode (cname = "void", free_function = "SQLFREEENVHANDLE")]
[Compact]
public class EnvironmentHandle {
	[CCode (cname = "SQLALLOCENVHANDLE")]
	public static Return allocate (out EnvironmentHandle output_handle);

	[CCode (cname = "SQLENVGETDIAGREC")]
	public Return get_diagnostic_record (
		short record_number, [CCode (array_length = false)] uint8[] state,
		out int native_error,
		[CCode (array_length = true, array_pos = 5.1)] uint8[] message_text,
		out short text_length);

	[CCode (cname = "SQLSetEnvAttr")]
	public Return set_attribute (Attribute attribute, void* value, int string_length);

	[CCode (cname = "SQLDrivers")]
	public Return get_drivers (FetchDirection direction,
		[CCode (array_length = true, array_pos = 2.1)] uint8[] name, out short name_ret,
		[CCode (array_length = true, array_pos = 4.1)] uint8[] attributes, out short attribute_ret);
}

// ConnectionHandle ------------------------------------------------------------

[CCode (cname = "SQLHWND")]
public struct Hwnd : long { }

[CCode (cname = "unsinged short", cprefix = "SQL_DRIVER_")]
public enum DriverCompletion {
	NOPROMPT,
	COMPLETE,
	PROMPT,
	COMPLETE_REQUIRED
}

[CCode (cname = "void", free_function = "SQLFREEDBCHANDLE")]
[Compact]
public class ConnectionHandle {
	[CCode (cname = "SQLALLOCDBCHANDLE")]
	public static Return allocate (EnvironmentHandle input_handle, out ConnectionHandle output_handle);

	[CCode (cname = "SQLDBCGETDIAGREC")]
	public Return get_diagnostic_record (
		short record_number, [CCode (array_length = false)] uint8[] state,
		out int native_error,
		[CCode (array_length = true, array_pos = 5.1)] uint8[] message_text,
		out short text_length);

	[CCode (cname = "SQLDriverConnect")]
	public Return driver_connect (Hwnd hwnd, 
		[CCode (array_length = true, array_pos = 2.1)] uint8[] connection_string_in,
		[CCode (array_length = true, array_pos = 3.1)] uint8[]? connection_string_out,
		out short? connection_string_out_len, DriverCompletion driver_completion);

	[CCode (cname = "SQLDisconnect")]
	public Return disconnect ();
}

// StatementHandle -------------------------------------------------------------

[CCode (cname = "unsinged short", cprefix = "SQL_DESC_")]
public enum ColumnDescriptor {
	COUNT,
	TYPE,
	LENGTH,
	LENGTH_PTR,
	PRECISION,
	SCALE,
	DATETIME_INTERVAL_CODE,
	NULLABLE,
	INDICATOR_PTR,
	DATA_PTR,
	NAME,
	UNNAMED,
	OCTET_LENGTH,
	ALLOC_TYPE
}

[CCode (cname = "void", free_function = "SQLFREESTMTHANDLE")]
[Compact]
public class StatementHandle {
	[CCode (cname = "SQLALLOCSTMTHANDLE")]
	public static Return allocate (ConnectionHandle input_handle, out StatementHandle output_handle);

	[CCode (cname = "SQLSTMTGETDIAGREC")]
	public Return get_diagnostic_record (
		short record_number, [CCode (array_length = false)] uint8[] state,
		out int native_error,
		[CCode (array_length = true, array_pos = 5.1)] uint8[] message_text,
		out short text_length);

	[CCode (cname = "SQLExecDirect")]
	public Return execute_direct (
		[CCode (array_length = true, array_pos = 1.1)] uint8[] text);

	[CCode (cname = "SQLNumResultCols")]
	public Return number_of_result_columns (out short column_count);

	[CCode (cname = "SQLColAttribute")]
	public Return column_attribute (ushort column_number,
		ColumnDescriptor field_identifier, void* character_attribute, 
		short buffer_length, out short string_length, out long numeric_attribute);

	[CCode (cname = "SQLFetch")]
	public Return fetch ();
}

}