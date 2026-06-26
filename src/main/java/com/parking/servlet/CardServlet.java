package com.parking.servlet;

import com.parking.entity.Card;
import com.parking.service.CardService;
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


public class CardServlet extends HttpServlet {

    private CardService cardService = new CardService();

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
            if ("add".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                String 车牌号 = req.getParameter("plate");
                String 车主姓名 = req.getParameter("name");
                String 联系电话 = req.getParameter("phone");

                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                    out.write(JSON.toJSONString(result));
                    return;
                }

                Card card = new Card(卡号, 车牌号, 车主姓名, 联系电话);
                boolean success = cardService.addCard(card);

                if (success) {
                    result.put("code", 200);
                    result.put("msg", "车卡添加成功");
                } else {
                    result.put("code", 500);
                    result.put("msg", "卡号已存在，或添加失败");
                }

            } else if ("query".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else {
                    Card card = cardService.findByCardId(卡号);
                    if (card != null) {
                        result.put("code", 200);
                        result.put("data", card);
                        result.put("msg", "查询成功");
                    } else {
                        result.put("code", 404);
                        result.put("msg", "未找到该车卡");
                    }
                }

            } else if ("list".equals(action)) {
                List<Card> list = cardService.findAll();
                result.put("code", 200);
                result.put("data", list);
                result.put("msg", "查询成功");

            } else if ("update".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                String 车牌号 = req.getParameter("plate");
                String 车主姓名 = req.getParameter("name");
                String 联系电话 = req.getParameter("phone");

                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else {
                    Card card = new Card(卡号, 车牌号, 车主姓名, 联系电话);
                    boolean success = cardService.updateCard(card);
                    if (success) {
                        result.put("code", 200);
                        result.put("msg", "车卡信息修改成功");
                    } else {
                        result.put("code", 500);
                        result.put("msg", "修改失败");
                    }
                }

            } else if ("delete".equals(action)) {
                String 卡号 = req.getParameter("cardId");
                if (卡号 == null || 卡号.trim().isEmpty()) {
                    result.put("code", 400);
                    result.put("msg", "请输入卡号");
                } else {
                    boolean success = cardService.deleteCard(卡号);
                    if (success) {
                        result.put("code", 200);
                        result.put("msg", "车卡删除成功");
                    } else {
                        result.put("code", 500);
                        result.put("msg", "删除失败");
                    }
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
