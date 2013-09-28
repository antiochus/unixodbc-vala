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

[CCode (cheader_filename = "sqlext.h")]
// Low level adaption
namespace UnixOdbcLL {

[CCode (cname = "SQLRETURN", cprefix = "SQL_")]
public enum Return {
	SUCCESS,
	SUCCESS_WITH_INFO,
	ERROR,
	INVALID_HANDLE
}

[CCode (cname = "SQLSMALLINT", cprefix = "SQL_HANDLE_")]
public enum HandleType {
	ENV,
	DBC,
	STMT,
	DESC
}

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

[CCode (cname = "unsinged short", cprefix = "SQL_DRIVER_")]
public enum DriverCompletion {
	NOPROMPT,
	COMPLETE,
	PROMPT,
	COMPLETE_REQUIRED
}

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

/*
 * This would work, but have some issues. SQLFreeHandle expects a HandleType.
 * 
 * For now let's just pretend a handle is a long integer.
 * 
[CCode(cname = "void", free_function = "SQLFreeHandle")]
[Compact]
public class Handle {
}
*/

[CCode (cname = "SQLHANDLE")]
public struct Handle : long { }

[CCode (cname = "SQLHWND")]
public struct Hwnd : long { }

[CCode (cname = "SQLAllocHandle")]
public static Return allocate_handle (HandleType type, Handle input_handle, out Handle output_handle);

[CCode (cname = "SQLFreeHandle")]
public static Return free_handle (HandleType type, Handle handle);

[CCode (cname = "SQLSetEnvAttr")]
public static Return set_environment_attribute (Handle environment, Attribute attribute, void* value, int string_length);

[CCode (cname = "SQLDrivers")]
public static Return get_drivers (Handle environment, FetchDirection direction,
	[CCode (array_length = true, array_pos = 2.1)] uint8[] name, out short name_ret,
	[CCode (array_length = true, array_pos = 4.1)] uint8[] attributes, out short attribute_ret
);

[CCode (cname = "SQLDriverConnect")]
public static Return driver_connect (Handle connection, Hwnd hwnd, 
	[CCode (array_length = true, array_pos = 2.1)] uint8[] connection_string_in,
	[CCode (array_length = true, array_pos = 3.1)] uint8[]? connection_string_out,
	out short? connection_string_out_len, DriverCompletion driver_completion);

[CCode (cname = "SQLDisconnect")]
public static Return disconnect (Handle connection);

[CCode (cname = "SQLExecDirect")]
public static Return execute_direct (Handle statement, 
	[CCode (array_length = true, array_pos = 1.1)] uint8[] text);

[CCode (cname = "SQLNumResultCols")]
public static Return number_result_columns (Handle statement, out short column_count);

[CCode (cname = "SQLColAttribute")]
public static Return column_attribute (Handle statement, ushort column_number,
	ColumnDescriptor field_identifier, void* character_attribute, 
	short buffer_length, out short string_length, out long numeric_attribute);

[CCode (cname = "SQLGetDiagRec")]
public static Return get_diagnostic_record (HandleType handle_type, 
	Handle handle, short record_number, 
	[CCode (array_length = false)] uint8[] state, out int native_error, 
	[CCode (array_length = true, array_pos = 5.1)] uint8[] message_text,
	out short text_length);

[CCode (cname = "SQLFetch")]
public static Return fetch (Handle handle);

}