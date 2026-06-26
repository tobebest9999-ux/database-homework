<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>车位管理</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 850px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 140px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 250px; font-size: 14px; }
        .form-group input[readonly] { background: #e9ecef; }
        .btn { padding: 10px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.3s; margin: 5px 5px 5px 0; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-warning { background: #f39c12; color: white; }
        .btn-warning:hover { background: #e67e22; }
        .msg { padding: 12px 18px; border-radius: 8px; margin: 10px 0; }
        .msg-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .msg-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .msg-info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .result-area { margin-top: 15px; padding: 15px; background: white; border-radius: 8px; border: 1px solid #ddd; display: none; }
        .result-area.show { display: block; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .info-grid .item { padding: 6px 0; border-bottom: 1px solid #eee; }
        .info-grid .item strong { display: inline-block; width: 100px; }
        .hint { font-size: 13px; color: #888; margin-top: 5px; }
        .fixed-only { background: #fff3cd; padding: 10px 15px; border-radius: 6px; border: 1px solid #ffc107; margin-bottom: 15px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/parking/parkingManage.jsp" class="back">返回停车管理</a>
    <h1>车位管理</h1>
    <hr>

    <div class="fixed-only">
        提示：本页用于维护 A 编号车位的关联卡号。只有空闲车位可以修改。
    </div>

    <div class="section">
        <h3>🔎 查询车位</h3>
        <div class="form-group">
            <label>车位编号：</label>
            <input type="text" id="spaceId" placeholder="例如：A-00" style="width:250px;">
            <button class="btn btn-primary" onclick="querySpace()">查询</button>
        </div>
        <div id="queryResult"></div>
    </div>

    <div id="detailArea" class="result-area">
        <h3>📋 车位信息</h3>
        <div class="info-grid">
            <div class="item"><strong>车位编号：</strong> <span id="dSpaceId"></span></div>
            <div class="item"><strong>类型：</strong> <span id="dType"></span></div>
            <div class="item"><strong>状态：</strong> <span id="dStatus"></span></div>
            <div class="item"><strong>当前车牌号：</strong> <span id="dPlate"></span></div>
            <div class="item"><strong>关联卡号：</strong> <span id="dCard"></span></div>
        </div>
        <hr>
        <div id="editArea">
            <h4>更新关联卡号</h4>
            <div class="form-group">
                <label>新关联卡号：</label>
                <input type="text" id="newCardId" placeholder="请输入要关联的卡号" style="width:250px;">
            </div>
            <button class="btn btn-warning" onclick="updateSpace()">保存修改</button>
            <div id="updateResult"></div>
        </div>
    </div>
</div>

<script>
    let currentSpaceId = '';

    function querySpace() {
        const spaceId = document.getElementById('spaceId').value.trim().toUpperCase();
        if (!spaceId) {
            document.getElementById('queryResult').innerHTML =
                '<div class="msg msg-error">❌ 请输入车位编号</div>';
            return;
        }

        if (!spaceId.startsWith('A-')) {
            document.getElementById('queryResult').innerHTML =
                '<div class="msg msg-error">❌ 本页只管理 A 编号车位</div>';
            document.getElementById('detailArea').className = 'result-area';
            return;
        }

        fetch('<%= ctx %>/parking?action=getSpace&spaceId=' + encodeURIComponent(spaceId))
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('queryResult');
                if (data.code === 200) {
                    const s = data.data;
                    currentSpaceId = s.车位编号;
                    resultDiv.innerHTML = '<div class="msg msg-success">✅ 已找到车位： ' + s.车位编号 + '</div>';

                    document.getElementById('dSpaceId').textContent = s.车位编号;
                    document.getElementById('dType').textContent = '停车位';
                    document.getElementById('dStatus').textContent = s.车位状态;
                    document.getElementById('dPlate').textContent = s.当前停放车牌 || '无';
                    document.getElementById('dCard').textContent = s.固定车位卡号 || '无';

                    if (s.车位状态 === '空闲') {
                        document.getElementById('editArea').style.display = 'block';
                        document.getElementById('updateResult').innerHTML = '';
                        document.getElementById('newCardId').value = s.固定车位卡号 || '';
                    } else {
                        document.getElementById('editArea').style.display = 'block';
                        document.getElementById('updateResult').innerHTML =
                            '<div class="msg msg-error">❌ 该车位已占用，占用期间不能修改。</div>';
                    }

                    document.getElementById('detailArea').className = 'result-area show';
                } else {
                    resultDiv.innerHTML = '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                    document.getElementById('detailArea').className = 'result-area';
                }
            })
            .catch(err => {
                document.getElementById('queryResult').innerHTML =
                    '<div class="msg msg-error">❌ 服务器错误： ' + err.message + '</div>';
            });
    }

    function updateSpace() {
        const newCardId = document.getElementById('newCardId').value.trim();
        if (!newCardId) {
            document.getElementById('updateResult').innerHTML =
                '<div class="msg msg-error">❌ 请输入卡号</div>';
            return;
        }

        fetch('<%= ctx %>/parking?action=updateFixedCard&spaceId=' + encodeURIComponent(currentSpaceId) +
              '&cardId=' + encodeURIComponent(newCardId))
            .then(res => res.json())
            .then(data => {
                const div = document.getElementById('updateResult');
                if (data.code === 200) {
                    div.innerHTML = '<div class="msg msg-success">✅ ' + data.msg + '</div>';
                    document.getElementById('dCard').textContent = newCardId;
                } else {
                    div.innerHTML = '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                }
            });
    }

    document.getElementById('spaceId').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') querySpace();
    });
</script>
</body>
</html>
