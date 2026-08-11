import 'package:meta/meta.dart';

/// Ein Bild in bis zu drei Aufloesungsstufen.
///
/// Alle bisher angebundenen Quellen liefern genau dieses Muster: Tjek als
/// `thumb`/`view`/`zoom`, Schwarz als `thumbnail`/`image`/`zoom`. Einzelne
/// Stufen koennen fehlen, deshalb ist jede optional.
@immutable
class ImageSet {
  const ImageSet({this.thumbnail, this.normal, this.large});

  final Uri? thumbnail;
  final Uri? normal;
  final Uri? large;

  static const ImageSet empty = ImageSet();

  bool get isEmpty => thumbnail == null && normal == null && large == null;

  /// Beste verfuegbare Aufloesung, absteigend.
  Uri? get best => large ?? normal ?? thumbnail;

  /// Kleinste verfuegbare Aufloesung, aufsteigend. Fuer Listen und Vorschauen.
  Uri? get smallest => thumbnail ?? normal ?? large;

  Map<String, Object?> toJson() => {
        if (thumbnail != null) 'thumbnail': thumbnail.toString(),
        if (normal != null) 'normal': normal.toString(),
        if (large != null) 'large': large.toString(),
      };

  static ImageSet fromJson(Map<String, Object?> json) => ImageSet(
        thumbnail: _uri(json['thumbnail']),
        normal: _uri(json['normal']),
        large: _uri(json['large']),
      );

  static Uri? _uri(Object? value) =>
      value is String && value.isNotEmpty ? Uri.tryParse(value) : null;

  @override
  bool operator ==(Object other) =>
      other is ImageSet &&
      other.thumbnail == thumbnail &&
      other.normal == normal &&
      other.large == large;

  @override
  int get hashCode => Object.hash(thumbnail, normal, large);

  @override
  String toString() => 'ImageSet(${best ?? 'leer'})';
}
