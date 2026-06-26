<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>车卡查询</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 850px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; }
        .back { display: inline-block; margin-bottom: 15px; color: #3498db; text-decoration: none; font-weight: bold; }
        .nav-links { text-align: center; padding: 12px; background: #ecf0f1; border-radius: 10px; margin-bottom: 25px; }
        .nav-links a { color: #3498db; font-weight: bold; margin: 0 15px; text-decoration: none; }
        .nav-links a:hover { text-decoration: underline; }
        .nav-links a.active { color: #2c3e50; text-decoration: underline; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .query-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
        .query-box { background: white; border: 1px solid #e2e8f0; border-radius: 10px; padding: 18px; }
        .query-box h3 { margin-top: 0; color: #2c3e50; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 90px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 230px; font-size: 14px; }
        .btn { padding: 10px 26px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.3s; margin: 5px 5px 5px 0; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .msg { padding: 12px 18px; border-radius: 8px; margin: 10px 0; }
        .msg-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .msg-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .detail-area { display: none; margin-top: 20px; padding: 20px; background: white; border-radius: 10px; border: 1px solid #ddd; }
        .detail-area.show { display: block; }
        .card-info { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .card-info .item { padding: 8px 0; border-bottom: 1px solid #eee; }
        .card-info .item strong { display: inline-block; width: 100px; }
        .status { font-weight: bold; }
        .status.normal { color: #27ae60; }
        .status.lost { color: #f39c12; }
        .status.cancelled { color: #c0392b; }
        @media (max-width: 768px) { .query-grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>

    <div class="nav-links">
        <a href="<%= ctx %>/card/cardAdd.jsp">新增车卡</a>
        |
        <a href="<%= ctx %>/card/cardQuery.jsp" class="active">查询车卡</a>
        |
        <a href="<%= ctx %>/card/cardManage.jsp">管理车卡</a>
    </div>

    <h1>车卡查询</h1>

    <div class="section">
        <div class="query-grid">
            <div class="query-box">
                <h3>按卡号查询</h3>
                <div class="form-group">
                    <label>卡号：</label>
                    <input type="text" id="queryCardId" placeholder="请输入卡号">
                </div>
                <button class="btn btn-primary" onclick="queryByCardId()">查询</button>
            </div>
            <div class="query-box">
                <h3>按车牌号查询</h3>
                <div class="form-group">
                    <label>车牌号：</label>
                    <input type="text" id="queryPlate" placeholder="请输入车牌号">
                </div>
                <button class="btn btn-primary" onclick="queryByPlate()">查询</button>
            </div>
        </div>
        <div id="queryResult"></div>
    </div>

    <div id="cardDetail" class="detail-area">
        <h3>车卡信息</h3>
        <div class="card-info">
            <div class="item"><strong>卡号：</strong> <span id="dCardId"></span></div>
            <div class="item"><strong>车牌号：</strong> <span id="dPlate"></span></div>
            <div class="item"><strong>车主姓名：</strong> <span id="dName"></span></div>
            <div class="item"><strong>联系电话：</strong> <span id="dPhone"></span></div>
            <div class="item"><strong>车卡状态：</strong> <span id="dStatus" class="status"></span></div>
        </div>
    </div>
</div>

<script>
    function queryByCardId() {
        const cardId = document.getElementById('queryCardId').value.trim();
        if (!cardId) {
            showError('请输入卡号');
            return;
        }
        queryCard('cardId=' + encodeURIComponent(cardId));
    }

    function queryByPlate() {
        const plate = document.getElementById('queryPlate').value.trim();
        if (!plate) {
            showError('请输入车牌号');
            return;
        }
        queryCard('plate=' + encodeURIComponent(plate));
    }

    function queryCard(params) {
        fetch('<%= ctx %>/card?action=query&' + params)
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('queryResult');
                if (data.code === 200) {
                    const c = data.data;
                    resultDiv.innerHTML = '<div class="msg msg-success">已找到车卡： ' + c.卡号 + '</div>';
                    renderCard(c);
                } else {
                    showError(data.msg);
                }
            })
            .catch(err => showError('服务器错误： ' + err.message));
    }

    function renderCard(c) {
        document.getElementById('dCardId').textContent = c.卡号 || '';
        document.getElementById('dPlate').textContent = c.车牌号 || '';
        document.getElementById('dName').textContent = c.车主姓名 || '';
        document.getElementById('dPhone').textContent = c.联系电话 || '';
        const status = c.车卡状态 || '正常';
        const statusSpan = document.getElementById('dStatus');
        statusSpan.textContent = status;
        statusSpan.className = 'status ' + statusClass(status);
        document.getElementById('cardDetail').className = 'detail-area show';
    }

    function showError(msg) {
        document.getElementById('queryResult').innerHTML = '<div class="msg msg-error">' + msg + '</div>';
        document.getElementById('cardDetail').className = 'detail-area';
    }

    function statusClass(status) {
        if (status === '挂失') return 'lost';
        if (status === '注销') return 'cancelled';
        return 'normal';
    }

    document.getElementById('queryCardId').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') queryByCardId();
    });
    document.getElementById('queryPlate').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') queryByPlate();
    });
</script>
</body>
</html>
