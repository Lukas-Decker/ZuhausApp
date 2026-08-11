import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../../prospect_client.dart';

/// Kommandozeilenschnittstelle fuer Entwicklung und Debugging.
///
/// Nutzt exakt dieselbe [ProspectRepository]-Schnittstelle wie die Flutter-App.
/// Was hier funktioniert, funktioniert dort genauso.
class CliRunner {
  CliRunner({IOSink? out, IOSink? err})
      : _out = out ?? stdout,
        _err = err ?? stderr;

  final IOSink _out;
  final IOSink _err;

  static const String _usage = '''
prospect_client - Prospekte deutscher Haendler abrufen

Verwendung: prospect_client <kommando> [argumente] [optionen]

Kommandos:
  retailers                    Bekannte Haendler auflisten
  brochures <haendlerId>       Prospekte eines Haendlers
  brochure <prospektId>        Einen Prospekt mit Seiten und Angeboten
  search <suchbegriff>         Angebote durchsuchen
  stores <haendlerId>          Filialen eines Haendlers
  update                       Cache fuer alle Haendler warmlaufen lassen
  debug <quellenId>            Quelle pruefen: Faehigkeiten, Timing, Rohdaten
  cache stats|clear            Cache verwalten
  sources                      Registrierte Adapter auflisten

Optionen:
  --near <lat,lng>             Umkreissuche, z.B. --near 52.52,13.405
  --zip <plz>                  Postleitzahl, fuer Quellen ohne Koordinaten
  --radius <meter>             Radius, Standard 50000
  --limit <n>                  Maximale Trefferzahl
  --include-expired            Auch abgelaufene Prospekte
  --all-regions                Auch filialgebundene und regionale Prospekte
                               ausserhalb des Ortes (ohne --near sonst nur
                               bundesweit gueltige)
  --json                       Maschinenlesbare Ausgabe
  --refresh                    Cache umgehen, aber ETags weiter nutzen
  --no-cache                   Ohne Cache arbeiten
  --cache-dir <pfad>           Cache-Verzeichnis
  --pages                      Bei "brochure" die Seiten mit ausgeben
  --offers                     Bei "brochure" die Angebote mit ausgeben
  --raw                        Bei "debug" die Rohantwort ausgeben
  -h, --help                   Diese Hilfe
''';

  Future<int> run(List<String> arguments) async {
    final parser = _buildParser();
    final ArgResults args;
    try {
      args = parser.parse(arguments);
    } on FormatException catch (e) {
      _err.writeln('Fehler: ${e.message}');
      _err.writeln(_usage);
      return 64;
    }

    if (args['help'] as bool || args.rest.isEmpty) {
      _out.writeln(_usage);
      return args.rest.isEmpty && !(args['help'] as bool) ? 64 : 0;
    }

    final asJson = args['json'] as bool;
    final client = _createClient(args);

    try {
      return await _dispatch(args, client, asJson);
    } on ProspectException catch (e) {
      _writeError(e, asJson);
      return _exitCodeFor(e);
    } on Object catch (e) {
      _err.writeln('Unerwarteter Fehler: $e');
      return 70;
    } finally {
      client.close();
    }
  }

  Future<int> _dispatch(
    ArgResults args,
    ProspectClient client,
    bool asJson,
  ) async {
    final command = args.rest.first;
    final rest = args.rest.skip(1).toList();
    final repo = client.repository;

    return switch (command) {
      'retailers' => _retailers(repo, args, asJson),
      'brochures' => _brochures(repo, args, rest, asJson),
      'brochure' => _brochure(repo, args, rest, asJson),
      'search' => _search(repo, args, rest, asJson),
      'stores' => _stores(repo, args, rest, asJson),
      'update' => _update(repo, args, asJson),
      'debug' => _debug(repo, args, rest, asJson),
      'cache' => _cache(client, rest, asJson),
      'sources' => _sources(client, asJson),
      _ => _unknown(command),
    };
  }

