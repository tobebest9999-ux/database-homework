package com.parking.service;

import com.parking.dao.ParkingSpaceDAO;
import com.parking.dao.ParkingRecordDAO;
import com.parking.dao.CardDAO;
import com.parking.entity.Card;
import com.parking.entity.ParkingSpace;
import com.parking.entity.ParkingRecord;
import com.parking.util.LogUtil;
import com.parking.util.FeeCalculator;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

public class ParkingService {

    private ParkingSpaceDAO spaceDAO = new ParkingSpaceDAO();
    private ParkingRecordDAO recordDAO = new ParkingRecordDAO();
    private CardDAO cardDAO = new CardDAO();

    public String checkIn(String 卡号, String 车位编号, String 车牌号) {
        ParkingRecord active = recordDAO.findActiveByCardId(卡号);
        if (active != null) {
            return "该车卡车辆已经在场，请先办理出库。";
        }

        ParkingSpace space = spaceDAO.findBySpaceId(车位编号);
        if (space == null) {
            return "未找到该停车位。";
        }

        if (!"空闲".equals(space.get车位状态())) {
            return "该停车位已被占用。";
        }

        String recordId = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmm")) + 卡号;

        ParkingRecord record = new ParkingRecord();
        record.set记录编号(recordId);
        record.set卡号(卡号);
        record.set停放车位编号(车位编号);
        record.set入库时间(Timestamp.valueOf(LocalDateTime.now()));

        boolean insertOk = recordDAO.insert(record);
        if (!insertOk) {
            return "新增停车记录失败。";
        }

        boolean updateOk = spaceDAO.updateStatus(车位编号, "有车", 车牌号);
        if (!updateOk) {
            return "更新停车位状态失败。";
        }

        // 记录审计日志（入库）
        Card card = cardDAO.findByCardId(卡号);
        String ownerName = card != null ? card.get车主姓名() : "未知";
        LogUtil.log("ParkingRecord", "INSERT", ownerName,
                "车辆入库：卡号=" + 卡号 + "，车主=" + ownerName + "，车位=" + 车位编号);

        return "SUCCESS:" + recordId;
    }

    public boolean checkOut(String 记录编号) {
        ParkingRecord record = recordDAO.findByRecordId(记录编号);
        if (record == null) {
            return false;
        }
        if (record.get出库时间() != null) {
            return false;
        }

        LocalDateTime exitTime = LocalDateTime.now();
        long minutes = (Timestamp.valueOf(exitTime).getTime() - record.get入库时间().getTime()) / 60000;
        double fee = FeeCalculator.calculateFee((int) minutes);
        boolean result = recordDAO.updateExit(记录编号, Timestamp.valueOf(exitTime), fee);
        if (result) {
            spaceDAO.updateStatus(record.get停放车位编号(), "空闲", null);
            // 记录审计日志（出库）
            Card card = cardDAO.findByCardId(record.get卡号());
            String ownerName = card != null ? card.get车主姓名() : "未知";
            LogUtil.log("ParkingRecord", "UPDATE", ownerName,
                    "车辆出库：卡号=" + record.get卡号() + "，车主=" + ownerName + "，车位=" + record.get停放车位编号() + "，费用=" + String.format("%.2f", fee) + "元");
        }
        return result;
    }

    public ParkingRecord getActiveRecord(String 卡号) {
        return recordDAO.findActiveByCardId(卡号);
    }

    public List<ParkingRecord> getAllActiveRecords() {
        return recordDAO.findAllActive();
    }

    public List<ParkingSpace> getAllSpaces() {
        return spaceDAO.findAll();
    }

    public ParkingSpace getSpaceById(String 车位编号) {
        return spaceDAO.findBySpaceId(车位编号);
    }

    public boolean updateFixedCard(String 车位编号, String 固定车位卡号) {
        ParkingSpace space = spaceDAO.findBySpaceId(车位编号);
        if (space == null || !space.isFixed()) {
            return false;
        }
        if (!"空闲".equals(space.get车位状态())) {
            return false;
        }
        String oldCard = space.get固定车位卡号();
        boolean result = spaceDAO.updateFixedCard(车位编号, 固定车位卡号);
        if (result) {
            LogUtil.log("ParkingSpace", "UPDATE", "系统",
                    "修改车位：" + 车位编号 + "，关联卡号 " + (oldCard == null ? "NULL" : oldCard) + "→" + (固定车位卡号 == null ? "NULL" : 固定车位卡号));
        }
        return result;
    }

    public int countFreeSpaces() {
        return spaceDAO.countFreeSpaces();
    }

    public int countFreeIdleSpaces() {
        return spaceDAO.countFreeIdleSpaces();
    }

    public List<ParkingSpace> getFixedSpaces() {
        return spaceDAO.findFixedSpaces();
    }

    public List<ParkingSpace> getFreeSpaces() {
        return spaceDAO.findFreeSpaces();
    }
}

