// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import GoogleMaps
import Testing

@testable import google_maps_flutter_ios_sdk9

@MainActor struct PolylineControllerTests {

  @Test func patternsSetSpans() {
    let mapView = PolylineControllerTests.mapView()

    let polyline = PlatformPolyline(
      polylineId: "polyline_id_0",
      consumesTapEvents: false,
      color: PlatformColor(red: 0, green: 0, blue: 0, alpha: 0),
      geodesic: false,
      jointType: .round,
      patterns: [
        PlatformPatternItem(type: .dot, length: 10),
        PlatformPatternItem(type: .dash, length: 10),
      ],
      points: PolylineControllerTests.polylinePoints(),
      visible: true,
      width: 1,
      zIndex: 0
    )

    let polylineController = PolylineController(
      identifier: polyline.polylineId,
      mapView: mapView
    )

    #expect(polylineController.polyline.spans == nil)

    polylineController.update(
      from: polyline, assetProvider: TestAssetProvider(), screenScale: 1.0)

    // `GMSStyleSpan` doesn't implement `isEqual` so cannot be compared by value at present.
    #expect(polylineController.polyline.spans != nil)
  }

  @Test func gradientSetsSingleSpanInsteadOfPatterns() {
    let mapView = PolylineControllerTests.mapView()
    let polylineController = PolylineControllerTests.updatedController(
      on: mapView,
      from: PolylineControllerTests.polyline(
        patterns: PolylineControllerTests.dotDashPatterns(),
        gradient: PolylineControllerTests.gradient()
      )
    )

    let spans = polylineController.polyline.spans ?? []
    #expect(spans.count == 1)
    #expect(spans.first?.style.stampStyle == nil)
  }

  @Test func textureSetsTextureStampStyle() {
    let mapView = PolylineControllerTests.mapView()
    let polylineController = PolylineControllerTests.updatedController(
      on: mapView,
      from: PolylineControllerTests.polyline(texture: PlatformBitmapDefaultMarker(hue: 0))
    )

    let spans = polylineController.polyline.spans ?? []
    #expect(spans.count == 1)
    #expect(spans.first?.style.stampStyle is GMSTextureStyle)
  }

  @Test func gradientAndTextureShareOneSpan() {
    let mapView = PolylineControllerTests.mapView()
    let polylineController = PolylineControllerTests.updatedController(
      on: mapView,
      from: PolylineControllerTests.polyline(
        gradient: PolylineControllerTests.gradient(),
        texture: PlatformBitmapDefaultMarker(hue: 0)
      )
    )

    let spans = polylineController.polyline.spans ?? []
    #expect(spans.count == 1)
    #expect(spans.first?.style.stampStyle is GMSTextureStyle)
  }

  @Test func removingGradientRestoresPatterns() {
    let mapView = PolylineControllerTests.mapView()
    let patterns = PolylineControllerTests.dotDashPatterns()
    let polylineController = PolylineControllerTests.updatedController(
      on: mapView,
      from: PolylineControllerTests.polyline(
        patterns: patterns,
        gradient: PolylineControllerTests.gradient()
      )
    )
    #expect(polylineController.polyline.spans?.count == 1)

    polylineController.update(
      from: PolylineControllerTests.polyline(patterns: patterns),
      assetProvider: TestAssetProvider(),
      screenScale: 1.0
    )

    // A dot-dash pattern along this path takes many spans.
    #expect((polylineController.polyline.spans?.count ?? 0) > 1)
  }

  @Test func removingGradientAndTextureClearsSpans() {
    let mapView = PolylineControllerTests.mapView()
    let polylineController = PolylineControllerTests.updatedController(
      on: mapView,
      from: PolylineControllerTests.polyline(
        gradient: PolylineControllerTests.gradient(),
        texture: PlatformBitmapDefaultMarker(hue: 0)
      )
    )
    #expect(polylineController.polyline.spans?.count == 1)

    polylineController.update(
      from: PolylineControllerTests.polyline(),
      assetProvider: TestAssetProvider(),
      screenScale: 1.0
    )

    #expect((polylineController.polyline.spans ?? []).isEmpty)
  }

