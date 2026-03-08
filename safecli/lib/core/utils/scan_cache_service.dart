// lib/core/utils/scan_cache_service.dart
//
// SQLite-backed local URL scan cache.
//
// Architecture:
//   - url_cache table  → caches scan results with per-classification TTL.
//   - scans table      → stores full scan history (unchanged, used by app).
//
// Cache TTL policy:
//   safe        → 12 hours
//   suspicious  → 10 hours
//   malicious   → 48 hours

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cache TTL constants (in hours)
// ─────────────────────────────────────────────────────────────────────────────
const int _ttlSafeHours       = 12;
const int _ttlSuspiciousHours = 10;
const int _ttlMaliciousHours  = 48;

// ─────────────────────────────────────────────────────────────────────────────
// Cache eviction policy
// ─────────────────────────────────────────────────────────────────────────────
/// Maximum number of entries allowed in url_cache before eviction kicks in.
const int _maxCacheEntries = 200;

/// Extra entries deleted beyond the limit to reduce cleanup frequency.
/// When count > _maxCacheEntries, we delete (overshoot + _evictExtraCount)
/// oldest entries so the next N inserts won't trigger eviction again.
const int _evictExtraCount = 20;

// ─────────────────────────────────────────────────────────────────────────────
// URL Normalization
// ─────────────────────────────────────────────────────────────────────────────

