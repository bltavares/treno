import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary _sledNative = Platform.isAndroid
    ? ffi.DynamicLibrary.open("libsled.so")
    : ffi.DynamicLibrary.process();

final _createConfig =
    _sledNative.lookupFunction<ffi.Pointer Function(), ffi.Pointer Function()>(
        "sled_create_config");

final _freeConfig = _sledNative.lookupFunction<ffi.Void Function(ffi.Pointer),
    void Function(ffi.Pointer)>("sled_free_config");

final _configSetPath = _sledNative.lookupFunction<
    ffi.Pointer Function(ffi.Pointer, ffi.Pointer<Utf8>),
    ffi.Pointer Function(
        ffi.Pointer, ffi.Pointer<Utf8>)>("sled_config_set_path");

final _configSetReadOnly = _sledNative.lookupFunction<
    ffi.Pointer Function(ffi.Pointer, ffi.Uint8),
    ffi.Pointer Function(ffi.Pointer, int)>("sled_config_read_only");

final _configSetCacheCapacity = _sledNative.lookupFunction<
    ffi.Pointer Function(ffi.Pointer, ffi.Uint32),
    ffi.Pointer Function(ffi.Pointer, int)>("sled_config_set_cache_capacity");

final _configUseCompression = _sledNative.lookupFunction<
    ffi.Pointer Function(ffi.Pointer, ffi.Uint8),
    ffi.Pointer Function(ffi.Pointer, int)>("sled_config_use_compression");

final _configFlushEveryMs = _sledNative.lookupFunction<
    ffi.Pointer Function(ffi.Pointer, ffi.Uint64),
    ffi.Pointer Function(ffi.Pointer, int)>("sled_config_flush_every_ms");

class Config {
  ffi.Pointer _configPointer = _createConfig();

  Config(
    String path, {
    bool readOnly = false,
    int cacheCapacity = 1024 * 1024 * 1024, // 1gb,
    int flushEveryMs = 500,

    /// The compression feature must be enabled on the lib
    bool useCompression = false,
  }) {
    this._configPointer =
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

final _openDb = _sledNative.lookupFunction<ffi.Pointer Function(ffi.Pointer),
    ffi.Pointer Function(ffi.Pointer)>("sled_open_db");

final _closeDb = _sledNative.lookupFunction<ffi.Void Function(ffi.Pointer),
    void Function(ffi.Pointer)>("sled_close");

final _set = _sledNative.lookupFunction<
    ffi.Void Function(
  ffi.Pointer, // Db
  ffi.Pointer<Utf8>, // Key value
  ffi.Uint64, // Key len
  ffi.Pointer<Utf8>, // Value value
  ffi.Uint64, // Value len
),
    void Function(
  ffi.Pointer, // Db
  ffi.Pointer<Utf8>, // Key value
  int, // Key len
  ffi.Pointer<Utf8>, // Value value
  int, // Value len
)>("sled_set");

final _get = _sledNative.lookupFunction<
    ffi.Pointer<Utf8> Function(
  ffi.Pointer,
  ffi.Pointer<Utf8>,
  ffi.Uint64,
  ffi.Pointer<ffi.Uint64>,
),
    ffi.Pointer<Utf8> Function(
  ffi.Pointer,
  ffi.Pointer<Utf8>,
  int,
  ffi.Pointer<ffi.Uint64>,
)>("sled_get");

final _freeBuffer = _sledNative.lookupFunction<
    ffi.Void Function(ffi.Pointer<Utf8>),
    void Function(ffi.Pointer<Utf8>)>("sled_free_buf");

final startLogger =
    _sledNative.lookupFunction<ffi.Void Function(), void Function()>(
        "camarim_setup_logger");

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
