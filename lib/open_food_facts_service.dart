import 'dart:convert';

import 'package:http/http.dart' as http;

class ProductLookupResult {
  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;
  final bool found;

  const ProductLookupResult({
    required this.barcode,
    required this.found,
    this.name,
    this.brand,
    this.imageUrl,
  });

  String get displayName {
    final trimmedName = name?.trim();
    final trimmedBrand = brand?.trim();

    if (trimmedName != null && trimmedName.isNotEmpty) {
      if (trimmedBrand != null &&
          trimmedBrand.isNotEmpty &&
          !trimmedName.toLowerCase().contains(trimmedBrand.toLowerCase())) {
        return '$trimmedName ($trimmedBrand)';
      }
      return trimmedName;
    }

    if (trimmedBrand != null && trimmedBrand.isNotEmpty) {
      return trimmedBrand;
    }

    return barcode;
  }
}

class OpenFoodFactsService {
  static const _userAgent = 'DLCApp/1.0 (Flutter; https://github.com/local/dlc_app)';

  /// Extracts a product barcode from raw scanner data (EAN, QR URL, GS1).
  static String? extractBarcode(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (_looksLikeBarcode(digitsOnly) && digitsOnly == value) {
      return digitsOnly;
    }

    final uri = Uri.tryParse(value);
    if (uri != null) {
      final fromPath = _barcodeFromPathSegments(uri.pathSegments);
      if (fromPath != null) return fromPath;

      for (final entry in uri.queryParameters.entries) {
        if (_looksLikeBarcode(entry.value)) return entry.value;
      }
    }

    // GS1 element string, e.g. (01)03490140000011 or 0103490140000011
    final gs1Match = RegExp(r'(?:\(01\)|01)(\d{8,14})').firstMatch(value);
    if (gs1Match != null) return gs1Match.group(1);

    if (_looksLikeBarcode(digitsOnly)) return digitsOnly;

    return null;
  }

  static bool _looksLikeBarcode(String value) {
    return RegExp(r'^\d{8}$|^\d{12,14}$').hasMatch(value);
  }

  static String? _barcodeFromPathSegments(List<String> segments) {
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i].toLowerCase();
      if ((segment == 'product' || segment == '01') && i + 1 < segments.length) {
        final candidate = segments[i + 1].split(RegExp(r'[^0-9]')).first;
        if (_looksLikeBarcode(candidate)) return candidate;
      }
      if (_looksLikeBarcode(segments[i])) return segments[i];
    }
    return null;
  }

  Future<ProductLookupResult> fetchProduct(String barcode) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode'
      '?fields=product_name,product_name_fr,brands,image_front_small_url',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return ProductLookupResult(barcode: barcode, found: false);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'];
    final product = data['product'] as Map<String, dynamic>?;

    if (status != 1 || product == null) {
      return ProductLookupResult(barcode: barcode, found: false);
    }

    final nameFr = product['product_name_fr'] as String?;
    final name = product['product_name'] as String?;

    return ProductLookupResult(
      barcode: barcode,
      found: true,
      name: (nameFr != null && nameFr.trim().isNotEmpty) ? nameFr : name,
      brand: product['brands'] as String?,
      imageUrl: product['image_front_small_url'] as String?,
    );
  }
}
