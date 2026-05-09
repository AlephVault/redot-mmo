extends Object

class_name AlephVault__MMO

class Client:
	const Main = preload("./client/main.gd")
	const Connections = preload("./client/connections.gd")
	const Connection = preload("./client/connections/connection.gd")
	const ConnectionCommands = preload("./client/connections/commands.gd")
	const ConnectionNotifications = preload("./client/connections/notifications.gd")
	const World = preload("./client/world.gd")
	const Scope = preload("./client/scope.gd")

class Server:
	const Main = preload("./server/main.gd")
	const Connections = preload("./server/connections.gd")
	const Connection = preload("./server/connections/connection.gd")
	const ConnectionCommands = preload("./server/connections/commands.gd")
	const ConnectionNotifications = preload("./server/connections/notifications.gd")
	const World = preload("./server/world.gd")
	const Scope = preload("./server/scope.gd")

class Common:
	const Scopes = preload("./common/scopes.gd")
 
