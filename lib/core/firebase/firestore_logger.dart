import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Logs Firestore operations to the terminal in real time (debug only).
/// Use to spot permission-denied and other failures during development.
class FirestoreLogger {
  FirestoreLogger._();

  static const _tag = 'Firestore';

  static bool get _enabled => kDebugMode;

  static void _log(String message, {String? path, Object? error}) {
    if (!_enabled) return;
    final buf = StringBuffer('[$_tag] $message');
    if (path != null && path.isNotEmpty) buf.write(' path=$path');
    if (error != null) buf.write(' error=$error');
    debugPrint(buf.toString());
  }

  /// Extract a short error code for permission-denied and similar.
  static String _errorCode(Object e) {
    if (e is FirebaseException) {
      final code = e.code;
      if (code == 'permission-denied') return 'PERMISSION-DENIED';
      return code;
    }
    return e.toString().replaceAll(RegExp(r'\s+'), ' ').length > 60
        ? '${e.toString().substring(0, 57)}...'
        : e.toString();
  }

  /// Log a read (get) and return the result or rethrow.
  static Future<T> logRead<T>(String path, Future<T> Function() fn) async {
    if (!_enabled) return fn();
    _log('READ', path: path);
    try {
      final r = await fn();
      _log('READ OK', path: path);
      return r;
    } catch (e, st) {
      _log('READ FAILED', path: path, error: _errorCode(e));
      developer.log('', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Log a stream listen (snapshots). Logs on error (e.g. permission-denied).
  static Stream<T> logStream<T>(String path, Stream<T> stream) {
    if (!_enabled) return stream;
    return stream.handleError((Object e, StackTrace st) {
      _log('STREAM FAILED', path: path, error: _errorCode(e));
      developer.log('', name: _tag, error: e, stackTrace: st);
      throw e;
    });
  }

  /// Log a write (set / update / delete) and return or rethrow.
  static Future<T> logWrite<T>(
    String path,
    String op,
    Future<T> Function() fn,
  ) async {
    if (!_enabled) return fn();
    _log('WRITE $op', path: path);
    try {
      final r = await fn();
      _log('WRITE $op OK', path: path);
      return r;
    } catch (e, st) {
      _log('WRITE $op FAILED', path: path, error: _errorCode(e));
      developer.log('', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Log a transaction and return or rethrow.
  static Future<T> logTransaction<T>(
    String label,
    Future<T> Function(Transaction transaction) fn,
    FirebaseFirestore firestore,
  ) async {
    if (!_enabled) return firestore.runTransaction(fn);
    _log('TRANSACTION', path: label);
    try {
      final r = await firestore.runTransaction(fn);
      _log('TRANSACTION OK', path: label);
      return r;
    } catch (e, st) {
      _log('TRANSACTION FAILED', path: label, error: _errorCode(e));
      developer.log('', name: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }
}
