<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.parking.dao.ParkingRecordDAO, com.parking.entity.ParkingRecord, java.util.List, java.sql.*, com.parking.util.DBUtil, java.util.ArrayList" %>
<%
    ParkingRecordDAO recordDAO = new ParkingRecordDAO();

    // 1. 当前在库记录
    List<ParkingRecord> activeRecords = recordDAO.findAllActive();

    // 2. 今日记录数
    int todayCount = 0;
    // 3. 总记录数
    int totalCount = 0;
    // 4. 最近50条记录（包含已出库和未出库）
    List<ParkingRecord> recentRecords = new ArrayList<>();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = DBUtil.getConnection();

        // 查询今日记录数
        String todaySql = "SELECT COUNT(*) FROM ParkingRecord WHERE DATE(入库时间) = CURDATE()";
        ps = conn.prepareStatement(todaySql);
        rs = ps.executeQuery();
        if (rs.next()) {
            todayCount = rs.getInt(1);
        }
        rs.close();
        ps.close();

        // 查询总记录数
        String totalSql = "SELECT COUNT(*) FROM ParkingRecord";
        ps = conn.prepareStatement(totalSql);
        rs = ps.executeQuery();
        if (rs.next()) {
            totalCount = rs.getInt(1);
        }
        rs.close();
        ps.close();

        // 查询最近50条记录（按入库时间倒序）
        String recentSql = "SELECT * FROM ParkingRecord ORDER BY 入库时间 DESC LIMIT 50";
        ps = conn.prepareStatement(recentSql);
        rs = ps.executeQuery();
        while (rs.next()) {
            ParkingRecord r = new ParkingRecord();
            r.set记录编号(rs.getString("记录编号"));
            r.set卡号(rs.getString("卡号"));
            r.set停放车位编号(rs.getString("停放车位编号"));
            r.set入库时间(rs.getTimestamp("入库时间"));
            r.set出库时间(rs.getTimestamp("出库时间"));
            r.set收费数额(rs.getDouble("收费数额"));
            recentRecords.add(r);
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
        .container { max-width: 1300px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 14px; }
        th, td { padding: 8px 12px; border: 1px solid #ddd; text-align: left; }
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
        .stat-card .number.blue { color: #3498db; }
        .stat-card .number.green { color: #2ecc71; }
        .stat-card .number.orange { color: #f39c12; }
        .stat-card .label { font-size: 14px; color: #888; margin-top: 5px; }
        .sub-info { margin-top: 10px; color: #888; font-size: 13px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>停车记录</h1>

    <!-- ========== 统计信息 ========== -->
    <div class="section">
        <h2>统计信息</h2>
        <div class="stats-grid">
            <div class="stat-card">
                <div class="number blue"><%= activeRecords.size() %></div>
                <div class="label">当前在场</div>
            </div>
            <div class="stat-card">
                <div class="number green"><%= todayCount %></div>
                <div class="label">今日记录</div>
            </div>
            <div class="stat-card">
                <div class="number orange"><%= totalCount %></div>
                <div class="label">总记录数</div>
            </div>
        </div>
    </div>

    <!-- ========== 当前在库车辆 ========== -->
    <div class="section">
        <h2>当前在场车辆</h2>
        <table>
            <thead>
                <tr>
                    <th>记录编号</th>
                    <th>卡号</th>
                    <th>车位编号</th>
                    <th>入库时间</th>
                    <th>状态</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (activeRecords.isEmpty()) {
                %>
                    <tr><td colspan="5" class="empty-msg">当前没有在场车辆</td></tr>
                <%
                    } else {
                        for (ParkingRecord r : activeRecords) {
                %>
                    <tr>
                        <td><%= r.get记录编号() %></td>
                        <td><strong><%= r.get卡号() %></strong></td>
                        <td><%= r.get停放车位编号() %></td>
                        <td><%= r.get入库时间() %></td>
                        <td><span class="status-badge in-park">🟢 在场</span></td>
                    </tr>
                <%
                        }
                    }
                %>
            </tbody>
        </table>
    </div>

    <!-- ========== 最近50条记录 ========== -->
    <div class="section">
        <h2>最近50条停车记录</h2>
        <div class="sub-info">当前显示最近 50 条记录（包含已出库和在场车辆）</div>
        <table>
            <thead>
                <tr>
                    <th>记录编号</th>
                    <th>卡号</th>
                    <th>车位编号</th>
                    <th>入库时间</th>
                    <th>出库时间</th>
                    <th>收费金额</th>
                    <th>状态</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (recentRecords.isEmpty()) {
                %>
                    <tr><td colspan="7" class="empty-msg">暂无停车记录</td></tr>
                <%
                    } else {
                        for (ParkingRecord r : recentRecords) {
                            boolean isInPark = r.get出库时间() == null;
                            String statusText = isInPark ? "在场" : "已出库";
                            String statusClass = isInPark ? "in-park" : "exited";
                            String feeText = r.get收费数额() == null || r.get收费数额() == 0 ? "-" : String.format("%.2f", r.get收费数额());
                %>
                    <tr>
                        <td><%= r.get记录编号() %></td>
                        <td><strong><%= r.get卡号() %></strong></td>
                        <td><%= r.get停放车位编号() %></td>
                        <td><%= r.get入库时间() %></td>
                        <td><%= isInPark ? "-" : r.get出库时间() %></td>
                        <td><%= feeText %></td>
                        <td><span class="status-badge <%= statusClass %>"><%= statusText %></span></td>
                    </tr>
                <%
                        }
                    }
                %>
            </tbody>
        </table>
        <div class="sub-info" style="margin-top:10px;">
            记录总数： <strong><%= recentRecords.size() %></strong> / 50（最多显示 50 条）
        </div>
    </div>
</div>
</body>
</html>