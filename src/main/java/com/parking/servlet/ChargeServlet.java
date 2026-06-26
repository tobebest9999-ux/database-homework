package com.parking.servlet;

import com.parking.entity.ParkingRecord;
import com.parking.service.ChargeService;
import com.alibaba.fastjson.JSON;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class ChargeServlet extends HttpServlet {

    private ChargeService chargeService = new ChargeService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doPost(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");

        String action = req.getParameter("action");
        PrintWriter out = resp.getWriter();
        Map<String, Object> result = new HashMap<>();

        try {
            if ("getChargeInfo".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else {
                    ChargeService.ChargeInfo info = chargeService.getChargeInfo(卡号);
                    if (!info.exists) {
                        result.put("code", 404);
                        result.put("msg", info.message);
                    } else if (!info.active) {
                        result.put("code", 404);
                        result.put("msg", info.message);
                        result.put("cardStatus", info.cardStatus);
                    } else {
                        result.put("code", 200);
                        result.put("data", chargeInfoMap(info));
                        result.put("msg", "查询成功");
                    }
                }

            } else if ("checkout".equals(action)) {
                String 记录编号 = req.getParameter("recordId");
                if (记录编号 == null || 记录编号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入停车记录编号");
                } else {
                    ChargeService.ChargeResult checkout = chargeService.checkout(记录编号);
                    result.put("code", checkout.success ? 200 : 500);
                    result.put("msg", checkout.message);
                    if (checkout.chargeRecord != null) {
                        result.put("chargeRecord", chargeRecordMap(checkout.chargeRecord));
                    }
                }

            } else if ("history".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else {
                    List<ParkingRecord> list = chargeService.getHistory(卡号);
                    result.put("code", 200);
                    result.put("data", list);
                    result.put("msg", "查询成功");
                }

            } else {
                result.put("code", 400);
                result.put("msg", "未知操作：" + action);
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.put("code", 500);
            result.put("msg", "服务器错误：" + e.getMessage());
        }

        out.write(JSON.toJSONString(result));
        out.flush();
        out.close();
    }

    private Map<String, Object> chargeInfoMap(ChargeService.ChargeInfo info) {
        Map<String, Object> data = new HashMap<>();
        data.put("recordId", info.recordId);
        data.put("cardId", info.cardId);
        data.put("spaceId", info.spaceId);
        data.put("plate", info.plate);
        data.put("ownerName", info.ownerName);
        data.put("phone", info.phone);
        data.put("cardStatus", info.cardStatus);
        data.put("entryTime", info.entryTime.toString());
        data.put("currentTime", info.currentTime.toString());
        data.put("minutes", info.minutes);
        data.put("durationDisplay", info.getDurationDisplay());
        data.put("fee", info.fee);
        data.put("feeDisplay", info.getFeeDisplay());
        return data;
    }

    private Map<String, Object> chargeRecordMap(ChargeService.ChargeRecordInfo info) {
        Map<String, Object> data = new HashMap<>();
        data.put("chargeId", info.chargeId);
        data.put("recordId", info.recordId);
        data.put("cardId", info.cardId);
        data.put("spaceId", info.spaceId);
        data.put("minutes", info.minutes);
        data.put("durationDisplay", info.getDurationDisplay());
        data.put("fee", info.fee);
        data.put("feeDisplay", info.getFeeDisplay());
        data.put("chargeTime", info.chargeTime.toString());
        data.put("payStatus", info.payStatus);
        return data;
    }
}
