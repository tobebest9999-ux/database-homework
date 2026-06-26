package com.parking.servlet;

import com.parking.entity.ParkingRecord;
import com.parking.service.ChargeService;
import com.alibaba.fastjson.JSON;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
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
                    if (info != null) {
                        result.put("code", 200);
                        Map<String, Object> data = new HashMap<>();
                        data.put("recordId", info.recordId);
                        data.put("cardId", info.cardId);
                        data.put("spaceId", info.spaceId);
                        data.put("entryTime", info.entryTime.toString());
                        data.put("currentTime", info.currentTime.toString());
                        data.put("minutes", info.minutes);
                        data.put("durationDisplay", info.getDurationDisplay());
                        data.put("fee", info.fee);
                        data.put("feeDisplay", info.getFeeDisplay());
                        result.put("data", data);
                        result.put("msg", "查询成功");
                    } else {
                        result.put("code", 404);
                        result.put("msg", "该车卡车辆当前不在场，或没有有效停车记录");
                    }
                }

            } else if ("checkout".equals(action)) {
                String 记录编号 = req.getParameter("recordId");
                if (记录编号 == null || 记录编号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入停车记录编号");
                } else {
                    boolean success = chargeService.checkout(记录编号);
                    if (success) {
                        result.put("code", 200);
                        result.put("msg", "出库成功");
                    } else {
                        result.put("code", 500);
                        result.put("msg", "出库失败");
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
}