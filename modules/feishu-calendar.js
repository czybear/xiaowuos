#!/usr/bin/env node

// 飞书日历管理模块
const https = require('https');
const fs = require('fs');
const path = require('path');

// 配置文件路径
const CREDENTIALS_PATH = '/home/john/xiaowuOS/config/feishu-credentials.json';

// 飞书API配置
const FEISHU_API_BASE = 'https://open.feishu.cn/open-apis';

// 日历管理类
class FeishuCalendar {
    constructor() {
        this.credentials = this.readCredentials();
        this.accessToken = null;
    }

    // 读取配置文件
    readCredentials() {
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

    // 获取访问令牌
    async getAccessToken() {
        if (!this.credentials) {
            throw new Error('配置文件不存在');
        }

        // 检查令牌是否过期
        if (this.credentials.tenant_access_token && 
            this.credentials.expire > Date.now() + 300000) { // 5分钟缓冲
            this.accessToken = this.credentials.tenant_access_token;
            return this.accessToken;
        }

        return new Promise((resolve, reject) => {
            const postData = JSON.stringify({
                app_id: this.credentials.app_id,
                app_secret: this.credentials.app_secret
            });

            const options = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: '/open-apis/auth/v3/tenant_access_token/internal',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData)
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            this.accessToken = response.tenant_access_token;
                            this.credentials.tenant_access_token = response.tenant_access_token;
                            this.credentials.expire = Date.now() + response.expire - 300000; // 5分钟缓冲
                            this.saveCredentials();
                            resolve(this.accessToken);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.write(postData);
            req.end();
        });
    }

    // 保存配置文件
    saveCredentials() {
        try {
            this.credentials.updated_at = new Date().toISOString();
            fs.writeFileSync(CREDENTIALS_PATH, JSON.stringify(this.credentials, null, 2));
        } catch (error) {
            console.error('保存配置文件失败:', error.message);
        }
    }

    // 获取日历列表
    async getCalendars() {
        await this.getAccessToken();
        
        return new Promise((resolve, reject) => {
            const options = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: '/open-apis/calendar/v4/calendars',
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json'
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            resolve(response.data.calendars || []);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.end();
        });
    }

    // 创建日程
    async createEvent(calendarId, eventData) {
        await this.getAccessToken();
        
        return new Promise((resolve, reject) => {
            const postData = JSON.stringify({
                summary: eventData.summary,
                start_time: eventData.startTime,
                end_time: eventData.endTime,
                description: eventData.description || '',
                location: eventData.location || '',
                attendees: eventData.attendees || [],
                visibility: eventData.visibility || 'default',
                reminder: eventData.reminder || []
            });

            const options = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: `/open-apis/calendar/v4/calendars/${calendarId}/events`,
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData)
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.write(postData);
            req.end();
        });
    }

    // 修改日程
    async updateEvent(calendarId, eventId, eventData) {
        await this.getAccessToken();
        
        return new Promise((resolve, reject) => {
            const postData = JSON.stringify({
                summary: eventData.summary,
                start_time: eventData.startTime,
                end_time: eventData.endTime,
                description: eventData.description || '',
                location: eventData.location || '',
                attendees: eventData.attendees || [],
                visibility: eventData.visibility || 'default',
                reminder: eventData.reminder || []
            });

            const options = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: `/open-apis/calendar/v4/calendars/${calendarId}/events/${eventId}`,
                method: 'PUT',
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData)
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.write(postData);
            req.end();
        });
    }

    // 删除日程
    async deleteEvent(calendarId, eventId) {
        await this.getAccessToken();
        
        return new Promise((resolve, reject) => {
            const options = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: `/open-apis/calendar/v4/calendars/${calendarId}/events/${eventId}`,
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json'
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.end();
        });
    }

    // 获取日程列表
    async getEvents(calendarId, options = {}) {
        await this.getAccessToken();
        
        const query = new URLSearchParams();
        if (options.startTime) query.append('start_time', options.startTime);
        if (options.endTime) query.append('end_time', options.endTime);
        if (options.pageSize) query.append('page_size', options.pageSize);
        if (options.token) query.append('page_token', options.token);

        const path = `/open-apis/calendar/v4/calendars/${calendarId}/events${query.toString() ? '?' + query.toString() : ''}`;
        
        return new Promise((resolve, reject) => {
            const reqOptions = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: path,
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json'
                }
            };

            const req = https.request(reqOptions, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.end();
        });
    }

    // 创建默认日历
    async createDefaultCalendar() {
        await this.getAccessToken();
        
        return new Promise((resolve, reject) => {
            const postData = JSON.stringify({
                summary: 'xiaowuOS 日程',
                description: 'xiaowuOS 系统管理的日程日历',
                color: 0,
                permissions: {
                    default: 'read_write'
                }
            });

            const options = {
                hostname: 'open.feishu.cn',
                port: 443,
                path: '/open-apis/calendar/v4/calendars',
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData)
                }
            };

            const req = https.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => {
                    data += chunk;
                });
                res.on('end', () => {
                    try {
                        const response = JSON.parse(data);
                        if (response.code === 0) {
                            resolve(response.data);
                        } else {
                            reject(new Error(response.msg));
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.write(postData);
            req.end();
        });
    }
}

