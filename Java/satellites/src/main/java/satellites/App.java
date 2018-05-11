package satellites;

import java.io.File;
import java.text.DecimalFormat;
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
        public static final DecimalFormat format = new DecimalFormat("0.########");

        // Target
        // Signal frequency (Hz)
        public static double targetFreqHz = 12e6;
        // Coordinates (Colorado Springs)
        public static double targetLatDegrees = 38.8;
        public static double targetLonDegrees = -104.8;
        public static double targetAltMeters = 1750.0;

        // Monitoring station 1
        // Signal frequency (Hz)
        public static double monFreqHz = 11.75e6;
        // Coordinates (San Antonio)
        public static double monLatDegrees = 29.4;
        public static double monLonDegrees = -98.5;
        public static double monAltMeters = 198.0;

        // Reference station
        // Signal frequency (Hz)
        public static double refFreqHz = 12.25e6;
        // Coordinates (Miami)
        public static double refLatDegrees = 25.8;
        public static double refLonDegrees = -80.2;
        public static double refAltMeters = 19.0;

        // SES-3
        public static String tle1Line1 = "1 37748U 11035A   18109.87218494 -.00000112 +00000-0 +00000-0 0  9996";
        public static String tle1Line2 = "2 37748 000.0410 067.9524 0001724 308.8489 042.1154 01.00271942024721";

        // G-16
        public static String tle2Line1 = "1 29236U 06023A   18110.48934799 -.00000139  00000-0  00000+0 0  9990";
        public static String tle2Line2 = "2 29236   0.0143 223.8848 0002723 162.4695 259.3224  1.00270133 43386";

        public static void main(String[] args) throws OrekitException {
                long start = 0;
                long end = 0;
                // Orekit needs to be initialized with physical data files.
                // These were downloaded from the Orekit website as the "example quick start"
                // data files.
                // Not sure if there are other physical data files that would be better used.
                initOreKit();

                // Get the current time as UTC
                Date now = Calendar.getInstance(TimeZone.getTimeZone("UTC")).getTime();

                System.out.println("Current date is " + now.toString() + '\n');

                // Orekit uses the GeodeticPoint class to represent a lat/lon/alt location on a
                // body.
                // Create three ground stations: target, monitoring station 1, and monitoring
                // station 2
                GeodeticPoint target = new GeodeticPoint(Math.toRadians(targetLatDegrees),
                                Math.toRadians(targetLonDegrees), targetAltMeters);
                System.out.println("Target location is at " + targetLatDegrees + " deg latitude ("
                                + target.getLatitude() + " rad), " + targetLonDegrees + " deg longitude ("
                                + target.getLongitude() + " rad), altitude " + target.getAltitude() + " meters.");
                GeodeticPoint mon = new GeodeticPoint(Math.toRadians(monLatDegrees), Math.toRadians(monLonDegrees),
                                monAltMeters);
                System.out.println("Monitoring station location is at " + monLatDegrees + " deg latitude ("
                                + mon.getLatitude() + " rad), " + monLonDegrees + " deg longitude ("
                                + mon.getLongitude() + " rad), altitude " + mon.getAltitude() + " meters.");
                GeodeticPoint ref = new GeodeticPoint(Math.toRadians(refLatDegrees), Math.toRadians(refLonDegrees),
                                refAltMeters);
                System.out.println("Reference signal location is at " + refLatDegrees + " deg latitude ("
                                + ref.getLatitude() + " rad), " + refLonDegrees + " deg longitude ("
                                + ref.getLongitude() + " rad), altitude " + ref.getAltitude() + " meters.");

                // Propagate the two given satellite TLE's to the current time using the Orekit
                // TLE SGP4/SDP4 propagator.
                // This currenty does not check TLE epoch vs current time to determine how
                // realistic this propagation is.
                start = System.nanoTime();
                SpacecraftState sat1State = propagateTLE(tle1Line1, tle1Line2, now);
                end = System.nanoTime();
                System.out.println("\nSatellite 1 TLE:\n" + tle1Line1 + '\n' + tle1Line2 + '\n');
                System.out.println("Propagated to " + sat1State.getPVCoordinates() + '\n');
                System.out.println("Propagation done in " + (end - start) / 1000000. + "ms.\n");
                start = System.nanoTime();
                SpacecraftState sat2State = propagateTLE(tle2Line1, tle2Line2, now);
                end = System.nanoTime();
                System.out.println("Satellite 2 TLE:\n" + tle2Line1 + '\n' + tle2Line2 + '\n');
                System.out.println("Propagated to " + sat2State.getPVCoordinates() + '\n');
                System.out.println("Propagation done in " + (end - start) / 1000000. + "ms.\n");

                // Create a BodyShape object of Earth in an unintutive way for
                // measuring/manipulating coordinates and distances.
                // Uses WGS84 data and IERS_1996 data to build the shape. Supposedly, this is
                // compatible with SGP4/SDP4 TLE propagation.
                Frame earthFrame = FramesFactory.getITRF(IERSConventions.IERS_2010, true);
                BodyShape earth = new OneAxisEllipsoid(Constants.WGS84_EARTH_EQUATORIAL_RADIUS,
                                Constants.WGS84_EARTH_FLATTENING, earthFrame);

                start = System.nanoTime();
                TopocentricFrame targetFrame = new TopocentricFrame(earth, target, "TargetFrame");
                TopocentricFrame monFrame = new TopocentricFrame(earth, mon, "MonitoringStationFrame");
                TopocentricFrame refFrame = new TopocentricFrame(earth, ref, "ReferenceSignalFrame");

                PVCoordinates targetVSsat1 = sat1State.getPVCoordinates(targetFrame);
                double dt1 = targetVSsat1.getPosition().getNorm();
                double dopT1 = computeDopplerShift(targetFreqHz, targetVSsat1);
                PVCoordinates targetVSsat2 = sat2State.getPVCoordinates(targetFrame);
                double dt2 = targetVSsat2.getPosition().getNorm();
                double dopT2 = computeDopplerShift(targetFreqHz, targetVSsat2);

                PVCoordinates monVSsat1 = sat1State.getPVCoordinates(monFrame);
                double dm1 = monVSsat1.getPosition().getNorm();
                double dopM1 = computeDopplerShift(monFreqHz, monVSsat1);
                PVCoordinates monVSsat2 = sat2State.getPVCoordinates(monFrame);
                double dm2 = monVSsat2.getPosition().getNorm();
                double dopM2 = computeDopplerShift(monFreqHz, monVSsat2);

                PVCoordinates refVSsat1 = sat1State.getPVCoordinates(refFrame);
                double dr1 = refVSsat1.getPosition().getNorm();
                double dopR1 = computeDopplerShift(refFreqHz, refVSsat1);
                PVCoordinates refVSsat2 = sat2State.getPVCoordinates(refFrame);
                double dr2 = refVSsat2.getPosition().getNorm();
                double dopR2 = computeDopplerShift(refFreqHz, refVSsat2);

                // Determine DTO and DFO of target and monitoring station using difference of
                // satellite 1 and 2
                double targetDTO = ((dt1 + dm1) - (dt2 + dm2)) / Constants.SPEED_OF_LIGHT;
                double targetDFO = (dopT1 + dopM1) - (dopT2 + dopM2);

                // Determine DTO and DFO of reference and monitoring station using difference of
                // satellite 1 and 2
                double referenceDTO = ((dr1 + dm1) - (dr2 + dm2)) / Constants.SPEED_OF_LIGHT;
                double referenceDFO = (dopR1 + dopM1) - (dopR2 + dopM2);

                // Determine TDOA (Time Difference of Arrival) of target
                double TDOA = targetDTO - referenceDTO;

                // Determine FDOA (Frequency Difference of Arrival) of target to relative to
                // reference signal
                double FDOA = targetDFO - referenceDFO;

                end = System.nanoTime();

                System.out.println("Distance/Doppler from target to satellite 1:\t\t" + format.format(dt1)
                                + " meters / " + format.format(dopT1) + " Hz");
                System.out.println("Distance/Doppler from target to satellite 2:\t\t" + format.format(dt2)
                                + " meters / " + format.format(dopT2) + " Hz");
                System.out.println("Distance/Doppler from monitor to satellite 1:\t\t" + format.format(dm1)
                                + " meters / " + format.format(dopM1) + " Hz");
                System.out.println("Distance/Doppler from monitor to satellite 2:\t\t" + format.format(dm2)
                                + " meters / " + format.format(dopM2) + " Hz");
                System.out.println("Distance/Doppler from reference to satellite 1:\t\t" + format.format(dr1)
                                + " meters / " + format.format(dopR1) + " Hz");
                System.out.println("Distance/Doppler from reference to satellite 2:\t\t" + format.format(dr2)
                                + " meters / " + format.format(dopR2) + " Hz");
                System.out.println();

                System.out.println("Target vs Monitoring Station DTO/DFO:\t\t\t" + format.format(targetDTO)
                                + " seconds / " + format.format(targetDFO) + " Hz");
                System.out.println("Reference vs Monitoring Station DTO/DFO:\t\t" + format.format(referenceDTO)
                                + " seconds / " + format.format(referenceDFO) + " Hz");

                System.out.println("Target vs Reference TDOA:\t\t\t\t" + format.format(TDOA) + " seconds.");
                System.out.println("Target vs Reference FDOA:\t\t\t\t" + format.format(FDOA) + " Hz.");

                System.out.println("\nTDOA/FDOA calculations done in " + (end - start) / 1000000. + "ms.\n");
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
                return (targetFreqHz / Constants.SPEED_OF_LIGHT)
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
                                oldTLE.getLaunchNumber(), oldTLE.getLaunchPiece(), TLE.DEFAULT,
                                oldTLE.getElementNumber(), kep.getDate(), kep.getKeplerianMeanMotion(), 0.0, 0.0,
                                kep.getE(), MathUtils.normalizeAngle(kep.getI(), FastMath.PI),
                                MathUtils.normalizeAngle(kep.getPerigeeArgument(), FastMath.PI),
                                MathUtils.normalizeAngle(kep.getRightAscensionOfAscendingNode(), FastMath.PI),
                                MathUtils.normalizeAngle(kep.getMeanAnomaly(), FastMath.PI),
                                oldTLE.getRevolutionNumberAtEpoch(), oldTLE.getBStar());
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
                for (AbsoluteDate extrapDate = initialDate; extrapDate
                                .compareTo(finalDate) <= 0; extrapDate = extrapDate.shiftedBy(stepT)) {
                        SpacecraftState currentState = kepler.propagate(extrapDate);
                        System.out.println("step " + cpt++);
                        System.out.println(" time : " + currentState.getDate());
                        System.out.println(" " + currentState.getOrbit());
                }

        }
}
