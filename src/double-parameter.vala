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
using UnixOdbcLL;

namespace UnixOdbc {

public class DoubleParameter : Parameter {
	private double value;

	public override string? get_as_string () {
		if (length_or_indicator == -1) {
			return null;
		} 
		else {
			return value.to_string ();
		}
	}

	public DoubleParameter (double? value) {
		base ();
		if (value == null) {
			length_or_indicator = -1;
		}
		else {
			this.value = (!) value;
			length_or_indicator = 0;
		}
	}

	internal override void bind (Statement statement, int number) throws Error, GLib.ConvertError {
		// TODO: This doesn't work when the SQL data type is NUMERIC (exact numeric)
		// Maybe introduce a DecimalParameter, based on the SQL_NUMERIC_STRUCT data type
		if (!succeeded (statement.handle.bind_double_input_parameter (number,
			&value, &length_or_indicator))) {
			throw new Error.BIND_PARAMETER (statement.get_diagnostic_text ("SQLBindCol") + @"\nCould not bind parameter $number (input, double)");
		}
	}
}

}