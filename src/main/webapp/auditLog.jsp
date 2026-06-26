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
        if ("TRIGGER".equals(type)) return "触发器";
        return type;
    }
%>
<!DOCTYPE html><html>
<head>
    <meta charset="UTF-8">
    <title>审计日志</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 15px; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 14px; }
        th, td { padding: 8px 12px; border: 1px solid #ddd; text-align: left; }
        th { background: #2c3e50; color: white; }
        tr:nth-child(even) { background: #f8f9fa; }
        .empty-msg { text-align: center; color: #888; padding: 20px; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .section h2 { color: #2c3e50; margin-bottom: 15px; border-left: 4px solid #f39c12; padding-left: 12px; font-size: 18px; }
        .log-type { padding: 2px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; display: inline-block; }
        .log-type.INSERT { background: #2ecc71; color: white; }
        .log-type.UPDATE { background: #f39c12; color: white; }
        .log-type.DELETE { background: #e74c3c; color: white; }
        .operator-badge { padding: 2px 8px; border-radius: 10px; font-size: 11px; background: #3498db; color: white; }
        .operator-badge.system { background: #95a5a6; }
        .stats { text-align: right; color: #888; font-size: 13px; margin-bottom: 10px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>审计日志</h1>

    <div class="section">
        <h2>操作历史记录</h2>
        <div class="stats">当前显示最近 <%= logs.size() %> 条记录</div>
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>表名</th>
                    <th>操作类型</th>
                    <th>操作员</th>
                    <th>内容</th>
                    <th>时间</th>
                </tr>
            </thead>
            <tbody>
                <%
                    if (logs.isEmpty()) {
                %>
                    <tr><td colspan="6" class="empty-msg">暂无审计日志</td></tr>
                <%
                    } else {
                        int index = 1;
                        for (Map<String, Object> row : logs) {
                            String type = (String) row.get("操作类型");
                            String operator = (String) row.get("操作员");
                            boolean isSystem = "系统".equals(operator) || operator == null;
                %>
                    <tr>
                        <td><%= index++ %></td>
                        <td><%= displayAuditTable(row.get("表名")) %></td>
                        <td><span class="log-type <%= type %>"><%= displayAuditType(type) %></span></td>
                        <td>
                            <span class="operator-badge <%= isSystem ? "system" : "" %>">
                                <%= displayAuditOperator(operator) %>
                            </span>
                        </td>
                        <td><%= displayAuditContent(row.get("记录内容")) %></td>
                        <td><%= row.get("操作时间") %></td>
                    </tr>
                <%
                        }
                    }
                %>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>