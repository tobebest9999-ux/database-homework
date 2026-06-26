<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>车卡信息管理</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; }
        .back { display: inline-block; margin-bottom: 15px; color: #3498db; text-decoration: none; font-weight: bold; }
        .nav-links { text-align: center; padding: 12px; background: #ecf0f1; border-radius: 10px; margin-bottom: 25px; }
        .nav-links a { color: #3498db; font-weight: bold; margin: 0 15px; text-decoration: none; }
        .nav-links a:hover { text-decoration: underline; }
        .nav-links a.active { color: #2c3e50; text-decoration: underline; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 100px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 250px; font-size: 14px; }
        .form-group input[readonly] { background: #e9ecef; }
        .btn { padding: 10px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.3s; margin: 5px 5px 5px 0; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-warning { background: #f39c12; color: white; }
        .btn-warning:hover { background: #e67e22; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-danger:hover { background: #c0392b; }
        .btn-success { background: #2ecc71; color: white; }
        .btn-success:hover { background: #27ae60; }
        .msg { padding: 12px 18px; border-radius: 8px; margin: 10px 0; }
        .msg-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .msg-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .msg-info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .detail-area { display: none; margin-top: 20px; padding: 20px; background: white; border-radius: 10px; border: 1px solid #ddd; }
        .detail-area.show { display: block; }
        .card-info { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .card-info .item { padding: 8px 0; border-bottom: 1px solid #eee; }
        .card-info .item strong { display: inline-block; width: 100px; }
        .btn-group { margin-top: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px 14px; border: 1px solid #ddd; text-align: left; }
        th { background: #3498db; color: white; }
        tr:nth-child(even) { background: #f8f9fa; }
        .all-cards-area { margin-top: 20px; border-top: 2px solid #ddd; padding-top: 20px; }
        .all-cards-area h3 { color: #2c3e50; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>

    <div class="nav-links">
        <a href="<%= ctx %>/card/cardAdd.jsp">新增车卡</a>
        |
        <a href="<%= ctx %>/card/cardQuery.jsp">查询车卡</a>
        |
        <a href="<%= ctx %>/card/cardManage.jsp" class="active">管理车卡</a>
    </div>

    <h1>车卡信息管理</h1>

    <div class="section">
        <h3>🔎 查找要管理的车卡</h3>
        <div class="form-group">
            <label>卡号：</label>
            <input type="text" id="queryCardId" placeholder="请输入卡号" style="width:250px;">
            <button class="btn btn-primary" onclick="queryCard()">查询</button>
        </div>
        <div id="queryResult"></div>
    </div>

    <div id="cardDetail" class="detail-area">
        <h3>📋 车卡信息</h3>
        <div class="card-info">
            <div class="item"><strong>卡号：</strong> <span id="dCardId"></span></div>
            <div class="item"><strong>车牌号：</strong> <span id="dPlate"></span></div>
            <div class="item"><strong>车主姓名：</strong> <span id="dName"></span></div>
            <div class="item"><strong>联系电话：</strong> <span id="dPhone"></span></div>
        </div>

        <hr>
        <h4>更新信息</h4>
        <div class="form-group">
            <label>车牌号：</label>
            <input type="text" id="editPlate" style="width:250px;">
        </div>
        <div class="form-group">
            <label>车主姓名：</label>
            <input type="text" id="editName" style="width:250px;">
        </div>
        <div class="form-group">
            <label>联系电话：</label>
            <input type="text" id="editPhone" style="width:250px;">
        </div>

        <div class="btn-group">
            <button class="btn btn-warning" onclick="updateCard()">更新</button>
            <button class="btn btn-danger" onclick="deleteCard()">删除</button>
        </div>
        <div id="actionResult"></div>
    </div>

    <!-- ========== 显示所有车卡 ========== -->
    <div class="all-cards-area">
        <h3>📋 全部车卡</h3>
        <button class="btn btn-success" onclick="loadAllCards()">显示全部车卡</button>
        <div id="allCardsResult" style="margin-top:15px;"></div>
    </div>
</div>

<script>
    let currentCardId = '';

    function queryCard() {
        const cardId = document.getElementById('queryCardId').value.trim();
        if (!cardId) {
            document.getElementById('queryResult').innerHTML =
                '<div class="msg msg-error">❌ 请输入卡号</div>';
            return;
        }

        fetch('<%= ctx %>/card?action=query&cardId=' + encodeURIComponent(cardId))
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('queryResult');
                if (data.code === 200) {
                    const c = data.data;
                    currentCardId = c.卡号;
                    resultDiv.innerHTML = '<div class="msg msg-success">✅ 已找到车卡： ' + c.卡号 + '</div>';

                    document.getElementById('dCardId').textContent = c.卡号;
                    document.getElementById('dPlate').textContent = c.车牌号;
                    document.getElementById('dName').textContent = c.车主姓名;
                    document.getElementById('dPhone').textContent = c.联系电话;

                    document.getElementById('editPlate').value = c.车牌号;
                    document.getElementById('editName').value = c.车主姓名;
                    document.getElementById('editPhone').value = c.联系电话;

                    document.getElementById('cardDetail').className = 'detail-area show';
                    document.getElementById('actionResult').innerHTML = '';
                } else {
                    resultDiv.innerHTML = '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                    document.getElementById('cardDetail').className = 'detail-area';
                }
            })
            .catch(err => {
                document.getElementById('queryResult').innerHTML =
                    '<div class="msg msg-error">❌ 服务器错误： ' + err.message + '</div>';
            });
    }

    function updateCard() {
        const plate = document.getElementById('editPlate').value.trim();
        const name = document.getElementById('editName').value.trim();
        const phone = document.getElementById('editPhone').value.trim();

        if (!plate || !name || !phone) {
            alert('请填写所有字段');
            return;
        }

        fetch('<%= ctx %>/card?action=update&cardId=' + encodeURIComponent(currentCardId) +
              '&plate=' + encodeURIComponent(plate) +
              '&name=' + encodeURIComponent(name) +
              '&phone=' + encodeURIComponent(phone))
            .then(res => res.json())
            .then(data => {
                const div = document.getElementById('actionResult');
                const cls = data.code === 200 ? 'msg-success' : 'msg-error';
                div.innerHTML = '<div class="msg ' + cls + '">' + data.msg + '</div>';
                if (data.code === 200) {
                    document.getElementById('dPlate').textContent = plate;
                    document.getElementById('dName').textContent = name;
                    document.getElementById('dPhone').textContent = phone;
                }
            });
    }

    function deleteCard() {
        if (!confirm('⚠️ 确定要删除车卡： ' + currentCardId + '?\n此操作不可撤销！')) {
            return;
        }

        fetch('<%= ctx %>/card?action=delete&cardId=' + encodeURIComponent(currentCardId))
            .then(res => res.json())
            .then(data => {
                const div = document.getElementById('actionResult');
                const cls = data.code === 200 ? 'msg-success' : 'msg-error';
                div.innerHTML = '<div class="msg ' + cls + '">' + data.msg + '</div>';
                if (data.code === 200) {
                    document.getElementById('cardDetail').className = 'detail-area';
                    document.getElementById('queryResult').innerHTML =
                        '<div class="msg msg-success">✅ 车卡 ' + currentCardId + ' 已删除</div>';
                    document.getElementById('queryCardId').value = '';
                    currentCardId = '';
                }
            });
    }

    function loadAllCards() {
        const div = document.getElementById('allCardsResult');
        div.innerHTML = '<div class="msg msg-info">⏳ 正在加载...</div>';

        fetch('<%= ctx %>/card?action=list')
            .then(res => res.json())
            .then(data => {
                if (data.code === 200 && data.data) {
                    const cards = data.data;
                    if (cards.length === 0) {
                        div.innerHTML = '<div class="msg msg-info">ℹ️ 暂无车卡</div>';
                        return;
                    }
                    let html = '<table>';
                    html += '<thead><tr><th>卡号</th><th>车牌号</th><th>车主姓名</th><th>联系电话</th></tr></thead><tbody>';
                    for (var i = 0; i < cards.length; i++) {
                        var c = cards[i];
                        html += '<tr><td><strong>' + c.卡号 + '</strong></td><td>' + c.车牌号 + '</td><td>' + c.车主姓名 + '</td><td>' + c.联系电话 + '</td></tr>';
                    }
                    html += '</tbody></table>';
                    html += '<div style="margin-top:10px; color:#888; font-size:13px;">总数： <strong>' + cards.length + '</strong> 张车卡</div>';
                    div.innerHTML = html;
                } else {
                    div.innerHTML = '<div class="msg msg-error">❌ 加载车卡失败： ' + data.msg + '</div>';
                }
            })
            .catch(err => {
                div.innerHTML = '<div class="msg msg-error">❌ 服务器错误： ' + err.message + '</div>';
            });
    }

    document.getElementById('queryCardId').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') queryCard();
    });
</script>
</body>
</html>