// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.googlemaps

import com.google.android.gms.maps.model.PolylineOptions
import com.google.android.gms.maps.model.StrokeStyle
import com.google.android.gms.maps.model.StyleSpan
import org.junit.Assert.assertEquals
import org.junit.Test
import org.mockito.Mockito
import org.mockito.kotlin.verify

class PolylineBuilderTest {
  @Test
  fun density_AppliesToStrokeWidth() {
    val density = 5f
    val strokeWidth = 3f

    val builder = PolylineBuilder(density)
    builder.setWidth(strokeWidth)

    val options = builder.build()
    val width = options.width

    assertEquals(density * strokeWidth, width)
  }

  @Test
  fun setSpans_AddsSpansToOptions() {
    val spans =
        listOf(
            StyleSpan(StrokeStyle.gradientBuilder(0xFF1B2A4A.toInt(), 0xFFF5A524.toInt()).build()))

    // PolylineOptions does not expose its spans, so check the call made on it instead.
    Mockito.mockConstruction(PolylineOptions::class.java).use { constructed ->
      val builder = PolylineBuilder(1f)
      builder.setSpans(spans)

      verify(constructed.constructed().single()).addAllSpans(spans)
    }
  }
}
