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

public class DateTimeParameter : Parameter {
	private string value;

	public override string? get_as_string () {
		if (length_or_indicator == -1) {
			return null;
		} 
		else {
			return value;
		}
	}

	public DateTimeParameter (DateTime? value) {
		base ();
		if (value == null) {
			length_or_indicator = -1;
		}
		else {
			DateTime v = (!) value;
			// Note that month is "m", minute is "n" and day of month is "d"
			int y = v.get_year ();
			int m = v.get_month ();
			int d = v.get_day_of_month ();
			int h = v.get_hour ();
			int n = v.get_minute ();
			int s = v.get_second ();
			int f = v.get_microsecond () / 1000;
			// This is the only correct way, ODBC only accepts these specific formats:
			// yyyy-mm-dd hh:nn:ss.fff
			// yyyy-mm-dd hh:nn:ss
			this.value = "%0.4d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d.%0.3d".printf (y, m, d, h, n, s, f);
			length_or_indicator = this.value.data.length;
		}
	}

	internal override void bind (Statement statement, int number) throws Error {
		if (!succeeded (statement.handle.bind_datetime_input_parameter (number,
			value.data, &length_or_indicator))) {
			throw new Error.BIND_PARAMETER (@"Could not bind parameter $number (input, datetime)");
		}
	}
}

}