// import 'dart:async';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../core/di/providers.dart';
// import '../../../core/config/socket_events.dart';
// import '../data/models.dart';

// final chatSocketProvider = Provider<ChatSocket>((ref) {
//   final socket = ref.watch(socketClientProvider).socket;
//   return ChatSocket(socket);
// });

// class ChatSocket {
//   ChatSocket(this.socket);

//   final dynamic socket; // io.Socket from socket_io_client

//   Stream<ChatMessage> onNewMessage() {
//     final controller = StreamController<ChatMessage>.broadcast();
//     socket.on(SocketEvents.messageNew, (data) {
//       // data = { message: {...}, media: {...?} }
//       final msgJson = (data['message'] as Map).cast<String, dynamic>();
//       controller.add(ChatMessage.fromJson(msgJson));
//     });
//     return controller.stream;
//   }

//   Future<Map<String, dynamic>> send({
//     required String conversationId,
//     required String type,
//     String? text,
//     Map<String, dynamic>? media,
//   }) async {
//     final completer = Completer<Map<String, dynamic>>();
//     socket.emitWithAck(
//       SocketEvents.messageSend,
//       {
//         'conversationId': conversationId,
//         'type': type,
//         if (text != null) 'text': text,
//         if (media != null) 'media': media,
//       },
//       ack: (ack) {
//         completer.complete((ack as Map).cast<String, dynamic>());
//       },
//     );
//     return completer.future;
//   }

//   void typingStart(String conversationId) {
//     socket.emit(SocketEvents.typingStart, {'conversationId': conversationId});
//   }

//   void typingStop(String conversationId) {
//     socket.emit(SocketEvents.typingStop, {'conversationId': conversationId});
//   }

//   void messageRead(String conversationId, String messageId) {
//     socket.emitWithAck(SocketEvents.messageRead, {
//       'conversationId': conversationId,
//       'messageId': messageId,
//     }, ack: (_) {});
//   }
// }
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/config/socket_events.dart';

// final chatSocketProvider = Provider<ChatSocket>((ref) {
//   final socket = ref.watch(socketClientProvider).socket;
//   return ChatSocket(socket);
// });

// class ChatSocket {
//   ChatSocket(this.socket);

//   final dynamic socket; // io.Socket

//   // --- Streams (broadcast) ---
//   Stream<Map<String, dynamic>> onNewMessageRaw() {
//     final controller = StreamController<Map<String, dynamic>>.broadcast();
//     socket.on(SocketEvents.messageNew, (data) {
//       print('SOCKET message:new payload => $data');
//       controller.add((data as Map).cast<String, dynamic>());
//     });
//     return controller.stream;
//   }

//   Stream<Map<String, dynamic>> onTypingStart() {
//     final controller = StreamController<Map<String, dynamic>>.broadcast();
//     socket.on(SocketEvents.typingStart, (data) {
//       controller.add((data as Map).cast<String, dynamic>());
//     });
//     return controller.stream;
//   }

//   Stream<Map<String, dynamic>> onTypingStop() {
//     final controller = StreamController<Map<String, dynamic>>.broadcast();
//     socket.on(SocketEvents.typingStop, (data) {
//       controller.add((data as Map).cast<String, dynamic>());
//     });
//     return controller.stream;
//   }

//   Stream<Map<String, dynamic>> onMessageRead() {
//     final controller = StreamController<Map<String, dynamic>>.broadcast();
//     socket.on(SocketEvents.messageRead, (data) {
//       controller.add((data as Map).cast<String, dynamic>());
//     });
//     return controller.stream;
//   }

//   // --- Emitters ---
//   Future<Map<String, dynamic>> send({
//     required String conversationId,
//     required String type,
//     String? text,
//     Map<String, dynamic>? media,
//   }) async {
//     final completer = Completer<Map<String, dynamic>>();
//     socket.emitWithAck(
//       SocketEvents.messageSend,
//       {
//         'conversationId': conversationId,
//         'type': type,
//         if (text != null) 'text': text,
//         if (media != null) 'media': media,
//       },
//       ack: (ack) => completer.complete((ack as Map).cast<String, dynamic>()),
//     );
//     return completer.future;
//   }

//   void typingStart(String conversationId) {
//     socket.emit(SocketEvents.typingStart, {'conversationId': conversationId});
//   }

//   void typingStop(String conversationId) {
//     socket.emit(SocketEvents.typingStop, {'conversationId': conversationId});
//   }

// Future<void> messageRead(String conversationId, String messageId) async {
//   // ack optional
//   socket.emitWithAck(SocketEvents.messageRead, {
//     'conversationId': conversationId,
//     'messageId': messageId,
//   }, ack: (_) {});
// }
// }

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ref.watch(socketClientProvider).socket;
  final chatSocket = ChatSocket(socket);
  ref.onDispose(chatSocket.dispose);
  return chatSocket;
});

class ChatSocket {
  ChatSocket(this.socket) {
    // register ONCE
    socket.on(SocketEvents.messageNew, (data) {
      // ignore: avoid_print
      print('SOCKET message:new payload => $data');
      _newMessageCtrl.add((data as Map).cast<String, dynamic>());
    });

    socket.on(SocketEvents.typingStart, (data) {
      _typingStartCtrl.add((data as Map).cast<String, dynamic>());
    });

    socket.on(SocketEvents.typingStop, (data) {
      _typingStopCtrl.add((data as Map).cast<String, dynamic>());
    });

    socket.on(SocketEvents.messageRead, (data) {
      _messageReadCtrl.add((data as Map).cast<String, dynamic>());
    });
  }

  final dynamic socket; // io.Socket

  final _newMessageCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStartCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStopCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessageRaw => _newMessageCtrl.stream;
  Stream<Map<String, dynamic>> get onTypingStart => _typingStartCtrl.stream;
  Stream<Map<String, dynamic>> get onTypingStop => _typingStopCtrl.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadCtrl.stream;

  void dispose() {
    _newMessageCtrl.close();
    _typingStartCtrl.close();
    _typingStopCtrl.close();
    _messageReadCtrl.close();
  }

  // emitters remain same:
  Future<Map<String, dynamic>> send({
    required String conversationId,
    required String type,
    String? text,
    Map<String, dynamic>? media,
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    socket.emitWithAck(
      SocketEvents.messageSend,
      {
        'conversationId': conversationId,
        'type': type,
        if (text != null) 'text': text,
        if (media != null) 'media': media,
      },
      ack: (ack) => completer.complete((ack as Map).cast<String, dynamic>()),
    );
    return completer.future;
  }

  void typingStart(String conversationId) {
    socket.emit(SocketEvents.typingStart, {'conversationId': conversationId});
  }

  void typingStop(String conversationId) {
    socket.emit(SocketEvents.typingStop, {'conversationId': conversationId});
  }

  Future<void> messageRead(String conversationId, String messageId) async {
    socket.emitWithAck(SocketEvents.messageRead, {
      'conversationId': conversationId,
      'messageId': messageId,
    }, ack: (_) {});
  }
}
