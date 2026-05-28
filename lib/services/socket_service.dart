// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService
{
	static final SocketService _instance = SocketService._internal();
	
	factory SocketService() => _instance;
	
	SocketService._internal();

	IO.Socket? _socket;
	bool _isConnected = false;
	String? _currentWorkplaceId;

	bool get isConnected => _isConnected;

	void connect(String url)
	{
		if (_socket != null && _socket!.connected)
		{
			debugPrint('⚠️ Socket уже подключен');
			return;
		}

		debugPrint('🔌 Подключение к Socket.IO: $url');

		_socket = IO.io(
			url,
			IO.OptionBuilder()
				.setTransports(['websocket'])
				.disableAutoConnect()
				.build(),
		);

		_socket?.connect();

		_socket?.onConnect((_)
		{
			_isConnected = true;
			debugPrint('✅ Socket.IO подключен');

			if (_currentWorkplaceId != null)
			{
				_subscribeToWorkplace(_currentWorkplaceId!);
			}
		});

		_socket?.onDisconnect((_)
		{
			_isConnected = false;
			debugPrint('❌ Socket.IO отключен');
		});

		_socket?.onConnectError((error)
		{
			debugPrint('⚠️ Ошибка подключения Socket.IO: $error');
		});
	}

	void setWorkplace(String workplaceId)
	{
		if (_currentWorkplaceId == workplaceId) return;

		if (_currentWorkplaceId != null)
		{
			_unsubscribeFromWorkplace(_currentWorkplaceId!);
		}

		_currentWorkplaceId = workplaceId;

		if (_isConnected)
		{
			_subscribeToWorkplace(workplaceId);
		}
	}

	void _subscribeToWorkplace(String workplaceId)
	{
		debugPrint('📢 Подписка на участок: $workplaceId');
		_socket?.emit('subscribe:workplace', workplaceId);
	}

	void _unsubscribeFromWorkplace(String workplaceId)
	{
		debugPrint('📢 Отписка от участка: $workplaceId');
		_socket?.emit('unsubscribe:workplace', workplaceId);
	}

	void onOrderUpdate(Function(Map<String, dynamic>) callback)
	{
		_socket?.on('order:update', (data)
		{
			debugPrint('📨 Получено обновление заказа: $data');
			callback(data as Map<String, dynamic>);
		});
	}

	void disconnect() {
		_socket?.disconnect();
		_socket?.dispose();
		_socket = null;
		_isConnected = false;
	}
}
