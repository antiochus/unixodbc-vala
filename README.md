unixodbc-vala
=============

Vala bindings for unixODBC.

This projects consists of two bindings for the unixODBC API:

The low level binding (namespace `UnixOdbcLL`)
----------------------------------------------

This binding intends to make the orignal C API available in a Vala 
friendly format. It can be used to port ODBC code from C to Vala.

It gets rid of the original naming conventions (e.g. SQLBindCol is 
mapped to `bind_column ()` (which is a method of the `StatementHandle` 
class)).

Compact classes are used to add some OOP into the low level binding.

Example (error handling ommitted):

```vala
EnvironmentHandle environment;
ConnectionHandle connection;
StatementHandle statement;
uint8[] connection_string = (uint8[]) "DSN=MyDataSource;UID=MyUserName;PWD=MyPassword".data;
uint8[] code = (uint8[]) "SELECT * FROM INFORMATION_SCHEMA.TABLES".data;

EnvironmentHandle.allocate (out environment);
environment.set_attribute (Attribute.ODBC_VERSION, (void *) OdbcVersion.ODBC3, 0);
ConnectionHandle.allocate (environment, out connection);
connection.driver_connect (0, connection_string, null, null, DriverCompletion.COMPLETE);
StatementHandle.allocate (connection, out statement);
statement.execute_direct (code);
```

The high level binding (namespace `UnixOdbc`)
---------------------------------------------

Since unixODBC is pretty hard to use this namespace consists of real
Vala classes with an errordomain and some more fancy stuff.

It is built on top of `UnixOdbcLL`.

Example:

```vala
try {
	// ODBC 3 or higher is required and automatically set up
	Environment environment = new Environment ();
	Connection connection = new Connection (environment);
	connection.open ("DSN=MyDataSource;UID=MyUserName;PWD=MyPassword");
	Statement statement = new Statement (connection);
	statement.text = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?";
	statement.add_string_parameter ("TableName", "mytable");
	statement.execute ();
	foreach (var record in statement) {
		foreach (var field in record) {
			// ...
		}
	}
}
catch (UnixOdbcError e) {
	stderr.printf (@"UnixOdbc error: $(e.message)\n");
}
```

