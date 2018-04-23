package satellites;

import java.io.File;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import org.hipparchus.geometry.euclidean.threed.Vector3D;
import org.hipparchus.util.FastMath;
import org.hipparchus.util.MathUtils;
import org.orekit.bodies.BodyShape;
import org.orekit.bodies.GeodeticPoint;
import org.orekit.bodies.OneAxisEllipsoid;
import org.orekit.data.DataProvidersManager;
import org.orekit.data.DirectoryCrawler;
import org.orekit.errors.OrekitException;
import org.orekit.frames.Frame;
import org.orekit.frames.FramesFactory;
import org.orekit.frames.TopocentricFrame;
import org.orekit.orbits.KeplerianOrbit;
import org.orekit.orbits.Orbit;
import org.orekit.orbits.OrbitType;
import org.orekit.orbits.PositionAngle;
import org.orekit.propagation.SpacecraftState;
import org.orekit.propagation.analytical.KeplerianPropagator;
import org.orekit.propagation.analytical.tle.TLE;
import org.orekit.propagation.analytical.tle.TLEPropagator;
import org.orekit.time.AbsoluteDate;
import org.orekit.time.TimeScale;
import org.orekit.time.TimeScalesFactory;
import org.orekit.utils.Constants;
import org.orekit.utils.IERSConventions;
import org.orekit.utils.PVCoordinates;

public class App {

    public static final String orekitPhysicalDataLocation = "C:\\orekit-data";

    // Target
    // Signal frequency (Hz)
    public static double targetFreq = 12e6;
    // Coordinates (Colorado Springs)
    public static double targetLatDegrees = 38.8;
    public static double targetLonDegrees = -104.8;
    public static double targetAltMeters = 1750.0;

    // Monitoring station 1
    // Signal frequency (Hz)
    public static double mon1Freq = 11.75e6;
    // Coordinates (San Antonio)
    public static double mon1LatDegrees = 29.4;
    public static double mon1LonDegrees = -98.5;
    public static double mon1AltMeters = 198.0;

    // Monitoring station 2
    // Signal frequency (Hz)
    public static double mon2Freq = 12.25e6;
    // Coordinates (San Diego)
    public static double mon2LatDegrees = 32.7;
    public static double mon2LonDegrees = -117.15;
    public static double mon2AltMeters = 19.0;

    // SES-3
    public static String tle1Line1 = "1 37748U 11035A   18109.87218494 -.00000112 +00000-0 +00000-0 0  9996";
    public static String tle1Line2 = "2 37748 000.0410 067.9524 0001724 308.8489 042.1154 01.00271942024721";

    // G-16
    public static String tle2Line1 = "1 29236U 06023A   18110.48934799 -.00000139  00000-0  00000+0 0  9990";
    public static String tle2Line2 = "2 29236   0.0143 223.8848 0002723 162.4695 259.3224  1.00270133 43386";