  @Test func updatePolylineSetsVisibilityLast() {
    let polyline = PropertyOrderValidatingPolyline()
    PolylineController.update(
      polyline,
      from: PlatformPolyline(
        polylineId: "polyline",
        consumesTapEvents: false,
        color: PlatformColor(red: 0, green: 0, blue: 0, alpha: 0),
        geodesic: false,
        jointType: .round,
        patterns: [],
        points: PolylineControllerTests.polylinePoints(),
        visible: true,
        width: 1,
        zIndex: 0,
        gradient: PolylineControllerTests.gradient(),
        texture: PlatformBitmapDefaultMarker(hue: 0)
      ),
      with: PolylineControllerTests.mapView(),
      assetProvider: TestAssetProvider(),
      screenScale: 1.0
    )
    #expect(polyline.hasSetMap)
  }

  /// Returns a polyline with arbitrary points and the given styling.
  static func polyline(
    patterns: [PlatformPatternItem] = [],
    gradient: PlatformPolylineGradient? = nil,
    texture: PlatformBitmap? = nil
  ) -> PlatformPolyline {
    return PlatformPolyline(
      polylineId: "polyline_id_0",
      consumesTapEvents: false,
      color: PlatformColor(red: 0, green: 0, blue: 0, alpha: 1),
      geodesic: false,
      jointType: .round,
      patterns: patterns,
      points: PolylineControllerTests.polylinePoints(),
      visible: true,
      width: 4,
      zIndex: 0,
      gradient: gradient,
      texture: texture
    )
  }

  /// Returns a controller on the given map view, updated from the given polyline.
  ///
  /// The controller holds the map view weakly, so callers must keep it alive.
  static func updatedController(
    on mapView: GMSMapView,
    from polyline: PlatformPolyline
  ) -> PolylineController {
    let controller = PolylineController(identifier: polyline.polylineId, mapView: mapView)
    controller.update(from: polyline, assetProvider: TestAssetProvider(), screenScale: 1.0)
    return controller
  }

  /// Returns an arbitrary two-color gradient.
  static func gradient() -> PlatformPolylineGradient {
    return PlatformPolylineGradient(
      startColor: PlatformColor(red: 0.1, green: 0.16, blue: 0.29, alpha: 1),
      endColor: PlatformColor(red: 0.96, green: 0.65, blue: 0.14, alpha: 1)
    )
  }

  /// Returns a dot-dash pattern.
  static func dotDashPatterns() -> [PlatformPatternItem] {
    return [
      PlatformPatternItem(type: .dot, length: 10),
      PlatformPatternItem(type: .dash, length: 10),
    ]
  }

  /// Returns a simple map view to add map objects to.
  static func mapView() -> GMSMapView {
    let mapViewOptions = GMSMapViewOptions()
    mapViewOptions.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    mapViewOptions.camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 0)
    return PartiallyMockedMapView(options: mapViewOptions)
  }

  /// Returns a set of points to use for tests that need a valid but arbitrary line.
  static func polylinePoints() -> [PlatformLatLng] {
    return [
      PlatformLatLng(latitude: 52.4816, longitude: -3.1791),
      PlatformLatLng(latitude: 54.043, longitude: -2.9925),
      PlatformLatLng(latitude: 54.1396, longitude: -4.2739),
      PlatformLatLng(latitude: 53.4153, longitude: -4.0829),
    ]
  }
}

/// A GMSPolyline that ensures that property updates are made before the map is set.
class PropertyOrderValidatingPolyline: GMSPolyline {
  var hasSetMap = false

  override var path: GMSPath? {
    get { super.path }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.path = newValue
    }
  }

  override var strokeWidth: CGFloat {
    get { super.strokeWidth }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.strokeWidth = newValue
    }
  }

  override var strokeColor: UIColor {
    get { super.strokeColor }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.strokeColor = newValue
    }
  }

  override var geodesic: Bool {
    get { super.geodesic }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.geodesic = newValue
    }
  }

  override var title: String? {
    get { super.title }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.title = newValue
    }
  }

  override var isTappable: Bool {
    get { super.isTappable }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.isTappable = newValue
    }
  }

  override var zIndex: Int32 {
    get { super.zIndex }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.zIndex = newValue
    }
  }

  override var userData: Any? {
    get { super.userData }
    set {
      #expect(!hasSetMap, "Property set after map was set.")
      super.userData = newValue
    }
  }

  override var map: GMSMapView? {
    get { super.map }
    set {
      // Don't actually set the map, since that requires more test setup.
      if newValue != nil {
        hasSetMap = true
      }
    }
  }
}
