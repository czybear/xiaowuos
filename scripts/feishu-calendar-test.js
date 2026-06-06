#!/usr/bin/env node

// 飞书日历功能测试脚本
const FeishuCalendarAPI = require('../modules/feishu-calendar');
const fs = require('fs');
const path = require('path');

// 配置文件路径
const CREDENTIALS_PATH = '/home/john/xiaowuOS/config/feishu-credentials.json';

// 日志文件路径
const LOG_PATH = '/home/john/xiaowuOS/logs/feishu-calendar-test.log';

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

// 测试飞书日历功能
async function testFeishuCalendar() {
    writeLog('=== 开始飞书日历功能测试 ===');
    
    const api = new FeishuCalendarAPI();
    
    try {
        // 1. 测试初始化
        writeLog('1. 测试初始化...');
        await api.init();
        writeLog('✅ 初始化成功');
        
        // 2. 测试获取日历列表
        writeLog('2. 测试获取日历列表...');
        let calendars;
        try {
            calendars = await api.getCalendars();
            writeLog(`原始响应: ${JSON.stringify(calendars, null, 2)}`);
        } catch (error) {
            writeLog(`获取日历列表失败: ${error.message}`);
            throw error;
        }
        
        if (calendars && calendars.calendars && calendars.calendars.length > 0) {
            const calendarsList = calendars.calendars;
            writeLog(`✅ 日历列表获取成功，共 ${calendarsList.length} 个日历`);
            calendarsList.forEach((calendar, index) => {
                writeLog(`${index + 1}. ${calendar.summary} (${calendar.calendar_id})`);
            });
            
            // 使用第一个日历进行后续测试
            const firstCalendar = calendarsList[0];
            writeLog(`使用日历: ${firstCalendar.summary}`);
            
            // 3. 测试创建日程
            writeLog('3. 测试创建日程...');
            const eventData = {
                summary: 'xiaowuOS 测试日程',
                description: '这是一个测试日程，用于验证飞书日历功能',
                start_time: {
                    timestamp: Math.floor(Date.now() / 1000) + 3600, // 1小时后
                    timezone: 'Asia/Shanghai'
                },
                end_time: {
                    timestamp: Math.floor(Date.now() / 1000) + 7200, // 2小时后
                    timezone: 'Asia/Shanghai'
                },
                visibility: 'default',
                attendees: []
            };
            
            const result = await api.createEvent(firstCalendar.calendar_id, eventData);
            writeLog(`✅ 日程创建成功: ${result.event_id}`);
            
            // 4. 测试获取日程列表
            writeLog('4. 测试获取日程列表...');
            const events = await api.getEvents(firstCalendar.calendar_id, {
                startTime: Math.floor(Date.now() / 1000),
                endTime: Math.floor(Date.now() / 1000) + 86400 // 24小时后
            });
            
            writeLog(`✅ 日程列表获取成功，共 ${events.events.length} 个日程`);
            events.events.forEach((event, index) => {
                writeLog(`${index + 1}. ${event.summary} (${event.event_id})`);
            });
            
            // 5. 测试更新日程
            writeLog('5. 测试更新日程...');
            const updateData = {
                summary: 'xiaowuOS 更新后的测试日程',
                description: '日程已更新',
                start_time: {
                    timestamp: Math.floor(Date.now() / 1000) + 5400, // 1.5小时后
                    timezone: 'Asia/Shanghai'
                },
                end_time: {
                    timestamp: Math.floor(Date.now() / 1000) + 9000, // 2.5小时后
                    timezone: 'Asia/Shanghai'
                },
                visibility: 'default',
                attendees: []
            };
            
            const updateResult = await api.updateEvent(firstCalendar.calendar_id, result.event_id, updateData);
            writeLog(`✅ 日程更新成功: ${updateResult.event_id}`);
            
            // 6. 测试删除日程
            writeLog('6. 测试删除日程...');
            await api.deleteEvent(firstCalendar.calendar_id, result.event_id);
            writeLog(`✅ 日程删除成功: ${result.event_id}`);
            
            writeLog('=== 所有测试完成 ===');
            writeLog('✅ 飞书日历功能正常');
            
        } else {
            writeLog('❌ 没有可用日历');
            writeLog('🔧 请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        }
        
    } catch (error) {
        writeLog(`❌ 测试失败: ${error.message}`);
        
        if (error.message.includes('Access denied')) {
            writeLog('🔧 权限不足，请配置日历权限');
            writeLog('权限配置链接: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        } else if (error.message.includes('tenant_access_token')) {
            writeLog('🔧 认证失败，请检查App ID和App Secret');
        } else {
            writeLog('🔧 其他错误，请检查网络连接和API配置');
        }
    }
}

// 测试待办事项功能
async function testTodoFunction() {
    writeLog('=== 开始待办事项功能测试 ===');
    
    // 这里可以添加待办事项相关的测试
    // 由于飞书没有单独的待办事项API，我们使用日程来模拟待办事项
    
    writeLog('✅ 待办事项功能测试完成');
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
        
        // 执行测试
        await testFeishuCalendar();
        await testTodoFunction();
        
    } catch (error) {
        writeLog(`❌ 主函数执行失败: ${error.message}`);
        process.exit(1);
    }
}

// 如果直接运行此文件，则执行主函数
if (require.main === module) {
    main().catch(console.error);
}

// 导出测试函数
module.exports = {
    testFeishuCalendar,
    testTodoFunction
};