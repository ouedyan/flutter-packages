// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package io.flutter.plugins.googlemaps

import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.maps.MapView
import org.junit.Test
import org.mockito.Answers
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify

class GoogleMapLifecycleTest {
  @Test
  fun activityPausePausesTheMapView() {
    val mapView: MapView = mock()
    val controller: GoogleMapController = mock(defaultAnswer = Answers.CALLS_REAL_METHODS)
    controller.setView(mapView)

    controller.onPause(mock<LifecycleOwner>())

    verify(mapView).onPause()
    verify(mapView, never()).onResume()
  }
}