// 工具函数
function formatDate(date) {
    const d = new Date(date);
    return {
        timestamp: Math.floor(d.getTime() / 1000),
        timezone: 'Asia/Shanghai'
    };
}

function formatEvent(event) {
    return {
        event_id: event.event_id,
        calendar_id: event.calendar_id,
        summary: event.summary,
        start_time: event.start_time,
        end_time: event.end_time,
        description: event.description,
        location: event.location,
        attendees: event.attendees,
        visibility: event.visibility,
        organizer: event.organizer,
        created_at: event.created_at,
        updated_at: event.updated_at
    };
}

// 导出模块
module.exports = {
    FeishuCalendar,
    formatDate,
    formatEvent
};

// 命令行接口
if (require.main === module) {
    const calendar = new FeishuCalendar();
    
    // 获取命令行参数
    const args = process.argv.slice(2);
    const command = args[0];
    
    async function main() {
        try {
            switch (command) {
                case 'calendars':
                    console.log('获取日历列表...');
                    const calendars = await calendar.getCalendars();
                    console.log('日历列表:');
                    calendars.forEach((cal, index) => {
                        console.log(`${index + 1}. ${cal.summary} (${cal.calendar_id})`);
                        console.log(`   权限: ${cal.permission}`);
                        console.log(`   所有者: ${cal.owner?.name || '未知'}`);
                    });
                    break;
                    
                case 'create-calendar':
                    console.log('创建默认日历...');
                    const newCalendar = await calendar.createDefaultCalendar();
                    console.log('日历创建成功:');
                    console.log('日历ID:', newCalendar.calendar_id);
                    console.log('日历标题:', newCalendar.summary);
                    break;
                    
                case 'events':
                    if (!args[1]) {
                        console.log('请提供日历ID');
                        process.exit(1);
                    }
                    console.log('获取日程列表...');
                    const events = await calendar.getEvents(args[1]);
                    console.log('日程列表:');
                    events.events?.forEach((event, index) => {
                        console.log(`${index + 1}. ${event.summary}`);
                        console.log(`   开始时间: ${new Date(event.start_time.timestamp * 1000).toLocaleString()}`);
                        console.log(`   结束时间: ${new Date(event.end_time.timestamp * 1000).toLocaleString()}`);
                        console.log(`   日程ID: ${event.event_id}`);
                    });
                    break;
                    
                case 'create-event':
                    if (!args[1]) {
                        console.log('请提供日历ID');
                        process.exit(1);
                    }
                    console.log('创建日程...');
                    const eventData = {
                        summary: args[2] || '测试日程',
                        startTime: formatDate(new Date()),
                        endTime: formatDate(new Date(Date.now() + 3600000)), // 1小时后
                        description: '这是一个测试日程',
                        location: '会议室',
                        attendees: []
                    };
                    const newEvent = await calendar.createEvent(args[1], eventData);
                    console.log('日程创建成功:');
                    console.log('日程ID:', newEvent.event_id);
                    console.log('日程标题:', newEvent.summary);
                    break;
                    
                default:
                    console.log('使用方法:');
                    console.log('  node feishu-calendar.js calendars        # 获取日历列表');
                    console.log('  node feishu-calendar.js create-calendar  # 创建默认日历');
                    console.log('  node feishu-calendar.js events <calendar_id>  # 获取日程列表');
                    console.log('  node feishu-calendar.js create-event <calendar_id> [title]  # 创建日程');
                    break;
            }
        } catch (error) {
            console.error('错误:', error.message);
            process.exit(1);
        }
    }
    
    main();
}