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
      version: 1,
      onCreate: _createDB,
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
  }

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

    // Delete match
    await db.delete(
      'matches',
      where: 'id = ?',
      whereArgs: [matchId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}