// database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scary_strokes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // Added for database migration
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE matches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        total_holes INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE player_scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER,
        player_name TEXT,
        player_icon_index INTEGER,
        total_strokes INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE hole_scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_score_id INTEGER,
        hole_number INTEGER,
        strokes INTEGER
      )
    ''');

    // New winners table
    await db.execute('''
      CREATE TABLE winners(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        match_id INTEGER,
        player_name TEXT,
        player_icon_index INTEGER,
        total_strokes INTEGER,
        date TEXT,
        FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster queries on winners table
    await db.execute('''
      CREATE INDEX idx_winners_date ON winners(date DESC)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Upgrade from version 1 to 2 - add winners table
      await db.execute('''
        CREATE TABLE winners(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          match_id INTEGER,
          player_name TEXT,
          player_icon_index INTEGER,
          total_strokes INTEGER,
          date TEXT,
          FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_winners_date ON winners(date DESC)
      ''');
    }
  }

  // Existing methods remain the same...

  Future<int> createMatch(int totalHoles) async {
    final db = await database;
    return await db.insert('matches', {
      'date': DateTime.now().toIso8601String(),
      'total_holes': totalHoles,
    });
  }

  Future<int> createPlayerScore({
    required int matchId,
    required String playerName,
    required int playerIconIndex,
    required int totalStrokes,
  }) async {
    final db = await database;
    return await db.insert('player_scores', {
      'match_id': matchId,
      'player_name': playerName,
      'player_icon_index': playerIconIndex,
      'total_strokes': totalStrokes,
    });
  }

  Future<int> createHoleScore({
    required int playerScoreId,
    required int holeNumber,
    required int strokes,
  }) async {
    final db = await database;
    return await db.insert('hole_scores', {
      'player_score_id': playerScoreId,
      'hole_number': holeNumber,
      'strokes': strokes,
    });
  }

  // NEW: Add winner to winners table
  Future<int> addWinner({
    required int matchId,
    required String playerName,
    required int playerIconIndex,
    required int totalStrokes,
  }) async {
    final db = await database;

    // Get match date to store with the winner
    final match = await db.query(
      'matches',
      where: 'id = ?',
      whereArgs: [matchId],
      columns: ['date'],
    );

    final matchDate = match.isNotEmpty ? match.first['date'] : DateTime.now().toIso8601String();

    return await db.insert('winners', {
      'match_id': matchId,
      'player_name': playerName,
      'player_icon_index': playerIconIndex,
      'total_strokes': totalStrokes,
      'date': matchDate,
    });
  }

  // NEW: Add multiple winners (for ties)
  Future<void> addWinners(List<Map<String, dynamic>> winners) async {
    final db = await database;
    final batch = db.batch();

    for (final winner in winners) {
      batch.insert('winners', winner);
    }

    await batch.commit();
  }

  // NEW: Get all winners sorted by date (most recent first)
  Future<List<Map<String, dynamic>>> getAllWinners() async {
    final db = await database;
    return await db.query(
      'winners',
      orderBy: 'date DESC',
    );
  }

  // NEW: Get winners for a specific match
  Future<List<Map<String, dynamic>>> getWinnersForMatch(int matchId) async {
    final db = await database;
    return await db.query(
      'winners',
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'total_strokes ASC',
    );
  }

  // NEW: Get top N winners with lowest scores (for leaderboard)
  Future<List<Map<String, dynamic>>> getTopWinners({int limit = 10}) async {
    final db = await database;
    return await db.query(
      'winners',
      orderBy: 'total_strokes ASC, date DESC',
      limit: limit,
    );
  }

  // NEW: Get a player's winning statistics
  Future<Map<String, dynamic>> getPlayerWinningStats(String playerName) async {
    final db = await database;

    // Get total wins
    final winsResult = await db.rawQuery('''
      SELECT COUNT(*) as total_wins, MIN(total_strokes) as best_score
      FROM winners 
      WHERE player_name = ?
    ''', [playerName]);

    // Get average strokes
    final avgResult = await db.rawQuery('''
      SELECT AVG(total_strokes) as average_strokes
      FROM winners 
      WHERE player_name = ?
    ''', [playerName]);

    // Get recent wins
    final recentWins = await db.query(
      'winners',
      where: 'player_name = ?',
      whereArgs: [playerName],
      orderBy: 'date DESC',
      limit: 5,
    );

    return {
      'total_wins': winsResult.isNotEmpty ? winsResult.first['total_wins'] ?? 0 : 0,
      'best_score': winsResult.isNotEmpty ? winsResult.first['best_score'] ?? 0 : 0,
      'average_strokes': avgResult.isNotEmpty ? avgResult.first['average_strokes'] ?? 0.0 : 0.0,
      'recent_wins': recentWins,
    };
  }

  // NEW: Delete winner by match ID (useful when deleting a match)
  Future<void> deleteWinnersForMatch(int matchId) async {
    final db = await database;
    await db.delete(
      'winners',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
  }

  // NEW: Delete all winners (for reset functionality)
  Future<void> deleteAllWinners() async {
    final db = await database;
    await db.delete('winners');
  }

  // Updated deleteMatch to also delete winners
  Future<void> deleteMatch(int matchId) async {
    final db = await database;

    // Get all player scores for this match
    final playerScores = await getPlayerScoresForMatch(matchId);

    // Delete hole scores for each player
    for (var playerScore in playerScores) {
      await db.delete(
        'hole_scores',
        where: 'player_score_id = ?',
        whereArgs: [playerScore['id']],
      );
    }

    // Delete player scores
    await db.delete(
      'player_scores',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );

    // Delete winners for this match
    await deleteWinnersForMatch(matchId);

    // Delete match
    await db.delete(
      'matches',
      where: 'id = ?',
      whereArgs: [matchId],
    );
  }

  // Existing retrieval methods remain the same...

  Future<List<Map<String, dynamic>>> getAllMatches() async {
    final db = await database;
    return await db.query('matches', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getPlayerScoresForMatch(int matchId) async {
    final db = await database;
    return await db.query(
      'player_scores',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
  }

  Future<List<Map<String, dynamic>>> getHoleScoresForPlayer(int playerScoreId) async {
    final db = await database;
    return await db.query(
      'hole_scores',
      where: 'player_score_id = ?',
      whereArgs: [playerScoreId],
      orderBy: 'hole_number ASC',
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}