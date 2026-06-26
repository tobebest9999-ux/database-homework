<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.parking.service.ParkingService, com.parking.entity.ParkingSpace, java.util.List" %>
<%
    ParkingService parkingService = new ParkingService();

    List<ParkingSpace> allSpaces = parkingService.getAllSpaces();
    int totalSpaces = allSpaces.size();
    int idleSpaces = 0;
    for (ParkingSpace s : allSpaces) {
        if ("空闲".equals(s.get车位状态())) idleSpaces++;
    }
    int occupiedSpaces = totalSpaces - idleSpaces;
    double usageRate = totalSpaces > 0 ? (double) occupiedSpaces / totalSpaces * 100 : 0;

    List<ParkingSpace> aSpaces = parkingService.getFixedSpaces();
    List<ParkingSpace> bSpaces = parkingService.getFreeSpaces();

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>查询管理</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .section h2 { color: #2c3e50; margin-bottom: 15px; border-left: 4px solid #3498db; padding-left: 12px; }
        .stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 15px; }
        .stat-card { background: white; border-radius: 12px; padding: 20px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
        .stat-card .number { font-size: 32px; font-weight: bold; color: #2c3e50; }
        .stat-card .label { font-size: 14px; color: #888; margin-top: 5px; }
        .stat-card .number.green { color: #2ecc71; }
        .stat-card .number.red { color: #e74c3c; }
        .stat-card .number.blue { color: #3498db; }
        .stat-card .number.orange { color: #f39c12; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px 14px; border: 1px solid #ddd; text-align: left; }
        th { background: #3498db; color: white; }
        tr:nth-child(even) { background: #f8f9fa; }
        .status-badge { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; display: inline-block; }
        .status-badge.occupied { background: #e74c3c; color: white; }
        .status-badge.available { background: #2ecc71; color: white; }
        .empty-msg { text-align: center; color: #888; padding: 20px; }
        .usage-bar { width: 100%; height: 20px; background: #ecf0f1; border-radius: 10px; overflow: hidden; margin-top: 10px; }
        .usage-bar .fill { height: 100%; border-radius: 10px; transition: width 0.5s; }
        .usage-bar .fill.low { background: #2ecc71; }
        .usage-bar .fill.medium { background: #f39c12; }
        .usage-bar .fill.high { background: #e74c3c; }
        .section-stats { margin-top: 15px; font-size: 14px; color: #555; }
        .two-columns { display: grid; grid-template-columns: 1fr 1fr; gap: 25px; }
        @media (max-width: 768px) { .two-columns { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>查询管理</h1>

    <div class="section">
        <h2>车位统计</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="number blue"><%= totalSpaces %></div>
                <div class="label">总车位数</div>
            </div>
            <div class="stat-card">
                <div class="number green"><%= idleSpaces %></div>
                <div class="label">空闲车位</div>
            </div>
            <div class="stat-card">
                <div class="number red"><%= occupiedSpaces %></div>
                <div class="label">已占用车位</div>
            </div>
            <div class="stat-card">
                <div class="number orange"><%= String.format("%.1f", usageRate) %>%</div>
                <div class="label">使用率</div>
            </div>
        </div>
        <div class="usage-bar">
            <%
                String barColor = usageRate < 50 ? "low" : (usageRate < 80 ? "medium" : "high");
            %>
            <div class="fill <%= barColor %>" style="width: <%= usageRate %>%;"></div>
        </div>
        <div class="section-stats">
            使用率：<%= String.format("%.1f", usageRate) %>%
            &nbsp;&nbsp;|&nbsp;&nbsp; 空闲： <%= idleSpaces %> / <%= totalSpaces %>
        </div>
    </div>

    <div class="two-columns">
        <div class="section">
            <h2>A编号车位</h2>
            <p style="color:#666; font-size:14px; margin-bottom:10px;">
                总数： <strong><%= aSpaces.size() %></strong>
            </p>
            <table>
                <thead>
                    <tr>
                        <th>车位编号</th>
                        <th>关联卡号</th>
                        <th>车牌号</th>
                        <th>状态</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        int aOccupied = 0;
                        for (ParkingSpace s : aSpaces) {
                            if ("有车".equals(s.get车位状态())) aOccupied++;
                            boolean occupied = "有车".equals(s.get车位状态());
                            String statusText = occupied ? "已占用" : "空闲";
                            String statusClass = occupied ? "occupied" : "available";
                            String plate = s.get当前停放车牌() == null ? "-" : s.get当前停放车牌();
                            String card = s.get固定车位卡号() == null ? "-" : s.get固定车位卡号();
                    %>
                        <tr>
                            <td><strong><%= s.get车位编号() %></strong></td>
                            <td><%= card %></td>
                            <td><%= plate %></td>
                            <td><span class="status-badge <%= statusClass %>"><%= statusText %></span></td>
                        </tr>
                    <%
                        }
                        if (aSpaces.isEmpty()) {
                    %>
                        <tr><td colspan="4" class="empty-msg">暂无车位</td></tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
            <div class="section-stats">
                🟢 空闲： <%= aSpaces.size() - aOccupied %>
                &nbsp;|&nbsp; 🔴 已占用： <%= aOccupied %>
                &nbsp;|&nbsp; 📊 <%= aSpaces.size() > 0 ? String.format("%.1f", (double) aOccupied / aSpaces.size() * 100) : 0 %>%
            </div>
        </div>

        <div class="section">
            <h2>B编号车位</h2>
            <p style="color:#666; font-size:14px; margin-bottom:10px;">
                总数： <strong><%= bSpaces.size() %></strong>
            </p>
            <table>
                <thead>
                    <tr>
                        <th>车位编号</th>
                        <th>车牌号</th>
                        <th>状态</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        int bOccupied = 0;
                        for (ParkingSpace s : bSpaces) {
                            if ("有车".equals(s.get车位状态())) bOccupied++;
                            boolean occupied = "有车".equals(s.get车位状态());
                            String statusText = occupied ? "已占用" : "空闲";
                            String statusClass = occupied ? "occupied" : "available";
                            String plate = s.get当前停放车牌() == null ? "-" : s.get当前停放车牌();
                    %>
                        <tr>
                            <td><strong><%= s.get车位编号() %></strong></td>
                            <td><%= plate %></td>
                            <td><span class="status-badge <%= statusClass %>"><%= statusText %></span></td>
                        </tr>
                    <%
                        }
                        if (bSpaces.isEmpty()) {
                    %>
                        <tr><td colspan="3" class="empty-msg">暂无车位</td></tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
            <div class="section-stats">
                🟢 空闲： <%= bSpaces.size() - bOccupied %>
                &nbsp;|&nbsp; 🔴 已占用： <%= bOccupied %>
                &nbsp;|&nbsp; 📊 <%= bSpaces.size() > 0 ? String.format("%.1f", (double) bOccupied / bSpaces.size() * 100) : 0 %>%
            </div>
        </div>
    </div>
</div>
</body>
</html>