  Future<int> _retailers(
    ProspectRepository repo,
    ArgResults args,
    bool asJson,
  ) async {
    // Die Haendlerliste haengt nicht an der Postleitzahl, deshalb hier kein
    // --zip: Marktguru liefert seine Haendler unabhaengig vom Ort.
    final result = await repo.getRetailers(
      near: _near(args),
      radiusMeters: _radius(args),
    );

    if (asJson) {
      _writeJson(result.toJson((r) => r.map((e) => e.toJson()).toList()));
      return result.isTotalFailure ? 1 : 0;
    }

    _writeHeader('${result.data.length} Haendler');
    for (final retailer in result.data) {
      final sources = retailer.bindings.map((b) => b.sourceId).join(', ');
      _out.writeln('  ${retailer.id.padRight(18)} ${retailer.name.padRight(20)} [$sources]');
    }
    _writeFooter(result);
    return result.isTotalFailure ? 1 : 0;
  }

  Future<int> _brochures(
    ProspectRepository repo,
    ArgResults args,
    List<String> rest,
    bool asJson,
  ) async {
    if (rest.isEmpty) {
      _err.writeln('Fehler: brochures braucht eine Haendler-ID.');
      _err.writeln('Beispiel: prospect_client brochures netto');
      return 64;
    }

    final result = await repo.getBrochures(
      retailerId: rest.first,
      near: _near(args),
      postalCode: args['zip'] as String?,
      radiusMeters: _radius(args),
      includeExpired: args['include-expired'] as bool,
      includeOutOfArea: args['all-regions'] as bool,
      limit: _limit(args, 100),
    );

    if (asJson) {
      _writeJson(result.toJson((b) => b.map((e) => e.toJson()).toList()));
      return result.isTotalFailure ? 1 : 0;
    }

    _writeHeader('${result.data.length} Prospekte fuer "${rest.first}"');
    for (final brochure in result.data) {
      _out.writeln('  ${brochure.id}');
      _out.writeln('    ${brochure.title}'
          '${brochure.subtitle != null ? ' (${brochure.subtitle})' : ''}');
      _out.writeln('    ${_formatValidity(brochure)}'
          '  Seiten: ${brochure.pageCount > 0 ? brochure.pageCount : '?'}'
          '  Inhalt: ${_contentLabel(brochure.contentLevel)}');
      if (brochure.pdfUrl != null) _out.writeln('    PDF: ${brochure.pdfUrl}');
    }
    _writeFooter(result);
    return result.isTotalFailure ? 1 : 0;
  }

