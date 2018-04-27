package satellites;

import java.io.File;

import org.orekit.bodies.BodyShape;
import org.orekit.bodies.OneAxisEllipsoid;
import org.orekit.data.DataProvidersManager;
import org.orekit.data.DirectoryCrawler;
import org.orekit.errors.OrekitException;
import org.orekit.frames.Frame;
import org.orekit.frames.FramesFactory;
import org.orekit.utils.Constants;
import org.orekit.utils.IERSConventions;

public class GEO {

    private static String orekitPhysicalDataLocation = "C:\\orekit-data";
    private static BodyShape earth = null;
    private static Frame earthFrame = null;

    static {
        // Create a BodyShape object of Earth in an unintutive way for measuring/manipulating coordinates and distances.
        // Uses WGS84 data and IERS_1996 data to build the shape. Supposedly, this is compatible with SGP4/SDP4 TLE propagation.
        try {
            File orekitData = new File(orekitPhysicalDataLocation);
            if (!orekitData.exists()) {
                throw new RuntimeException(
                        "Unrecoverable error: Could not locate orekit physical data at default location of '"
                                + orekitPhysicalDataLocation + "'!");
            }
            DataProvidersManager manager = DataProvidersManager.getInstance();
            manager.addProvider(new DirectoryCrawler(orekitData));
            earth = new OneAxisEllipsoid(Constants.WGS84_EARTH_EQUATORIAL_RADIUS, Constants.WGS84_EARTH_FLATTENING,
                    FramesFactory.getITRF(IERSConventions.IERS_2010, true));
        } catch (OrekitException e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

}