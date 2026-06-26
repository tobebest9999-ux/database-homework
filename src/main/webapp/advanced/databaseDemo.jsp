<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, com.parking.util.DBUtil" %>
<%!
    private String h(Object value) {
        if (value == null) return "";
        return String.valueOf(value)
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private String displayCellValue(Object value) {
        if (value == null) return "";
        String text = String.valueOf(value);
        if ("Card".equals(text)) return "车卡表";
        if ("ParkingRecord".equals(text)) return "停车记录表";
        if ("ParkingSpace".equals(text)) return "停车位表";
        if ("AuditLog".equals(text)) return "审计日志表";
        if ("INSERT".equals(text)) return "新增";
        if ("UPDATE".equals(text)) return "修改";
        if ("DELETE".equals(text)) return "删除";
        if ("DB_TRIGGER".equals(text)) return "数据库触发器";
        text = text.replace("NULL", "未关联");
        text = text.replace(" -> ", " → ");
        return text;
    }

    private List<Map<String, Object>> queryRows(String sql, Object... params) {
        List<Map<String, Object>> rows = new ArrayList<>();
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            ps = conn.prepareStatement(sql);
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            rs = ps.executeQuery();
            ResultSetMetaData meta = rs.getMetaData();
            int count = meta.getColumnCount();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= count; i++) {
                    row.put(meta.getColumnLabel(i), rs.getObject(i));
                }
                rows.add(row);
            }
        } catch (Exception e) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("提示", "查询失败，请先执行 sql/01_schema_and_seed.sql 和 sql/02_advanced_features.sql");
            row.put("错误", e.getMessage());
            rows.add(row);
        } finally {
            DBUtil.close(rs, ps, conn);
        }
        return rows;
    }