    public static void main(String[] args) throws OrekitException {
        // Orekit needs to be initialized with physical data files.
        // These were downloaded from the Orekit website as the "example quick start" data files.
        // Not sure if there are other physical data files that would be better used.
        initOreKit();

        // Get the current time as UTC
        Date now = Calendar.getInstance(TimeZone.getTimeZone("UTC")).getTime();

        System.out.println("Current date is " + now.toString() + '\n');

        // Orekit uses the GeodeticPoint class to represent a lat/lon/alt location on a body.
        // Create three ground stations: target, monitoring station 1, and monitoring station 2
        GeodeticPoint target = new GeodeticPoint(Math.toRadians(targetLatDegrees), Math.toRadians(targetLonDegrees),
                targetAltMeters);
        System.out.println("Target location is at " + target.getLatitude() + " deg latitude (" + target.getLatitude()
                + " rad), " + targetLonDegrees + " deg longitude (" + target.getLongitude() + " rad), altitude "
                + target.getAltitude() + " meters.");
        GeodeticPoint mon1 = new GeodeticPoint(Math.toRadians(mon1LatDegrees), Math.toRadians(mon1LonDegrees),
                mon1AltMeters);
        System.out.println("Monitor 1 location is at " + mon1.getLatitude() + " deg latitude (" + mon1.getLatitude()
                + " rad), " + mon1LonDegrees + " deg longitude (" + mon1.getLongitude() + " rad), altitude "
                + mon1.getAltitude() + " meters.");
        GeodeticPoint mon2 = new GeodeticPoint(Math.toRadians(mon2LatDegrees), Math.toRadians(mon2LonDegrees),
                mon2AltMeters);
        System.out.println("Monitor 2 location is at " + mon2.getLatitude() + " deg latitude (" + mon2.getLatitude()
                + " rad), " + mon2LonDegrees + " deg longitude (" + mon2.getLongitude() + " rad), altitude "
                + mon2.getAltitude() + " meters.");

        // Propagate the two given satellite TLE's to the current time using the Orekit TLE SGP4/SDP4 propagator.
        // This currenty does not check TLE epoch vs current time to determine how realistic this propagation is.
        SpacecraftState sat1State = propagateTLE(tle1Line1, tle1Line2, now);
        System.out.println("\nSatellite 1 TLE:\n" + tle1Line1 + '\n' + tle1Line2 + '\n');
        System.out.println("Propagated to " + sat1State.getPVCoordinates() + '\n');
        SpacecraftState sat2State = propagateTLE(tle2Line1, tle2Line2, now);
        System.out.println("Satellite 2 TLE:\n" + tle2Line1 + '\n' + tle2Line2 + '\n');
        System.out.println("Propagated to " + sat2State.getPVCoordinates() + '\n');

        // Create a BodyShape object of Earth in an unintutive way for measuring/manipulating coordinates and distances.
        // Uses WGS84 data and IERS_1996 data to build the shape. Supposedly, this is compatible with SGP4/SDP4 TLE propagation.
        Frame earthFrame = FramesFactory.getITRF(IERSConventions.IERS_2010, true);
        BodyShape earth = new OneAxisEllipsoid(Constants.WGS84_EARTH_EQUATORIAL_RADIUS,
                Constants.WGS84_EARTH_FLATTENING, earthFrame);

        TopocentricFrame targetFrame = new TopocentricFrame(earth, target, "TargetFrame");
        TopocentricFrame mon1Frame = new TopocentricFrame(earth, mon1, "MonitoringStation1Frame");
        TopocentricFrame mon2Frame = new TopocentricFrame(earth, mon2, "MonitoringStation2Frame");

        PVCoordinates targetVSsat1 = sat1State.getPVCoordinates(targetFrame);
        double dt1 = targetVSsat1.getPosition().getNorm();
        double dopT1 = computeDopplerShift(targetFreq, targetVSsat1);
        PVCoordinates targetVSsat2 = sat2State.getPVCoordinates(targetFrame);
        double dt2 = targetVSsat2.getPosition().getNorm();
        double dopT2 = computeDopplerShift(targetFreq, targetVSsat2);

        PVCoordinates mon1VSsat1 = sat1State.getPVCoordinates(mon1Frame);
        double dm11 = mon1VSsat1.getPosition().getNorm();
        double dopM11 = computeDopplerShift(mon1Freq, mon1VSsat1);
        PVCoordinates mon1VSsat2 = sat2State.getPVCoordinates(mon1Frame);
        double dm12 = mon1VSsat2.getPosition().getNorm();
        double dopM12 = computeDopplerShift(mon1Freq, mon1VSsat2);

        PVCoordinates mon2VSsat1 = sat1State.getPVCoordinates(mon2Frame);
        double dm21 = mon2VSsat1.getPosition().getNorm();
        double dopM21 = computeDopplerShift(mon2Freq, mon2VSsat1);
        PVCoordinates mon2VSsat2 = sat2State.getPVCoordinates(mon2Frame);
        double dm22 = mon2VSsat2.getPosition().getNorm();
        double dopM22 = computeDopplerShift(mon2Freq, mon2VSsat2);

        System.out.println("Distance/Doppler from target to satellite 1:\t\t" + dt1 + " meters / " + dopT1 + " Hz");
        System.out.println("Distance/Doppler from target to satellite 2:\t\t" + dt2 + " meters / " + dopT2 + " Hz");
        System.out
                .println("Distance/Doppler from monitor 1 to satellite 1:\t\t" + dm11 + " meters / " + dopM11 + " Hz");
        System.out
                .println("Distance/Doppler from monitor 1 to satellite 2:\t\t" + dm12 + " meters / " + dopM12 + " Hz");
        System.out
                .println("Distance/Doppler from monitor 2 to satellite 1:\t\t" + dm21 + " meters / " + dopM21 + " Hz");
        System.out
                .println("Distance/Doppler from monitor 2 to satellite 2:\t\t" + dm22 + " meters / " + dopM22 + " Hz");
        System.out.println();

        // Determine DTO (Difference Time of Arrival) of each station to both satellites
        double targetDTO = (dt1 - dt2) / Constants.SPEED_OF_LIGHT;
        double mon1DTO = (dm11 - dm12) / Constants.SPEED_OF_LIGHT;
        double mon2DTO = (dm21 - dm22) / Constants.SPEED_OF_LIGHT;

        // Determine DFO (Difference Frequency of Arrival) of each station to both satellites
        double targetDFO = (dopT1 - dopT2) / Constants.SPEED_OF_LIGHT;
        double mon1DFO = (dopM11 - dopM12) / Constants.SPEED_OF_LIGHT;
        double mon2DFO = (dopM21 - dopM22) / Constants.SPEED_OF_LIGHT;

        System.out.println("Target DTO/DFO:\t\t\t\t\t\t" + targetDTO + " meters / " + targetDFO + " Hz");
        System.out.println("Monitor 1 DTO/DFO:\t\t\t\t\t" + mon1DTO + " meters / " + mon1DFO + " Hz");
        System.out.println("Monitor 2 DTO/DFO:\t\t\t\t\t" + mon2DTO + " meters / " + mon2DFO + " Hz");
    }

