// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import GoogleMaps

/// Defines polyline controllable by Flutter.
class PolylineController {
  let polyline: GMSPolyline
  private weak var mapView: GMSMapView?

  init(identifier: String, mapView: GMSMapView) {
    self.polyline = GMSPolyline()
    self.mapView = mapView
    self.polyline.userData = [identifier]
  }

  func removePolyline() {
    polyline.map = nil
  }

  /// Updates the controller's polyline with the properties from a PlatformPolyline.
  ///
  /// Setting the polyline to visible will set its map to the controller's mapView.
  func update(
    from platformPolyline: PlatformPolyline,
    assetProvider: AssetProvider,
    screenScale: CGFloat
  ) {
    if let mapView = mapView {
      PolylineController.update(
        polyline,
        from: platformPolyline,
        with: mapView,
        assetProvider: assetProvider,
        screenScale: screenScale
      )
    }
  }

  /// Updates the given GMSPolyline with the properties from a PlatformPolyline.
  ///
  /// Setting the polyline to visible will set its map to the given mapView.
  static func update(
    _ polyline: GMSPolyline,
    from platformPolyline: PlatformPolyline,
    with mapView: GMSMapView,
    assetProvider: AssetProvider,
    screenScale: CGFloat
  ) {
    polyline.isTappable = platformPolyline.consumesTapEvents
    polyline.zIndex = Int32(platformPolyline.zIndex)
    let gmsPath = makePath(from: platformPolyline.points.map { $0.toCLLocationCoordinate2D() })
    polyline.path = gmsPath
    let strokeColor = platformPolyline.color.toUIColor()
    polyline.strokeColor = strokeColor
    polyline.strokeWidth = CGFloat(platformPolyline.width)
    polyline.geodesic = platformPolyline.geodesic
    polyline.spans = styleSpans(
      for: platformPolyline,
      path: gmsPath,
      strokeColor: strokeColor,
      assetProvider: assetProvider,
      screenScale: screenScale
    )

    // This must be done last, to avoid visual flickers of default property values.
    polyline.map = platformPolyline.visible ? mapView : nil
  }

  /// Returns the style spans for a PlatformPolyline's gradient, texture, or patterns.
  ///
  /// A gradient or texture is drawn as a single span covering the whole line. Patterns are also
  /// drawn as spans, so they are not applied while a gradient or texture is set.
  static func styleSpans(
    for platformPolyline: PlatformPolyline,
    path: GMSPath,
    strokeColor: UIColor,
    assetProvider: AssetProvider,
    screenScale: CGFloat
  ) -> [GMSStyleSpan] {
    let gradient = platformPolyline.gradient
    let texture = platformPolyline.texture?.createIcon(
      assetProvider: assetProvider,
      screenScale: screenScale
    )
    guard gradient != nil || texture != nil else {
      return GMSStyleSpans(
        path,
        platformPolyline.patterns.map { $0.gmsStrokeStyle(strokeColor: strokeColor) },
        platformPolyline.patterns.map { $0.gmsStyleSpanLength() },
        .rhumb
      )
    }
    let style: GMSStrokeStyle
    if let gradient = gradient {
      style = GMSStrokeStyle.gradient(
        from: gradient.startColor.toUIColor(),
        to: gradient.endColor.toUIColor()
      )
    } else {
      style = GMSStrokeStyle.solidColor(strokeColor)
    }
    if let texture = texture {
      style.stampStyle = GMSTextureStyle(image: texture)
    }
    return [GMSStyleSpan(style: style)]
  }
}

class PolylinesController {
  private var polylineIdentifierToController: [String: PolylineController] = [:]
  private weak var eventDelegate: MapEventDelegate?
  private let assetProvider: AssetProvider
  private weak var mapView: GMSMapView?

  init(mapView: GMSMapView, eventDelegate: MapEventDelegate, assetProvider: AssetProvider) {
    self.mapView = mapView
    self.eventDelegate = eventDelegate
    self.assetProvider = assetProvider
  }

  func add(_ polylines: [PlatformPolyline]) {
    guard let mapView = mapView else { return }
    let screenScale = getScreenScale()
    for polyline in polylines {
      let identifier = polyline.polylineId
      let controller = PolylineController(identifier: identifier, mapView: mapView)
      // TODO(stuarmorgan): Consider updating the flow here to do the update from within
      // the initialiazer, as in CircleController.
      controller.update(from: polyline, assetProvider: assetProvider, screenScale: screenScale)
      polylineIdentifierToController[identifier] = controller
    }
  }

  func change(_ polylines: [PlatformPolyline]) {
    let screenScale = getScreenScale()
    for polyline in polylines {
      let identifier = polyline.polylineId
      polylineIdentifierToController[identifier]?.update(
        from: polyline,
        assetProvider: assetProvider,
        screenScale: screenScale
      )
    }
  }

  func removePolyline(withIdentifiers identifiers: [String]) {
    for identifier in identifiers {
      if let controller = polylineIdentifierToController[identifier] {
        controller.removePolyline()
        polylineIdentifierToController.removeValue(forKey: identifier)
      }
    }
  }

  func didTapPolyline(withIdentifier identifier: String) {
    if hasPolyline(withIdentifier: identifier) {
      Task {
        try await eventDelegate?.didTapPolyline(withIdentifier: identifier)
      }
    }
  }

  func hasPolyline(withIdentifier identifier: String) -> Bool {
    return polylineIdentifierToController[identifier] != nil
  }

  func getScreenScale() -> CGFloat {
    // As for markers and ground overlays, initial polylines are created before the view is in the
    // view hierarchy, so this may not match the display the map is finally shown on. See
    // https://github.com/flutter/flutter/issues/125496.
    return mapView?.traitCollection.displayScale ?? 1.0
  }
}
