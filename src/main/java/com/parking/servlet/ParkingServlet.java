package com.parking.servlet;

import com.parking.entity.Card;
import com.parking.entity.ParkingRecord;
import com.parking.entity.ParkingSpace;
import com.parking.service.ParkingService;
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

public class ParkingServlet extends HttpServlet {

    private ParkingService parkingService = new ParkingService();

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
            if ("checkIn".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                String 车位编号 = req.getParameter("spaceId");
                String 车牌号 = req.getParameter("plate");

                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else if (车位编号 == null || 车位编号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请选择车位");
                } else {
                    String msg = parkingService.checkIn(卡号, 车位编号, 车牌号);
                    if (msg.startsWith("SUCCESS:")) {
                        result.put("code", 200);
                        result.put("recordId", msg.substring(8));
                        result.put("msg", "入库成功");
                    } else {
                        result.put("code", 400);
                        result.put("msg", msg);
                    }
                }

            } else if ("checkOut".equals(action)) {
                String 记录编号 = req.getParameter("recordId");
                if (记录编号 == null || 记录编号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入停车记录编号");
                } else {
                    boolean success = parkingService.checkOut(记录编号);
                    if (success) {
                        result.put("code", 200);
                        result.put("msg", "出库成功");
                    } else {
                        result.put("code", 500);
                        result.put("msg", "出库失败");
                    }
                }

            } else if ("getActive".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else {
                    Card card = parkingService.getCardById(卡号);
                    if (card == null) {
                        result.put("code", 404);
                        result.put("msg", "输入卡号不存在");
                        result.put("canCheckIn", false);
                    } else {
                        ParkingRecord record = parkingService.getActiveRecord(卡号);
                        if (record != null) {
                            result.put("code", 200);
                            result.put("data", record);
                            result.put("card", card);
                            result.put("msg", "该车卡车辆当前在场");
                        } else if ("挂失".equals(card.get车卡状态())) {
                            result.put("code", 400);
                            result.put("msg", "卡片已挂失，无法入库");
                            result.put("canCheckIn", false);
                        } else if ("注销".equals(card.get车卡状态())) {
                            result.put("code", 400);
                            result.put("msg", "卡片已注销，无法入库");
                            result.put("canCheckIn", false);
                        } else {
                            result.put("code", 404);
                            result.put("msg", "该车卡车辆当前不在场");
                            result.put("canCheckIn", true);
                            result.put("card", card);
                        }
                    }
                }

            } else if ("listAvailableCheckInSpaces".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                ParkingService.OperationResult op = parkingService.getAvailableCheckInSpacesResult(卡号);
                result.put("code", op.success ? 200 : 400);
                result.put("msg", op.message);
                if (op.data != null) {
                    result.put("data", op.data);
                }

            } else if ("listActive".equals(action)) {
                List<ParkingRecord> list = parkingService.getAllActiveRecords();
                result.put("code", 200);
                result.put("data", list);
                result.put("msg", "查询成功");

            } else if ("listSpaces".equals(action)) {
                List<ParkingSpace> list = parkingService.getAllSpaces();
                result.put("code", 200);
                result.put("data", list);
                result.put("msg", "查询成功");

            } else if ("getSpace".equals(action)) {
                String 车位编号 = req.getParameter("spaceId");
                if (车位编号 == null || 车位编号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入车位编号");
                } else {
                    ParkingSpace space = parkingService.getSpaceById(车位编号);
                    if (space != null) {
                        result.put("code", 200);
                        result.put("data", space);
                        result.put("msg", "查询成功");
                    } else {
                        result.put("code", 404);
                        result.put("msg", "未找到该车位");
                    }
                }

            } else if ("updateFixedCard".equals(action)) {
                String 车位编号 = req.getParameter("spaceId");
                String 固定车位卡号 = req.getParameter("cardId");
                if (车位编号 == null || 车位编号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入车位编号");
                } else if (固定车位卡号 == null || 固定车位卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入新关联卡号");
                } else {
                    ParkingService.OperationResult op = parkingService.updateFixedCardResult(车位编号, 固定车位卡号);
                    result.put("code", op.success ? 200 : 400);
                    result.put("msg", op.message);
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
