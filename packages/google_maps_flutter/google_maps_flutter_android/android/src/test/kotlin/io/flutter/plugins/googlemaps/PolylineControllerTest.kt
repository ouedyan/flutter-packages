// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.googlemaps

import com.google.android.gms.internal.maps.zzar
import com.google.android.gms.maps.model.Polyline
import com.google.android.gms.maps.model.StrokeStyle
import com.google.android.gms.maps.model.StyleSpan
import org.junit.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.spy
import org.mockito.kotlin.verify

class PolylineControllerTest {
  @Test
  fun controller_SetsStrokeDensity() {
    val z = mock<zzar>()
    val polyline = spy(Polyline(z))

    val density = 5f
    val strokeWidth = 3f
    val controller = PolylineController(polyline, false, density)
    controller.setWidth(strokeWidth)

    verify(polyline).width = density * strokeWidth
  }

  @Test
  fun setSpans_SetsSpansOnPolyline() {
    val z = mock<zzar>()
    val polyline = spy(Polyline(z))
    val spans =
        listOf(
            StyleSpan(StrokeStyle.gradientBuilder(0xFF1B2A4A.toInt(), 0xFFF5A524.toInt()).build()))

    val controller = PolylineController(polyline, false, 1f)
    controller.setSpans(spans)

    verify(polyline).spans = spans
  }

  @Test
  fun setSpans_EmptyListClearsSpans() {
    val z = mock<zzar>()
    val polyline = spy(Polyline(z))

    val controller = PolylineController(polyline, false, 1f)
    controller.setSpans(listOf())

    verify(polyline).spans = listOf()
  }
}
