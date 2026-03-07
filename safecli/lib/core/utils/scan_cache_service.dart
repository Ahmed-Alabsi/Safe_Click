// lib/core/utils/scan_cache_service.dart
//
// SQLite-backed local URL scan cache.
// Provides O(1) lookup by URL SHA-256 hash with a 24-hour TTL.
// Replaces the previous SharedPreferences-based scan history.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ScanCacheEntry {
  final String urlHash;
  final String url;
  final String result;       // 'safe' | 'malicious' | 'suspicious'
  final String threatLevel;  // 'none' | 'low' | 'medium' | 'high'
  final int riskScore;
  final DateTime scannedAt;

  const ScanCacheEntry({
    required this.urlHash,
    required this.url,
    required this.result,
    required this.threatLevel,
    required this.riskScore,
    required this.scannedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(scannedAt).inHours >= 24;

  Map<String, dynamic> toMap() => {
        'url_hash': urlHash,
        'url': url,
        'result': result,
        'threat_level': threatLevel,
        'risk_score': riskScore,
        'scanned_at': scannedAt.toIso8601String(),
      };

  factory ScanCacheEntry.fromMap(Map<String, dynamic> m) => ScanCacheEntry(
        urlHash: m['url_hash'] as String,
        url: m['url'] as String,
        result: m['result'] as String,
        threatLevel: m['threat_level'] as String,
        riskScore: m['risk_score'] as int,
        scannedAt: DateTime.parse(m['scanned_at'] as String),
      );
}

/// Computes SHA-256 of [url] and returns the hex digest.
/// Must match the backend: hashlib.sha256(url.encode()).hexdigest()
String computeUrlHash(String url) {
  final bytes = utf8.encode(url);
  return sha256.convert(bytes).toString();
}

class ScanCacheService {
  static const _dbName = 'safeclick_cache.db';
  static const _tableName = 'scan_cache';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            url_hash   TEXT PRIMARY KEY,
            url        TEXT NOT NULL,
            result     TEXT NOT NULL,
            threat_level TEXT NOT NULL,
            risk_score INTEGER NOT NULL DEFAULT 0,
            scanned_at TEXT NOT NULL
          )
        ''');
        // Explicit index on url_hash (already PK, extra index for clarity)
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_url_hash ON $_tableName(url_hash)');
      },
    );
  }

  /// Returns a cached [ScanCacheEntry] if it exists and is not expired.
  Future<ScanCacheEntry?> getCache(String url) async {
    final urlHash = computeUrlHash(url);
    try {
      final db = await _database;
      final rows = await db.query(
        _tableName,
        where: 'url_hash = ?',
        whereArgs: [urlHash],
        limit: 1,
      );
      if (rows.isEmpty) return null;

      final entry = ScanCacheEntry.fromMap(rows.first);
      if (entry.isExpired) {
        await _deleteEntry(urlHash);
        return null;
      }
      debugPrint('🟢 [LocalCache] Hit for $url');
      return entry;
    } catch (e) {
      debugPrint('⚠️ [LocalCache] Read error: $e');
      return null;
    }
  }

  /// Persists or updates a cache entry.
  Future<void> putCache(ScanCacheEntry entry) async {
    try {
      final db = await _database;
      await db.insert(
        _tableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('🟡 [LocalCache] Stored ${entry.url}');
    } catch (e) {
      debugPrint('⚠️ [LocalCache] Write error: $e');
    }
  }

  /// Removes all expired entries. Call periodically for housekeeping.
  Future<void> purgeExpired() async {
    try {
      final db = await _database;
      final cutoff = DateTime.now()
          .subtract(const Duration(hours: 24))
          .toIso8601String();
      await db.delete(
        _tableName,
        where: 'scanned_at < ?',
        whereArgs: [cutoff],
      );
    } catch (e) {
      debugPrint('⚠️ [LocalCache] Purge error: $e');
    }
  }

  /// Clears the entire local cache.
  Future<void> clearAll() async {
    try {
      final db = await _database;
      await db.delete(_tableName);
    } catch (e) {
      debugPrint('⚠️ [LocalCache] Clear error: $e');
    }
  }

  Future<void> _deleteEntry(String urlHash) async {
    final db = await _database;
    await db.delete(_tableName, where: 'url_hash = ?', whereArgs: [urlHash]);
  }
}
