<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.parking.util.DBUtil, java.sql.*" %>
<%
    String ctx = request.getContextPath();
    String chargeId = request.getParameter("chargeId");
    String error = null;
    String recordId = "";
    String cardId = "";
    String plate = "";
    String ownerName = "";
    String phone = "";
    String spaceId = "";
    int minutes = 0;
    double fee = 0;
    Timestamp chargeTime = null;
    String payStatus = "";

    if (chargeId == null || chargeId.trim().isEmpty()) {
        error = "缺少收费编号，无法查看收费记录。";
    } else {
        String sql = "SELECT cr.收费编号, cr.停车记录编号, cr.卡号, c.车牌号, c.车主姓名, c.联系电话, " +
                "cr.车位编号, cr.停车时长, cr.收费金额, cr.收费时间, cr.支付状态 " +
                "FROM ChargeRecord cr LEFT JOIN Card c ON cr.卡号 = c.卡号 WHERE cr.收费编号 = ?";
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            ps.setString(1, chargeId);
            rs = ps.executeQuery();
            if (rs.next()) {
                recordId = rs.getString("停车记录编号");
                cardId = rs.getString("卡号");
                plate = rs.getString("车牌号");
                ownerName = rs.getString("车主姓名");
                phone = rs.getString("联系电话");
                spaceId = rs.getString("车位编号");
                minutes = rs.getInt("停车时长");
                fee = rs.getDouble("收费金额");
                chargeTime = rs.getTimestamp("收费时间");
                payStatus = rs.getString("支付状态");
            } else {
                error = "未找到对应的收费记录。";
            }
        } catch (Exception e) {
            error = "读取收费记录失败：" + e.getMessage();
        } finally {
            DBUtil.close(rs, ps, conn);
        }
    }

    int hours = minutes / 60;
    int mins = minutes % 60;
    String durationDisplay = hours > 0 ? (hours + "小时" + mins + "分钟") : (mins + "分钟");
    String feeDisplay = String.format("%.2f", fee);
    String chargeTimeText = chargeTime == null ? "" : chargeTime.toString();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>收费记录</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; color: #2c3e50; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 18px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        h1 { text-align: center; border-bottom: 3px solid #3498db; padding-bottom: 15px; margin-bottom: 22px; }
        .summary { background: #fff3cd; border: 2px solid #f39c12; border-radius: 10px; padding: 18px; text-align: center; margin-bottom: 20px; }
        .summary .amount { font-size: 36px; font-weight: bold; color: #e67e22; margin-top: 6px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .item { padding: 12px 0; border-bottom: 1px solid #eee; }
        .item strong { display: inline-block; width: 130px; color: #34495e; }
        .msg { padding: 14px 18px; border-radius: 8px; background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .btn-group { margin-top: 24px; text-align: center; }
        .btn { padding: 10px 24px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; margin: 4px; }
        .btn-primary { background: #3498db; color: white; }
        .btn-warning { background: #f39c12; color: white; }
        @media (max-width: 700px) { .grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/charge/chargeManage.jsp" class="back">返回收费管理</a>
    <h1>收费记录</h1>
    <% if (error != null) { %>
        <div class="msg"><%= error %></div>
    <% } else { %>
        <div class="summary">
            <div>本次应收金额</div>
            <div class="amount">¥<%= feeDisplay %></div>
        </div>
        <div class="grid">
            <div class="item"><strong>收费编号：</strong><%= chargeId %></div>
            <div class="item"><strong>停车记录编号：</strong><%= recordId %></div>
            <div class="item"><strong>卡号：</strong><%= cardId %></div>
            <div class="item"><strong>车牌号：</strong><%= plate == null ? "未知" : plate %></div>
            <div class="item"><strong>车主姓名：</strong><%= ownerName == null ? "未知" : ownerName %></div>
            <div class="item"><strong>联系电话：</strong><%= phone == null ? "未知" : phone %></div>
            <div class="item"><strong>车位编号：</strong><%= spaceId %></div>
            <div class="item"><strong>停车时长：</strong><%= durationDisplay %></div>
            <div class="item"><strong>收费时间：</strong><%= chargeTimeText %></div>
            <div class="item"><strong>支付状态：</strong><%= payStatus %></div>
        </div>
        <div class="btn-group">
            <button class="btn btn-warning" onclick="showInvoice()">开发票</button>
            <button class="btn btn-primary" onclick="location.href='<%= ctx %>/charge/chargeManage.jsp'">继续收费</button>
        </div>
    <% } %>
</div>
<script>
    function showInvoice() {
        alert(
            '停车收费发票\n' +
            '收费编号：<%= chargeId == null ? "" : chargeId %>\n' +
            '停车记录编号：<%= recordId %>\n' +
            '卡号：<%= cardId %>\n' +
            '车牌号：<%= plate == null ? "未知" : plate %>\n' +
            '车主姓名：<%= ownerName == null ? "未知" : ownerName %>\n' +
            '联系电话：<%= phone == null ? "未知" : phone %>\n' +
            '车位编号：<%= spaceId %>\n' +
            '停车时长：<%= durationDisplay %>\n' +
            '收费金额：¥<%= feeDisplay %>\n' +
            '收费时间：<%= chargeTimeText %>\n' +
            '支付状态：<%= payStatus %>'
        );
    }
</script>
</body>
</html>
