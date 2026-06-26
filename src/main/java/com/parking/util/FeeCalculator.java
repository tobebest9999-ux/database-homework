package com.parking.util;

public class FeeCalculator {

    /**
     * Calculate parking fee based on minutes
     */
    public static double calculateFee(int minutes) {
        if (minutes < 0) {
            return 0;
        } else if (minutes <= 29) {
            return 5.00;
        } else if (minutes <= 179) {  // 30 minutes ~ 3 hours
            return 20.00;
        } else if (minutes <= 1439) { // 3 hours ~ 24 hours (1439 minutes)
            return 50.00;
        } else {
            return 100.00;  // >= 24 hours, cap at 100
        }
    }
}