import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:kaufda_api/kaufda_api.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'kaufda',
    'Client fuer die kaufDA Content-Viewer-API.',
  )
    ..argParser.addOption(
      'lat',
      help: 'Breitengrad des Standorts.',
      defaultsTo: '49.6378338',
    )
    ..argParser.addOption(
      'lng',
      help: 'Laengengrad des Standorts.',
      defaultsTo: '7.1113922',
    )
    ..argParser.addOption('zip', help: 'Postleitzahl (nur fuer Tracking).')
    ..argParser.addOption('city', help: 'Ort (nur fuer Tracking).')
    ..argParser
        .addOption('partner', help: 'Partnerkennung.', defaultsTo: 'kaufda_web')
    ..argParser.addOption('brochure-key',
        help: 'Key fuer nicht oeffentliche Prospekte.', defaultsTo: '')
    ..argParser.addOption('token',
        help: 'Fertiger sessionToken (JWT) statt anonymem Bootstrap.')
    ..argParser.addFlag('compact',
        help: 'JSON einzeilig statt eingerueckt ausgeben.', negatable: false)
    ..addCommand(BrochureCommand())
    ..addCommand(PagesCommand())
    ..addCommand(OffersCommand())
    ..addCommand(CollectionCommand.related())
    ..addCommand(CollectionCommand.sidebar())
    ..addCommand(CollectionCommand.lastPage())
    ..addCommand(StoreCommand())
    ..addCommand(ShelfCommand())
    ..addCommand(RetailerCommand())
    ..addCommand(SearchCommand())
    ..addCommand(NearbyCommand())
    ..addCommand(DumpCommand())
    ..addCommand(DownloadCommand());

  try {
    exitCode = await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  } on KaufdaException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

/// Gemeinsame Basis: baut aus den globalen Optionen einen [KaufdaClient].
abstract class KaufdaCommand extends Command<int> {
  KaufdaClient? _client;

  KaufdaClient get client => _client ??= _buildClient();

  KaufdaClient _buildClient() {
    final global = globalResults!;
    final token = global.option('token');
    return KaufdaClient(
      location: location,
      partner: global.option('partner') ?? 'kaufda_web',
      brochureKey: global.option('brochure-key') ?? '',
      sessionProvider:
          token == null ? null : StaticSessionProvider.fromToken(token),
    );
  }

  GeoLocation get location {
    final global = globalResults!;
    final lat = double.tryParse(global.option('lat') ?? '');
    final lng = double.tryParse(global.option('lng') ?? '');
    if (lat == null || lng == null) {
      usageException('--lat und --lng muessen Zahlen sein.');
    }
    return GeoLocation(
      lat: lat,
      lng: lng,
      zip: global.option('zip'),
      city: global.option('city'),
    );
  }

  bool get compact => globalResults!.flag('compact');

  String get brochureId {
    final rest = argResults!.rest;
    if (rest.isEmpty) usageException('Es fehlt die Prospekt-ID.');
    return rest.first;
  }

  void printJson(Object? value) {
    stdout.writeln(
      compact
          ? jsonEncode(value)
          : const JsonEncoder.withIndent('  ').convert(value),
    );
  }

  @override
  FutureOr<int> run() async {
    try {
      return await execute();
    } finally {
      _client?.close();
    }
  }

  Future<int> execute();
}

/// `kaufda brochure <id>`
class BrochureCommand extends KaufdaCommand {
  @override
  String get name => 'brochure';

  @override
  String get description => 'Metadaten eines Prospekts abrufen.';

  @override
  String get invocation => 'kaufda brochure <brochureId>';

  @override
  Future<int> execute() async {
    final brochure = await client.brochure(brochureId);
    printJson(brochure.toJson());
    return 0;
  }
}

/// `kaufda pages <id>`
class PagesCommand extends KaufdaCommand {
  PagesCommand() {
    argParser.addFlag(
      'summary',
      help: 'Nur eine Uebersicht statt der vollen Seitendaten.',
      negatable: false,
    );
  }

  @override
  String get name => 'pages';

  @override
  String get description => 'Alle Seiten inklusive Angebote abrufen.';

  @override
  String get invocation => 'kaufda pages <brochureId>';

