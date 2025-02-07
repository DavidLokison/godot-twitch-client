extends Node

enum Status {
	CONNECTING,
	AUTHORIZING,
	VERIFYING,
	VALIDATING,
	INITIALIZING,
	RECONNECTING,
	RUNNING,
	DISCONNECTED = -1,
	ERROR = -2
}

const EventSub = preload("res://twitch-client/event_sub.gd")

var status := Status.CONNECTING
var config_file := ConfigFile.new()
var config := Dictionary()
var headers := PackedStringArray()
var oauth_client := HTTPClient.new()
var oauth_payload := Dictionary()
var helix_client := HTTPClient.new()
var helix_queue: Array[Dictionary] = []
var helix_request := Dictionary()
var helix_response := PackedByteArray()
var _eventsub := EventSub.new(self)
var eventsub = _eventsub._ready

func helix(callback: Callable, path: String, method := HTTPClient.METHOD_GET, payload: Dictionary = {}) -> void:
	helix_queue.push_back({
		'method': method,
		'path': path,
		'payload': payload,
		'callback': callback
	} if payload else {
		'method': method,
		'path': path,
		'callback': callback
	})

func _enter_tree() -> void:
	if config_file.load("user://config.ini") == OK:
		config.client_id = config_file.get_value('Twitch', 'client_id')
		config.broadcaster_id = config_file.get_value('Twitch', 'broadcaster_id')
		config.user_id = config_file.get_value('Twitch', 'user_id')
		config.scopes = config_file.get_value('Twitch', 'scopes')
	else:
		print_rich("[color=red]No config file found! Creating empty config, aborting[/color]")
		config_file.set_value('Twitch', 'client_id', "<insert your client id here>")
		config_file.set_value('Twitch', 'broadcaster_id', "<insert your broadcaster id here>")
		config_file.set_value('Twitch', 'user_id', "<insert your user id here>")
		config_file.set_value('Twitch', 'scopes', "<which scopes do you need?>")
		config_file.save("user://config.ini")
		self.get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _physics_process(_delta: float) -> void:
	match status:
		Status.DISCONNECTED, Status.ERROR:
			self.get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		Status.RUNNING when _eventsub.reconnect:
			_eventsub.poll(_eventsub.reconnect)
		Status.RUNNING:
			_eventsub.poll()
			if helix_queue or helix_request:
				match oauth_client.get_status():
					HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_DISCONNECTED:
						status = Status.VALIDATING
					HTTPClient.STATUS_BODY:
						match helix_client.get_status():
							HTTPClient.STATUS_DISCONNECTED:
								print_verbose("HELIX Connecting")
								helix_client.connect_to_host("https://api.twitch.tv")
							HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_REQUESTING:
								helix_client.poll()
							HTTPClient.Status.STATUS_CANT_RESOLVE:
								status = Status.ERROR
								printerr("HELIX Unresolved")
							HTTPClient.STATUS_CANT_CONNECT:
								status = Status.ERROR
								printerr("HELIX Host Connection failed")
							HTTPClient.STATUS_CONNECTION_ERROR:
								status = Status.ERROR
								printerr("HELIX HTTP Connection failed")
							HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
								status = Status.ERROR
								printerr("HELIX TLS Handshake failed")
							HTTPClient.STATUS_CONNECTED when not helix_request.is_empty():
								print_verbose("Handling %s" % helix_request.path)
								helix_request.callback.call(JSON.parse_string(helix_response.get_string_from_utf8()))
								helix_request.clear()
								helix_response.clear()
							HTTPClient.STATUS_CONNECTED:
								helix_request = helix_queue.pop_front()
								@warning_ignore("shadowed_variable")
								var headers = self.headers.duplicate()
								var path = helix_request.path
								var payload = ""
								if 'payload' in helix_request:
									match helix_request.method:
										HTTPClient.METHOD_GET, HTTPClient.METHOD_DELETE:
											path += "?%s" % helix_client.query_string_from_dict(helix_request.payload)
										_:
											payload = JSON.stringify(helix_request.payload)
											headers.append("Content-Type: application/json")
								print_verbose("Requesting %s" % path)
								helix_client.request(helix_request.method, "/helix/%s" % path, headers, payload)
							HTTPClient.STATUS_BODY when helix_client.get_response_code() >= 400:
								status = Status.ERROR
								printerr("HELIX Response %d" % helix_client.get_response_code())
								if helix_client.has_response():
									printerr(helix_client.read_response_body_chunk().get_string_from_utf8())
							HTTPClient.STATUS_BODY:
								helix_response.append_array(helix_client.read_response_body_chunk())
			elif oauth_client.get_status() == HTTPClient.STATUS_BODY and helix_client.get_status():
				oauth_client.read_response_body_chunk()
				helix_client.close()
				print_verbose("HELIX Disconnected")
				oauth_client.close()
				print_verbose("OAUTH Disconnected")
		Status.RECONNECTING:
			if _eventsub.poll():
				_eventsub.transfer()
		Status.INITIALIZING:
			status = Status.VALIDATING
			_eventsub.open()
		_:
			match oauth_client.get_status():
				HTTPClient.STATUS_DISCONNECTED:
					print_verbose("OAUTH Connecting")
					oauth_client.connect_to_host("https://id.twitch.tv")
				HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_REQUESTING:
					oauth_client.poll()
				HTTPClient.Status.STATUS_CANT_RESOLVE:
					status = Status.ERROR
					printerr("OAUTH Unresolved")
				HTTPClient.STATUS_CANT_CONNECT:
					status = Status.ERROR
					printerr("OAUTH Host Connection failed")
				HTTPClient.STATUS_CONNECTION_ERROR:
					status = Status.ERROR
					printerr("OAUTH HTTP Connection failed")
				HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
					status = Status.ERROR
					printerr("OAUTH TLS Handshake failed")
				HTTPClient.STATUS_CONNECTED when status == Status.CONNECTING and FileAccess.file_exists("user://.access"):
					status = Status.INITIALIZING
					headers = [
						"Authorization: Bearer %s" % FileAccess.get_file_as_string("user://.access"),
						"Client-Id: %s" % config.client_id
					]
					oauth_payload = {
						'client_id': config.client_id,
						'grant_type': "refresh_token",
						'refresh_token': FileAccess.get_file_as_string("user://.refresh")
					}
				HTTPClient.STATUS_CONNECTED when status == Status.AUTHORIZING or status == Status.CONNECTING:
					status = Status.AUTHORIZING
					oauth_payload = {
						'client_id': config.client_id,
						'scopes': config.scopes
					}
				HTTPClient.STATUS_BODY when status == Status.AUTHORIZING:
					status = Status.VERIFYING
					var response = JSON.parse_string(oauth_client.read_response_body_chunk().get_string_from_utf8())
					oauth_payload['device_code'] = response['device_code']
					oauth_payload['grant_type'] = "urn:ietf:params:oauth:grant-type:device_code"
					print_verbose("Device code generated")
					print_rich("[color=orange]Visit [b][url=%s]%s[/url][/b] to verify the device.[/color]" % [response['verification_uri'], response['verification_uri']])
				HTTPClient.STATUS_BODY when status == Status.VERIFYING and oauth_client.get_response_code() == 200:
					status = Status.CONNECTING
					var response = JSON.parse_string(oauth_client.read_response_body_chunk().get_string_from_utf8())
					var file := FileAccess.open("user://.access", FileAccess.WRITE)
					file.store_string(response['access_token'])
					file.close()
					file = FileAccess.open("user://.refresh", FileAccess.WRITE)
					file.store_string(response['refresh_token'])
					file.close()
				HTTPClient.STATUS_BODY when status == Status.VERIFYING and oauth_client.get_response_code() == 400:
					var response = JSON.parse_string(oauth_client.read_response_body_chunk().get_string_from_utf8())
					if response['message'] != "authorization_pending":
						printerr("OAUTH Verification failed: %s" % response['message'])
						status = Status.ERROR
				HTTPClient.STATUS_BODY when status == Status.VERIFYING and oauth_client.get_response_code() == 401:
					status = Status.CONNECTING
					oauth_client.read_response_body_chunk()
					DirAccess.remove_absolute("user://.access")
					DirAccess.remove_absolute("user://.refresh")
					print("Refresh token expired, reauthorizing")
				HTTPClient.STATUS_BODY when status == Status.VALIDATING and oauth_client.get_response_code() == 200:
					status = Status.RUNNING
				HTTPClient.STATUS_BODY when status == Status.VALIDATING and oauth_client.get_response_code() == 401:
					status = Status.VERIFYING
					oauth_client.read_response_body_chunk()
					print("Access token expired, refreshing")
			if status > Status.CONNECTING and status < Status.INITIALIZING and oauth_client.get_status() == HTTPClient.STATUS_CONNECTED:
				var payload = oauth_client.query_string_from_dict(oauth_payload)
				match status:
					Status.AUTHORIZING:
						oauth_client.request(HTTPClient.METHOD_POST, "/oauth2/device", [
							"Content-Type: application/x-www-form-urlencoded",
							"Content-Length: " + str(payload.length())
						], payload)
					Status.VERIFYING:
						oauth_client.request(HTTPClient.METHOD_POST, "/oauth2/token", [
							"Content-Type: application/x-www-form-urlencoded",
							"Content-Length: " + str(payload.length())
						], payload)
					Status.VALIDATING:
						print_verbose("Validating")
						oauth_client.request(HTTPClient.METHOD_GET, "/oauth2/validate", headers)
