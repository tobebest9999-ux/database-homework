<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>车辆入库/出库</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f0f5f9; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; background: white; border-radius: 20px; padding: 30px; box-shadow: 0 10px 40px rgba(0,0,0,0.1); }
        h1 { text-align: center; color: #2c3e50; }
        .back { display: inline-block; margin-bottom: 20px; color: #3498db; text-decoration: none; font-weight: bold; }
        .section { background: #f8f9fa; border-radius: 12px; padding: 25px; margin-top: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: inline-block; width: 120px; font-weight: bold; }
        .form-group input { padding: 10px 14px; border: 1px solid #ddd; border-radius: 6px; width: 250px; font-size: 14px; }
        .btn { padding: 10px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 15px; transition: all 0.3s; margin: 5px 5px 5px 0; }
        .btn-primary { background: #3498db; color: white; }
        .btn-primary:hover { background: #2980b9; }
        .btn-success { background: #2ecc71; color: white; }
        .btn-success:hover { background: #27ae60; }
        .btn-danger { background: #e74c3c; color: white; }
        .btn-danger:hover { background: #c0392b; }
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
        .info-grid .item strong { display: inline-block; width: 120px; }
        .btn-group { margin-top: 15px; }
    </style>
</head>
<body>
<div class="container">
    <a href="<%= ctx %>/parking/parkingManage.jsp" class="back">返回停车管理</a>
    <h1>车辆入库/出库</h1>

    <div class="section">
        <h3>输入卡号</h3>
        <div class="form-group">
            <label>卡号：</label>
            <input type="text" id="cardId" placeholder="请输入卡号" style="width:250px;">
            <button class="btn btn-primary" onclick="checkStatus()">🔍 查询状态</button>
        </div>
        <div id="statusResult"></div>
    </div>

    <div id="detailArea" class="result-area">
        <div id="detailContent"></div>
        <div id="actionArea"></div>
    </div>
</div>

<script>
    let currentCardId = '';
    let currentRecordId = '';
    let currentPlate = '';
    let currentSpaceId = '';

    function checkStatus() {
        const cardId = document.getElementById('cardId').value.trim();
        if (!cardId) {
            document.getElementById('statusResult').innerHTML =
                '<div class="msg msg-error">❌ 请输入卡号</div>';
            return;
        }
        currentCardId = cardId;

        fetch('<%= ctx %>/parking?action=getActive&cardId=' + encodeURIComponent(cardId))
            .then(res => res.json())
            .then(data => {
                const area = document.getElementById('detailArea');
                const content = document.getElementById('detailContent');
                const action = document.getElementById('actionArea');

                if (data.code === 200) {
                    const record = data.data;
                    currentRecordId = record["记录编号"];
                    currentPlate = record["车牌号"] || '未知';
                    currentSpaceId = record["停放车位编号"];

                    fetch('<%= ctx %>/charge?action=getChargeInfo&cardId=' + encodeURIComponent(cardId))
                        .then(res => res.json())
                        .then(chargeData => {
                            if (chargeData.code === 200) {
                                const info = chargeData.data;
                                content.innerHTML = `
                                    <h3>📋 车辆信息</h3>
                                    <div class="info-grid">
                                        <div class="item"><strong>卡号：</strong> ${info.cardId}</div>
                                        <div class="item"><strong>车位编号：</strong> ${info.spaceId}</div>
                                        <div class="item"><strong>入库时间：</strong> ${info.entryTime}</div>
                                        <div class="item"><strong>当前时间：</strong> ${info.currentTime}</div>
                                        <div class="item"><strong>停车时长：</strong> ${info.durationDisplay}</div>
                                        <div class="item"><strong>收费金额：</strong> ¥${info.feeDisplay}</div>
                                    </div>
                                `;
                                action.innerHTML = `
                                    <div class="btn-group">
                                        <button class="btn btn-success" onclick="doCheckout()">办理出库</button>
                                        <button class="btn btn-danger" onclick="cancelOperation()">取消</button>
                                    </div>
                                    <div id="actionResult"></div>
                                `;
                            } else {
                                content.innerHTML = `<div class="msg msg-error">❌ ${chargeData.msg}</div>`;
                                action.innerHTML = '';
                            }
                            area.className = 'result-area show';
                            document.getElementById('statusResult').innerHTML =
                                '<div class="msg msg-info">ℹ️ 该车卡车辆当前在场</div>';
                        });

                } else {
                    content.innerHTML = `
                        <h3>办理入库</h3>
                        <div class="msg msg-info">ℹ️ ${data.msg}</div>
                        <div class="form-group">
                            <label>车牌号：</label>
                            <input type="text" id="inPlate" placeholder="请输入车牌号" style="width:250px;">
                        </div>
                        <div class="form-group">
                            <label>车位编号：</label>
                            <input type="text" id="inSpace" placeholder="例如：B-00 或 A-00" style="width:250px;">
                        </div>
                        <button class="btn btn-success" onclick="doCheckin()">办理入库</button>
                        <div id="checkinResult"></div>
                    `;
                    action.innerHTML = '';
                    area.className = 'result-area show';
                    document.getElementById('statusResult').innerHTML =
                        '<div class="msg msg-info">ℹ️ 该车卡车辆当前不在场</div>';
                }
            })
            .catch(err => {
                document.getElementById('statusResult').innerHTML =
                    '<div class="msg msg-error">❌ 服务器错误： ' + err.message + '</div>';
            });
    }

    function doCheckout() {
        if (!confirm('确定要办理出库吗？系统将自动计算费用。')) return;

        fetch('<%= ctx %>/charge?action=checkout&recordId=' + encodeURIComponent(currentRecordId))
            .then(res => res.json())
            .then(data => {
                const resultDiv = document.getElementById('actionResult');
                if (data.code === 200) {
                    resultDiv.innerHTML = '<div class="msg msg-success">✅ 出库成功！收费金额已计算。</div>';
                    if (confirm('是否打印发票？')) {
                        showInvoice();
                    }
                    document.getElementById('detailArea').className = 'result-area';
                    document.getElementById('statusResult').innerHTML =
                        '<div class="msg msg-success">✅ 已完成出库，卡号： ' + currentCardId + '</div>';
                } else {
                    resultDiv.innerHTML = '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                }
            });
    }

    function showInvoice() {
        fetch('<%= ctx %>/charge?action=getChargeInfo&cardId=' + encodeURIComponent(currentCardId))
            .then(res => res.json())
            .then(data => {
                if (data.code === 200) {
                    const info = data.data;
                    alert(
                        '═══════════════════════════════\n' +
                        '        停车收费发票\n' +
                        '═══════════════════════════════\n' +
                        '  卡号    : ' + info.cardId + '\n' +
                        '  车位编号   : ' + info.spaceId + '\n' +
                        '  入库时间 : ' + info.entryTime + '\n' +
                        '  出库时间  : ' + info.currentTime + '\n' +
                        '  停车时长   : ' + info.durationDisplay + '\n' +
                        '  收费金额        : ¥' + info.feeDisplay + '\n' +
                        '═══════════════════════════════\n' +
                        '  谢谢使用！'
                    );
                }
            });
    }

    function doCheckin() {
        const plate = document.getElementById('inPlate').value.trim();
        const spaceId = document.getElementById('inSpace').value.trim();

        if (!plate || !spaceId) {
            document.getElementById('checkinResult').innerHTML =
                '<div class="msg msg-error">❌ 请填写所有字段</div>';
            return;
        }

        fetch('<%= ctx %>/parking?action=checkIn&cardId=' + encodeURIComponent(currentCardId) +
              '&spaceId=' + encodeURIComponent(spaceId) +
              '&plate=' + encodeURIComponent(plate))
            .then(res => res.json())
            .then(data => {
                const div = document.getElementById('checkinResult');
                if (data.code === 200) {
                    div.innerHTML = '<div class="msg msg-success">✅ 入库成功！ 记录编号： ' + data.recordId + '</div>';
                    document.getElementById('detailArea').className = 'result-area';
                    document.getElementById('statusResult').innerHTML =
                        '<div class="msg msg-success">✅ 已完成入库，卡号： ' + currentCardId + '</div>';
                } else {
                    div.innerHTML = '<div class="msg msg-error">❌ ' + data.msg + '</div>';
                }
            });
    }

    function cancelOperation() {
        document.getElementById('detailArea').className = 'result-area';
        document.getElementById('statusResult').innerHTML = '';
        document.getElementById('cardId').value = '';
    }

    document.getElementById('cardId').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') checkStatus();
    });
</script>
</body>
</html>
