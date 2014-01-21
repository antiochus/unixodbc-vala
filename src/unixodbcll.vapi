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

[CCode (cheader_filename = "sqlext.h,unixodbcll.h")]
// Low level adaption
namespace UnixOdbcLL {

[CCode (cname = "SQLRETURN", cprefix = "SQL_", has_type_id = false)]
public enum Return {
	SUCCESS,
	SUCCESS_WITH_INFO,
	ERROR,
	INVALID_HANDLE,
	NO_DATA
}

public bool succeeded (Return ret) {
	return (ret == Return.SUCCESS || ret == Return.SUCCESS_WITH_INFO);
}

// EnvironmentHandle -----------------------------------------------------------

[CCode (cname = "SQLINTEGER", cprefix = "SQL_ATTR_", has_type_id = false)]
public enum Attribute {
	ODBC_VERSION
}

// There is no exact ODBC data type that is unsigned long for 32 and 64 bits
// The constant is defined as UL, so use unsigned long as the cname
[CCode (cname = "unsigned long", cprefix = "SQL_OV_", has_type_id = false)]
public enum OdbcVersion {
	ODBC3
}

[CCode (cname = "SQLUSMALLINT", cprefix = "SQL_FETCH_", has_type_id = false)]
public enum FetchDirection {
	NEXT,
	FIRST,
	LAST,
	PRIOR,
	ABSOLUTE,
	RELATIVE
}

[CCode (cname = "void", free_function = "SQLFREEENVHANDLE", has_type_id = false)]
[Compact]
public class EnvironmentHandle {
	[CCode (cname = "SQLALLOCENVHANDLE")]
	public static Return allocate (out EnvironmentHandle output_handle);

	[CCode (cname = "SQLENVGETDIAGREC")]
	public Return get_diagnostic_record (
		short record_number, [CCode (array_length = false)] uint8[] state,
		out int native_error, uint8[] message_text, out short text_length);

	[CCode (cname = "SQLSetEnvAttr")]
	public Return set_attribute (Attribute attribute, void* value, int string_length);

