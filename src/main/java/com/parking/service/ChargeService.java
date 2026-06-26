package com.parking.service;

import com.parking.dao.ParkingRecordDAO;
import com.parking.dao.CardDAO;
import com.parking.dao.ParkingSpaceDAO;
import com.parking.entity.Card;
import com.parking.entity.ParkingRecord;
import com.parking.util.FeeCalculator;
import com.parking.util.LogUtil;

import java.time.Duration;
import java.time.LocalDateTime;
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

    public boolean checkout(String recordId) {
        ParkingRecord record = recordDAO.findByRecordId(recordId);
        if (record == null || record.get出库时间() != null) {
            return false;
        }

        LocalDateTime entryTime = record.get入库时间().toLocalDateTime();
        LocalDateTime exitTime = LocalDateTime.now();
        int minutes = (int) Duration.between(entryTime, exitTime).toMinutes();
        double fee = calculateFee(minutes);

        boolean recordUpdated = recordDAO.updateExit(recordId, java.sql.Timestamp.valueOf(exitTime), fee);
        if (!recordUpdated) {
            return false;
        }

        spaceDAO.updateStatus(record.get停放车位编号(), "空闲", null);

        Card card = cardDAO.findByCardId(record.get卡号());
        String ownerName = card != null ? card.get车主姓名() : "未知";
        LogUtil.log("ParkingRecord", "UPDATE", ownerName,
                "车辆出库：卡号=" + record.get卡号() + "，车主=" + ownerName +
                        "，车位=" + record.get停放车位编号() + "，费用=" + String.format("%.2f", fee) + "元");

        return true;
    }

    public ChargeInfo getChargeInfo(String cardId) {
        ParkingRecord record = recordDAO.findActiveByCardId(cardId);
        if (record == null) {
            return null;
        }

        LocalDateTime entryTime = record.get入库时间().toLocalDateTime();
        LocalDateTime now = LocalDateTime.now();
        long minutes = Duration.between(entryTime, now).toMinutes();

        double fee = calculateFee((int) minutes);

        ChargeInfo info = new ChargeInfo();
        info.recordId = record.get记录编号();
        info.cardId = record.get卡号();
        info.spaceId = record.get停放车位编号();
        info.entryTime = entryTime;
        info.currentTime = now;
        info.minutes = (int) minutes;
        info.fee = fee;

        return info;
    }

    public static class ChargeInfo {
        public String recordId;
        public String cardId;
        public String spaceId;
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
}
