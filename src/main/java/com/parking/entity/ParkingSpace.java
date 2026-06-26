package com.parking.entity;

public class ParkingSpace {
    private String 车位编号;
    private String 车位状态;
    private String 当前停放车牌;
    private String 固定车位卡号;

    public ParkingSpace() {}

    public ParkingSpace(String 车位编号, String 车位状态, String 当前停放车牌, String 固定车位卡号) {
        this.车位编号 = 车位编号;
        this.车位状态 = 车位状态;
        this.当前停放车牌 = 当前停放车牌;
        this.固定车位卡号 = 固定车位卡号;
    }

    public String get车位编号() { return 车位编号; }
    public void set车位编号(String 车位编号) { this.车位编号 = 车位编号; }

    public String get车位状态() { return 车位状态; }
    public void set车位状态(String 车位状态) { this.车位状态 = 车位状态; }

    public String get当前停放车牌() { return 当前停放车牌; }
    public void set当前停放车牌(String 当前停放车牌) { this.当前停放车牌 = 当前停放车牌; }

    public String get固定车位卡号() { return 固定车位卡号; }
    public void set固定车位卡号(String 固定车位卡号) { this.固定车位卡号 = 固定车位卡号; }

    public boolean isFixed() {
        return 车位编号 != null && 车位编号.startsWith("A-");
    }

    public boolean isFree() {
        return 车位编号 != null && 车位编号.startsWith("B-");
    }

    public boolean isIdle() {
        return "空闲".equals(车位状态);
    }
}