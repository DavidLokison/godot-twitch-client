extends Object

signal _ready(eventsub: TwitchClient.EventSub)

var Subscription

var client: TwitchClient
var eventsub := WebSocketPeer.new()
var reconnect: WebSocketPeer = null
var subscriptions := {}
var message_cache := {}

func _init(_client) -> void:
	self.client = _client

func open() -> void:
	if not eventsub.get_requested_url():
		eventsub.connect_to_url("wss://eventsub.wss.twitch.tv/ws")

func transfer() -> void:
	client.status = TwitchClient.Status.RUNNING
	eventsub.close()
	eventsub = reconnect
	reconnect = null

func poll(peer: WebSocketPeer = eventsub) -> bool:
	peer.poll()
	match peer.get_ready_state():
		WebSocketPeer.STATE_OPEN when peer.get_available_packet_count():
			var packet: Dictionary = JSON.parse_string(peer.get_packet().get_string_from_utf8())
			if not packet.metadata.message_id in message_cache:
				var payload = packet.payload
				message_cache[packet.metadata.message_id] = payload
				match packet.metadata.message_type:
					'session_welcome':
						Subscription = preload("subscription.gd").new(payload.session.id)
						if client.eventsub is Signal:
							client.eventsub = self
							_ready.emit(self)
						else:
							client.status = TwitchClient.Status.RECONNECTING
					'session_keepalive':
						print_verbose("Received keepalive message")
					'session_reconnect':
						print_verbose("Received reconnect notice")
						reconnect = WebSocketPeer.new()
						reconnect.connect_to_url(payload.session.reconnect_url)
					'notification':
						print_verbose("Received notification: %s (%s)" % [payload.subscription.id, payload.subscription.type])
						emit_signal(payload.subscription.id, payload.event)
					'revocation':
						print_rich("[color=red]Received revocation message for subscription %s (%s). Reason: %s[/color]" % [payload.subscription.id, payload.subscription.type, payload.subscription.status])
						client.status = TwitchClient.Status.ERROR
		WebSocketPeer.STATE_OPEN:
			return true
		WebSocketPeer.STATE_CLOSED:
			printerr("WebSocket closed (%d). Reason: %s" % [peer.get_close_code(), peer.get_close_reason()])
			client.status = TwitchClient.Status.DISCONNECTED
	return false

func subscribe(subscription: Dictionary, callable: Callable) -> void:
	var key := hash(subscription)
	if not key in subscriptions:
		subscriptions[key] = []
		client.helix(func(response):
			var callbacks: Array = subscriptions[key]
			var id := StringName(response.data[0].id)
			subscriptions[key] = id
			add_user_signal(id, [ { 'name': 'payload', 'type': TYPE_DICTIONARY } ])
			print("Subscribed to %s (%s)" % [id, subscription.type])
			for callback in callbacks:
				connect(id, callback)
		, "eventsub/subscriptions", HTTPClient.METHOD_POST, subscription)
	if subscriptions[key] is StringName:
		if not is_connected(subscriptions[key], callable):
			connect(subscriptions[key], callable)
	subscriptions[key].append(callable)

func unsubscribe(subscription: Dictionary, callable: Callable) -> void:
	var key := hash(subscription)
	if not key in subscriptions:
		return
	# TODO: unsubscribing while still pending???
	if not is_connected(subscriptions[key], callable):
		return
	disconnect(subscriptions[key], callable)
	if not get_signal_connection_list(subscriptions[key]):
		client.helix(func(_response):
			print("Unsubscribed from %s (%s)" % [subscriptions[key], subscription.type])
		, "eventsub/subscriptions", HTTPClient.METHOD_DELETE)
		remove_user_signal(subscriptions[key])
		subscriptions.erase(key)
