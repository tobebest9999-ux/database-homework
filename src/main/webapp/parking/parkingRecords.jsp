<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.time.*, com.parking.util.DBUtil, com.parking.util.FeeCalculator" %>
<%
    class RowMap extends HashMap<String, Object> {}
    List<RowMap> activeRows = new ArrayList<>();
    List<RowMap> recentRows = new ArrayList<>();
    int todayCount = 0;
    int totalCount = 0;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = DBUtil.getConnection();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM ParkingRecord WHERE DATE(入库时间) = CURDATE()");
        rs = ps.executeQuery();
        if (rs.next()) todayCount = rs.getInt(1);
        rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM ParkingRecord");
        rs = ps.executeQuery();
        if (rs.next()) totalCount = rs.getInt(1);
        rs.close(); ps.close();

        String activeSql = "SELECT pr.*, c.车牌号 AS 绑定车牌号, c.车主姓名, c.联系电话, ps.当前停放车牌 " +
                "FROM ParkingRecord pr JOIN Card c ON c.卡号 = pr.卡号 " +
                "LEFT JOIN ParkingSpace ps ON ps.车位编号 = pr.停放车位编号 " +
                "WHERE pr.出库时间 IS NULL ORDER BY pr.入库时间 DESC";
        ps = conn.prepareStatement(activeSql);
        rs = ps.executeQuery();
        while (rs.next()) {
            RowMap row = new RowMap();
            Timestamp inTime = rs.getTimestamp("入库时间");
            int minutes = (int)Math.max(0, Duration.between(inTime.toLocalDateTime(), LocalDateTime.now()).toMinutes());
            row.put("记录编号", rs.getString("记录编号"));
            row.put("卡号", rs.getString("卡号"));
            row.put("车位编号", rs.getString("停放车位编号"));
            row.put("车牌号", rs.getString("当前停放车牌") == null ? rs.getString("绑定车牌号") : rs.getString("当前停放车牌"));
            row.put("车主姓名", rs.getString("车主姓名"));
            row.put("入库时间", inTime);
            row.put("停车时长", minutes);
            row.put("预估费用", FeeCalculator.calculateFee(minutes));
            activeRows.add(row);
        }
        rs.close(); ps.close();

        String recentSql = "SELECT pr.*, c.车牌号 AS 绑定车牌号, c.车主姓名, ps.当前停放车牌 " +
                "FROM ParkingRecord pr JOIN Card c ON c.卡号 = pr.卡号 " +
                "LEFT JOIN ParkingSpace ps ON ps.车位编号 = pr.停放车位编号 " +
                "ORDER BY pr.入库时间 DESC LIMIT 50";
        ps = conn.prepareStatement(recentSql);
        rs = ps.executeQuery();
        while (rs.next()) {
            RowMap row = new RowMap();
            row.put("记录编号", rs.getString("记录编号"));
            row.put("卡号", rs.getString("卡号"));
            row.put("车位编号", rs.getString("停放车位编号"));
            row.put("车牌号", rs.getString("当前停放车牌") == null ? rs.getString("绑定车牌号") : rs.getString("当前停放车牌"));
            row.put("车主姓名", rs.getString("车主姓名"));
            row.put("入库时间", rs.getTimestamp("入库时间"));
            row.put("出库时间", rs.getTimestamp("出库时间"));
            double fee = rs.getDouble("收费数额");
            row.put("收费数额", rs.wasNull() ? null : fee);
            recentRows.add(row);
        }
    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        DBUtil.close(rs, ps, conn);
    }

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>停车记录</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 14px; }
        th, td { padding: 8px 10px; border: 1px solid #ddd; text-align: left; }
        th { background: #3498db; color: white; }
        tr:nth-child(even) { background: #f8f9fa; }
        .status-badge { padding: 3px 10px; border-radius: 15px; font-size: 11px; font-weight: bold; display: inline-block; }
        .status-badge.in-park { background: #2ecc71; color: white; }
        .status-badge.exited { background: #95a5a6; color: white; }
        .empty-msg { text-align: center; color: #888; padding: 20px; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .section h2 { color: #2c3e50; margin-bottom: 15px; border-left: 4px solid #3498db; padding-left: 12px; }
        .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin-bottom: 20px; }
        .stat-card { background: white; border-radius: 12px; padding: 20px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
        .stat-card .number { font-size: 28px; font-weight: bold; }
        .blue { color: #3498db; } .green { color: #2ecc71; } .orange { color: #f39c12; }
        .sub-info { margin-top: 10px; color: #888; font-size: 13px; }
        .toolbar { display:flex; gap:12px; align-items:center; flex-wrap:wrap; margin: 10px 0; }
        .toolbar input { padding: 9px 12px; border: 1px solid #ccc; border-radius: 6px; min-width: 280px; }
        .page-btn { padding: 7px 12px; border: 1px solid #3498db; background:white; color:#3498db; border-radius: 5px; cursor:pointer; margin-right:5px; }
        .page-btn.active { background:#3498db; color:white; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>停车记录</h1>

    <div class="section">
        <h2>统计信息</h2>
        <div class="stats-grid">
            <div class="stat-card"><div class="number blue"><%= activeRows.size() %></div><div>当前在场</div></div>
            <div class="stat-card"><div class="number green"><%= todayCount %></div><div>今日记录</div></div>
            <div class="stat-card"><div class="number orange"><%= totalCount %></div><div>总记录数</div></div>
        </div>
    </div>

    <div class="section">
        <h2>当前在场车辆</h2>
        <table>
            <thead><tr><th>记录编号</th><th>卡号</th><th>车牌号</th><th>车主姓名</th><th>车位编号</th><th>入库时间</th><th>已停车时长</th><th>当前预估费用</th><th>状态</th></tr></thead>
            <tbody>
            <% if (activeRows.isEmpty()) { %>
                <tr><td colspan="9" class="empty-msg">当前没有在场车辆</td></tr>
            <% } else { for (RowMap r : activeRows) {
                int mins = (Integer)r.get("停车时长");
                String duration = (mins / 60 > 0 ? (mins / 60) + "小时" : "") + (mins % 60) + "分钟";
            %>
                <tr><td><%= r.get("记录编号") %></td><td><strong><%= r.get("卡号") %></strong></td><td><%= r.get("车牌号") %></td><td><%= r.get("车主姓名") %></td><td><%= r.get("车位编号") %></td><td><%= r.get("入库时间") %></td><td><%= duration %></td><td>¥<%= String.format("%.2f", (Double)r.get("预估费用")) %></td><td><span class="status-badge in-park">在场</span></td></tr>
            <% }} %>
            </tbody>
        </table>
    </div>

    <div class="section">
        <h2>最近50条停车记录</h2>
        <div class="toolbar">
            <label>关键字搜索：</label>
            <input type="text" id="recordSearch" placeholder="输入卡号、车牌号、车位编号、车主姓名" oninput="applyRecordFilter()">
            <span id="recordCount" class="sub-info"></span>
        </div>
        <table>
            <thead><tr><th>记录编号</th><th>卡号</th><th>车牌号</th><th>车主姓名</th><th>车位编号</th><th>入库时间</th><th>出库时间</th><th>收费金额</th><th>状态</th></tr></thead>
            <tbody id="recentBody">
            <% if (recentRows.isEmpty()) { %>
                <tr><td colspan="9" class="empty-msg">暂无停车记录</td></tr>
            <% } else { for (RowMap r : recentRows) {
                boolean inPark = r.get("出库时间") == null;
                String statusClass = inPark ? "in-park" : "exited";
                String statusText = inPark ? "在场" : "已出库";
                Object fee = r.get("收费数额");
                String feeText = fee == null ? "-" : String.format("%.2f", (Double)fee);
                String keyword = (r.get("记录编号") + " " + r.get("卡号") + " " + r.get("车牌号") + " " + r.get("车主姓名") + " " + r.get("车位编号")).toLowerCase();
            %>
                <tr class="recent-row" data-keyword="<%= keyword %>"><td><%= r.get("记录编号") %></td><td><strong><%= r.get("卡号") %></strong></td><td><%= r.get("车牌号") %></td><td><%= r.get("车主姓名") %></td><td><%= r.get("车位编号") %></td><td><%= r.get("入库时间") %></td><td><%= inPark ? "-" : r.get("出库时间") %></td><td><%= feeText %></td><td><span class="status-badge <%= statusClass %>"><%= statusText %></span></td></tr>
            <% }} %>
            </tbody>
        </table>
        <div id="pager" style="margin-top:12px;"></div>
    </div>
</div>
<script>
    var pageSize = 20;
    var currentPage = 1;
    function filteredRows() {
        var keyword = document.getElementById('recordSearch').value.trim().toLowerCase();
        var rows = Array.prototype.slice.call(document.querySelectorAll('.recent-row'));
        return rows.filter(function(row) { return !keyword || row.getAttribute('data-keyword').indexOf(keyword) >= 0; });
    }
    function applyRecordFilter(page) {
        currentPage = page || 1;
        var all = Array.prototype.slice.call(document.querySelectorAll('.recent-row'));
        for (var i = 0; i < all.length; i++) all[i].style.display = 'none';
        var rows = filteredRows();
        var totalPages = Math.max(1, Math.ceil(rows.length / pageSize));
        if (currentPage > totalPages) currentPage = totalPages;
        var start = (currentPage - 1) * pageSize;
        for (var j = start; j < Math.min(start + pageSize, rows.length); j++) rows[j].style.display = '';
        document.getElementById('recordCount').textContent = '匹配 ' + rows.length + ' 条，当前第 ' + currentPage + ' / ' + totalPages + ' 页';
        var html = '';
        for (var p = 1; p <= totalPages; p++) html += '<button class="page-btn ' + (p === currentPage ? 'active' : '') + '" onclick="applyRecordFilter(' + p + ')">' + p + '</button>';
        document.getElementById('pager').innerHTML = html;
    }
    applyRecordFilter(1);
</script>
</body>
</html>
