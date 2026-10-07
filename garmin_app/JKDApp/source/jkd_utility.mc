using Toybox.Graphics;
using Toybox.UserProfile;

module JkdUtility {

    /// Returns the color for displaying heart rate based on the current zone.
    ///
    /// Zones are determined by UserProfile.getHeartRateZones() and map to:
    /// - <Zone1 (50-60%):  Blue   — Warm Up
    /// - Zone1-2 (60-70%): Green  — Fat Burn
    /// - Zone2-3 (70-80%): Yellow — Cardio
    /// - Zone3-4 (80-90%): Orange — Peak
    /// - >=Zone4 (>90%):   Red    — Max Effort
    function getHRColor(heartRate) {
        if (heartRate == 0) { return Graphics.COLOR_WHITE; }

        var zones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
        if (zones == null || zones.size() < 5) { return Graphics.COLOR_RED; }

        switch (true) {
            case heartRate < zones[1]: return Graphics.COLOR_BLUE;
            case heartRate < zones[2]: return Graphics.COLOR_GREEN;
            case heartRate < zones[3]: return Graphics.COLOR_YELLOW;
            case heartRate < zones[4]: return Graphics.COLOR_ORANGE;
        }
        return Graphics.COLOR_RED;
    }

} // module JkdUtility
