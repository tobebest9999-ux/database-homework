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
import java.util.ArrayList;
import java.util.List;

public class ParkingService {

    private ParkingSpaceDAO spaceDAO = new ParkingSpaceDAO();
    private ParkingRecordDAO recordDAO = new ParkingRecordDAO();
    private CardDAO cardDAO = new CardDAO();

    public String checkIn(String 卡号, String 车位编号, String 车牌号) {
        Card card = cardDAO.findByCardId(trim(卡号));
        if (card == null) {
            return "输入卡号不存在。";
        }
        if ("挂失".equals(card.get车卡状态())) {
            return "卡片已挂失，无法入库。";
        }
        if ("注销".equals(card.get车卡状态())) {
            return "卡片已注销，无法入库。";
        }
        if (trim(车牌号).isEmpty()) {
            return "请输入车牌号。";
        }
        if (!trim(card.get车牌号()).equalsIgnoreCase(trim(车牌号))) {
            return "车牌号输入错误。";
        }

        ParkingRecord active = recordDAO.findActiveByCardId(trim(卡号));
        if (active != null) {
            return "该车卡车辆已经在场，请先办理出库。";
        }

        ParkingSpace space = spaceDAO.findBySpaceId(trim(车位编号).toUpperCase());
        if (space == null) {
            return "未找到该停车位。";
        }
        if (!"空闲".equals(space.get车位状态())) {
            return "该停车位已被占用。";
        }
        if (space.get车位编号().startsWith("A-") && !trim(card.get卡号()).equals(trim(space.get固定车位卡号()))) {
            return "该固定车位未绑定当前车卡，不能入库。";
        }
        if (!space.get车位编号().startsWith("A-") && !space.get车位编号().startsWith("B-")) {
            return "该停车位编号不符合规则。";
        }

        String recordId = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmm")) + card.get卡号();

        ParkingRecord record = new ParkingRecord();
        record.set记录编号(recordId);
        record.set卡号(card.get卡号());
        record.set停放车位编号(space.get车位编号());
        record.set入库时间(Timestamp.valueOf(LocalDateTime.now()));

        boolean insertOk = recordDAO.insert(record);
        if (!insertOk) {
            return "新增停车记录失败。";
        }

        boolean updateOk = spaceDAO.updateStatus(space.get车位编号(), "有车", trim(车牌号));
        if (!updateOk) {
            return "更新停车位状态失败。";
        }

        String ownerName = card.get车主姓名();
        LogUtil.log("ParkingRecord", "INSERT", ownerName,
                "车辆入库：卡号=" + card.get卡号() + "，车主=" + ownerName + "，车牌=" + trim(车牌号) + "，车位=" + space.get车位编号());

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
            Card card = cardDAO.findByCardId(record.get卡号());
            String ownerName = card != null ? card.get车主姓名() : "未知";
            LogUtil.log("ParkingRecord", "UPDATE", ownerName,
                    "车辆出库：卡号=" + record.get卡号() + "，车主=" + ownerName + "，车位=" + record.get停放车位编号() + "，费用=" + String.format("%.2f", fee) + "元");
        }
        return result;
    }

    public Card getCardById(String 卡号) {
        return cardDAO.findByCardId(trim(卡号));
    }

    public ParkingRecord getActiveRecord(String 卡号) {
        return recordDAO.findActiveByCardId(trim(卡号));
    }

    public List<ParkingRecord> getAllActiveRecords() {
        return recordDAO.findAllActive();
    }

    public List<ParkingSpace> getAllSpaces() {
        return spaceDAO.findAll();
    }

    public ParkingSpace getSpaceById(String 车位编号) {
        return spaceDAO.findBySpaceId(trim(车位编号).toUpperCase());
    }

    public OperationResult updateFixedCardResult(String 车位编号, String 固定车位卡号) {
        ParkingSpace space = spaceDAO.findBySpaceId(trim(车位编号).toUpperCase());
        if (space == null) {
            return new OperationResult(false, "该车位不存在");
        }
        if (!space.isFixed()) {
            return new OperationResult(false, "本页只支持修改 A 编号固定车位");
        }
        if (!"空闲".equals(space.get车位状态())) {
            return new OperationResult(false, "该车位已占用，占用期间不能修改");
        }

        Card card = cardDAO.findByCardId(trim(固定车位卡号));
        if (card == null) {
            return new OperationResult(false, "新关联卡号不存在");
        }
        if ("挂失".equals(card.get车卡状态())) {
            return new OperationResult(false, "新关联卡号已挂失，不能关联固定车位");
        }
        if ("注销".equals(card.get车卡状态())) {
            return new OperationResult(false, "新关联卡号已注销，不能关联固定车位");
        }

        String oldCard = space.get固定车位卡号();
        boolean result = spaceDAO.updateFixedCard(space.get车位编号(), card.get卡号());
        if (result) {
            LogUtil.log("ParkingSpace", "UPDATE", "系统",
                    "修改车位：" + space.get车位编号() + "，关联卡号 " + (oldCard == null ? "NULL" : oldCard) + "→" + card.get卡号());
            return new OperationResult(true, "车位关联卡号修改成功");
        }
        return new OperationResult(false, "修改失败：车位可能已占用，或该车位不支持修改");
    }

    public boolean updateFixedCard(String 车位编号, String 固定车位卡号) {
        return updateFixedCardResult(车位编号, 固定车位卡号).success;
    }

    public OperationResult getAvailableCheckInSpacesResult(String 卡号) {
        Card card = cardDAO.findByCardId(trim(卡号));
        if (card == null) {
            return new OperationResult(false, "输入卡号不存在");
        }
        if ("挂失".equals(card.get车卡状态())) {
            return new OperationResult(false, "卡片已挂失，无法入库");
        }
        if ("注销".equals(card.get车卡状态())) {
            return new OperationResult(false, "卡片已注销，无法入库");
        }

        List<ParkingSpace> spaces = new ArrayList<>();
        ParkingSpace fixed = spaceDAO.findIdleFixedSpaceByCardId(card.get卡号());
        if (fixed != null) {
            spaces.add(fixed);
        }
        spaces.addAll(spaceDAO.findIdleFreeSpaces());
        return new OperationResult(true, "查询成功", spaces);
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

    private String trim(String text) {
        return text == null ? "" : text.trim();
    }

    public static class OperationResult {
        public final boolean success;
        public final String message;
        public final Object data;

        public OperationResult(boolean success, String message) {
            this(success, message, null);
        }

        public OperationResult(boolean success, String message, Object data) {
            this.success = success;
            this.message = message;
            this.data = data;
        }
    }
}
