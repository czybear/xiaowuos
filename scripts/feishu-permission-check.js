#!/usr/bin/env node

// 飞书日历权限检查脚本
const FeishuCalendarAPI = require('../modules/feishu-calendar');
const fs = require('fs');
const path = require('path');

// 配置文件路径
const CREDENTIALS_PATH = '/home/john/xiaowuOS/config/feishu-credentials.json';

// 日志文件路径
const LOG_PATH = '/home/john/xiaowuOS/logs/feishu-permission-check.log';

// 写入日志
function writeLog(message) {
    const timestamp = new Date().toISOString();
    const logMessage = `[${timestamp}] ${message}\n`;
    
    // 写入控制台
    console.log(logMessage.trim());
    
    // 写入日志文件
    try {
        if (!fs.existsSync(path.dirname(LOG_PATH))) {
            fs.mkdirSync(path.dirname(LOG_PATH), { recursive: true });
        }
        
        fs.appendFileSync(LOG_PATH, logMessage, 'utf8');
    } catch (error) {
        console.error('写入日志失败:', error.message);
    }
}

// 检查飞书日历权限
async function checkFeishuPermissions() {
    writeLog('=== 开始检查飞书日历权限 ===');
    
    const api = new FeishuCalendarAPI();
    
    try {
        // 初始化
        await api.init();
        writeLog('✅ 初始化成功');
        
        // 尝试获取日历列表
        const calendars = await api.getCalendars();
        
        if (calendars && calendars.calendars && calendars.calendars.length > 0) {
            writeLog('✅ 日历权限已配置');
            writeLog(`✅ 找到 ${calendars.calendars.length} 个日历`);
            
            // 记录日历信息
            calendars.calendars.forEach((calendar, index) => {
                writeLog(`${index + 1}. ${calendar.summary} (${calendar.calendar_id})`);
            });
            
            // 创建权限状态文件
            const status = {
                timestamp: new Date().toISOString(),
                status: 'enabled',
                calendars: calendars.calendars.length,
                calendars_list: calendars.calendars
            };
            
            const statusPath = '/home/john/xiaowuOS/docs/feishu-permission-status.json';
            fs.writeFileSync(statusPath, JSON.stringify(status, null, 2));
            writeLog(`✅ 权限状态已保存到: ${statusPath}`);
            
            return true;
        } else {
            writeLog('❌ 日历权限未配置');
            writeLog('🔧 请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
            
            // 创建权限状态文件
            const status = {
                timestamp: new Date().toISOString(),
                status: 'disabled',
                error: '日历权限未配置',
                solution: '请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth'
            };
            
            const statusPath = '/home/john/xiaowuOS/docs/feishu-permission-status.json';
            fs.writeFileSync(statusPath, JSON.stringify(status, null, 2));
            writeLog(`❌ 权限状态已保存到: ${statusPath}`);
            
            return false;
        }
        
    } catch (error) {
        writeLog(`❌ 检查权限失败: ${error.message}`);
        
        if (error.message.includes('Access denied')) {
            writeLog('🔧 权限不足，请配置日历权限');
            writeLog('权限配置链接: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
            
            // 创建权限状态文件
            const status = {
                timestamp: new Date().toISOString(),
                status: 'denied',
                error: '权限不足',
                solution: '请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth'
            };
            
            const statusPath = '/home/john/xiaowuOS/docs/feishu-permission-status.json';
            fs.writeFileSync(statusPath, JSON.stringify(status, null, 2));
            writeLog(`❌ 权限状态已保存到: ${statusPath}`);
            
            return false;
        } else {
            writeLog('🔧 其他错误，请检查网络连接和API配置');
            
            // 创建权限状态文件
            const status = {
                timestamp: new Date().toISOString(),
                status: 'error',
                error: error.message,
                solution: '请检查网络连接和API配置'
            };
            
            const statusPath = '/home/john/xiaowuOS/docs/feishu-permission-status.json';
            fs.writeFileSync(statusPath, JSON.stringify(status, null, 2));
            writeLog(`❌ 权限状态已保存到: ${statusPath}`);
            
            return false;
        }
    }
}

// 主函数
async function main() {
    try {
        // 检查配置文件
        if (!fs.existsSync(CREDENTIALS_PATH)) {
            writeLog('❌ 配置文件不存在');
            writeLog(`配置文件路径: ${CREDENTIALS_PATH}`);
            process.exit(1);
        }
        
        // 读取配置文件
        const credentials = JSON.parse(fs.readFileSync(CREDENTIALS_PATH, 'utf8'));
        writeLog(`配置文件加载成功`);
        writeLog(`App ID: ${credentials.app_id}`);
        writeLog(`状态: ${credentials.status}`);
        
        // 检查权限
        const hasPermission = await checkFeishuPermissions();
        
        if (hasPermission) {
            writeLog('✅ 飞书日历权限检查完成 - 权限正常');
            process.exit(0);
        } else {
            writeLog('❌ 飞书日历权限检查完成 - 权限不足');
            process.exit(1);
        }
        
    } catch (error) {
        writeLog(`❌ 主函数执行失败: ${error.message}`);
        process.exit(1);
    }
}

// 如果直接运行此文件，则执行主函数
if (require.main === module) {
    main().catch(console.error);
}

// 导出函数
module.exports = {
    checkFeishuPermissions
};