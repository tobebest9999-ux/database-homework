package com.parking.entity;

import java.sql.Timestamp;

public class ParkingRecord {
    private String 记录编号;
    private String 卡号;
    private String 停放车位编号;
    private Timestamp 入库时间;
    private Timestamp 出库时间;
    private Double 收费数额;

    public ParkingRecord() {}

    public ParkingRecord(String 记录编号, String 卡号, String 停放车位编号,
                         Timestamp 入库时间, Timestamp 出库时间, Double 收费数额) {
        this.记录编号 = 记录编号;
        this.卡号 = 卡号;
        this.停放车位编号 = 停放车位编号;
        this.入库时间 = 入库时间;
        this.出库时间 = 出库时间;
        this.收费数额 = 收费数额;
    }

    public String get记录编号() { return 记录编号; }
    public void set记录编号(String 记录编号) { this.记录编号 = 记录编号; }

    public String get卡号() { return 卡号; }
    public void set卡号(String 卡号) { this.卡号 = 卡号; }

    public String get停放车位编号() { return 停放车位编号; }
    public void set停放车位编号(String 停放车位编号) { this.停放车位编号 = 停放车位编号; }

    public Timestamp get入库时间() { return 入库时间; }
    public void set入库时间(Timestamp 入库时间) { this.入库时间 = 入库时间; }

    public Timestamp get出库时间() { return 出库时间; }
    public void set出库时间(Timestamp 出库时间) { this.出库时间 = 出库时间; }

    public Double get收费数额() { return 收费数额; }
    public void set收费数额(Double 收费数额) { this.收费数额 = 收费数额; }

    public boolean isInPark() {
        return 出库时间 == null;
    }
}