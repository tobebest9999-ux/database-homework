<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>停车管理</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        .menu-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 25px; margin-top: 30px; }
        .menu-card { background: #f8f9fa; border-radius: 15px; padding: 35px 25px; text-align: center; cursor: pointer; transition: all 0.3s; text-decoration: none; color: #2c3e50; display: block; border: 2px solid #ecf0f1; }
        .menu-card:hover { transform: translateY(-5px); box-shadow: 0 8px 25px rgba(52,152,219,0.25); border-color: #3498db; }
        .menu-card .icon { font-size: 48px; display: block; margin-bottom: 12px; }
        .menu-card .title { font-size: 20px; font-weight: bold; }
        .menu-card .desc { font-size: 14px; color: #888; margin-top: 8px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>
    <h1>停车管理</h1>
    <hr>

    <div class="menu-grid">
        <a href="<%= ctx %>/parking/inOutManage.jsp" class="menu-card">
            <span class="icon">🚗</span>
            <span class="title">办理入库 / 出库</span>
            <span class="desc">车辆入库和出库管理</span>
        </a>
        <a href="<%= ctx %>/parking/spaceManage.jsp" class="menu-card">
            <span class="icon">📐</span>
            <span class="title">车位管理</span>
            <span class="desc">维护车位卡号</span>
        </a>
    </div>
</div>
</body>
</html>