%>
<%
    String ctx = request.getContextPath();
    String keyword = request.getParameter("keyword");
    if (keyword == null || keyword.trim().isEmpty()) {
        keyword = "车辆 出库";
    }

    List<Map<String, Object>> retainedObjects = queryRows(
            "SELECT '收费计算函数 fn_calculate_parking_fee' AS 保留内容, COUNT(*) AS 是否存在 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME = 'fn_calculate_parking_fee' " +
            "UNION ALL SELECT '月度收费汇总过程 sp_generate_monthly_charge_summary', COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() AND ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'sp_generate_monthly_charge_summary' " +
            "UNION ALL SELECT '审计触发器', COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE() AND TRIGGER_NAME IN ('trg_card_audit_ai','trg_card_audit_au','trg_card_audit_ad','trg_space_audit_au','trg_record_audit_ai','trg_record_audit_au') " +
            "UNION ALL SELECT '页面正在使用的视图', COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('v_space_stats','v_active_parking_detail','v_parking_fee_rank','v_monthly_charge_summary') " +
            "UNION ALL SELECT '业务查询索引', COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND INDEX_NAME IN ('idx_record_card_active','idx_record_space_time','idx_space_status_id','idx_audit_time','ft_audit_content')");
    List<Map<String, Object>> spaceStats = queryRows("SELECT * FROM v_space_stats");
    List<Map<String, Object>> activeDetail = queryRows("SELECT * FROM v_active_parking_detail ORDER BY 入库时间 DESC LIMIT 10");
    List<Map<String, Object>> rankRows = queryRows("SELECT * FROM v_parking_fee_rank ORDER BY 卡号, 单卡费用排名 LIMIT 20");
    List<Map<String, Object>> monthlyRows = queryRows("SELECT * FROM v_monthly_charge_summary ORDER BY 收费月份 DESC LIMIT 12");
    List<Map<String, Object>> auditRows = queryRows(
            "SELECT 审计编号, 表名, 操作类型, 操作时间, 记录内容 FROM AuditLog " +
            "WHERE MATCH(记录内容) AGAINST(? IN NATURAL LANGUAGE MODE) ORDER BY 操作时间 DESC LIMIT 20", keyword);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>数据库高级技术演示</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 1300px; margin: 0 auto; background: white; border-radius: 16px; padding: 28px; box-shadow: 0 10px 36px rgba(0,0,0,0.08); }
        .back { display: inline-block; margin-bottom: 18px; color: #2878b5; text-decoration: none; font-weight: bold; }
        h1 { text-align: center; color: #22313f; border-bottom: 3px solid #2878b5; padding-bottom: 14px; }
        .section { margin-top: 22px; background: #f8fafc; border-radius: 10px; padding: 18px; border: 1px solid #e5ebf1; }
        h2 { color: #22313f; margin-bottom: 12px; border-left: 4px solid #2878b5; padding-left: 10px; }
        table { width: 100%; border-collapse: collapse; background: white; font-size: 13px; }
        th, td { border: 1px solid #dce4ec; padding: 8px 10px; text-align: left; vertical-align: top; }
        th { background: #2878b5; color: white; }
        tr:nth-child(even) { background: #f7f9fb; }
        .tip { color: #607080; font-size: 13px; line-height: 1.7; margin-bottom: 10px; }
        .search { display: flex; gap: 10px; margin-bottom: 12px; }
        .search input { flex: 1; padding: 9px 10px; border: 1px solid #bdc9d4; border-radius: 6px; }
        .search button { padding: 9px 16px; border: 0; border-radius: 6px; background: #2878b5; color: white; font-weight: bold; cursor: pointer; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>数据库高级技术演示</h1>

    <div class="section">
        <h2>当前保留的高级数据库内容</h2>
        <div class="tip">这里按名称检查目前仍在使用的数据库对象，避免把已经取消的内容继续展示出来。</div>
        <%= render表名(retainedObjects) %>
    </div>


    <div class="section">
        <h2>车位统计视图</h2>
        <div class="tip">这里查询车位统计视图，集中展示车位总数、空闲数量、已占用数量和使用率。</div>
        <%= render表名(spaceStats) %>
    </div>

    <div class="section">
        <h2>当前停车详情视图</h2>
        <div class="tip">这里查询当前停车详情视图，实时展示在场车辆、已停车时长和当前应收费用。</div>
        <%= render表名(activeDetail) %>
    </div>

    <div class="section">
        <h2>窗口函数费用排名</h2>
        <div class="tip">这里使用窗口函数计算每张车卡的停车费用排名和累计消费。</div>
        <%= render表名(rankRows) %>
    </div>

    <div class="section">
        <h2>月度收费汇总</h2>
        <div class="tip">这里查询月度收费汇总视图，展示每月出库次数和收费合计。</div>
        <%= render表名(monthlyRows) %>
    </div>

    <div class="section">
        <h2>审计日志全文检索</h2>
        <div class="tip">这里通过审计日志内容的全文索引搜索操作记录。默认搜索“车辆 出库”，可以换成其他关键词。</div>
        <form class="search" method="get">
            <input name="keyword" value="<%= h(keyword) %>" placeholder="输入审计日志关键词">
            <button type="submit">搜索</button>
        </form>
        <%= render表名(auditRows) %>
    </div>
</div>
</body>
</html>
<%!
    private String render表名(List<Map<String, Object>> rows) {
        if (rows == null || rows.isEmpty()) {
            return "<div class='tip'>暂无数据</div>";
        }
        StringBuilder sb = new StringBuilder();
        sb.append("<table><thead><tr>");
        for (String key : rows.get(0).keySet()) {
            sb.append("<th>").append(h(key)).append("</th>");
        }
        sb.append("</tr></thead><tbody>");
        for (Map<String, Object> row : rows) {
            sb.append("<tr>");
            for (Object value : row.values()) {
                sb.append("<td>").append(h(displayCellValue(value))).append("</td>");
            }
            sb.append("</tr>");
        }
        sb.append("</tbody></table>");
        return sb.toString();
    }
%>
