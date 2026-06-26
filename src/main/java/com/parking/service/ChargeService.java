package com.parking.service;

import com.parking.dao.ParkingRecordDAO;
import com.parking.dao.CardDAO;
import com.parking.dao.ParkingSpaceDAO;
import com.parking.entity.Card;
import com.parking.entity.ParkingRecord;
import com.parking.entity.ParkingSpace;
import com.parking.util.DBUtil;
import com.parking.util.FeeCalculator;
import com.parking.util.LogUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

public class ChargeService {

    private ParkingRecordDAO recordDAO = new ParkingRecordDAO();
    private CardDAO cardDAO = new CardDAO();
    private ParkingSpaceDAO spaceDAO = new ParkingSpaceDAO();

    public double calculateFee(int minutes) {
        return FeeCalculator.calculateFee(minutes);
    }

    public ParkingRecord getActiveRecord(String cardId) {
        return recordDAO.findActiveByCardId(cardId);
    }

    public List<ParkingRecord> getHistory(String cardId) {
        return recordDAO.findByCardId(cardId);
    }

    public ChargeResult checkout(String recordId) {
        ParkingRecord record = recordDAO.findByRecordId(recordId);
        if (record == null || record.get出库时间() != null) {
            return new ChargeResult(false, "出库失败：未找到有效在场记录");
        }

        LocalDateTime entryTime = record.get入库时间().toLocalDateTime();
        LocalDateTime exitTime = LocalDateTime.now();
        int minutes = Math.max(0, (int) Duration.between(entryTime, exitTime).toMinutes());
        double fee = calculateFee(minutes);

        boolean recordUpdated = recordDAO.updateExit(recordId, Timestamp.valueOf(exitTime), fee);
        if (!recordUpdated) {
            return new ChargeResult(false, "出库失败：停车记录更新失败");
        }

        String chargeId = "F" + exitTime.format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")) + record.get卡号();
        boolean chargeOk = insertChargeRecord(chargeId, record, minutes, fee, exitTime, "已支付");
        spaceDAO.updateStatus(record.get停放车位编号(), "空闲", null);

        Card card = cardDAO.findByCardId(record.get卡号());
        String ownerName = card != null ? card.get车主姓名() : "未知";
        LogUtil.log("ParkingRecord", "UPDATE", ownerName,
                "车辆出库：卡号=" + record.get卡号() + "，车主=" + ownerName +
                        "，车位=" + record.get停放车位编号() + "，费用=" + String.format("%.2f", fee) + "元");
        LogUtil.log("ChargeRecord", "INSERT", "系统",
                "收费：收费编号=" + chargeId + "，停车记录=" + record.get记录编号() + "，卡号=" + record.get卡号() +
                        "，车位=" + record.get停放车位编号() + "，金额=" + String.format("%.2f", fee) + "元，支付状态=已支付");

        ChargeRecordInfo charge = new ChargeRecordInfo();
        charge.chargeId = chargeId;
        charge.recordId = record.get记录编号();
        charge.cardId = record.get卡号();
        charge.spaceId = record.get停放车位编号();
        charge.minutes = minutes;
        charge.fee = fee;
        charge.chargeTime = exitTime;
        charge.payStatus = "已支付";

        return new ChargeResult(chargeOk, chargeOk ? "出库成功" : "出库成功，但收费记录保存失败", charge);
    }

    public ChargeInfo getChargeInfo(String cardId) {
        Card card = cardDAO.findByCardId(cardId);
        if (card == null) {
            ChargeInfo info = new ChargeInfo();
            info.exists = false;
            info.message = "该卡号不存在";
            return info;
        }

        ParkingRecord record = recordDAO.findActiveByCardId(cardId);
        if (record == null) {
            ChargeInfo info = new ChargeInfo();
            info.exists = true;
            info.active = false;
            info.cardStatus = card.get车卡状态();
            info.message = "该车卡车辆当前不在场，或没有有效停车记录";
            return info;
        }

        LocalDateTime entryTime = record.get入库时间().toLocalDateTime();
        LocalDateTime now = LocalDateTime.now();
        long minutes = Duration.between(entryTime, now).toMinutes();
        double fee = calculateFee((int) minutes);
        ParkingSpace space = spaceDAO.findBySpaceId(record.get停放车位编号());

        ChargeInfo info = new ChargeInfo();
        info.exists = true;
        info.active = true;
        info.recordId = record.get记录编号();
        info.cardId = record.get卡号();
        info.spaceId = record.get停放车位编号();
        info.plate = space == null ? card.get车牌号() : space.get当前停放车牌();
        info.ownerName = card.get车主姓名();
        info.phone = card.get联系电话();
        info.cardStatus = card.get车卡状态();
        info.entryTime = entryTime;
        info.currentTime = now;
        info.minutes = (int) minutes;
        info.fee = fee;
        info.message = "查询成功";

        return info;
    }

    private boolean insertChargeRecord(String chargeId, ParkingRecord record, int minutes, double fee, LocalDateTime chargeTime, String payStatus) {
        String sql = "INSERT INTO ChargeRecord (收费编号, 停车记录编号, 卡号, 车位编号, 停车时长, 收费金额, 收费时间, 支付状态) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, chargeId);
            ps.setString(2, record.get记录编号());
            ps.setString(3, record.get卡号());
            ps.setString(4, record.get停放车位编号());
            ps.setInt(5, minutes);
            ps.setDouble(6, fee);
            ps.setTimestamp(7, Timestamp.valueOf(chargeTime));
            ps.setString(8, payStatus);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            DBUtil.close(ps, conn);
        }
    }

    public static class ChargeInfo {
        public boolean exists = true;
        public boolean active = true;
        public String message;
        public String recordId;
        public String cardId;
        public String spaceId;
        public String plate;
        public String ownerName;
        public String phone;
        public String cardStatus;
        public LocalDateTime entryTime;
        public LocalDateTime currentTime;
        public int minutes;
        public double fee;

        public String getDurationDisplay() {
            int hours = minutes / 60;
            int mins = minutes % 60;
            if (hours > 0) {
                return hours + "小时" + mins + "分钟";
            }
            return mins + "分钟";
        }

        public String getFeeDisplay() {
            return String.format("%.2f", fee);
        }
    }

    public static class ChargeResult {
        public final boolean success;
        public final String message;
        public final ChargeRecordInfo chargeRecord;

        public ChargeResult(boolean success, String message) {
            this(success, message, null);
        }

        public ChargeResult(boolean success, String message, ChargeRecordInfo chargeRecord) {
            this.success = success;
            this.message = message;
            this.chargeRecord = chargeRecord;
        }
    }

    public static class ChargeRecordInfo {
        public String chargeId;
        public String recordId;
        public String cardId;
        public String spaceId;
        public int minutes;
        public double fee;
        public LocalDateTime chargeTime;
        public String payStatus;

        public String getDurationDisplay() {
            int hours = minutes / 60;
            int mins = minutes % 60;
            if (hours > 0) {
                return hours + "小时" + mins + "分钟";
            }
            return mins + "分钟";
        }

        public String getFeeDisplay() {
            return String.format("%.2f", fee);
        }
    }
}
