import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary _sledNative = Platform.isAndroid
    ? ffi.DynamicLibrary.open("libsled_native.so")
    : ffi.DynamicLibrary.process();

final ffi.Pointer Function() _createConfig = _sledNative
    .lookup<ffi.NativeFunction<ffi.Pointer Function()>>("sled_create_config")
    .asFunction();

final void Function(ffi.Pointer) _freeConfig = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer)>>(
        "sled_free_config")
    .asFunction();

final void Function(ffi.Pointer, ffi.Pointer<Utf8>) _configSetPath = _sledNative
    .lookup<
        ffi.NativeFunction<
            ffi.Void Function(
                ffi.Pointer, ffi.Pointer<Utf8>)>>("sled_config_set_path")
    .asFunction();

final void Function(ffi.Pointer, int) _configSetReadOnly = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer, ffi.Uint8)>>(
        "sled_config_read_only")
    .asFunction();

final void Function(ffi.Pointer, int) _configSetCacheCapacity = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer, ffi.Uint32)>>(
        "sled_config_set_cache_capacity")
    .asFunction();

final void Function(ffi.Pointer, int) _configUseCompression = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer, ffi.Uint8)>>(
        "sled_config_use_compression")
    .asFunction();

final void Function(ffi.Pointer, int) _configFlushEveryMs = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer, ffi.Uint64)>>(
        "sled_config_flush_every_ms")
    .asFunction();

class Config {
  ffi.Pointer _configPointer = _createConfig();

  Config(
    String path, {
    bool readOnly = false,
    int cacheCapacity = 200,
    bool useCompression = true,
    int flushEveryMs = 1000,
  }) {
    _configSetPath(this._configPointer, Utf8.toUtf8(path));
    _configSetReadOnly(this._configPointer, readOnly ? 1 : 0);
    if (cacheCapacity != 0) {
      _configSetCacheCapacity(this._configPointer, cacheCapacity);
    }
    _configUseCompression(this._configPointer, useCompression ? 1 : 0);
    _configFlushEveryMs(this._configPointer, flushEveryMs);
  }

  ffi.Pointer _consume() {
    var pointer = this._configPointer;
    this._configPointer = null;
    return pointer;
  }

  void dispose() {
    if (this._configPointer != null) {
      _freeConfig(this._configPointer);
    }
  }
}

final ffi.Pointer Function(ffi.Pointer) _openDb = _sledNative
    .lookup<ffi.NativeFunction<ffi.Pointer Function(ffi.Pointer)>>(
        "sled_open_db")
    .asFunction();

final void Function(ffi.Pointer) _closeDb = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer)>>("sled_close")
    .asFunction();

final void Function(
  ffi.Pointer, // Db
  ffi.Pointer<Utf8>, // Key value
  int, // Key len
  ffi.Pointer<Utf8>, // Value value
  int, // Value len
) _set = _sledNative
    .lookup<
        ffi.NativeFunction<
            ffi.Void Function(
      ffi.Pointer, // Db
      ffi.Pointer<Utf8>, // Key value
      ffi.Uint64, // Key len
      ffi.Pointer<Utf8>, // Value value
      ffi.Uint64, // Value len
    )>>("sled_set")
    .asFunction();

final ffi.Pointer<Utf8> Function(
  ffi.Pointer,
  ffi.Pointer<Utf8>,
  int,
  ffi.Pointer<ffi.Uint64>,
) _get = _sledNative
    .lookup<
        ffi.NativeFunction<
            ffi.Pointer<Utf8> Function(
      ffi.Pointer,
      ffi.Pointer<Utf8>,
      ffi.Uint64,
      ffi.Pointer<ffi.Uint64>,
    )>>("sled_get")
    .asFunction();

final void Function(ffi.Pointer<Utf8>) _freeBuffer = _sledNative
    .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>(
        "sled_free_buf")
    .asFunction();

class Db {
  ffi.Pointer _dbPointer;

  Db(Config config) {
    this._dbPointer = _openDb(config._consume());
  }

  void setKey(String key, String value) {
    _set(
      this._dbPointer,
      Utf8.toUtf8(key),
      key.length,
      Utf8.toUtf8(value),
      value.length,
    );
  }

  String getKey(String key) {
    var valueSize = allocate<ffi.Uint64>();
    // Double alloc, but avoids leak while finalizers are not ready
    // https://github.com/dart-lang/sdk/issues/35770
    var valueFfi = _get(
      this._dbPointer,
      Utf8.toUtf8(key),
      key.length,
      valueSize,
    );
    var value = Utf8.fromUtf8(valueFfi);
    _freeBuffer(valueFfi);
    return value;
  }

  void dispose() {
    _closeDb(this._dbPointer);
  }
}