	[CCode (cname = "SQLDrivers")]
	public Return get_drivers (FetchDirection direction,
		uint8[] name, out short name_ret,
		uint8[] attributes, out short attribute_ret);
}

// ConnectionHandle ------------------------------------------------------------

[CCode (cname = "SQLHWND", has_type_id = false)]
public struct Hwnd : long { }

[CCode (cname = "SQLUSMALLINT", cprefix = "SQL_DRIVER_", has_type_id = false)]
public enum DriverCompletion {
	NOPROMPT,
	COMPLETE,
	PROMPT,
	COMPLETE_REQUIRED
}

[CCode (cname = "void", free_function = "SQLFREEDBCHANDLE", has_type_id = false)]
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

[CCode (cname = "SQLUSMALLINT", cprefix = "SQL_DESC_", has_type_id = false)]
public enum ColumnDescriptorInt {
	AUTO_UNIQUE_VALUE, // ODBC 1.0
	CASE_SENSITIVE, // ODBC 1.0
	CONCISE_TYPE,  // ODBC 1.0
	COUNT, // ODBC 1.0
	DISPLAY_SIZE, // ODBC 1.0
	FIXED_PREC_SCALE, // ODBC 1.0
	LENGTH, // ODBC 3.0
	NULLABLE, // ODBC 3.0
	NUM_PREC_RADIX, // ODBC 3.0
	OCTET_LENGTH, // ODBC 3.0
	PRECISION, // ODBC 3.0
	SCALE, // ODBC 3.0
	SEARCHABLE, // ODBC 1.0
	TYPE, // ODBC 3.0
	UNNAMED, // ODBC 3.0
	UNSIGNED, // ODBC 1.0
	UPDATABLE, // ODBC 1.0
}

[CCode (cname = "SQLUSMALLINT", cprefix = "SQL_DESC_", has_type_id = false)]
public enum ColumnDescriptorString {
	BASE_COLUMN_NAME, // ODBC 3.0
	BASE_TABLE_NAME, // ODBC 3.0
	CATALOG_NAME, // ODBC 3.0
	LABEL, // ODBC 2.0
	LITERAL_PREFIX, // ODBC 3.0
	LITERAL_SUFFIX, // ODBC 3.0
	LOCAL_TYPE_NAME, // ODBC 3.0
	NAME, // ODBC 3.0
	SCHEMA_NAME, // ODBC 2.0
	TABLE_NAME, // ODBC 2.0
	TYPE_NAME, // ODBC 1.0
}

/*
	// TODO: Other SQL_DESC_ values from the unixodbc header files
	LENGTH_PTR,
	DATETIME_INTERVAL_CODE,
	INDICATOR_PTR,
	DATA_PTR,
	ALLOC_TYPE,
*/

[CCode (cname = "SQLSMALLINT", cprefix = "SQL_C_", has_type_id = false)]
public enum CDataType {
	CHAR,
	LONG,
	SHORT,
	FLOAT,
	DOUBLE,
	NUMERIC,
	DEFAULT,
	DATE,
	TIME,
	TIMESTAMP,
	TYPE_DATE,
	TYPE_TIME,
	TYPE_TIMESTAMP,
	INTERVAL_YEAR,
	INTERVAL_MONTH,
	INTERVAL_DAY,
	INTERVAL_HOUR,
	INTERVAL_MINUTE,
	INTERVAL_SECOND,
	INTERVAL_YEAR_TO_MONTH,
	INTERVAL_DAY_TO_HOUR,
	INTERVAL_DAY_TO_MINUTE,
	INTERVAL_DAY_TO_SECOND,
	INTERVAL_HOUR_TO_MINUTE,
	INTERVAL_HOUR_TO_SECOND,
	INTERVAL_MINUTE_TO_SECOND,
	BINARY,
	BIT,
	SBIGINT,
	UBIGINT,
	TINYINT,
	SLONG,
	SSHORT,
	STINYINT,
	ULONG,
	USHORT,
	UTINYINT,
	BOOKMARK,
	GUID,
	VARBOOKMARK,
	WCHAR
}

[CCode (cname = "SQLSMALLINT", cprefix = "SQL_", has_type_id = false)]
public enum DataType {
	CHAR,
	VARCHAR,
	LONGVARCHAR,
	WCHAR,
	WVARCHAR,
	WLONGVARCHAR,
	DECIMAL,
	NUMERIC,
	SMALLINT,
	INTEGER,
	REAL,
	FLOAT,
	DOUBLE,
	BIT,
	TINYINT,
	BIGINT,
	BINARY,
	VARBINARY,
	LONGVARBINARY,
	TYPE_DATE,
	TYPE_TIME,
	TYPE_TIMESTAMP,
	TYPE_UTCDATETIME,
	TYPE_UTCTIME,
	INTERVAL_MONTH,
	INTERVAL_YEAR,
	INTERVAL_YEAR_TO_MONTH,
	INTERVAL_DAY,
	INTERVAL_HOUR,
	INTERVAL_MINUTE,
	INTERVAL_SECOND,
	INTERVAL_DAY_TO_HOUR,
	INTERVAL_DAY_TO_MINUTE,
	INTERVAL_DAY_TO_SECOND,
	INTERVAL_HOUR_TO_MINUTE,
	INTERVAL_HOUR_TO_SECOND,
	INTERVAL_MINUTE_TO_SECOND,
	GUID
}

[CCode (cname = "SQLSMALLINT", cprefix = "SQL_PARAM_", has_type_id = false)]
public enum InputOutputType {
	INPUT,
	INPUT_OUTPUT,
	OUTPUT,
	OUTPUT_STREAM
}

[CCode (cname = "void", free_function = "SQLFREESTMTHANDLE", has_type_id = false)]
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
		uint8[] text);

	[CCode (cname = "SQLPrepare")]
	public Return prepare (
		uint8[] text);

	[CCode (cname = "SQLExecute")]
	public Return execute ();

	[CCode (cname = "SQLNumResultCols")]
	public Return number_of_result_columns (out short column_count);

	[CCode (cname = "SQLColAttribute")]
	private Return column_attribute (ushort column_number,
		ushort field_identifier, void *character_attribute, 
		short buffer_length, out short string_length, out long numeric_attribute);

	[CCode (cname = "SQLColIntAttribute")]
	public Return column_int_attribute (int column_number,
		ColumnDescriptorInt field_identifier, int value)
	{
		short string_length;
		long numeric_attribute;
		return column_attribute ((ushort) column_number, (ushort) field_identifier,
			&value, 0, out string_length, out numeric_attribute);
	}

	[CCode (cname = "SQLColStringAttribute")]
	public Return column_string_attribute (int column_number,
		ColumnDescriptorString field_identifier, uint8[] value)
	{
		short string_length;
		long numeric_attribute;
		return column_attribute ((ushort) column_number, (ushort) field_identifier,
			value, (short) value.length, out string_length, out numeric_attribute);
	}

	[CCode (cname = "SQLFetch")]
	public Return fetch ();

	[CCode (cname = "SQLBindCol")]
	private Return bind_column (ushort column_number, CDataType target_type,
		void *target_value, long buffer_length, long *length_or_indicator);

	[CCode (cname = "SQLBindStringCol")]
	public Return bind_string_column (int column_number, uint8[] value,
		long *length_or_indicator)
		requires (column_number >= 0)
	{
		return bind_column ((ushort) column_number, CDataType.CHAR, value, value.length,
			length_or_indicator);
	}

	[CCode (cname = "SQLBindParameter")]
	private Return bind_parameter (ushort parameter_number,
		InputOutputType input_output_type, CDataType value_type,
		DataType parameter_type, ulong column_size, short decimals_digits,
		void *parameter_value, long buffer_length, long *length_or_indicator);

	[CCode (cname = "SQLBindBytesInputParameter")]
	public Return bind_bytes_input_parameter (int number, uchar[] value, 
		long *length_or_indicator)
		requires (number >= 1)
	{
		return bind_parameter ((ushort) number, InputOutputType.INPUT,
			CDataType.BINARY, DataType.BINARY, value.length, 0, value, value.length,
			length_or_indicator);
	}

	[CCode (cname = "SQLBindStringInputParameter")]
	public Return bind_string_input_parameter (int number, uint8[] value, 
		long *length_or_indicator)
		requires (number >= 1)
	{
		return bind_parameter ((ushort) number, InputOutputType.INPUT,
			CDataType.CHAR, DataType.CHAR, value.length, 0, value, value.length,
			length_or_indicator);
	}

	[CCode (cname = "SQLBindIntInputParameter")]
	public Return bind_int_input_parameter (int number, int *value,
		long *length_or_indicator)
		requires (number >= 1)
	{
		return bind_parameter ((ushort) number, InputOutputType.INPUT,
			CDataType.LONG, DataType.INTEGER, 0, 0, value, 0,
			length_or_indicator);
	}

	[CCode (cname = "SQLBindDoubleInputParameter")]
	public Return bind_double_input_parameter (int number, double *value,
		long *length_or_indicator)
		requires (number >= 1)
	{
		return bind_parameter ((ushort) number, InputOutputType.INPUT,
			CDataType.DOUBLE, DataType.FLOAT, 0, 0, value, 0,
			length_or_indicator);
	}

	[CCode (cname = "SQLBindDateTimeInputParameter")]
	public Return bind_datetime_input_parameter (int number, uint8[] value, 
		long *length_or_indicator)
		requires (number >= 1)
	{
		// Three digits for second fractions
		return bind_parameter ((ushort) number, InputOutputType.INPUT,
			CDataType.CHAR, DataType.TYPE_TIMESTAMP, 0, 3, value, value.length,
			length_or_indicator);
	}
}

}