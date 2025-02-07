extends Resource

var session_id: String

func subscription(type: String, version: String, condition: Dictionary) -> Dictionary:
	return {
		'type': type,
		'version': version,
		'condition': condition,
		'transport': {
			'method': "websocket",
			'session_id': session_id
		}
	}

func user_subscription(type: String, version: String, user_id: String) -> Dictionary:
	return subscription(type, version, { 'user_id': user_id })

func broadcaster_subscription(type: String, version: String, broadcaster_user_id: String) -> Dictionary:
	return subscription(type, version, { 'broadcaster_user_id': broadcaster_user_id })

func moderator_subscription(type: String, version: String, broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return subscription(type, version, { 'broadcaster_user_id': broadcaster_user_id, 'moderator_user_id': moderator_user_id })

func chat_subscription(type: String, version: String, broadcaster_user_id: String, user_id: String) -> Dictionary:
	return subscription(type, version, { 'broadcaster_user_id': broadcaster_user_id, 'user_id': user_id })

func raid_subscription(type: String, version: String, broadcaster_user_id: String, raiding: bool) -> Dictionary:
	return subscription(type, version, { 'from_broadcaster_user_id' if raiding else 'to_broadcaster_user_id': broadcaster_user_id })

func channel_points_subscription(type: String, version: String, broadcaster_user_id: String, reward_id: String = "") -> Dictionary:
	var d = { 'broadcaster_user_id': broadcaster_user_id }
	if reward_id:
		d.merge({ 'reward_id': reward_id })
	return subscription(type, version, d)

func client_subscription(type: String, version: String, client_id: String) -> Dictionary:
	return subscription(type, version, { 'client_id': client_id })

func conduit_shard_subscription(type: String, version: String, client_id: String, conduit_id: String = "") -> Dictionary:
	var d = { 'client_id': client_id }
	if conduit_id:
		d.merge({ 'conduit_id': conduit_id })
	return subscription(type, version, d)

func extension_client_subscription(type: String, version: String, extension_client_id: String) -> Dictionary:
	return subscription(type, version, { 'extension_client_id': extension_client_id })

func drop_entitlement_subscription(type: String, version: String, organization_id: String, category_id: String = "", campaign_id: String = "") -> Dictionary:
	var d = { 'organization_id': organization_id }
	if category_id:
		d.merge({ 'category_id': category_id })
	if campaign_id:
		d.merge({ 'campaign_id': campaign_id })
	return subscription(type, version, d)

func automod_message_hold(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('automod.message.hold', '2', broadcaster_user_id, moderator_user_id)

func automod_message_update(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('automod.message.update', '2', broadcaster_user_id, moderator_user_id)

func automod_settings_update(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('automod.settings.update', '1', broadcaster_user_id, moderator_user_id)

func automod_terms_update(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('automod.terms.update', '1', broadcaster_user_id, moderator_user_id)

func channel_update(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.update', '2', broadcaster_user_id)

func channel_follow(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.follow', '2', broadcaster_user_id, moderator_user_id)

func channel_ad_break_begin(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.ad_break.begin', '1', broadcaster_user_id)

func channel_chat_clear(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.clear', '1', broadcaster_user_id, user_id)

func channel_chat_clear_user_messages(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.clear_user_messages', '1', broadcaster_user_id, user_id)

func channel_chat_message(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.message', '1', broadcaster_user_id, user_id)

func channel_chat_message_delete(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.message_delete', '1', broadcaster_user_id, user_id)

func channel_chat_notification(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.notification', '1', broadcaster_user_id, user_id)

func channel_chat_settings_update(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat_settings.update', '1', broadcaster_user_id, user_id)

func channel_chat_user_message_hold(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.user_message_hold', '1', broadcaster_user_id, user_id)

func channel_chat_user_message_update(broadcaster_user_id: String, user_id: String) -> Dictionary:
	return chat_subscription('channel.chat.user_message_update', '1', broadcaster_user_id, user_id)

func channel_shared_chat_begin(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.shared_chat.begin', '1', broadcaster_user_id)

func channel_shared_chat_update(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.shared_chat.update', '1', broadcaster_user_id)

func channel_shared_chat_end(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.shared_chat.end', '1', broadcaster_user_id)

func channel_subscribe(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.subscribe', '1', broadcaster_user_id)

func channel_subscription_end(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.subscription.end', '1', broadcaster_user_id)

func channel_subscription_gift(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.subscription.gift', '1', broadcaster_user_id)

func channel_subscription_message(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.subscription.message', '1', broadcaster_user_id)

func channel_cheer(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.cheer', '1', broadcaster_user_id)

func channel_raid(broadcaster_user_id: String, raiding: bool) -> Dictionary:
	return raid_subscription('channel.raid', '1', broadcaster_user_id, raiding)

func channel_ban(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.ban', '1', broadcaster_user_id)

func channel_unban(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.unban', '1', broadcaster_user_id)

func channel_unban_request_create(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.unban_request.create', '1', broadcaster_user_id, moderator_user_id)

func channel_unban_request_resolve(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.unban_request.resolve', '1', broadcaster_user_id, moderator_user_id)

func channel_moderate(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.moderate', '2', broadcaster_user_id, moderator_user_id)

func channel_moderator_add(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.moderator.add', '1', broadcaster_user_id)

func channel_moderator_remove(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.moderator.remove', '1', broadcaster_user_id)

func channel_guest_star_session_begin(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.guest_star_session.begin', 'beta', broadcaster_user_id, moderator_user_id)

func channel_guest_star_session_end(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.guest_star_session.end', 'beta', broadcaster_user_id, moderator_user_id)

func channel_guest_star_guest_update(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.guest_star_guest.update', 'beta', broadcaster_user_id, moderator_user_id)

func channel_guest_star_settings_update(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.guest_star_settings.update', 'beta', broadcaster_user_id, moderator_user_id)

func channel_points_automatic_reward_redemption_add(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.channel_points_automatic_reward_redemption.add', '1', broadcaster_user_id)

func channel_points_custom_reward_add(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.channel_points_custom_reward.add', '1', broadcaster_user_id)

func channel_points_custom_reward_update(broadcaster_user_id: String, reward_id: String = "") -> Dictionary:
	return channel_points_subscription('channel.channel_points_custom_reward.update', '1', broadcaster_user_id, reward_id)

func channel_points_custom_reward_remove(broadcaster_user_id: String, reward_id: String = "") -> Dictionary:
	return channel_points_subscription('channel.channel_points_custom_reward.remove', '1', broadcaster_user_id, reward_id)

func channel_points_custom_reward_redemption_add(broadcaster_user_id: String, reward_id: String = "") -> Dictionary:
	return channel_points_subscription('channel.channel_points_custom_reward_redemption.add', '1', broadcaster_user_id, reward_id)

func channel_points_custom_reward_redemption_update(broadcaster_user_id: String, reward_id: String = "") -> Dictionary:
	return channel_points_subscription('channel.channel_points_custom_reward_redemption.update', '1', broadcaster_user_id, reward_id)

func channel_poll_begin(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.poll.begin', '1', broadcaster_user_id)

func channel_poll_progress(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.poll.progress', '1', broadcaster_user_id)

func channel_poll_end(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.poll.end', '1', broadcaster_user_id)

func channel_prediction_begin(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.prediction.begin', '1', broadcaster_user_id)

func channel_prediction_progress(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.prediction.progress', '1', broadcaster_user_id)

func channel_prediction_lock(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.prediction.lock', '1', broadcaster_user_id)

func channel_prediction_end(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.prediction.end', '1', broadcaster_user_id)

func channel_suspicious_user_message(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.suspicious_user.message', '1', broadcaster_user_id, moderator_user_id)

func channel_suspicious_user_update(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.suspicious_user.update', '1', broadcaster_user_id, moderator_user_id)

func channel_vip_add(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.vip.add', '1', broadcaster_user_id)

func channel_vip_remove(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.vip.remove', '1', broadcaster_user_id)

func channel_warning_acknowledge(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.warning.acknowledge', '1', broadcaster_user_id, moderator_user_id)

func channel_warning_send(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.warning.send', '1', broadcaster_user_id, moderator_user_id)

func channel_charity_campaign_donate(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.charity_campaign.donate', '1', broadcaster_user_id)

func channel_charity_campaign_start(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.charity_campaign.start', '1', broadcaster_user_id)

func channel_charity_campaign_progress(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.charity_campaign.progress', '1', broadcaster_user_id)

func channel_charity_campaign_stop(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.charity_campaign.stop', '1', broadcaster_user_id)

func conduit_shard_disabled(client_id: String, conduit_id: String = "") -> Dictionary:
	return conduit_shard_subscription('conduit.shard.disabled', '1', client_id, conduit_id)

func drop_entitlement_grant(organization_id: String, category_id: String = "", campaign_id: String = "") -> Dictionary:
	return drop_entitlement_subscription('drop.entitlement.grant', '1', organization_id, category_id, campaign_id)

func extension_bits_transaction_create(extension_client_id: String) -> Dictionary:
	return extension_client_subscription('extension.bits_transaction.create', '1', extension_client_id)

func channel_goal_begin(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.goal.begin', '1', broadcaster_user_id)

func channel_goal_progress(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.goal.progress', '1', broadcaster_user_id)

func channel_goal_end(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.goal.end', '1', broadcaster_user_id)

func channel_hype_train_begin(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.hype_train.begin', '1', broadcaster_user_id)

func channel_hype_train_progress(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.hype_train.progress', '1', broadcaster_user_id)

func channel_hype_train_end(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('channel.hype_train.end', '1', broadcaster_user_id)

func channel_shield_mode_begin(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.shield_mode.begin', '1', broadcaster_user_id, moderator_user_id)

func channel_shield_mode_end(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.shield_mode.end', '1', broadcaster_user_id, moderator_user_id)

func channel_shoutout_create(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.shoutout.create', '1', broadcaster_user_id, moderator_user_id)

func channel_shoutout_receive(broadcaster_user_id: String, moderator_user_id: String) -> Dictionary:
	return moderator_subscription('channel.shoutout.receive', '1', broadcaster_user_id, moderator_user_id)

func stream_online(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('stream.online', '1', broadcaster_user_id)

func stream_offline(broadcaster_user_id: String) -> Dictionary:
	return broadcaster_subscription('stream.offline', '1', broadcaster_user_id)

func user_authorization_grant(client_id: String) -> Dictionary:
	return client_subscription('user.authorization.grant', '1', client_id)

func user_authorization_revoke(client_id: String) -> Dictionary:
	return client_subscription('user.authorization.revoke', '1', client_id)

func user_update(user_id: String) -> Dictionary:
	return user_subscription('user.update', '1', user_id)

func user_whisper_message(user_id: String) -> Dictionary:
	return user_subscription('user.whisper.message', '1', user_id)

func _init(_session_id: String) -> void:
	self.session_id = _session_id
