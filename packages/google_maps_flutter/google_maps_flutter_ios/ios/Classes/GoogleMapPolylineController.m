// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoogleMapPolylineController.h"

#import "FGMImageUtils.h"
#import "FLTGoogleMapJSONConversions.h"

@interface FLTGoogleMapPolylineController ()

@property(strong, nonatomic) GMSPolyline *polyline;
@property(weak, nonatomic) GMSMapView *mapView;
@property(strong, nonatomic) UIImage *textureImage;
@property(strong, nonatomic) NSArray<UIColor *> *gradientColors;

@end

@implementation FLTGoogleMapPolylineController

- (instancetype)initWithPath:(GMSMutablePath *)path
                  identifier:(NSString *)identifier
                     mapView:(GMSMapView *)mapView {
  self = [super init];
  if (self) {
    _polyline = [GMSPolyline polylineWithPath:path];
    _mapView = mapView;
    _polyline.userData = @[ identifier ];
    _gradientColors = nil;
    _textureImage = nil;
  }
  return self;
}

- (void)removePolyline {
  self.polyline.map = nil;
}

- (void)setConsumeTapEvents:(BOOL)consumes {
  self.polyline.tappable = consumes;
}
- (void)setVisible:(BOOL)visible {
  self.polyline.map = visible ? self.mapView : nil;
}
- (void)setZIndex:(int)zIndex {
  self.polyline.zIndex = zIndex;
}
- (void)setPoints:(NSArray<CLLocation *> *)points {
  GMSMutablePath *path = [GMSMutablePath path];

  for (CLLocation *location in points) {
    [path addCoordinate:location.coordinate];
  }
  self.polyline.path = path;
}

- (void)setColor:(UIColor *)color {
  self.polyline.strokeColor = color;
  // Apply spans if gradient or texture exists
  [self applyStyleSpans];
}
- (void)setStrokeWidth:(CGFloat)width {
  self.polyline.strokeWidth = width;
}

- (void)setGeodesic:(BOOL)isGeodesic {
  self.polyline.geodesic = isGeodesic;
}

- (void)setPattern:(NSArray<GMSStrokeStyle *> *)styles lengths:(NSArray<NSNumber *> *)lengths {
  // If we have a pattern, we should clear any existing gradient/texture spans
  // as they can't coexist logically
  self.gradientColors = nil;
  self.textureImage = nil;

  self.polyline.spans = GMSStyleSpans(self.polyline.path, styles, lengths, kGMSLengthRhumb);
}

- (void)setGradient:(NSArray<UIColor *> *)colors {
  if (colors.count == 2) {
    self.gradientColors = colors;
    [self applyStyleSpans];
  } else {
    self.gradientColors = nil;
    // If gradient is being removed and no texture exists, clear spans
    if (!self.textureImage) {
      self.polyline.spans = nil;
    } else {
      [self applyStyleSpans];
    }
  }
}

- (void)setTexture:(UIImage *)image {
  self.textureImage = image;
  [self applyStyleSpans];

  if (!image && !self.gradientColors) {
    // If texture is being removed and no gradient exists, clear spans
    self.polyline.spans = nil;
  }
}

- (void)applyStyleSpans {
  GMSStrokeStyle *baseStrokeStyle;

  // Create the base stroke style (solid color or gradient)
  if (self.gradientColors && self.gradientColors.count == 2) {
    baseStrokeStyle = [GMSStrokeStyle gradientFromColor:self.gradientColors.firstObject
                                               toColor:self.gradientColors.lastObject];
  } else {
    baseStrokeStyle = [GMSStrokeStyle solidColor:self.polyline.strokeColor];
  }

  // Apply texture if it exists
  if (self.textureImage) {
      baseStrokeStyle.stampStyle = [GMSTextureStyle textureStyleWithImage:self.textureImage];
  }

  // Create a style span with the final style
  GMSStyleSpan *styleSpan = [GMSStyleSpan spanWithStyle:baseStrokeStyle];

  // Apply the span to the polyline
  self.polyline.spans = @[styleSpan];
}