    private static void initOreKit() throws OrekitException {
        File orekitData = new File(orekitPhysicalDataLocation);
        if (!orekitData.exists()) {
            throw new RuntimeException(
                    "Unrecoverable error: Could not locate orekit physical data at default location of '"
                            + orekitPhysicalDataLocation + "'!");
        }
        DataProvidersManager manager = DataProvidersManager.getInstance();
        manager.addProvider(new DirectoryCrawler(orekitData));
    }

    public static double computeDopplerShift(double signalFrequencyHz, PVCoordinates relativePV) {
        return (targetFreq / Constants.SPEED_OF_LIGHT)
                * (Vector3D.dotProduct(relativePV.getPosition(), relativePV.getVelocity())
                        / relativePV.getPosition().getNorm());
    }

    public static SpacecraftState propagateTLE(String tleLine1, String tleLine2, Date date) throws OrekitException {
        TLE tle = buildTLEFromLines(tleLine1, tleLine2);
        TLEPropagator tleProp = TLEPropagator.selectExtrapolator(tle);
        SpacecraftState state = tleProp.propagate(new AbsoluteDate(date, TimeScalesFactory.getUTC()));
        return state;
    }

    public static TLE buildTLEFromLines(String tleLine1, String tleLine2) throws OrekitException {
        // Always test if TLE is good first
        if (!TLE.isFormatOK(tleLine1, tleLine2)) {
            throw new RuntimeException("Bad TLE format!\n" + tleLine1 + '\n' + tleLine2 + '\n');
        }
        return new TLE(tleLine1, tleLine2);
    }

    public static TLE updateTLEFromKeplarianOrbit(TLE oldTLE, Orbit orbit) {
        final KeplerianOrbit kep = (KeplerianOrbit) OrbitType.KEPLERIAN.convertType(orbit);
        return new TLE(oldTLE.getSatelliteNumber(), oldTLE.getClassification(), oldTLE.getLaunchYear(),
                oldTLE.getLaunchNumber(), oldTLE.getLaunchPiece(), TLE.DEFAULT, oldTLE.getElementNumber(),
                kep.getDate(), kep.getKeplerianMeanMotion(), 0.0, 0.0, kep.getE(),
                MathUtils.normalizeAngle(kep.getI(), FastMath.PI),
                MathUtils.normalizeAngle(kep.getPerigeeArgument(), FastMath.PI),
                MathUtils.normalizeAngle(kep.getRightAscensionOfAscendingNode(), FastMath.PI),
                MathUtils.normalizeAngle(kep.getMeanAnomaly(), FastMath.PI), oldTLE.getRevolutionNumberAtEpoch(),
                oldTLE.getBStar());
    }

    // Example on Orekit tutorial
    public static void test1() throws OrekitException {
        Frame inertialFrame = FramesFactory.getEME2000();

        TimeScale utc = TimeScalesFactory.getUTC();
        AbsoluteDate initialDate = new AbsoluteDate(2004, 01, 01, 23, 30, 0.0, utc);

        double mu = 3.986004415e+14;

        double a = 24396159; // semi major axis in meters
        double e = 0.72831215; // eccentricity
        double i = Math.toRadians(7); // inclination
        double omega = Math.toRadians(180); // perigee argument
        double raan = Math.toRadians(261); // right ascension of ascending node
        double lM = 0; // mean anomaly

        Orbit initialOrbit = new KeplerianOrbit(a, e, i, omega, raan, lM, PositionAngle.MEAN, inertialFrame,
                initialDate, mu);

        KeplerianPropagator kepler = new KeplerianPropagator(initialOrbit);
        kepler.setSlaveMode();

        double duration = 600.;
        AbsoluteDate finalDate = initialDate.shiftedBy(duration);
        double stepT = 60.;
        int cpt = 1;
        for (AbsoluteDate extrapDate = initialDate; extrapDate.compareTo(finalDate) <= 0; extrapDate = extrapDate
                .shiftedBy(stepT)) {
            SpacecraftState currentState = kepler.propagate(extrapDate);
            System.out.println("step " + cpt++);
            System.out.println(" time : " + currentState.getDate());
            System.out.println(" " + currentState.getOrbit());
        }

    }
}
