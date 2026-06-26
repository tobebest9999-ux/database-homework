<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.parking.service.ParkingService, com.parking.entity.ParkingSpace, com.parking.entity.ParkingRecord, java.util.List, java.util.Map, java.util.HashMap" %>
<%
    ParkingService parkingService = new ParkingService();
    List<ParkingSpace> spaces = parkingService.getAllSpaces();
    List<ParkingRecord> activeRecords = parkingService.getAllActiveRecords();
    Map<String, String> activeCardBySpace = new HashMap<>();
    for (ParkingRecord r : activeRecords) {
        activeCardBySpace.put(r.get停放车位编号(), r.get卡号());
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>小区停车管理系统</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 1300px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .menu-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin: 30px 0; }
        .menu-card { background: #ecf0f1; border-radius: 15px; padding: 25px; text-align: center; cursor: pointer; transition: all 0.3s; text-decoration: none; color: #2c3e50; display: block; }
        .menu-card:hover { transform: translateY(-5px); box-shadow: 0 8px 25px rgba(52,152,219,0.3); background: #3498db; color: white; }
        .menu-card .icon { font-size: 40px; display: block; margin-bottom: 10px; }
        .menu-card .title { font-size: 18px; font-weight: bold; }
        .parking-matrix { margin-top: 30px; }
        .parking-matrix h2 { text-align: center; color: #2c3e50; margin-bottom: 8px; }
        .space-note { text-align: center; color: #555; font-size: 14px; margin-bottom: 15px; }
        .matrix { display: grid; grid-template-columns: repeat(10, 1fr); gap: 6px; max-width: 900px; margin: 0 auto; }
        .space { padding: 8px 2px; text-align: center; border-radius: 6px; font-size: 11px; font-weight: bold; border: 2px solid #ddd; cursor: help; }
        .space.available { background: #2ecc71; color: white; border-color: #27ae60; }
        .space.occupied { background: #e74c3c; color: white; border-color: #c0392b; }
        .legend { display: flex; justify-content: center; gap: 24px; margin-top: 15px; flex-wrap: wrap; }
        .legend-item { display: flex; align-items: center; gap: 8px; }
        .legend-color { width: 20px; height: 20px; border-radius: 5px; }
        .legend-color.green { background: #2ecc71; }
        .legend-color.red { background: #e74c3c; }
        .status-msg { text-align: center; margin-top: 10px; color: #555; font-size: 14px; }
        .btn-row { text-align: center; margin: 15px 0; }
        .btn-record { display: inline-block; padding: 10px 25px; background: #3498db; color: white; border-radius: 8px; text-decoration: none; font-weight: bold; margin: 0 10px; }
        .btn-log { display: inline-block; padding: 4px 12px; background: #95a5a6; color: white; border-radius: 5px; text-decoration: none; font-size: 12px; margin: 0 10px; }
        @media (max-width: 768px) { .menu-grid { grid-template-columns: repeat(2, 1fr); } .matrix { grid-template-columns: repeat(5, 1fr); } }
    </style>
</head>
<body>
<div class="container">
    <h1>小区停车管理系统</h1>

    <div class="menu-grid">
        <a href="<%= ctx %>/card/cardAdd.jsp" class="menu-card"><span class="icon">💳</span><span class="title">车卡管理</span></a>
        <a href="<%= ctx %>/parking/parkingManage.jsp" class="menu-card"><span class="icon">🅿️</span><span class="title">停车管理</span></a>
        <a href="<%= ctx %>/query/queryManage.jsp" class="menu-card"><span class="icon">📊</span><span class="title">查询管理</span></a>
        <a href="<%= ctx %>/charge/chargeManage.jsp" class="menu-card"><span class="icon">💰</span><span class="title">收费管理</span></a>
    </div>

    <div class="btn-row">
        <a href="<%= ctx %>/parking/parkingRecords.jsp" class="btn-record">停车记录</a>
        <a href="<%= ctx %>/auditLog.jsp" class="btn-log">审计日志</a>
    </div>

    <div class="parking-matrix">
        <h2>停车场车位状态</h2>
        <div class="space-note">A 编号车位为固定车位，B 编号车位为自由车位；鼠标悬停车位可查看状态、占用卡号和车牌号。</div>
        <div class="matrix">
            <%
                int total = 0, occupied = 0;
                for (ParkingSpace s : spaces) {
                    total++;
                    boolean hasCar = "有车".equals(s.get车位状态());
                    if (hasCar) occupied++;
                    String cssClass = hasCar ? "occupied" : "available";
                    String label = hasCar ? "🔴" : "🟢";
                    String hoverCard = activeCardBySpace.get(s.get车位编号());
                    String hoverPlate = s.get当前停放车牌() == null ? "无" : s.get当前停放车牌();
                    String hoverInfo = "车位编号：" + s.get车位编号() + "\n类型：" + (s.get车位编号().startsWith("A-") ? "固定车位" : "自由车位") + "\n状态：" + (hasCar ? "已占用" : "空闲") + "\n占用卡号：" + (hoverCard == null ? "无" : hoverCard) + "\n车牌号：" + hoverPlate;
            %>
                <div class="space <%= cssClass %>" title="<%= hoverInfo %>"><%= s.get车位编号() %><br><%= label %></div>
            <%
                }
            %>
        </div>
        <div class="legend">
            <div class="legend-item"><span class="legend-color green"></span>空闲</div>
            <div class="legend-item"><span class="legend-color red"></span>已占用</div>
            <div class="legend-item">A：固定车位</div>
            <div class="legend-item">B：自由车位</div>
        </div>
        <p class="status-msg">空闲车位： <%= total - occupied %> &nbsp;|&nbsp; 已占用车位： <%= occupied %> &nbsp;|&nbsp; 使用率： <%= total > 0 ? String.format("%.1f", (double)occupied / total * 100) : 0 %>%</p>
    </div>
</div>
</body>
</html>
