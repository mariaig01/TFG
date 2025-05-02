import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../env.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket socket;
  bool _isConnected = false;
  int? _userId;

  Function(dynamic)? _onDirectMessage;
  Function(dynamic)? _onGroupMessage;
  Function(dynamic)? _onNewComment;

  SocketService._internal();

  void init({
    required int userId,
    Function(dynamic)? onDirectMessage,
    Function(dynamic)? onGroupMessage,
    Function(dynamic)? onNewComment,
  }) {
    _userId = userId;
    _onDirectMessage = onDirectMessage;
    _onGroupMessage = onGroupMessage;
    _onNewComment = onNewComment;

    if (_isConnected) {
      print('🔄 Socket ya conectado, actualizando callbacks...');
      return;
    }

    socket = IO.io(baseURL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('🟢 Socket.IO conectado');
      _isConnected = true;
      socket.emit('join', {'user_id': _userId});
    });

    socket.onDisconnect((_) {
      print('🔴 Socket.IO desconectado');
      _isConnected = false;
    });

    socket.on('nuevo_mensaje', (data) {
      print('📩 nuevo_mensaje: $data');
      _onDirectMessage?.call(data);
    });

    socket.on('nuevo_mensaje_grupo', (data) {
      print('👥 nuevo_mensaje_grupo: $data');
      _onGroupMessage?.call(data);
    });
  }

  void joinGroup(int groupId) {
    if (_isConnected) {
      socket.emit('join_group', {'grupo_id': groupId});
    }
  }

  void listenToComments(int postId, Function(dynamic) callback) {
    socket.on('nuevo_comentario_$postId', callback);
  }

  void setCallbacks({
    Function(dynamic)? onDirectMessage,
    Function(dynamic)? onGroupMessage,
  }) {
    _onDirectMessage = onDirectMessage;
    _onGroupMessage = onGroupMessage;
  }

  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      _isConnected = false;
    }
    _onDirectMessage = null;
    _onGroupMessage = null;
  }

  void dispose() {
    if (_isConnected) {
      socket.dispose();
      _isConnected = false;
    }
    _onDirectMessage = null;
    _onGroupMessage = null;
  }
}
