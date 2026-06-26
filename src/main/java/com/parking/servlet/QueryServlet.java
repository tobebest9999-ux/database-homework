package com.parking.servlet;

import com.parking.entity.ParkingSpace;
import com.parking.service.ParkingService;
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


public class QueryServlet extends HttpServlet {

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
            if ("freeSpaceStats".equals(action)) {
                int total = parkingService.countFreeSpaces();
                int idle = parkingService.countFreeIdleSpaces();
                double rate = total > 0 ? (double) (total - idle) / total * 100 : 0;

                Map<String, Object> data = new HashMap<>();
                data.put("total", total);
                data.put("idle", idle);
                data.put("occupied", total - idle);
                data.put("usageRate", String.format("%.2f", rate) + "%");

                result.put("code", 200);
                result.put("data", data);
                result.put("msg", "查询成功");

            } else if ("fixedSpaces".equals(action)) {
                List<ParkingSpace> list = parkingService.getFixedSpaces();
                result.put("code", 200);
                result.put("data", list);
                result.put("msg", "查询成功");

            } else if ("freeSpaces".equals(action)) {
                List<ParkingSpace> list = parkingService.getFreeSpaces();
                result.put("code", 200);
                result.put("data", list);
                result.put("msg", "查询成功");

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