  @override
  Future<int> execute() async {
    final pages = await client.pages(brochureId);
    if (argResults!.flag('summary')) {
      for (final page in pages) {
        final image = page.largestImage?.url ?? '-';
        stdout.writeln(
          'Seite ${page.number + 1}: ${page.offers.length} Angebote, '
          '${page.linkOuts.length} Links, $image',
        );
      }
      return 0;
    }
    printJson([for (final page in pages) page.toJson()]);
    return 0;
  }
}

/// `kaufda offers <id>`
class OffersCommand extends KaufdaCommand {
  OffersCommand() {
    argParser
      ..addOption('csv', help: 'Angebote als CSV in diese Datei schreiben.')
      ..addFlag('json', help: 'Angebote als JSON ausgeben.', negatable: false);
  }

  @override
  String get name => 'offers';

  @override
  String get description => 'Alle Angebote eines Prospekts auflisten.';

  @override
  String get invocation => 'kaufda offers <brochureId> [--csv datei.csv]';

  @override
  Future<int> execute() async {
    final pages = await client.pages(brochureId);
    final rows = <(BrochurePage, Offer)>[
      for (final page in pages)
        for (final offer in page.offerContents) (page, offer),
    ];

    final csvPath = argResults!.option('csv');
    if (csvPath != null) {
      final file = File(csvPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(_toCsv(rows), encoding: utf8);
      stdout.writeln('${rows.length} Angebote nach ${file.path} geschrieben.');
      return 0;
    }

    if (argResults!.flag('json')) {
      printJson([for (final (_, offer) in rows) offer.toJson()]);
      return 0;
    }

    for (final (page, offer) in rows) {
      final deal = offer.bestDeal;
      final price = deal?.min == null
          ? ''
          : '${deal!.min!.toStringAsFixed(2)} ${deal.currencyCode ?? ''}'
              .trim();
      final conditions = deal?.conditions
              .map((e) => e.label)
              .where((e) => e.isNotEmpty)
              .join(', ') ??
          '';
      stdout.writeln(
        'S.${(page.number + 1).toString().padLeft(2)}  '
        '${price.padLeft(10)}  ${offer.displayName}'
        '${conditions.isEmpty ? '' : '  ($conditions)'}',
      );
    }
    stdout.writeln('\n${rows.length} Angebote.');
    return 0;
  }

  static String _toCsv(List<(BrochurePage, Offer)> rows) {
    const header = [
      'seite',
      'angebot_id',
      'marke',
      'produkt',
      'beschreibung',
      'kategorie',
      'preis_min',
      'preis_max',
      'waehrung',
      'preistyp',
      'bedingungen',
      'grundpreis',
      'gueltig_von',
      'gueltig_bis',
      'bild',
      'link',
    ];
    final buffer = StringBuffer()..writeln(header.map(_escape).join(';'));
    for (final (page, offer) in rows) {
      final product = offer.product;
      final deal = offer.bestDeal;
      buffer.writeln([
        '${page.number + 1}',
        offer.id,
        product?.brandName ?? '',
        product?.name ?? '',
        product?.description.replaceAll('\n', ' ') ?? '',
        product?.categoryPaths.map((e) => e.name).join(' > ') ?? '',
        deal?.min?.toStringAsFixed(2) ?? '',
        deal?.max?.toStringAsFixed(2) ?? '',
        deal?.currencyCode ?? '',
        deal?.type ?? '',
        deal?.conditions
                .map((e) => e.label)
                .where((e) => e.isNotEmpty)
                .join(', ') ??
            '',
        deal?.priceByBaseUnit ?? '',
        offer.validFrom?.toIso8601String() ?? '',
        offer.validUntil?.toIso8601String() ?? '',
        offer.image ?? '',
        offer.linkOuts.isEmpty ? '' : offer.linkOuts.first.url ?? '',
      ].map(_escape).join(';'));
    }
    return buffer.toString();
  }

  static String _escape(String value) {
    final needsQuotes =
        value.contains(';') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}

/// `kaufda related|sidebar|lastpage <id>`
class CollectionCommand extends KaufdaCommand {
  CollectionCommand._(this.name, this.description, this._fetch);

  factory CollectionCommand.related() => CollectionCommand._(
        'related',
        'Empfehlungen zum Prospekt (naechster Prospekt).',
        (client, id) => client.related(id),
      );

  factory CollectionCommand.sidebar() => CollectionCommand._(
        'sidebar',
        'Prospektleiste neben dem Viewer.',
        (client, id) => client.sidebar(id),
      );

  factory CollectionCommand.lastPage() => CollectionCommand._(
        'lastpage',
        'Kacheln fuer die letzte Prospektseite.',
        (client, id) => client.lastPage(id),
      );

  @override
  final String name;

  @override
  final String description;

  final Future<BrochureCollections> Function(KaufdaClient, String) _fetch;

  @override
  String get invocation => 'kaufda $name <brochureId>';

  @override
  Future<int> execute() async {
    printJson((await _fetch(client, brochureId)).toJson());
    return 0;
  }
}

/// `kaufda store <id>`
class StoreCommand extends KaufdaCommand {
  @override
  String get name => 'store';

  @override
  String get description => 'Naechstgelegene Filiale zum Prospekt.';

  @override
  String get invocation => 'kaufda store <brochureId>';

  @override
  Future<int> execute() async {
    final store = await client.nearestStore(brochureId);
    if (store == null) {
      stderr.writeln('Keine Filiale gefunden.');
      return 1;
    }
    printJson(store.toJson());
    return 0;
  }
}

/// `kaufda retailer <name>`
class RetailerCommand extends KaufdaCommand {
  RetailerCommand() {
    argParser
      ..addOption('limit', help: 'Treffer pro Abfrage.', defaultsTo: '100')
      ..addFlag('valid', help: 'Nur gueltige Prospekte.', negatable: false)
      ..addFlag('offers', help: 'Auch Angebote auflisten.', negatable: false)
      ..addFlag('json', help: 'Ergebnis als JSON ausgeben.', negatable: false);
  }

  @override
  String get name => 'retailer';

  @override
  String get description => 'Prospekte eines Haendlers ueber den Namen suchen.';

  @override
  String get invocation => 'kaufda retailer <haendlername>';

  @override
  Future<int> execute() async {
    final query = argResults!.rest.join(' ').trim();
    if (query.isEmpty) usageException('Es fehlt der Haendlername.');

    final found = await client.searchRetailer(
      query,
      limit: int.tryParse(argResults!.option('limit') ?? '100') ?? 100,
      onlyValid: argResults!.flag('valid'),
      includeOffers: argResults!.flag('offers'),
    );

    if (argResults!.flag('json')) {
      printJson({
        'query': found.query,
        'publisherId': found.publisherId,
        'publisherName': found.publisherName,
        'brochures': [for (final b in found.brochures) b.toJson()],
        'offers': [for (final o in found.offers) o.toJson()],
      });
      return 0;
    }

    if (!found.isRetailer) {
      stderr.writeln(
        'Kein Haendler zu "$query" erkannt '
        '(Suchtyp: ${found.result.metadata.searchType ?? 'unbekannt'}). '
        'Zeige alle Treffer.',
      );
    } else {
      // Die Zahlen aus den Metadaten zaehlen alle Haendler im Suchergebnis,
      // nicht nur den erkannten.
      stdout.writeln('${found.publisherName} (${found.publisherId})\n'
          'Suchtreffer gesamt: ${found.result.metadata.brochureCount} '
          'Prospekte, ${found.result.metadata.offerCount} Angebote '
          '(alle Haendler)\n');
    }

    for (final item in found.brochures) {
      final until = item.validUntil?.toLocal();
      final bis = until == null
          ? ''
          : 'bis ${until.day.toString().padLeft(2, '0')}.'
              '${until.month.toString().padLeft(2, '0')}.';
      final entfernung = item.distance == null
          ? ''
          : '${item.distance!.toStringAsFixed(1)} km';
      stdout.writeln(
        '${item.publisher.name.padRight(24)} ${bis.padRight(11)} '
        '${entfernung.padLeft(8)}  ${item.title}\n${' ' * 36}${item.id}',
      );
    }

    if (found.offers.isNotEmpty) {
      stdout.writeln('\nAngebote:');
      for (final offer in found.offers) {
        final preis = offer.price?.mainPriceFormatted ?? '';
        stdout.writeln('  ${preis.padLeft(10)}  ${offer.displayName}');
      }
    }

    stdout.writeln('\n${found.brochures.length} Prospekte'
        '${found.offers.isEmpty ? '' : ', ${found.offers.length} Angebote'}.');
    return 0;
  }
}

/// `kaufda search <begriff>`
class SearchCommand extends KaufdaCommand {
  SearchCommand() {
    argParser
      ..addOption('limit', help: 'Treffer pro Abfrage.', defaultsTo: '24')
      ..addOption('offset', help: 'Treffer ueberspringen.', defaultsTo: '0')
      ..addOption(
        'sort',
        help: 'Sortierung.',
        allowed: [
          SearchSort.relevance,
          SearchSort.price,
          SearchSort.validityEnd
        ],
      )
      ..addFlag('json', help: 'Ergebnis als JSON ausgeben.', negatable: false);
  }

  @override
  String get name => 'search';

  @override
  String get description =>
      'Volltextsuche nach Haendlern und Produkten im Umkreis.';

  @override
  String get invocation => 'kaufda search <begriff> [--sort price]';

  @override
  Future<int> execute() async {
    final query = argResults!.rest.join(' ').trim();
    if (query.isEmpty) usageException('Es fehlt der Suchbegriff.');

    final result = await client.search(
      query,
      limit: int.tryParse(argResults!.option('limit') ?? '24') ?? 24,
      offset: int.tryParse(argResults!.option('offset') ?? '0') ?? 0,
      sort: argResults!.option('sort'),
    );

    if (argResults!.flag('json')) {
      printJson(result.toJson());
      return 0;
    }

    final meta = result.metadata;
    stdout.writeln('Suchtyp: ${meta.searchType ?? 'unbekannt'}, '
        '${meta.brochureCount} Prospekte, ${meta.offerCount} Angebote');
    if (meta.recognizedEntities.isNotEmpty) {
      stdout.writeln('Erkannt: '
          '${meta.recognizedEntities.take(4).map((e) => '$e').join(', ')}');
    }

    if (result.brochures.isNotEmpty) {
      stdout.writeln('\nProspekte:');
      for (final item in result.brochureContents) {
        stdout.writeln('  ${item.publisher.name.padRight(24)} ${item.title}\n'
            '${' ' * 28}${item.id}');
      }
    }

    if (result.offers.isNotEmpty) {
      stdout.writeln('\nAngebote:');
      for (final offer in result.offers) {
        final preis = offer.price?.mainPriceFormatted ?? '';
        stdout.writeln('  ${preis.padLeft(10)}  '
            '${(offer.publisherName ?? '').padRight(22)} ${offer.displayName}');
      }
    }
    return 0;
  }
}

/// `kaufda shelf`
class ShelfCommand extends KaufdaCommand {
  ShelfCommand() {
    argParser
      ..addMultiOption(
        'sector',
        help: 'Branchenfilter, z. B. DE-48. Mehrfach angebbar, '
            '--sector list zeigt alle.',
      )
      ..addOption('size', help: 'Treffer pro Seite.', defaultsTo: '24')
      ..addOption('page', help: 'Seite, ab 0.', defaultsTo: '0')
      ..addFlag('all', help: 'Alle Seiten durchblaettern.', negatable: false)
      ..addFlag('valid', help: 'Nur gueltige Prospekte.', negatable: false)
      ..addFlag('json', help: 'Ergebnis als JSON ausgeben.', negatable: false);
  }

  @override
  String get name => 'shelf';

  @override
  String get description => 'Prospekte im Umkreis eines Standorts suchen.';

  @override
  String get invocation => 'kaufda [--lat .. --lng ..] shelf [--all]';

  @override
  Future<int> execute() async {
    final sectors = argResults!.multiOption('sector');
    if (sectors.contains('list')) {
      KaufdaSector.names.forEach((id, label) {
        stdout.writeln('${id.padRight(16)} $label');
      });
      return 0;
    }

    final onlyValid = argResults!.flag('valid');
    final List<ShelfBrochure> brochures;
    PageInfo? pageInfo;

    if (argResults!.flag('all')) {
      brochures = await client.shelfAll(
        sectorIds: sectors,
        onlyValid: onlyValid,
        pageSize: int.tryParse(argResults!.option('size') ?? '100') ?? 100,
      );
    } else {
      final result = await client.shelf(
        sectorIds: sectors,
        page: int.tryParse(argResults!.option('page') ?? '0') ?? 0,
        size: int.tryParse(argResults!.option('size') ?? '24') ?? 24,
      );
      pageInfo = result.page;
      brochures = [
        for (final brochure in result.brochures)
          if (!onlyValid || brochure.isValidNow) brochure,
      ];
    }

    if (argResults!.flag('json')) {
      printJson([for (final item in brochures) item.toJson()]);
      return 0;
    }

    for (final item in brochures) {
      final until = item.validUntil?.toLocal();
      final bis = until == null
          ? ''
          : 'bis ${until.day.toString().padLeft(2, '0')}.'
              '${until.month.toString().padLeft(2, '0')}.';
      final filiale = item.closestStore?.address ?? '';
      stdout.writeln(
        '${item.publisher.name.padRight(24)} ${bis.padRight(11)} '
        '${item.title}\n${' ' * 36}${item.id}'
        '${filiale.isEmpty ? '' : '\n${' ' * 36}$filiale'}',
      );
    }
    stdout.writeln(
      '\n${brochures.length} Prospekte'
      '${pageInfo == null ? '' : ' (Seite ${pageInfo.number + 1} von '
          '${pageInfo.totalPages}, ${pageInfo.totalElements} gesamt)'}.',
    );
    return 0;
  }
}

/// `kaufda nearby <id>`
class NearbyCommand extends KaufdaCommand {
  NearbyCommand() {
    argParser
      ..addOption(
        'depth',
        help: 'Wie oft weitergehangelt wird. 2 findet deutlich mehr, '
            'braucht aber mehr Requests.',
        defaultsTo: '1',
      )
      ..addOption('max', help: 'Obergrenze fuer Treffer.', defaultsTo: '250')
      ..addOption('publisher',
          help: 'Nur Prospekte dieses Haendlers, z. B. DE-1013.')
      ..addFlag('valid',
          help: 'Nur aktuell gueltige Prospekte.', negatable: false)
      ..addFlag('json', help: 'Ergebnis als JSON ausgeben.', negatable: false);
  }

  @override
  String get name => 'nearby';

  @override
  String get description =>
      'Prospekte im Umkreis suchen, ausgehend von einer bekannten Prospekt-ID.';

  @override
  String get invocation => 'kaufda nearby <startBrochureId> [--depth 2]';

  @override
  Future<int> execute() async {
    final results = await client.nearbyBrochures(
      seedBrochureIds: argResults!.rest.isEmpty ? const [] : argResults!.rest,
      depth: int.tryParse(argResults!.option('depth') ?? '1') ?? 1,
      maxBrochures: int.tryParse(argResults!.option('max') ?? '250') ?? 250,
      publisherId: argResults!.option('publisher'),
      onlyValid: argResults!.flag('valid'),
    );

    if (argResults!.flag('json')) {
      printJson([for (final item in results) item.toJson()]);
      return 0;
    }

    for (final item in results) {
      final until = item.validUntil;
      final bis = until == null
          ? ''
          : 'bis ${until.toLocal().day.toString().padLeft(2, '0')}.'
              '${until.toLocal().month.toString().padLeft(2, '0')}.';
      stdout.writeln(
        '${item.publisher.name.padRight(24)} ${bis.padRight(11)} '
        '${item.title}\n${' ' * 36}${item.id}',
      );
    }
    stdout.writeln('\n${results.length} Prospekte in der Naehe.');
    return 0;
  }
}

/// `kaufda dump <id>`
class DumpCommand extends KaufdaCommand {
  DumpCommand() {
    argParser.addOption(
      'out',
      abbr: 'o',
      help: 'Zielverzeichnis.',
      defaultsTo: 'dump',
    );
  }

  @override
  String get name => 'dump';

  @override
  String get description =>
      'Alle Endpunkte zu einem Prospekt als JSON-Dateien speichern.';

  @override
  String get invocation => 'kaufda dump <brochureId> [-o verzeichnis]';

  @override
  Future<int> execute() async {
    final id = brochureId;
    final bundle = await client.bundle(id);
    final dir = Directory('${argResults!.option('out') ?? 'dump'}/$id');
    await dir.create(recursive: true);

    final files = <String, Object?>{
      'brochure.json': bundle.brochure.toJson(),
      'pages.json': [for (final page in bundle.pages) page.toJson()],
      'nearestStore.json': bundle.nearestStore?.toJson(),
      'related.json': bundle.related.toJson(),
      'sidebar.json': bundle.sidebar.toJson(),
      'lastPage.json': bundle.lastPage.toJson(),
      'offers.json': [for (final offer in bundle.offers) offer.toJson()],
    };
    const encoder = JsonEncoder.withIndent('  ');
    for (final entry in files.entries) {
      if (entry.value == null) continue;
      await File('${dir.path}/${entry.key}')
          .writeAsString(encoder.convert(entry.value), encoding: utf8);
    }
    stdout.writeln(
      'Dump nach ${dir.path}: ${bundle.pages.length} Seiten, '
      '${bundle.offers.length} Angebote.',
    );
    return 0;
  }
}

/// `kaufda download <id>`
class DownloadCommand extends KaufdaCommand {
  DownloadCommand() {
    argParser
      ..addOption('out', abbr: 'o', help: 'Zielverzeichnis.', defaultsTo: 'out')
      ..addOption(
        'size',
        help: 'Gewuenschte Bildgroesse, z. B. 768x1024. Standard ist die '
            'groesste verfuegbare.',
      )
      ..addOption(
        'pages',
        help: 'Seitenauswahl, einsbasiert, z. B. 1-5 oder 1,3,7-9.',
      )
      ..addOption(
        'concurrency',
        help: 'Parallele Downloads.',
        defaultsTo: '4',
      );
  }

  @override
  String get name => 'download';

  @override
  String get description => 'Seitenbilder eines Prospekts herunterladen.';

  @override
  String get invocation =>
      'kaufda download <brochureId> [-o verzeichnis] [--size 1600x1600]';

  @override
  Future<int> execute() async {
    final id = brochureId;
    final size = argResults!.option('size');
    final selection = _parsePageSelection(argResults!.option('pages'));
    final concurrency =
        int.tryParse(argResults!.option('concurrency') ?? '4') ?? 4;

    final pages = await client.pages(id);
    final targets = <(int, String)>[];
    for (final page in pages) {
      final humanNumber = page.number + 1;
      if (selection != null && !selection.contains(humanNumber)) continue;
      final image = size == null ? page.largestImage : page.imageBySize(size);
      if (image == null) {
        stderr.writeln('Seite $humanNumber: keine Bildgroesse "$size".');
        continue;
      }
      targets.add((humanNumber, image.url));
    }
    if (targets.isEmpty) {
      stderr.writeln('Nichts zum Herunterladen.');
      return 1;
    }

    final dir = Directory('${argResults!.option('out') ?? 'out'}/$id');
    await dir.create(recursive: true);

    final httpClient = http.Client();
    var done = 0;
    var failed = 0;
    try {
      final queue = List.of(targets);
      Future<void> worker() async {
        while (queue.isNotEmpty) {
          final (number, url) = queue.removeAt(0);
          final target = File(
            '${dir.path}/seite_${number.toString().padLeft(3, '0')}'
            '${_extension(url)}',
          );
          try {
            final response = await httpClient.get(Uri.parse(url));
            if (response.statusCode != 200) {
              failed++;
              stderr.writeln('Seite $number: HTTP ${response.statusCode}');
              continue;
            }
            await target.writeAsBytes(response.bodyBytes);
            done++;
            stdout.writeln('Seite $number -> ${target.path}');
          } on Object catch (error) {
            failed++;
            stderr.writeln('Seite $number: $error');
          }
        }
      }

      await Future.wait([
        for (var i = 0; i < concurrency.clamp(1, 16); i++) worker(),
      ]);
    } finally {
      httpClient.close();
    }
    stdout.writeln('$done Bilder geladen, $failed fehlgeschlagen.');
    return failed == 0 ? 0 : 1;
  }

  static String _extension(String url) {
    final path = Uri.parse(url).path;
    final dot = path.lastIndexOf('.');
    if (dot == -1 || path.length - dot > 6) return '.jpg';
    return path.substring(dot);
  }

  static Set<int>? _parsePageSelection(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final result = <int>{};
    for (final part in value.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final range = trimmed.split('-');
      if (range.length == 2) {
        final from = int.tryParse(range[0]);
        final to = int.tryParse(range[1]);
        if (from == null || to == null) continue;
        for (var i = from; i <= to; i++) {
          result.add(i);
        }
      } else {
        final single = int.tryParse(trimmed);
        if (single != null) result.add(single);
      }
    }
    return result.isEmpty ? null : result;
  }
}
