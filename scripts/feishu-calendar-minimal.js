#!/usr/bin/env node

// 飞书日历最小化脚本
const FeishuCalendarAPI = require('../modules/feishu-calendar');
const fs = require('fs');

// 配置文件路径
const CREDENTIALS_PATH = '/home/john/xiaowuOS/config/feishu-credentials.json';

// 读取配置文件
function readCredentials() {
    try {
        if (fs.existsSync(CREDENTIALS_PATH)) {
            const data = fs.readFileSync(CREDENTIALS_PATH, 'utf8');
            return JSON.parse(data);
        }
    } catch (error) {
        console.error('读取配置文件失败:', error.message);
    }
    return null;
}

// 获取今日日历
async function getTodayEvents() {
    console.log('=== 获取今日飞书日历 ===');
    console.log(`时间: ${new Date().toLocaleString('zh-CN')}`);
    console.log('');
    
    const api = new FeishuCalendarAPI();
    
    try {
        // 初始化
        await api.init();
        console.log('✅ 初始化成功');
        
        // 获取日历列表
        const calendars = await api.getCalendars();
        
        if (calendars && calendars.calendars && calendars.calendars.length > 0) {
            const today = new Date();
            const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
            const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
            
            const calendarsList = calendars.calendars;
            console.log(`✅ 找到 ${calendarsList.length} 个日历`);
            
            for (const calendar of calendarsList) {
                console.log(`\n--- 日历: ${calendar.summary} ---`);
                
                try {
                    // 获取今日日程
                    const events = await api.getEvents(calendar.calendar_id, {
                        startTime: Math.floor(startOfDay.getTime() / 1000),
                        endTime: Math.floor(endOfDay.getTime() / 1000),
                        pageSize: 50
                    });
                    
                    if (events.events && events.events.length > 0) {
                        console.log(`今日日程 (${events.events.length} 个):`);
                        events.events.forEach((event, index) => {
                            const startTime = new Date(event.start_time.timestamp * 1000);
                            const endTime = new Date(event.end_time.timestamp * 1000);
                            console.log(`${index + 1}. ${event.summary}`);
                            console.log(`   时间: ${startTime.toLocaleString('zh-CN')} - ${endTime.toLocaleString('zh-CN')}`);
                            if (event.description) {
                                console.log(`   描述: ${event.description}`);
                            }
                            console.log('');
                        });
                    } else {
                        console.log('今日无日程');
                    }
                } catch (error) {
                    console.log(`❌ 获取日程失败: ${error.message}`);
                }
            }
        } else {
            console.log('❌ 没有可用日历');
            console.log('🔧 请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        }
        
    } catch (error) {
        console.log(`❌ 获取日历失败: ${error.message}`);
        
        if (error.message.includes('Access denied')) {
            console.log('🔧 权限不足，请配置日历权限');
            console.log('权限配置链接: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        } else {
            console.log('🔧 其他错误，请检查网络连接和API配置');
        }
    }
}

// 创建测试待办/日程
async function createTestTodo() {
    console.log('=== 创建测试待办/日程 ===');
    console.log(`时间: ${new Date().toLocaleString('zh-CN')}`);
    console.log('');
    
    const api = new FeishuCalendarAPI();
    
    try {
        // 初始化
        await api.init();
        console.log('✅ 初始化成功');
        
        // 获取日历列表
        const calendars = await api.getCalendars();
        
        if (calendars && calendars.calendars && calendars.calendars.length > 0) {
            const calendarsList = calendars.calendars;
            console.log(`✅ 找到 ${calendarsList.length} 个日历`);
            
            // 使用第一个日历
            const firstCalendar = calendarsList[0];
            console.log(`使用日历: ${firstCalendar.summary}`);
            
            // 创建测试日程
            const eventData = {
                summary: 'xiaowuOS 测试待办',
                description: '这是一个测试待办/日程，用于验证飞书日历功能',
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
            console.log('✅ 测试待办/日程创建成功');
            console.log(`ID: ${result.event_id}`);
            console.log(`标题: ${result.summary}`);
            console.log(`描述: ${result.description}`);
            console.log(`开始时间: ${new Date(result.start_time.timestamp * 1000).toLocaleString('zh-CN')}`);
            console.log(`结束时间: ${new Date(result.end_time.timestamp * 1000).toLocaleString('zh-CN')}`);
            
        } else {
            console.log('❌ 没有可用日历');
            console.log('🔧 请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        }
        
    } catch (error) {
        console.log(`❌ 创建待办/日程失败: ${error.message}`);
        
        if (error.message.includes('Access denied')) {
            console.log('🔧 权限不足，请配置日历权限');
            console.log('权限配置链接: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        } else {
            console.log('🔧 其他错误，请检查网络连接和API配置');
        }
    }
}

// 查询待办事项
async function queryTodos() {
    console.log('=== 查询待办事项 ===');
    console.log(`时间: ${new Date().toLocaleString('zh-CN')}`);
    console.log('');
    
    const api = new FeishuCalendarAPI();
    
    try {
        // 初始化
        await api.init();
        console.log('✅ 初始化成功');
        
        // 获取日历列表
        const calendars = await api.getCalendars();
        
        if (calendars && calendars.calendars && calendars.calendars.length > 0) {
            const calendarsList = calendars.calendars;
            console.log(`✅ 找到 ${calendarsList.length} 个日历`);
            
            // 查询未来7天的日程
            const today = new Date();
            const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000);
            
            for (const calendar of calendarsList) {
                console.log(`\n--- 日历: ${calendar.summary} ---`);
                
                try {
                    // 获取未来7天的日程
                    const events = await api.getEvents(calendar.calendar_id, {
                        startTime: Math.floor(today.getTime() / 1000),
                        endTime: Math.floor(nextWeek.getTime() / 1000),
                        pageSize: 100
                    });
                    
                    if (events.events && events.events.length > 0) {
                        console.log(`未来7天日程 (${events.events.length} 个):`);
                        events.events.forEach((event, index) => {
                            const startTime = new Date(event.start_time.timestamp * 1000);
                            const endTime = new Date(event.end_time.timestamp * 1000);
                            console.log(`${index + 1}. ${event.summary}`);
                            console.log(`   时间: ${startTime.toLocaleString('zh-CN')} - ${endTime.toLocaleString('zh-CN')}`);
                            if (event.description) {
                                console.log(`   描述: ${event.description}`);
                            }
                            console.log('');
                        });
                    } else {
                        console.log('未来7天无日程');
                    }
                } catch (error) {
                    console.log(`❌ 获取日程失败: ${error.message}`);
                }
            }
        } else {
            console.log('❌ 没有可用日历');
            console.log('🔧 请配置日历权限: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        }
        
    } catch (error) {
        console.log(`❌ 查询待办事项失败: ${error.message}`);
        
        if (error.message.includes('Access denied')) {
            console.log('🔧 权限不足，请配置日历权限');
            console.log('权限配置链接: https://open.feishu.cn/app/cli_a926c6c775f8dcd2/auth');
        } else {
            console.log('🔧 其他错误，请检查网络连接和API配置');
        }
    }
}

// 主函数
async function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.log('用法:');
        console.log('  node feishu-calendar-minimal.js today    # 获取今日日历');
        console.log('  node feishu-calendar-minimal.js create   # 创建测试待办/日程');
        console.log('  node feishu-calendar-minimal.js query    # 查询待办事项');
        console.log('  node feishu-calendar-minimal.js test     # 运行所有测试');
        return;
    }
    
    const command = args[0];
    
    try {
        switch (command) {
            case 'today':
                await getTodayEvents();
                break;
            case 'create':
                await createTestTodo();
                break;
            case 'query':
                await queryTodos();
                break;
            case 'test':
                await getTodayEvents();
                await createTestTodo();
                await queryTodos();
                break;
            default:
                console.log(`未知命令: ${command}`);
                console.log('支持的命令: today, create, query, test');
        }
    } catch (error) {
        console.log(`❌ 执行失败: ${error.message}`);
        process.exit(1);
    }
}

// 如果直接运行此文件，则执行主函数
if (require.main === module) {
    main().catch(console.error);
}

// 导出函数
module.exports = {
    getTodayEvents,
    createTestTodo,
    queryTodos
};