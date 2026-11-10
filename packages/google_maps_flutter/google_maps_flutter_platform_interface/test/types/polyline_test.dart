// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Polyline', () {
    const kId = PolylineId('polyline');
    const kGradient = <Color>[Color(0xFF1B2A4A), Color(0xFFF5A524)];
    final kTexture = BytesMapBitmap(
      Uint8List.fromList(<int>[0, 1, 2, 3]),
      bitmapScaling: MapBitmapScaling.none,
    );

    test('defaults to no gradient and no texture', () {
      const polyline = Polyline(polylineId: kId);

      expect(polyline.gradient, isNull);
      expect(polyline.texture, isNull);
    });

    test('toJson omits gradient and texture when unset', () {
      final json = const Polyline(polylineId: kId).toJson() as Map<String, Object>;

      expect(json.containsKey('gradient'), isFalse);
      expect(json.containsKey('texture'), isFalse);
    });

    test('toJson serializes gradient and texture', () {
      final polyline = Polyline(polylineId: kId, gradient: kGradient, texture: kTexture);

      final json = polyline.toJson() as Map<String, Object>;

      expect(json['gradient'], <int>[0xFF1B2A4A, 0xFFF5A524]);
      expect(json['texture'], kTexture.toJson());
    });

    test('copyWith sets gradient and texture', () {
      const polyline = Polyline(polylineId: kId);

      final Polyline copy = polyline.copyWith(gradientParam: kGradient, textureParam: kTexture);

      expect(copy.gradient, kGradient);
      expect(copy.texture, kTexture);
    });

    test('copyWith keeps gradient and texture by default', () {
      final polyline = Polyline(polylineId: kId, gradient: kGradient, texture: kTexture);

      final Polyline copy = polyline.copyWith(widthParam: 4);

      expect(copy.gradient, kGradient);
      expect(copy.texture, kTexture);
      expect(copy.width, 4);
    });

    test('clone copies the gradient list', () {
      final gradient = List<Color>.of(kGradient);
      final polyline = Polyline(polylineId: kId, gradient: gradient, texture: kTexture);

      final Polyline clone = polyline.clone();

      expect(clone, polyline);
      expect(identical(clone.gradient, gradient), isFalse);
      expect(clone.texture, kTexture);
    });

    test('equality compares gradient values', () {
      const a = Polyline(polylineId: kId, gradient: kGradient);
      final b = Polyline(polylineId: kId, gradient: List<Color>.of(kGradient));
      const reversed = Polyline(
        polylineId: kId,
        gradient: <Color>[Color(0xFFF5A524), Color(0xFF1B2A4A)],
      );
      const none = Polyline(polylineId: kId);

      expect(a, b);
      expect(a, isNot(reversed));
      expect(a, isNot(none));
    });

    test('equality compares texture', () {
      final a = Polyline(polylineId: kId, texture: kTexture);
      final b = Polyline(polylineId: kId, texture: kTexture);
      final other = Polyline(
        polylineId: kId,
        texture: BytesMapBitmap(
          Uint8List.fromList(<int>[4, 5, 6, 7]),
          bitmapScaling: MapBitmapScaling.none,
        ),
      );
      const none = Polyline(polylineId: kId);

      expect(a, b);
      expect(a, isNot(other));
      expect(a, isNot(none));
    });
  });
}
