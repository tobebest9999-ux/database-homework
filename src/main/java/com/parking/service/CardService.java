package com.parking.service;

import com.parking.dao.CardDAO;
import com.parking.entity.Card;
import com.parking.util.LogUtil;

import java.util.List;

public class CardService {

    private CardDAO cardDAO = new CardDAO();

    public boolean addCard(Card card) {
        if (cardDAO.exists(card.get卡号())) {
            return false;
        }
        card.set车卡状态("正常");
        boolean result = cardDAO.insert(card);
        if (result) {
            LogUtil.log("Card", "INSERT", "系统",
                    "新增车卡：卡号=" + card.get卡号() + "，车牌=" + card.get车牌号() + "，姓名=" + card.get车主姓名() + "，状态=正常");
        }
        return result;
    }

    public Card findByCardId(String 卡号) {
        return cardDAO.findByCardId(卡号);
    }

    public Card findByPlate(String 车牌号) {
        return cardDAO.findByPlate(车牌号);
    }

    public List<Card> findAll() {
        return cardDAO.findAll();
    }

    public boolean updateCard(Card card) {
        return updateCardInfo(card).success;
    }

    public StatusResult updateCardInfo(Card card) {
        Card old = cardDAO.findByCardId(card.get卡号());
        if (old == null) {
            return new StatusResult(false, "未找到该车卡");
        }
        if ("注销".equals(old.get车卡状态())) {
            return new StatusResult(false, "该车卡已注销，不能修改信息");
        }
        if ("挂失".equals(old.get车卡状态())) {
            boolean plateChanged = !sameText(old.get车牌号(), card.get车牌号());
            boolean nameChanged = !sameText(old.get车主姓名(), card.get车主姓名());
            if (plateChanged || nameChanged) {
                return new StatusResult(false, "挂失状态下只能修改联系电话，不能修改车牌号和车主姓名");
            }
        }

        card.set车卡状态(old.get车卡状态());
        boolean result = cardDAO.update(card);
        if (result) {
            LogUtil.log("Card", "UPDATE", "系统",
                    "修改车卡：卡号=" + card.get卡号() +
                            "，车牌 " + old.get车牌号() + "→" + card.get车牌号() +
                            "，姓名 " + old.get车主姓名() + "→" + card.get车主姓名() +
                            "，联系电话 " + old.get联系电话() + "→" + card.get联系电话());
            return new StatusResult(true, "车卡信息修改成功", old.get车卡状态());
        }
        return new StatusResult(false, "修改失败");
    }

    public StatusResult reportLoss(String 卡号) {
        Card card = cardDAO.findByCardId(卡号);
        if (card == null) {
            return new StatusResult(false, "未找到该车卡");
        }
        if ("注销".equals(card.get车卡状态())) {
            return new StatusResult(false, "该车卡已注销，不能挂失");
        }
        if ("挂失".equals(card.get车卡状态())) {
            return new StatusResult(false, "该车卡已经是挂失状态");
        }
        return changeStatus(card, "挂失", "车卡挂失成功");
    }

    public StatusResult unreportLoss(String 卡号) {
        Card card = cardDAO.findByCardId(卡号);
        if (card == null) {
            return new StatusResult(false, "未找到该车卡");
        }
        if ("注销".equals(card.get车卡状态())) {
            return new StatusResult(false, "该车卡已注销，不能解挂");
        }
        if (!"挂失".equals(card.get车卡状态())) {
            return new StatusResult(false, "只有挂失状态的车卡才能解挂");
        }
        return changeStatus(card, "正常", "车卡解挂成功");
    }

    public StatusResult cancelCard(String 卡号) {
        Card card = cardDAO.findByCardId(卡号);
        if (card == null) {
            return new StatusResult(false, "未找到该车卡");
        }
        if ("注销".equals(card.get车卡状态())) {
            return new StatusResult(false, "该车卡已经注销");
        }
        return changeStatus(card, "注销", "车卡注销成功");
    }

    private StatusResult changeStatus(Card card, String newStatus, String successMsg) {
        String oldStatus = card.get车卡状态();
        boolean result = cardDAO.updateStatus(card.get卡号(), newStatus);
        if (result) {
            LogUtil.log("Card", "UPDATE", "系统",
                    "修改车卡状态：卡号=" + card.get卡号() + "，状态 " + oldStatus + "→" + newStatus);
            return new StatusResult(true, successMsg, newStatus);
        }
        return new StatusResult(false, "车卡状态修改失败");
    }

    public boolean exists(String 卡号) {
        return cardDAO.exists(卡号);
    }

    private boolean sameText(String a, String b) {
        String left = a == null ? "" : a.trim();
        String right = b == null ? "" : b.trim();
        return left.equals(right);
    }

    public static class StatusResult {
        public final boolean success;
        public final String message;
        public final String status;

        public StatusResult(boolean success, String message) {
            this(success, message, null);
        }

        public StatusResult(boolean success, String message, String status) {
            this.success = success;
            this.message = message;
            this.status = status;
        }
    }
}
