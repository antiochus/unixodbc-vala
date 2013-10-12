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
using UnixOdbcLL;

namespace UnixOdbc {

public class BytesParameter : Parameter {
	private uchar[] value;

	public override string? get_as_string () {
		if (length_or_indicator == -1) {
			return null;
		} 
		else {
			StringBuilder result = new StringBuilder ("");
			if (value.length > 0) {
				result.append ("0x");
				foreach (var byte in value) {
					result.append ("%x".printf (byte)); 
				}
			}
			return result.str;
		}
	}

	public BytesParameter (string name, uchar[]? value) {
		base (name);
		if (value == null) {
			length_or_indicator = -1;
		}
		else {
			this.value = (!) value;
			length_or_indicator = this.value.length;
		}
	}

	internal override void* get_data_pointer () {
		return value;
	}

	internal override long get_data_length () {
		return value.length;
	}

	internal override ulong get_column_size () {
		return value.length;
	}

	internal override short get_decimal_digits () {
		return 0;
	}

	internal override CDataType get_c_data_type () {
		return CDataType.BINARY;
	}

	internal override DataType get_sql_data_type () {
		return DataType.BINARY;
	}
}

}