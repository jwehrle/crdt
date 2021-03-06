import 'dart:async';
import 'dart:math';

import 'package:crdt/src/hlc.dart';

import 'crdt.dart';

abstract class Store<K, V> {
  Hlc get latestLogicalTime;

  Map<K, Record<V>> getMap([int logicalTime = 0]);

  Record<V> get(K key);

  Future<void> put(K key, Record<V> value);

  Future<void> putAll(Map<K, Record<V>> values);

  Future<void> clear();

  Stream<void> watch();
}

class MapStore<K, V> implements Store<K, V> {
  final Map<K, Record<V>> _map;
  final _controller = StreamController<void>();

  @override
  Hlc get latestLogicalTime => Hlc(_map.isEmpty
      ? 0
      : _map.values.map((record) => record.hlc.logicalTime).reduce(max));

  MapStore([Map<K, Record<V>> map]) : _map = map ?? <K, Record<V>>{};

  @override
  Map<K, Record<V>> getMap([int logicalTime = 0]) =>
      Map<K, Record<V>>.from(_map)
        ..removeWhere((_, record) => record.hlc.logicalTime <= logicalTime);

  @override
  Record<V> get(K key) => _map[key];

  @override
  Future<void> put(K key, Record<V> value) async {
    _map[key] = value;
    _controller.add(null);
  }

  @override
  Future<void> putAll(Map<K, Record<V>> values) async {
    _map.addAll(values);
    _controller.add(null);
  }

  @override
  Future<void> clear() async => _map.clear();

  @override
  Stream<void> watch() => _controller.stream;
}
