extends Object

## The type of peer to use for the connection. Both
## server and client must match the setup.
enum PeerType {
	## Will use ENetMultiplayerPeer. It will also
	## take care about enet_-related variables both
	## in the client and in the server.
	ENET=0,

	## Will use WebSocketMultiplayerPeer. It will also
	## take care about ws_-related variables both in
	## the client and the server.
	WEBSOCKETS=1
}