- (void)updateFromPlatformPolyline:(FGMPlatformPolyline *)polyline
                         registrar:(NSObject<FlutterPluginRegistrar> *)registrar
                       screenScale:(CGFloat)screenScale {
  [self setConsumeTapEvents:polyline.consumesTapEvents];
  [self setVisible:polyline.visible];
  [self setZIndex:(int)polyline.zIndex];
  [self setPoints:FGMGetPointsForPigeonLatLngs(polyline.points)];
  [self setColor:FGMGetColorForRGBA(polyline.color)];
  [self setStrokeWidth:polyline.width];
  [self setGeodesic:polyline.geodesic];
  [self setPattern:FGMGetStrokeStylesFromPatterns(polyline.patterns, self.polyline.strokeColor)
           lengths:FGMGetSpanLengthsFromPatterns(polyline.patterns)];

  // Check for gradient first
  if (polyline.gradient && polyline.gradient.x != 0 && polyline.gradient.y != 0) {
    NSArray<UIColor *> *colors = @[
      FGMGetColorForRGBA(polyline.gradient.x),
      FGMGetColorForRGBA(polyline.gradient.y)
    ];
    [self setGradient:colors];
  } else if (self.gradientColors) {
    // Clear gradient if it was set before but not in this update
    self.gradientColors = nil;
    [self applyStyleSpans];
  }

  // Check for texture
  if (polyline.texture) {
    UIImage *image = FGMIconFromBitmap(polyline.texture, registrar, screenScale);
    [self setTexture:image];
  } else if (self.textureImage) {
    // Clear texture if it was set before but not in this update
    self.textureImage = nil;
    [self applyStyleSpans];
  }
}

@end

@interface FLTPolylinesController ()

@property(strong, nonatomic) NSMutableDictionary *polylineIdentifierToController;
@property(strong, nonatomic) FGMMapsCallbackApi *callbackHandler;
@property(weak, nonatomic) NSObject<FlutterPluginRegistrar> *registrar;
@property(weak, nonatomic) GMSMapView *mapView;

@end
;

@implementation FLTPolylinesController

- (instancetype)initWithMapView:(GMSMapView *)mapView
                callbackHandler:(FGMMapsCallbackApi *)callbackHandler
                      registrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _callbackHandler = callbackHandler;
    _mapView = mapView;
    _polylineIdentifierToController = [NSMutableDictionary dictionaryWithCapacity:1];
    _registrar = registrar;
  }
  return self;
}

- (void)addPolylines:(NSArray<FGMPlatformPolyline *> *)polylinesToAdd {
  for (FGMPlatformPolyline *polyline in polylinesToAdd) {
    GMSMutablePath *path = FGMGetPathFromPoints(FGMGetPointsForPigeonLatLngs(polyline.points));
    NSString *identifier = polyline.polylineId;
    FLTGoogleMapPolylineController *controller =
        [[FLTGoogleMapPolylineController alloc] initWithPath:path
                                                  identifier:identifier
                                                     mapView:self.mapView];
    [controller updateFromPlatformPolyline:polyline
                                 registrar:self.registrar
                               screenScale:[self getScreenScale]];
    self.polylineIdentifierToController[identifier] = controller;
  }
}

- (void)changePolylines:(NSArray<FGMPlatformPolyline *> *)polylinesToChange {
  for (FGMPlatformPolyline *polyline in polylinesToChange) {
    NSString *identifier = polyline.polylineId;
    FLTGoogleMapPolylineController *controller = self.polylineIdentifierToController[identifier];
    [controller updateFromPlatformPolyline:polyline
                                 registrar:self.registrar
                               screenScale:[self getScreenScale]];
  }
}

- (void)removePolylineWithIdentifiers:(NSArray<NSString *> *)identifiers {
  for (NSString *identifier in identifiers) {
    FLTGoogleMapPolylineController *controller = self.polylineIdentifierToController[identifier];
    if (!controller) {
      continue;
    }
    [controller removePolyline];
    [self.polylineIdentifierToController removeObjectForKey:identifier];
  }
}

- (void)didTapPolylineWithIdentifier:(NSString *)identifier {
  if (!identifier) {
    return;
  }
  FLTGoogleMapPolylineController *controller = self.polylineIdentifierToController[identifier];
  if (!controller) {
    return;
  }
  [self.callbackHandler didTapPolylineWithIdentifier:identifier
                                          completion:^(FlutterError *_Nullable _){
                                          }];
}

- (bool)hasPolylineWithIdentifier:(NSString *)identifier {
  if (!identifier) {
    return false;
  }
  return self.polylineIdentifierToController[identifier] != nil;
}

- (CGFloat)getScreenScale {
  // TODO(jokerttu): This method is called on marker creation, which, for initial markers, is done
  // before the view is added to the view hierarchy. This means that the traitCollection values may
  // not be matching the right display where the map is finally shown. The solution should be
  // revisited after the proper way to fetch the display scale is resolved for platform views. This
  // should be done under the context of the following issue:
  // https://github.com/flutter/flutter/issues/125496.
  return self.mapView.traitCollection.displayScale;
}

@end