  Future<int> _brochure(
    ProspectRepository repo,
    ArgResults args,
    List<String> rest,
    bool asJson,
  ) async {
    if (rest.isEmpty) {
      _err.writeln('Fehler: brochure braucht eine Prospekt-ID (z.B. tjek:3sBnfFlz).');
      return 64;
    }
    final id = BrochureId.tryParse(rest.first);
    if (id == null) {
      _err.writeln('Fehler: "${rest.first}" ist keine gueltige Prospekt-ID. '
          'Format: <quelle>:<id>');
      return 64;
    }

    final brochure = await repo.getBrochure(id);

    if (asJson) {
      _writeJson(brochure.toJson());
      return 0;
    }

    _writeHeader(brochure.title);
    if (brochure.subtitle != null) _out.writeln('  ${brochure.subtitle}');
    _out.writeln('  Haendler:   ${brochure.retailerId}');
    _out.writeln('  Gueltig:    ${_formatValidity(brochure)}');
    _out.writeln('  Seiten:     ${brochure.pages.length}');
    _out.writeln('  Angebote:   ${brochure.offers.length}');
    _out.writeln('  Inhalt:     ${_contentLabel(brochure.contentLevel)}');
    _out.writeln('  Gilt fuer:  ${_coverageLabel(brochure.coverage)}');
    if (brochure.regionCodes.isNotEmpty) {
      _out.writeln('  Regionen:   ${brochure.regionCodes.join(', ')}');
    }
    if (brochure.pdfUrl != null) _out.writeln('  PDF:        ${brochure.pdfUrl}');

    if (brochure.coverage.needsLocation) {
      final stores = await repo.getBrochureStores(brochure);
      if (stores.data.isNotEmpty) {
        _out.writeln('\n  Gilt in ${stores.data.length} Filiale(n):');
        for (final store in stores.data.take(10)) {
          _out.writeln('    ${store.address}');
        }
        if (stores.data.length > 10) {
          _out.writeln('    ... und ${stores.data.length - 10} weitere');
        }
      }
    }

    if (args['pages'] as bool) {
      _out.writeln('\n  Seiten:');
      for (final page in brochure.pages) {
        _out.writeln('    ${page.number.toString().padLeft(3)}. '
            '${page.images.best ?? 'kein Bild'}'
            '${page.hotspots.isNotEmpty ? '  (${page.hotspots.length} Hotspots)' : ''}');
      }
    }

    if (args['offers'] as bool) {
      _out.writeln('\n  Angebote:');
      for (final offer in brochure.offers) {
        final price = offer.price;
        final priceText = price == null
            ? 'ohne Preis'
            : '${price.current.toStringAsFixed(2)} ${price.currency}'
                '${price.hasDiscount ? ' statt ${price.previous!.toStringAsFixed(2)} '
                    '(-${price.discountPercent}%)' : ''}';
        _out.writeln('    ${offer.title}');
        _out.writeln('      $priceText'
            '${offer.pageNumber != null ? '  Seite ${offer.pageNumber}' : ''}');
      }
    }
    return 0;
  }

  Future<int> _search(
    ProspectRepository repo,
    ArgResults args,
    List<String> rest,
    bool asJson,
  ) async {
    if (rest.isEmpty) {
      _err.writeln('Fehler: search braucht einen Suchbegriff.');
      return 64;
    }

    final result = await repo.searchOffers(
      rest.join(' '),
      near: _near(args),
      postalCode: args['zip'] as String?,
      radiusMeters: _radius(args),
      limit: _limit(args, 50),
    );

    if (asJson) {
      _writeJson(result.toJson((o) => o.map((e) => e.toJson()).toList()));
      return result.isTotalFailure ? 1 : 0;
    }

    _writeHeader('${result.data.length} Treffer fuer "${rest.join(' ')}"');
    for (final offer in result.data) {
      final price = offer.price;
      _out.writeln('  ${offer.title}');
      if (price != null) {
        _out.writeln('    ${price.current.toStringAsFixed(2)} ${price.currency}'
            '${price.hasDiscount ? '  statt ${price.previous!.toStringAsFixed(2)}'
                '  (-${price.discountPercent}%)' : ''}');
      }
      if (offer.description != null) _out.writeln('    ${offer.description}');
    }
    _writeFooter(result);
    return result.isTotalFailure ? 1 : 0;
  }

  Future<int> _stores(
    ProspectRepository repo,
    ArgResults args,
    List<String> rest,
    bool asJson,
  ) async {
    if (rest.isEmpty) {
      _err.writeln('Fehler: stores braucht eine Haendler-ID.');
      return 64;
    }

    final result = await repo.getStores(
      rest.first,
      near: _near(args),
      postalCode: args['zip'] as String?,
      radiusMeters: _radius(args),
    );

    if (asJson) {
      _writeJson(result.toJson((s) => s.map((e) => e.toJson()).toList()));
      return result.isTotalFailure ? 1 : 0;
    }

    _writeHeader('${result.data.length} Filialen fuer "${rest.first}"');
    for (final store in result.data) {
      _out.writeln('  ${store.address}'
          '${store.location != null ? '  (${store.location})' : ''}');
    }
    _writeFooter(result);
    return result.isTotalFailure ? 1 : 0;
  }

  Future<int> _update(
    ProspectRepository repo,
    ArgResults args,
    bool asJson,
  ) async {
    final near = _near(args) ?? const GeoPoint(52.52, 13.405);
    final retailers = await repo.getRetailers(near: near);

    var brochureCount = 0;
    final failures = <String>[];

    for (final retailer in retailers.data) {
      final result = await repo.getBrochures(retailerId: retailer.id, near: near);
      brochureCount += result.data.length;
      for (final error in result.errors) {
        failures.add('${retailer.id}: ${error.code}');
      }
    }

    if (asJson) {
      _writeJson({
        'retailers': retailers.data.length,
        'brochures': brochureCount,
        'failures': failures,
      });
      return 0;
    }

    _writeHeader('Cache aktualisiert');
    _out.writeln('  Haendler:  ${retailers.data.length}');
    _out.writeln('  Prospekte: $brochureCount');
    if (failures.isNotEmpty) {
      _out.writeln('  Fehlgeschlagen:');
      for (final failure in failures) {
        _out.writeln('    $failure');
      }
    }
    return 0;
  }

  Future<int> _debug(
    ProspectRepository repo,
    ArgResults args,
    List<String> rest,
    bool asJson,
  ) async {
    if (rest.isEmpty) {
      _err.writeln('Fehler: debug braucht eine Quellen-ID. '
          'Verfuegbar: ${repo.sources.map((s) => s.id).join(', ')}');
      return 64;
    }

    ProspectSource? source;
    for (final candidate in repo.sources) {
      if (candidate.id == rest.first) source = candidate;
    }
    if (source == null) {
      _err.writeln('Fehler: Quelle "${rest.first}" ist nicht registriert. '
          'Verfuegbar: ${repo.sources.map((s) => s.id).join(', ')}');
      return 64;
    }

    final near = _near(args) ?? const GeoPoint(52.52, 13.405);
    final report = <String, Object?>{
      'id': source.id,
      'displayName': source.displayName,
      'capabilities': source.capabilities.toJson(),
    };

    final watch = Stopwatch()..start();
    try {
      final retailers = await source.fetchRetailers(RetailerQuery(near: near));
      report['retailersMs'] = watch.elapsedMilliseconds;
      report['retailerCount'] = retailers.length;
      report['retailers'] = retailers.map((r) => r.id).toList();

      if (retailers.isNotEmpty) {
        watch.reset();
        final binding = retailers.first.bindingFor(source.id);
        final brochures = await source.fetchBrochures(
          BrochureQuery(binding: binding, near: near, limit: 10),
        );
        report['brochuresMs'] = watch.elapsedMilliseconds;
        report['brochureCount'] = brochures.length;
        report['sampleRetailer'] = retailers.first.id;
        if (args['raw'] as bool && brochures.isNotEmpty) {
          report['sampleBrochure'] = brochures.first.toJson();
        }
      }
    } on ProspectException catch (e) {
      report['error'] = e.toJson();
    }

    final parseReport = switch (source) {
      final TjekSource s => s.lastReport,
      final SchwarzSource s => s.lastReport,
      _ => null,
    };
    if (parseReport != null && parseReport.hasIssues) {
      report['parseIssues'] = parseReport.summary;
    }

    if (asJson) {
      _writeJson(report);
      return 0;
    }

    _writeHeader('Quelle ${source.id}');
    report.forEach((key, value) => _out.writeln('  ${key.padRight(16)} $value'));
    return report.containsKey('error') ? 1 : 0;
  }

  Future<int> _cache(
    ProspectClient client,
    List<String> rest,
    bool asJson,
  ) async {
    final action = rest.isEmpty ? 'stats' : rest.first;
    switch (action) {
      case 'stats':
        final stats = await client.cache.stats();
        if (asJson) {
          _writeJson({
            'entries': stats.entryCount,
            'expired': stats.expiredCount,
            'bytes': stats.totalBytes,
          });
        } else {
          _writeHeader('Cache');
          _out.writeln('  Eintraege:  ${stats.entryCount}');
          _out.writeln('  Abgelaufen: ${stats.expiredCount}');
          _out.writeln('  Groesse:    ${(stats.totalBytes / 1024).toStringAsFixed(1)} KiB');
        }
        return 0;
      case 'clear':
        await client.repository.clearCache();
        if (!asJson) _out.writeln('Cache geleert.');
        return 0;
      default:
        _err.writeln('Fehler: unbekannte Cache-Aktion "$action". '
            'Erlaubt: stats, clear');
        return 64;
    }
  }

  int _sources(ProspectClient client, bool asJson) {
    final repo = client.repository;
    final inactive = client.inactiveSources;

    if (asJson) {
      _writeJson({
        'active': repo.sources
            .map((s) => {
                  'id': s.id,
                  'displayName': s.displayName,
                  'capabilities': s.capabilities.toJson(),
                })
            .toList(),
        'inactive': inactive.entries
            .map((e) => {'id': e.key, 'missingEnv': e.value})
            .toList(),
      });
      return 0;
    }

    _writeHeader('${repo.sources.length} aktive Adapter');
    for (final source in repo.sources) {
      final caps = source.capabilities;
      final features = <String>[
        if (caps.supportsGeoSearch) 'koordinaten',
        if (caps.supportsPostalCode) 'plz',
        if (caps.supportsOfferSearch) 'suche',
        if (caps.supportsStores) 'filialen',
        if (caps.providesPrices) 'preise',
        if (caps.providesPdf) 'pdf',
        if (caps.requiresRegion) 'region-noetig',
      ];
      _out.writeln('  ${source.id.padRight(12)} ${source.displayName}');
      _out.writeln('  ${''.padRight(12)} ${features.join(', ')}');
    }

    if (inactive.isNotEmpty) {
      _out.writeln('\nNicht aktiv (Zugangsdaten fehlen)');
      _out.writeln('---------------------------------');
      for (final entry in inactive.entries) {
        _out.writeln('  ${entry.key.padRight(12)} setze ${entry.value.join(' und ')}');
      }
      _out.writeln('\n  Schluessel gehoeren in die Umgebung, nie ins Repository.');
    }
    return 0;
  }

  int _unknown(String command) {
    _err.writeln('Fehler: unbekanntes Kommando "$command".');
    _err.writeln(_usage);
    return 64;
  }

  ProspectClient _createClient(ArgResults args) {
    final noCache = args['no-cache'] as bool;
    final refresh = args['refresh'] as bool;
    return ProspectClient.create(
      cacheDirectory: args['cache-dir'] as String?,
      cacheStore: noCache ? const NullCacheStore() : null,
      policy: refresh ? CachePolicy.alwaysRevalidate : CachePolicy.defaults,
    );
  }

  ArgParser _buildParser() => ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('json', negatable: false)
    ..addFlag('include-expired', negatable: false)
    ..addFlag('all-regions', negatable: false)
    ..addFlag('refresh', negatable: false)
    ..addFlag('no-cache', negatable: false)
    ..addFlag('pages', negatable: false)
    ..addFlag('offers', negatable: false)
    ..addFlag('raw', negatable: false)
    ..addOption('near')
    ..addOption('zip')
    ..addOption('radius')
    ..addOption('limit')
    ..addOption('cache-dir');

  GeoPoint? _near(ArgResults args) {
    final value = args['near'] as String?;
    if (value == null) return null;
    final point = GeoPoint.tryParse(value);
    if (point == null) {
      _err.writeln('Warnung: "--near $value" ist ungueltig, wird ignoriert. '
          'Format: lat,lng');
    }
    return point;
  }

  int _radius(ArgResults args) =>
      int.tryParse(args['radius'] as String? ?? '') ?? 50000;

  int _limit(ArgResults args, int fallback) =>
      int.tryParse(args['limit'] as String? ?? '') ?? fallback;

  String _formatValidity(Brochure brochure) {
    String fmt(DateTime? d) => d == null
        ? '?'
        : '${d.day.toString().padLeft(2, '0')}.'
            '${d.month.toString().padLeft(2, '0')}.${d.year}';
    return '${fmt(brochure.validFrom)} bis ${fmt(brochure.validUntil)}';
  }

  String _coverageLabel(BrochureCoverage coverage) => switch (coverage) {
        BrochureCoverage.unknown => 'unbekannt',
        BrochureCoverage.national => 'bundesweit',
        BrochureCoverage.regional => 'eine Region',
        BrochureCoverage.storeBound => 'bestimmte Filialen',
      };

  String _contentLabel(BrochureContentLevel level) => switch (level) {
        BrochureContentLevel.unknown => 'noch nicht geprueft',
        BrochureContentLevel.imagesOnly => 'nur Bilder',
        BrochureContentLevel.productsWithoutPrices => 'Produkte ohne Preise',
        BrochureContentLevel.productsWithPrices => 'Produkte mit Preisen',
      };

  void _writeHeader(String title) => _out.writeln('\n$title\n${'-' * title.length}');

  void _writeFooter(SourceResult<Object?> result) {
    for (final warning in result.warnings) {
      _out.writeln('  Hinweis: $warning');
    }
    for (final error in result.errors) {
      _out.writeln('  Quelle nicht verfuegbar: $error');
    }
    if (result.isStale) {
      _out.writeln('  Hinweis: Daten stammen aus einem abgelaufenen Cache.');
    }
  }

  void _writeJson(Object? value) =>
      _out.writeln(const JsonEncoder.withIndent('  ').convert(value));

  void _writeError(ProspectException e, bool asJson) {
    if (asJson) {
      _writeJson({'error': e.toJson()});
    } else {
      _err.writeln('Fehler [${e.code}]: ${e.message}');
      if (e.isRetryable) _err.writeln('Ein erneuter Versuch kann helfen.');
    }
  }

  int _exitCodeFor(ProspectException e) => switch (e) {
        NotFound() => 1,
        AccessDenied() => 77,
        ConfigurationError() => 78,
        UnsupportedBySource() => 64,
        _ => 69,
      };
}