/// Normalizes [rawUrl] so that equivalent URLs produce the same SHA-256 hash.
///
/// Rules applied:
///   1. Trim leading/trailing whitespace.
///   2. Parse as URI; lowercase the scheme and host.
///   3. Remove trailing slash from the path (unless path is just "/").
///   4. Reconstruct the canonical URL string.
String normalizeUrl(String rawUrl) {
  try {
    final trimmed = rawUrl.trim();
    final uri = Uri.parse(trimmed);

    final scheme = uri.scheme.toLowerCase();
    final host   = uri.host.toLowerCase();

    // Remove trailing slash from path
    var path = uri.path;
    if (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }

    final normalized = Uri(
      scheme:   scheme,
      host:     host,
      port:     uri.hasPort ? uri.port : null,
      path:     path,
      query:    uri.hasQuery ? uri.query : null,
      fragment: uri.hasFragment ? uri.fragment : null,
    ).toString();

    return normalized;
  } catch (_) {
    // Fallback: return trimmed lowercase original if parsing fails
    return rawUrl.trim().toLowerCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHA-256 Hash
// ─────────────────────────────────────────────────────────────────────────────

/// Normalizes [url] then computes its SHA-256 hex digest.
/// This is the primary key used for cache lookups.
String computeUrlHash(String url) {
  final canonical = normalizeUrl(url);
  return sha256.convert(utf8.encode(canonical)).toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Cache Entry Model
// ─────────────────────────────────────────────────────────────────────────────

class UrlCacheEntry {
  final String urlHash;
  final String url;

  /// 'safe' | 'suspicious' | 'malicious'
  final String classification;

  /// JSON-encoded engine analysis data.
  final String engineResults;

  /// Unix timestamp (seconds) when the entry was created.
  final int createdAt;

  /// Unix timestamp (seconds) when the entry expires.
  final int expiresAt;

  const UrlCacheEntry({
    required this.urlHash,
    required this.url,
    required this.classification,
    required this.engineResults,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= expiresAt;
  }

  Map<String, dynamic> toMap() => {
        'url_hash':        urlHash,
        'url':             url,
        'classification':  classification,
        'engine_results':  engineResults,
        'created_at':      createdAt,
        'expires_at':      expiresAt,
      };

  factory UrlCacheEntry.fromMap(Map<String, dynamic> m) => UrlCacheEntry(
        urlHash:        m['url_hash']       as String,
        url:            m['url']            as String,
        classification: m['classification'] as String,
        engineResults:  m['engine_results'] as String,
        createdAt:      m['created_at']     as int,
        expiresAt:      m['expires_at']     as int,
      );

  /// Returns the TTL in hours for a given [classification].
  static int ttlHoursFor(String classification) {
    switch (classification.toLowerCase()) {
      case 'malicious':
        return _ttlMaliciousHours;
      case 'suspicious':
        return _ttlSuspiciousHours;
      case 'safe':
      default:
        return _ttlSafeHours;
    }
  }

  /// Convenience factory to build a new cache entry from scan data.
  factory UrlCacheEntry.create({
    required String url,
    required String classification,
    required Map<String, dynamic> engineResults,
  }) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ttlSeconds = UrlCacheEntry.ttlHoursFor(classification) * 3600;
    return UrlCacheEntry(
      urlHash:        computeUrlHash(url),
      url:            normalizeUrl(url),
      classification: classification.toLowerCase(),
      engineResults:  jsonEncode(engineResults),
      createdAt:      nowSeconds,
      expiresAt:      nowSeconds + ttlSeconds,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy Model (preserved for backward compatibility with scan history)
// ─────────────────────────────────────────────────────────────────────────────

class ScanCacheEntry {
  final String urlHash;
  final String url;
  final String result;
  final String threatLevel;
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
        'url_hash':     urlHash,
        'url':          url,
        'result':       result,
        'threat_level': threatLevel,
        'risk_score':   riskScore,
        'scanned_at':   scannedAt.toIso8601String(),
      };

  factory ScanCacheEntry.fromMap(Map<String, dynamic> m) => ScanCacheEntry(
        urlHash:     m['url_hash']     as String,
        url:         m['url']          as String,
        result:      m['result']       as String,
        threatLevel: m['threat_level'] as String,
        riskScore:   m['risk_score']   as int,
        scannedAt:   DateTime.parse(m['scanned_at'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ScanCacheService
// ─────────────────────────────────────────────────────────────────────────────

class ScanCacheService {
  static const _dbName    = 'safeclick_cache.db';
  static const _dbVersion = 3; // v3: adds url_cache table

  static const _urlCacheTable = 'url_cache';
  static const _scansTable    = 'scans';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  // ── Database Initialization ──

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createScansTable(db);
        await _createUrlCacheTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createScansTable(db);
        }
        if (oldVersion < 3) {
          await _createUrlCacheTable(db);
        }
      },
      onOpen: (db) async {
        // Auto-purge expired cache entries on every DB open (app start).
        await _purgeExpiredCache(db);
      },
    );
  }

  Future<void> _createScansTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_scansTable (
        id         TEXT PRIMARY KEY,
        data       TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createUrlCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_urlCacheTable (
        url_hash        TEXT PRIMARY KEY,
        url             TEXT NOT NULL,
        classification  TEXT NOT NULL,
        engine_results  TEXT NOT NULL,
        created_at      INTEGER NOT NULL,
        expires_at      INTEGER NOT NULL
      )
    ''');

    // Performance indexes
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_url_hash       ON $_urlCacheTable(url_hash)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expires_at     ON $_urlCacheTable(expires_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_classification ON $_urlCacheTable(classification)',
    );
  }

  // ── url_cache: Public API ──

  /// Returns a valid [UrlCacheEntry] for [url] if one exists and has not expired.
  ///
  /// Flow:
  ///   1. Normalize URL → compute SHA-256 hash.
  ///   2. Query url_cache by url_hash.
  ///   3a. No row → return null (caller should fetch from server).
  ///   3b. Row found but expired → delete it, return null.
  ///   3c. Row found and valid → return entry.
  Future<UrlCacheEntry?> getCachedResult(String url) async {
    final urlHash = computeUrlHash(url);
    try {
      final db   = await _database;
      final rows = await db.query(
        _urlCacheTable,
        where:     'url_hash = ?',
        whereArgs: [urlHash],
        limit:     1,
      );

      if (rows.isEmpty) {
        debugPrint('🔍 [Cache] MISS – no entry for $url');
        return null;
      }

      final entry = UrlCacheEntry.fromMap(rows.first);

      if (entry.isExpired) {
        debugPrint('⏰ [Cache] EXPIRED – deleting entry for $url');
        await _deleteUrlCacheEntry(urlHash, db);
        return null;
      }

      debugPrint('✅ [Cache] HIT – returning cached result for $url');
      return entry;
    } catch (e) {
      debugPrint('⚠️ [Cache] Read error: $e');
      return null;
    }
  }

  /// Stores or replaces a [UrlCacheEntry] in url_cache.
  ///
  /// Use [UrlCacheEntry.create] to build the entry from raw scan data.
  /// After a successful write, enforces [_maxCacheEntries] by evicting the
  /// oldest entries (by expires_at ASC) if the table is over the limit.
  Future<void> setCachedResult(UrlCacheEntry entry) async {
    try {
      final db = await _database;
      await db.insert(
        _urlCacheTable,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 [Cache] Stored "${entry.url}" '
          '(${entry.classification}, TTL ${UrlCacheEntry.ttlHoursFor(entry.classification)}h)');
      // Enforce max cache size after every write.
      await _enforceMaxCacheSize(db);
    } catch (e) {
      debugPrint('⚠️ [Cache] Write error: $e');
    }
  }

  /// Removes all entries from url_cache where expires_at <= now (seconds).
  Future<void> purgeExpiredCache() async {
    final db = await _database;
    await _purgeExpiredCache(db);
  }

  /// Clears all url_cache entries regardless of expiry.
  Future<void> clearUrlCache() async {
    try {
      final db = await _database;
      final count = await db.delete(_urlCacheTable);
      debugPrint('🗑️ [Cache] Cleared $count entries from url_cache');
    } catch (e) {
      debugPrint('⚠️ [Cache] Clear error: $e');
    }
  }

  // ── url_cache: Internal helpers ──

  /// Enforces [_maxCacheEntries] limit on the url_cache table.
  ///
  /// If the row count exceeds the limit, deletes the oldest entries by
  /// `expires_at ASC` (entries closest to expiry → effectively the oldest),
  /// plus [_evictExtraCount] extra rows. This overshoot reduces how often
  /// eviction runs, improving write performance for busy apps.
  Future<void> _enforceMaxCacheSize(Database db) async {
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM $_urlCacheTable',
      );
      final count = (result.first['cnt'] as int?) ?? 0;
      if (count <= _maxCacheEntries) return;

      final toDelete = (count - _maxCacheEntries) + _evictExtraCount;
      await db.rawDelete('''
        DELETE FROM $_urlCacheTable
        WHERE url_hash IN (
          SELECT url_hash FROM $_urlCacheTable
          ORDER BY expires_at ASC
          LIMIT ?
        )
      ''', [toDelete]);
      debugPrint(
        '♻️ [Cache] Evicted $toDelete entries '
        '(limit=$_maxCacheEntries, extra=$_evictExtraCount, was=$count)',
      );
    } catch (e) {
      debugPrint('⚠️ [Cache] Eviction error: $e');
    }
  }

  Future<void> _purgeExpiredCache(Database db) async {
    try {
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final deleted = await db.delete(
        _urlCacheTable,
        where:     'expires_at <= ?',
        whereArgs: [nowSeconds],
      );
      if (deleted > 0) {
        debugPrint('🧹 [Cache] Purged $deleted expired entries');
      }
    } catch (e) {
      debugPrint('⚠️ [Cache] Purge error: $e');
    }
  }

  Future<void> _deleteUrlCacheEntry(String urlHash, Database db) async {
    await db.delete(
      _urlCacheTable,
      where:     'url_hash = ?',
      whereArgs: [urlHash],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // scans table: Scan History (unchanged — preserves existing app behavior)
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getScansHistory() async {
    try {
      final db   = await _database;
      final rows = await db.query(_scansTable, where: 'is_deleted = 0');
      return rows
          .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [LocalDB] getScansHistory error: $e');
      return [];
    }
  }

  Future<void> saveScansHistory(List<Map<String, dynamic>> history) async {
    try {
      final db    = await _database;
      final batch = db.batch();
      for (final scanJson in history) {
        final id   = scanJson['id'] as String;
        final data = jsonEncode(scanJson);
        batch.execute('''
          INSERT INTO $_scansTable (id, data, is_deleted)
          VALUES (?, ?, 0)
          ON CONFLICT(id) DO UPDATE SET data=excluded.data
        ''', [id, data]);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('⚠️ [LocalDB] saveScansHistory error: $e');
    }
  }

  Future<void> softDeleteScan(String id) async {
    try {
      final db = await _database;
      await db.update(
        _scansTable,
        {'is_deleted': 1},
        where:     'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('⚠️ [LocalDB] softDeleteScan error: $e');
    }
  }

  Future<void> clearUserHistory() async {
    try {
      final db = await _database;
      await db.update(_scansTable, {'is_deleted': 1});
    } catch (e) {
      debugPrint('⚠️ [LocalDB] clearUserHistory error: $e');
    }
  }

  /// Clears both url_cache and scans history. Useful for user logout / data reset.
  Future<void> clearAll() async {
    await clearUrlCache();
    await clearUserHistory();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Legacy getCache / putCache (kept for backward compatibility)
  // Any new code should use getCachedResult / setCachedResult instead.
  // ─────────────────────────────────────────────────────────────────────────

  /// @deprecated Use [getCachedResult] instead.
  Future<ScanCacheEntry?> getCache(String url) async {
    debugPrint('⚠️ [Cache] getCache() is deprecated. Use getCachedResult().');
    final entry = await getCachedResult(url);
    if (entry == null) return null;
    return ScanCacheEntry(
      urlHash:     entry.urlHash,
      url:         entry.url,
      result:      entry.classification,
      threatLevel: 'unknown',
      riskScore:   0,
      scannedAt:   DateTime.fromMillisecondsSinceEpoch(entry.createdAt * 1000),
    );
  }

  /// @deprecated Use [setCachedResult] instead.
  Future<void> putCache(ScanCacheEntry entry) async {
    debugPrint('⚠️ [Cache] putCache() is deprecated. Use setCachedResult().');
    final newEntry = UrlCacheEntry.create(
      url:            entry.url,
      classification: entry.result,
      engineResults:  {'threat_level': entry.threatLevel, 'risk_score': entry.riskScore},
    );
    await setCachedResult(newEntry);
  }

  /// @deprecated Use [purgeExpiredCache] instead.
  Future<void> purgeExpired() async => purgeExpiredCache();
}
