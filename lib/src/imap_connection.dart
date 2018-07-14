part of imap_client;

/// A [Socket] wrapper. Holds methods tailored to imap's needs.
class ImapConnection {
  /// The socket used for communication
  Socket _socket;

  /// Direct access to the socket
  Socket get socket => _socket;

  /// Indicates whether the connection is currently open or not
  bool _isOpen = false;

  /// Read-only access to the isOpen state
  bool get isOpen => _isOpen;

  /// Sets up the socket and connects to the host
  ///
  /// Returns a future that completes when the connection is established and
  /// calls the [responseHandler] each time the new data arrives. There is an
  /// option for an [onDoneCallback] that gets called when the socket closes.
  Future<Socket> connect(
      String host, int port, bool secure, Function responseHandler,
      [Function onDoneCallback = null]) {
    Future<Socket> futureSocket =
        secure ? SecureSocket.connect(host, port) : Socket.connect(host, port);

    return futureSocket.then((socket) {
      _socket = socket;
      _isOpen = true;
      _socket.listen(responseHandler, cancelOnError: true, onDone: () {
        onDoneCallback();
        _socket.destroy();
        _isOpen = false;
      });
    });
  }

  /// Writes a line to the socket
  ///
  /// This is needed because rfc 3501 states that there should be a CRLF line
  /// ending after each command, but the normal socket writeln() just ends with
  /// a linefeed.
  /// Converts [obj] to a String by invoking Object.toString().
  /// Throws a [SocketException] if the connection is not open.
  void writeln([Object obj = ""]) {
    if (_isOpen) {
      _socket.write(obj.toString() + '\r\n');
    } else {
      throw new SocketException('Socket is closed.');
    }
  }
}