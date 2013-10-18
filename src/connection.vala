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

public class Connection {
	public bool connected { get; private set; }
	internal ConnectionHandle handle;
	public Environment environment { get; private set; }
	public string connection_string { get; set; }

	public Connection (Environment environment) throws Error {
		this.environment = environment;
		if (!succeeded (ConnectionHandle.allocate (environment.handle, out handle))) {
			throw new Error.ALLOCATE_HANDLE ("Could not allocate environment handle");
		}
	}

	~Connection () {
		close ();
	}

	private string get_diagnostic_text () {
		return UnixOdbc.get_diagnostic_record (handle.get_diagnostic_record);
	}

	public void open () throws Error {
		uchar[] connstr = (uchar[]) connection_string.data;
		if (!succeeded (handle.driver_connect (0, connstr, null, null, DriverCompletion.COMPLETE))) {
			throw new Error.DRIVER_CONNECT ("Could not open connection: " + get_diagnostic_text ());
		}
		connected = true;
	}

	public void close () {
		if (connected) {
			assert( succeeded (handle.disconnect ()));
		}
	}

	public void execute (string text) throws Error {
		var statement = new Statement (this);
		statement.text = text;
		statement.execute ();
	}
}

}