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

}