#!/usr/bin/env node

// 飞书日历测试脚本
const { FeishuCalendar } = require('./feishu-calendar');

async function testCalendarAPI() {
    console.log('=== 飞书日历API测试 ===');
    console.log('');
    
    const calendar = new FeishuCalendar();
    
    try {
        // 1. 测试获取访问令牌
        console.log('1. 测试获取访问令牌...');
        const accessToken = await calendar.getAccessToken();
        console.log('✅ 访问令牌获取成功');
        console.log('令牌:', accessToken.substring(0, 20) + '...');
        console.log('');
        
        // 2. 测试获取日历列表
        console.log('2. 测试获取日历列表...');
        const calendars = await calendar.getCalendars();
        console.log('✅ 日历列表获取成功');
        console.log('日历数量:', calendars.length);
        
        if (calendars.length > 0) {
            console.log('');
            console.log('可用日历:');
            calendars.forEach((cal, index) => {
                console.log(`${index + 1}. ${cal.summary} (${cal.calendar_id})`);
                console.log(`   权限: ${cal.permission}`);
                console.log(`   所有者: ${cal.owner?.name || '未知'}`);
            });
        }
        console.log('');
        
        // 3. 测试创建日程
        if (calendars.length > 0) {
            console.log('3. 测试创建日程...');
            const calendarId = calendars[0].calendar_id;
            const eventData = {
                summary: '测试日程',
                startTime: {
                    timestamp: Math.floor(Date.now() / 1000),
                    timezone: 'Asia/Shanghai'
                },
                endTime: {
                    timestamp: Math.floor(Date.now() / 1000) + 3600,
                    timezone: 'Asia/Shanghai'
                },
                description: '这是一个测试日程',
                location: '会议室',
                attendees: [],
                visibility: 'default',
                reminder: []
            };
            
            const event = await calendar.createEvent(calendarId, eventData);
            console.log('✅ 日程创建成功');
            console.log('日程ID:', event.event_id);
            console.log('日程标题:', event.summary);
            console.log('');
            
            // 4. 测试获取日程列表
            console.log('4. 测试获取日程列表...');
            const eventsData = await calendar.getEvents(calendarId);
            console.log('✅ 日程列表获取成功');
            console.log('日程数量:', eventsData.events?.length || 0);
            
            if (eventsData.events && eventsData.events.length > 0) {
                console.log('');
                console.log('日程列表:');
                eventsData.events.forEach((event, index) => {
                    console.log(`${index + 1}. ${event.summary}`);
                    console.log(`   开始时间: ${new Date(event.start_time.timestamp * 1000).toLocaleString()}`);
                    console.log(`   结束时间: ${new Date(event.end_time.timestamp * 1000).toLocaleString()}`);
                    console.log(`   日程ID: ${event.event_id}`);
                });
            }
            
            // 5. 测试删除日程
            console.log('');
            console.log('5. 测试删除日程...');
            await calendar.deleteEvent(calendarId, event.event_id);
            console.log('✅ 日程删除成功');
            
        } else {
            console.log('⚠️ 没有可用日历，跳过日程测试');
        }
        
        console.log('');
        console.log('=== 测试完成 ===');
        
    } catch (error) {
        console.error('❌ 测试失败:', error.message);
        console.error('错误堆栈:', error.stack);
    }
}

// 运行测试
testCalendarAPI();