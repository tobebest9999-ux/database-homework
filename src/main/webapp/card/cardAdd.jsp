<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>车卡办理</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 700px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; }
        .back { display: inline-block; margin-bottom: 15px; color: #3498db; text-decoration: none; font-weight: bold; }
        .nav-links { text-align: center; padding: 12px; background: #ecf0f1; border-radius: 10px; margin-bottom: 25px; }
        .nav-links a { color: #3498db; font-weight: bold; margin: 0 15px; text-decoration: none; }
        .nav-links a:hover { text-decoration: underline; }
        .nav-links a.active { color: #2c3e50; text-decoration: underline; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 120px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 300px; font-size: 14px; }
        .btn { padding: 12px 35px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; transition: all 0.3s; }
        .btn-success { background: #2ecc71; color: white; }
        .btn-success:hover { background: #27ae60; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-danger:hover { background: #c0392b; }
        .msg { padding: 12px 18px; border-radius: 8px; margin-top: 15px; }
        .msg-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .msg-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .hint { font-size: 13px; color: #888; margin-top: 5px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/index.jsp" class="back">返回首页</a>

    <div class="nav-links">
        <a href="<%= ctx %>/card/cardAdd.jsp" class="active">新增车卡</a>
        |
        <a href="<%= ctx %>/card/cardQuery.jsp">查询车卡</a>
        |
        <a href="<%= ctx %>/card/cardManage.jsp">管理车卡</a>
    </div>

    <h1>新增车卡办理</h1>
    <hr>

    <form id="addForm">
        <div class="form-group">
            <label>卡号：</label>
            <input type="text" id="cardId" required placeholder="例如：C1000003">
            <div class="hint">唯一车卡编号</div>
        </div>
        <div class="form-group">
            <label>车牌号：</label>
            <input type="text" id="plate" required placeholder="例如：沪C33333">
        </div>
        <div class="form-group">
            <label>车主姓名：</label>
            <input type="text" id="name" required placeholder="例如：王五">
        </div>
        <div class="form-group">
            <label>联系电话：</label>
            <input type="text" id="phone" required placeholder="例如：13800005555">
        </div>
        <button type="submit" class="btn btn-success">添加车卡</button>
        <button type="reset" class="btn btn-danger" style="margin-left:10px;">清空</button>
    </form>

    <div id="result"></div>
</div>

<script>
    document.getElementById('addForm').addEventListener('submit', function(e) {
        e.preventDefault();
        const cardId = document.getElementById('cardId').value.trim();
        const plate = document.getElementById('plate').value.trim();
        const name = document.getElementById('name').value.trim();
        const phone = document.getElementById('phone').value.trim();

        if (!cardId || !plate || !name || !phone) {
            alert('请填写所有字段');
            return;
        }

        fetch('<%= ctx %>/card?action=add&cardId=' + encodeURIComponent(cardId) +
              '&plate=' + encodeURIComponent(plate) +
              '&name=' + encodeURIComponent(name) +
              '&phone=' + encodeURIComponent(phone))
            .then(res => res.json())
            .then(data => {
                const div = document.getElementById('result');
                const cls = data.code === 200 ? 'msg-success' : 'msg-error';
                div.innerHTML = '<div class="msg ' + cls + '">' + data.msg + '</div>';
                if (data.code === 200) {
                    document.getElementById('addForm').reset();
                }
            })
            .catch(err => {
                document.getElementById('result').innerHTML =
                    '<div class="msg msg-error">❌ 服务器错误： ' + err.message + '</div>';
            });
    });
</script>
</body>
</html>