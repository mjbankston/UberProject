package performance_tester;

import java.util.ArrayList;
import java.util.Random;

public class App {

    private static final int SIZE = 1000000;

    public static void main(String[] args) {
        Random r = new Random();
        ArrayList<Double> values = new ArrayList<>();
        ArrayList<Double> values2 = new ArrayList<>();
        for (int i = 0; i < SIZE; i++) {
            values.add(r.nextDouble() * 360.0);
            values2.add(r.nextDouble() * 360.0);
        }
        long start = System.nanoTime();
        for (int i = 0; i < SIZE; i++) {
            Math.atan2(values.get(i), values2.get(i));
        }
        long end = System.nanoTime();
        long time = end - start;
        System.out.println("Java Math took " + time / 1000000.0 + "ms.");

        long start2 = System.nanoTime();
        for (int i = 0; i < SIZE; i++) {
            org.hipparchus.util.FastMath.atan2(values.get(i), values2.get(i));
        }
        long end2 = System.nanoTime();
        long time2 = end2 - start2;
        System.out.println("org.hipparchus.util.FastMath took " + time2 / 1000000.0 + "ms.");

        long start3 = System.nanoTime();
        for (int i = 0; i < SIZE; i++) {
            net.jafama.FastMath.atan2(values.get(i), values2.get(i));
        }
        long end3 = System.nanoTime();
        long time3 = end3 - start3;
        System.out.println("net.jafama.FastMath took " + time3 / 1000000.0 + "ms.");
    }
}
