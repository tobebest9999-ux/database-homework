<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.parking.dao.AuditLogDAO, java.util.*" %>
<%
    AuditLogDAO auditLogDAO = new AuditLogDAO();
    List<Map<String, Object>> logs = auditLogDAO.findLatest(100);
    String ctx = request.getContextPath();
%>
<%!
    private String displayAuditTable(Object value) {
        if (value == null) return "";
        String text = String.valueOf(value);
        if ("Card".equals(text)) return "车卡表";
        if ("ParkingRecord".equals(text)) return "停车记录表";
        if ("ParkingSpace".equals(text)) return "停车位表";
        if ("ChargeRecord".equals(text)) return "收费记录表";
        if ("AuditLog".equals(text)) return "审计日志表";
        return text;
    }

    private String displayAuditOperator(String operator) {
        if (operator == null || operator.trim().isEmpty()) return "系统";
        if ("DB_TRIGGER".equals(operator)) return "数据库触发器";
        return operator;
    }

    private String displayAuditContent(Object value) {
        if (value == null) return "";
        String text = String.valueOf(value);
        text = text.replace("DB_TRIGGER", "数据库触发器");
        text = text.replace("NULL", "未关联");
        text = text.replace(" -> ", " → ");
        return text;
    }

    private String displayAuditType(String type) {
        if (type == null) return "";
        if ("INSERT".equals(type)) return "新增";
        if ("UPDATE".equals(type)) return "修改";
        if ("DELETE".equals(type)) return "删除";
        return type;
    }

    private String businessType(Object tableObj, Object contentObj, String op) {
        String table = tableObj == null ? "" : String.valueOf(tableObj);
        String content = contentObj == null ? "" : String.valueOf(contentObj);
        if ("ChargeRecord".equals(table) || content.contains("收费")) return "收费";
        if (content.contains("车辆入库")) return "入库";
        if (content.contains("车辆出库")) return "出库";
        return displayAuditType(op);
    }

    private String attr(Object value) {
        if (value == null) return "";
        return String.valueOf(value)
                .replace("&", "&amp;")
                .replace("\"", "&quot;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .toLowerCase();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>审计日志</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 1250px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; font-size: 14px; }
        .table-wrap { width: 100%; overflow-x: auto; }
        table { width: 100%; min-width: 1100px; border-collapse: collapse; margin-top: 15px; font-size: 14px; }
        th, td { padding: 8px 12px; border: 1px solid #ddd; text-align: left; }
        th { background: #2c3e50; color: white; }
        tr:nth-child(even) { background: #f8f9fa; }
        .empty-msg { text-align: center; color: #888; padding: 20px; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .section h2 { color: #2c3e50; margin-bottom: 15px; border-left: 4px solid #f39c12; padding-left: 12px; font-size: 18px; }
        .log-type { padding: 2px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; display: inline-block; color: white; }
        .log-type.INSERT { background: #2ecc71; }
        .log-type.UPDATE { background: #f39c12; }
        .log-type.DELETE { background: #e74c3c; }
        .operator-cell { width: 120px; min-width: 120px; white-space: nowrap; }
        .operator-badge { padding: 3px 9px; border-radius: 10px; font-size: 11px; background: #3498db; color: white; display: inline-flex; align-items: center; justify-content: center; white-space: nowrap; line-height: 1.4; min-width: 70px; }
        .operator-badge.system { background: #95a5a6; }
        .stats { text-align: right; color: #888; font-size: 13px; margin-bottom: 10px; }
        .filters { display: grid; grid-template-columns: 180px 1fr 190px 190px auto; gap: 10px; align-items: end; margin-bottom: 12px; }
        .filters label { display:block; font-size: 13px; color:#555; margin-bottom: 4px; }
        .filters select, .filters input { width: 100%; padding: 9px 10px; border: 1px solid #ccc; border-radius: 6px; }
        .filters button { padding: 10px 16px; border: none; background: #3498db; color:white; border-radius: 6px; cursor:pointer; }
        @media (max-width: 900px) { .filters { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>审计日志</h1>

    <div class="section">
        <h2>操作历史记录</h2>
        <div class="filters">
            <div><label>操作类型</label><select id="typeFilter" onchange="filterLogs()"><option value="all">全部</option><option value="新增">新增</option><option value="修改">修改</option><option value="删除">删除</option><option value="入库">入库</option><option value="出库">出库</option><option value="收费">收费</option></select></div>
            <div><label>关键词</label><input id="keywordFilter" placeholder="输入卡号、车牌号、车位编号" oninput="filterLogs()"></div>
            <div><label>开始时间</label><input id="startFilter" type="datetime-local" onchange="filterLogs()"></div>
            <div><label>结束时间</label><input id="endFilter" type="datetime-local" onchange="filterLogs()"></div>
            <div><button onclick="resetFilters()">重置</button></div>
        </div>
        <div class="stats" id="logStats">当前显示最近 <%= logs.size() %> 条记录</div>
        <div class="table-wrap">
        <table>
            <thead><tr><th>#</th><th>表名</th><th>操作类型</th><th>业务类型</th><th>操作员</th><th>内容</th><th>时间</th></tr></thead>
            <tbody>
            <% if (logs.isEmpty()) { %>
                <tr><td colspan="7" class="empty-msg">暂无审计日志</td></tr>
            <% } else {
                int index = 1;
                for (Map<String, Object> row : logs) {
                    String type = (String) row.get("操作类型");
                    String operator = (String) row.get("操作员");
                    String biz = businessType(row.get("表名"), row.get("记录内容"), type);
                    String content = displayAuditContent(row.get("记录内容"));
                    Object time = row.get("操作时间");
                    boolean isSystem = "系统".equals(operator) || operator == null;
                    String keyword = displayAuditTable(row.get("表名")) + " " + displayAuditType(type) + " " + biz + " " + content;
            %>
                <tr class="log-row" data-type="<%= biz %>" data-time="<%= time %>" data-keyword="<%= attr(keyword) %>">
                    <td><%= index++ %></td>
                    <td><%= displayAuditTable(row.get("表名")) %></td>
                    <td><span class="log-type <%= type %>"><%= displayAuditType(type) %></span></td>
                    <td><%= biz %></td>
                    <td class="operator-cell"><span class="operator-badge <%= isSystem ? "system" : "" %>"><%= displayAuditOperator(operator) %></span></td>
                    <td><%= content %></td>
                    <td><%= time %></td>
                </tr>
            <% }} %>
            </tbody>
        </table>
        </div>
    </div>
</div>
<script>
    function filterLogs() {
        var type = document.getElementById('typeFilter').value;
        var keyword = document.getElementById('keywordFilter').value.trim().toLowerCase();
        var start = document.getElementById('startFilter').value;
        var end = document.getElementById('endFilter').value;
        var rows = document.querySelectorAll('.log-row');
        var count = 0;
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            var rowType = row.getAttribute('data-type');
            var rowKeyword = row.getAttribute('data-keyword') || '';
            var rowTimeRaw = (row.getAttribute('data-time') || '').replace(' ', 'T');
            var rowTime = rowTimeRaw ? new Date(rowTimeRaw) : null;
            var visible = true;
            if (type !== 'all' && rowType !== type) visible = false;
            if (keyword && rowKeyword.indexOf(keyword) < 0) visible = false;
            if (start && rowTime && rowTime < new Date(start)) visible = false;
            if (end && rowTime && rowTime > new Date(end)) visible = false;
            row.style.display = visible ? '' : 'none';
            if (visible) count++;
        }
        document.getElementById('logStats').textContent = '当前匹配 ' + count + ' 条记录';
    }
    function resetFilters() {
        document.getElementById('typeFilter').value = 'all';
        document.getElementById('keywordFilter').value = '';
        document.getElementById('startFilter').value = '';
        document.getElementById('endFilter').value = '';
        filterLogs();
    }
</script>
</body>
</html>
