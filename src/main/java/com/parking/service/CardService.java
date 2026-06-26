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
        boolean result = cardDAO.insert(card);
        if (result) {
            LogUtil.log("Card", "INSERT", "系统",
                    "新增车卡：卡号=" + card.get卡号() + "，车牌=" + card.get车牌号() + "，姓名=" + card.get车主姓名());
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
        Card old = cardDAO.findByCardId(card.get卡号());
        boolean result = cardDAO.update(card);
        if (result && old != null) {
            LogUtil.log("Card", "UPDATE", "系统",
                    "修改车卡：卡号=" + card.get卡号() +
                            "，车牌 " + old.get车牌号() + "→" + card.get车牌号() +
                            "，姓名 " + old.get车主姓名() + "→" + card.get车主姓名());
        }
        return result;
    }

    public boolean deleteCard(String 卡号) {
        Card card = cardDAO.findByCardId(卡号);
        boolean result = cardDAO.delete(卡号);
        if (result && card != null) {
            LogUtil.log("Card", "DELETE", "系统",
                    "删除车卡：卡号=" + card.get卡号() + "，车牌=" + card.get车牌号() + "，姓名=" + card.get车主姓名());
        }
        return result;
    }

    public boolean exists(String 卡号) {
        return cardDAO.exists(卡号);
    }
}