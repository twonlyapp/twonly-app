package eu.twonly.location

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class NativeLocationTest {
    @Test
    fun cityTakesPriorityOverCountry() {
        assertEquals("Berlin", NativeLocation.placeLabel(" Berlin ", "Germany"))
    }

    @Test
    fun missingCityFallsBackToCountry() {
        assertEquals("Germany", NativeLocation.placeLabel(null, " Germany "))
        assertEquals("Germany", NativeLocation.placeLabel("  ", "Germany"))
    }

    @Test
    fun missingCityAndCountryReturnNoLabel() {
        assertNull(NativeLocation.placeLabel(null, null))
        assertNull(NativeLocation.placeLabel(" ", " "))
    }
}
