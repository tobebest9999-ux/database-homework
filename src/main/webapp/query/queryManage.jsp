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
        .green { color: #2ecc71 !important; } .red { color: #e74c3c !important; } .blue { color: #3498db !important; } .orange { color: #f39c12 !important; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px 14px; border: 1px solid #ddd; text-align: left; }
        th { background: #3498db; color: white; }
        tr:nth-child(even) { background: #f8f9fa; }
        .status-badge { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; display: inline-block; }
        .status-badge.occupied { background: #e74c3c; color: white; }
        .status-badge.available { background: #2ecc71; color: white; }
        .empty-msg { text-align: center; color: #888; padding: 20px; }
        .section-stats { margin-top: 15px; font-size: 14px; color: #555; }
        .two-columns { display: grid; grid-template-columns: 1fr 1fr; gap: 25px; }
        .filter-bar { display: flex; gap: 10px; align-items: center; margin: 15px 0; flex-wrap: wrap; }
        .filter-btn { padding: 8px 16px; border: 1px solid #3498db; background: white; color: #3498db; border-radius: 6px; cursor: pointer; font-weight: bold; }
        .filter-btn.active { background: #3498db; color: white; }
        .type-note { color:#555; font-size:14px; margin-top:10px; }
        @media (max-width: 768px) { .two-columns, .stats-grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>查询管理</h1>

    <div class="section">
        <h2>车位统计</h2>
        <div class="stats-grid">
            <div class="stat-card"><div class="number blue"><%= totalSpaces %></div><div class="label">总车位数</div></div>
            <div class="stat-card"><div class="number green"><%= idleSpaces %></div><div class="label">空闲车位</div></div>
            <div class="stat-card"><div class="number red"><%= occupiedSpaces %></div><div class="label">已占用车位</div></div>
            <div class="stat-card"><div class="number orange"><%= String.format("%.1f", usageRate) %>%</div><div class="label">使用率</div></div>
        </div>
        <div class="type-note">A 编号车位为固定车位，B 编号车位为自由车位。</div>
        <div class="filter-bar">
            <span>车位筛选：</span>
            <button class="filter-btn active" onclick="filterSpaces('all', this)">全部</button>
            <button class="filter-btn" onclick="filterSpaces('idle', this)">只看空闲</button>
            <button class="filter-btn" onclick="filterSpaces('occupied', this)">只看占用</button>
        </div>
        <div class="section-stats">使用率：<%= String.format("%.1f", usageRate) %>% &nbsp;|&nbsp; 空闲： <%= idleSpaces %> / <%= totalSpaces %></div>
    </div>

    <div class="two-columns">
        <div class="section">
            <h2>A编号车位（固定车位）</h2>
            <p style="color:#666; font-size:14px; margin-bottom:10px;">总数： <strong><%= aSpaces.size() %></strong></p>
            <table><thead><tr><th>车位编号</th><th>关联卡号</th><th>车牌号</th><th>状态</th></tr></thead><tbody>
            <%
                int aOccupied = 0;
                for (ParkingSpace s : aSpaces) {
                    boolean occupied = "有车".equals(s.get车位状态());
                    if (occupied) aOccupied++;
                    String statusText = occupied ? "已占用" : "空闲";
                    String statusClass = occupied ? "occupied" : "available";
                    String plate = s.get当前停放车牌() == null ? "-" : s.get当前停放车牌();
                    String card = s.get固定车位卡号() == null ? "-" : s.get固定车位卡号();
            %>
                <tr class="space-row" data-status="<%= occupied ? "occupied" : "idle" %>"><td><strong><%= s.get车位编号() %></strong></td><td><%= card %></td><td><%= plate %></td><td><span class="status-badge <%= statusClass %>"><%= statusText %></span></td></tr>
            <% } if (aSpaces.isEmpty()) { %>
                <tr><td colspan="4" class="empty-msg">暂无车位</td></tr>
            <% } %>
            </tbody></table>
            <div class="section-stats">空闲： <%= aSpaces.size() - aOccupied %> &nbsp;|&nbsp; 已占用： <%= aOccupied %></div>
        </div>

        <div class="section">
            <h2>B编号车位（自由车位）</h2>
            <p style="color:#666; font-size:14px; margin-bottom:10px;">总数： <strong><%= bSpaces.size() %></strong></p>
            <table><thead><tr><th>车位编号</th><th>车牌号</th><th>状态</th></tr></thead><tbody>
            <%
                int bOccupied = 0;
                for (ParkingSpace s : bSpaces) {
                    boolean occupied = "有车".equals(s.get车位状态());
                    if (occupied) bOccupied++;
                    String statusText = occupied ? "已占用" : "空闲";
                    String statusClass = occupied ? "occupied" : "available";
                    String plate = s.get当前停放车牌() == null ? "-" : s.get当前停放车牌();
            %>
                <tr class="space-row" data-status="<%= occupied ? "occupied" : "idle" %>"><td><strong><%= s.get车位编号() %></strong></td><td><%= plate %></td><td><span class="status-badge <%= statusClass %>"><%= statusText %></span></td></tr>
            <% } if (bSpaces.isEmpty()) { %>
                <tr><td colspan="3" class="empty-msg">暂无车位</td></tr>
            <% } %>
            </tbody></table>
            <div class="section-stats">空闲： <%= bSpaces.size() - bOccupied %> &nbsp;|&nbsp; 已占用： <%= bOccupied %></div>
        </div>
    </div>
</div>
<script>
    function filterSpaces(mode, btn) {
        var buttons = document.querySelectorAll('.filter-btn');
        for (var i = 0; i < buttons.length; i++) buttons[i].classList.remove('active');
        btn.classList.add('active');
        var rows = document.querySelectorAll('.space-row');
        for (var j = 0; j < rows.length; j++) {
            var status = rows[j].getAttribute('data-status');
            rows[j].style.display = (mode === 'all' || mode === status) ? '' : 'none';
        }
    }
</script>
</body>
</html>
