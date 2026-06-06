#!/usr/bin/env node

// 任务同步模块 - 本地任务与飞书日历同步
const fs = require('fs');
const path = require('path');
const { FeishuCalendar, formatDate } = require('./feishu-calendar');

// 配置
const CONFIG = {
    // 本地任务文件路径
    localTasksPath: '/home/john/.openclaw/workspace/memory/tasks.json',
    // 同步日志文件路径
    syncLogPath: '/home/john/.openclaw/workspace/memory/task-sync.log',
    // 默认日历ID
    defaultCalendarId: null,
    // 同步配置
    sync: {
        // 自动同步间隔（毫秒）
        autoSyncInterval: 300000, // 5分钟
        // 冲突解决策略: 'local' | 'remote' | 'merge'
        conflictStrategy: 'merge',
        // 是否同步已完成任务
        syncCompletedTasks: false,
        // 是否删除已完成的任务
        deleteCompletedTasks: true
    }
};

// 任务类
class Task {
    constructor(data) {
        this.id = data.id || this.generateId();
        this.title = data.title || '';
        this.description = data.description || '';
        this.status = data.status || 'pending'; // pending, in_progress, completed
        this.priority = data.priority || 'medium'; // low, medium, high
        this.dueDate = data.dueDate || null;
        this.created_at = data.created_at || new Date().toISOString();
        this.updated_at = data.updated_at || new Date().toISOString();
        this.tags = data.tags || [];
        this.category = data.category || 'general';
        this.feishuEventId = data.feishuEventId || null;
        this.calendarId = data.calendarId || CONFIG.defaultCalendarId;
    }

    generateId() {
        return 'task_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    isOverdue() {
        return this.dueDate && new Date(this.dueDate) < new Date() && this.status !== 'completed';
    }

    toFeishuEvent() {
        const startTime = this.dueDate ? new Date(this.dueDate) : new Date();
        const endTime = new Date(startTime.getTime() + 3600000); // 默认1小时
        
        return {
            summary: this.title,
            startTime: formatDate(startTime),
            endTime: formatDate(endTime),
            description: this.description + '\n\n任务ID: ' + this.id,
            location: '',
            attendees: [],
            visibility: 'default',
            reminder: []
        };
    }

    fromFeishuEvent(event) {
        this.title = event.summary;
        this.description = event.description || '';
        this.dueDate = new Date(event.start_time.timestamp * 1000).toISOString();
        this.updated_at = new Date().toISOString();
        this.feishuEventId = event.event_id;
        this.calendarId = event.calendar_id;
    }
}

// 任务同步器类
class TaskSync {
    constructor() {
        this.calendar = new FeishuCalendar();
        this.tasks = [];
        this.syncLog = [];
        this.loadTasks();
        this.loadSyncLog();
    }

    // 加载本地任务
    loadTasks() {
        try {
            if (fs.existsSync(CONFIG.localTasksPath)) {
                const data = fs.readFileSync(CONFIG.localTasksPath, 'utf8');
                const tasksData = JSON.parse(data);
                this.tasks = tasksData.map(taskData => new Task(taskData));
            } else {
                this.tasks = [];
                this.saveTasks();
            }
        } catch (error) {
            console.error('加载任务文件失败:', error.message);
            this.tasks = [];
        }
    }

    // 保存本地任务
    saveTasks() {
        try {
            const tasksData = this.tasks.map(task => ({
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.status,
                priority: task.priority,
                dueDate: task.dueDate,
                created_at: task.created_at,
                updated_at: task.updated_at,
                tags: task.tags,
                category: task.category,
                feishuEventId: task.feishuEventId,
                calendarId: task.calendarId
            }));
            
            fs.writeFileSync(CONFIG.localTasksPath, JSON.stringify(tasksData, null, 2));
        } catch (error) {
            console.error('保存任务文件失败:', error.message);
        }
    }

    // 加载同步日志
    loadSyncLog() {
        try {
            if (fs.existsSync(CONFIG.syncLogPath)) {
                const data = fs.readFileSync(CONFIG.syncLogPath, 'utf8');
                this.syncLog = JSON.parse(data);
            } else {
                this.syncLog = [];
            }
        } catch (error) {
            console.error('加载同步日志失败:', error.message);
            this.syncLog = [];
        }
    }

    // 保存同步日志
    saveSyncLog() {
        try {
            fs.writeFileSync(CONFIG.syncLogPath, JSON.stringify(this.syncLog, null, 2));
        } catch (error) {
            console.error('保存同步日志失败:', error.message);
        }
    }

    // 添加同步日志
    addSyncLog(action, taskId, status, message) {
        const logEntry = {
            timestamp: new Date().toISOString(),
            action: action,
            taskId: taskId,
            status: status,
            message: message
        };
        
        this.syncLog.push(logEntry);
        
        // 只保留最近100条日志
        if (this.syncLog.length > 100) {
            this.syncLog = this.syncLog.slice(-100);
        }
        
        this.saveSyncLog();
    }

    // 获取默认日历ID
    async getDefaultCalendarId() {
        if (CONFIG.defaultCalendarId) {
            return CONFIG.defaultCalendarId;
        }

        try {
            const calendars = await this.calendar.getCalendars();
            if (calendars.length > 0) {
                // 查找名为"xiaowuOS 日程"的日历
                const targetCalendar = calendars.find(cal => cal.summary === 'xiaowuOS 日程');
                if (targetCalendar) {
                    CONFIG.defaultCalendarId = targetCalendar.calendar_id;
                    return CONFIG.defaultCalendarId;
                }
                
                // 如果没有找到，使用第一个日历
                CONFIG.defaultCalendarId = calendars[0].calendar_id;
                return CONFIG.defaultCalendarId;
            } else {
                // 如果没有日历，创建一个
                console.log('没有找到日历，创建默认日历...');
                const newCalendar = await this.calendar.createDefaultCalendar();
                CONFIG.defaultCalendarId = newCalendar.calendar_id;
                return CONFIG.defaultCalendarId;
            }
        } catch (error) {
            console.error('获取默认日历ID失败:', error.message);
            throw error;
        }
    }

    // 同步任务到飞书
    async syncTasksToFeishu() {
        console.log('开始同步任务到飞书...');
        const calendarId = await this.getDefaultCalendarId();
        
        let successCount = 0;
        let failCount = 0;
        
        for (const task of this.tasks) {
            try {
                if (!CONFIG.sync.syncCompletedTasks && task.status === 'completed') {
                    continue;
                }

                if (task.feishuEventId) {
                    // 更新现有日程
                    const eventData = task.toFeishuEvent();
                    await this.calendar.updateEvent(calendarId, task.feishuEventId, eventData);
                    this.addSyncLog('update', task.id, 'success', '任务已更新到飞书');
                    successCount++;
                } else {
                    // 创建新日程
                    const eventData = task.toFeishuEvent();
                    const event = await this.calendar.createEvent(calendarId, eventData);
                    task.feishuEventId = event.event_id;
                    task.calendarId = calendarId;
                    task.updated_at = new Date().toISOString();
                    this.addSyncLog('create', task.id, 'success', '任务已创建到飞书');
                    successCount++;
                }
                
                this.saveTasks();
            } catch (error) {
                console.error(`同步任务 ${task.id} 失败:`, error.message);
                this.addSyncLog('sync', task.id, 'error', error.message);
                failCount++;
            }
        }
        
        console.log(`同步完成: 成功 ${successCount} 个, 失败 ${failCount} 个`);
        return { success: successCount, failed: failCount };
    }

    // 从飞书同步任务
    async syncTasksFromFeishu() {
        console.log('开始从飞书同步任务...');
        const calendarId = await this.getDefaultCalendarId();
        
        try {
            const eventsData = await this.calendar.getEvents(calendarId);
            const events = eventsData.events || [];
            
            let successCount = 0;
            let failCount = 0;
            
            for (const event of events) {
                try {
                    // 检查是否是任务日程（通过描述中的任务ID判断）
                    const taskIdMatch = event.description?.match(/任务ID:\s*(\S+)/);
                    if (!taskIdMatch) {
                        continue;
                    }
                    
                    const taskId = taskIdMatch[1];
                    const existingTask = this.tasks.find(t => t.id === taskId);
                    
                    if (existingTask) {
                        // 更新现有任务
                        existingTask.fromFeishuEvent(event);
                        existingTask.updated_at = new Date().toISOString();
                        this.addSyncLog('update', taskId, 'success', '任务已从飞书更新');
                    } else {
                        // 创建新任务
                        const newTask = new Task({});
                        newTask.fromFeishuEvent(event);
                        newTask.id = taskId;
                        this.tasks.push(newTask);
                        this.addSyncLog('create', taskId, 'success', '任务已从飞书创建');
                    }
                    
                    successCount++;
                } catch (error) {
                    console.error(`处理日程 ${event.event_id} 失败:`, error.message);
                    this.addSyncLog('sync', event.event_id, 'error', error.message);
                    failCount++;
                }
            }
            
            this.saveTasks();
            console.log(`同步完成: 成功 ${successCount} 个, 失败 ${failCount} 个`);
            return { success: successCount, failed: failCount };
        } catch (error) {
            console.error('从飞书同步任务失败:', error.message);
            throw error;
        }
    }

    // 双向同步
    async sync() {
        console.log('开始双向同步...');
        
        try {
            // 1. 从飞书同步
            const fromFeishuResult = await this.syncTasksFromFeishu();
            
            // 2. 同步到飞书
            const toFeishuResult = await this.syncTasksToFeishu();
            
            console.log('双向同步完成:');
            console.log(`从飞书同步: 成功 ${fromFeishuResult.success} 个, 失败 ${fromFeishuResult.failed} 个`);
            console.log(`同步到飞书: 成功 ${toFeishuResult.success} 个, 失败 ${toFeishuResult.failed} 个`);
            
            return {
                fromFeishu: fromFeishuResult,
                toFeishu: toFeishuResult
            };
        } catch (error) {
            console.error('双向同步失败:', error.message);
            throw error;
        }
    }

    // 添加任务
    addTask(taskData) {
        const task = new Task(taskData);
        this.tasks.push(task);
        this.saveTasks();
        return task;
    }

    // 更新任务
    updateTask(taskId, updates) {
        const task = this.tasks.find(t => t.id === taskId);
        if (!task) {
            throw new Error(`任务 ${taskId} 不存在`);
        }
        
        Object.assign(task, updates, { updated_at: new Date().toISOString() });
        this.saveTasks();
        return task;
    }

    // 删除任务
    deleteTask(taskId) {
        const taskIndex = this.tasks.findIndex(t => t.id === taskId);
        if (taskIndex === -1) {
            throw new Error(`任务 ${taskId} 不存在`);
        }
        
        const task = this.tasks[taskIndex];
        this.tasks.splice(taskIndex, 1);
        this.saveTasks();
        return task;
    }

    // 获取任务列表
    getTasks(options = {}) {
        let filteredTasks = [...this.tasks];
        
        // 按状态过滤
        if (options.status) {
            filteredTasks = filteredTasks.filter(t => t.status === options.status);
        }
        
        // 按优先级过滤
        if (options.priority) {
            filteredTasks = filteredTasks.filter(t => t.priority === options.priority);
        }
        
        // 按分类过滤
        if (options.category) {
            filteredTasks = filteredTasks.filter(t => t.category === options.category);
        }
        
        // 按标签过滤
        if (options.tags) {
            filteredTasks = filteredTasks.filter(t => 
                options.tags.some(tag => t.tags.includes(tag))
            );
        }
        
        // 搜索
        if (options.search) {
            const searchTerm = options.search.toLowerCase();
            filteredTasks = filteredTasks.filter(t => 
                t.title.toLowerCase().includes(searchTerm) ||
                t.description.toLowerCase().includes(searchTerm)
            );
        }
        
        // 排序
        if (options.sortBy) {
            filteredTasks.sort((a, b) => {
                if (options.sortBy === 'dueDate') {
                    const aDate = a.dueDate ? new Date(a.dueDate) : new Date(0);
                    const bDate = b.dueDate ? new Date(b.dueDate) : new Date(0);
                    return aDate - bDate;
                } else if (options.sortBy === 'priority') {
                    const priorityOrder = { high: 3, medium: 2, low: 1 };
                    return priorityOrder[b.priority] - priorityOrder[a.priority];
                } else if (options.sortBy === 'created_at') {
                    return new Date(b.created_at) - new Date(a.created_at);
                }
            });
        }
        
        // 分页
        if (options.page && options.pageSize) {
            const start = (options.page - 1) * options.pageSize;
            const end = start + options.pageSize;
            filteredTasks = filteredTasks.slice(start, end);
        }
        
        return filteredTasks;
    }

    // 获取任务统计
    getTaskStats() {
        const stats = {
            total: this.tasks.length,
            pending: this.tasks.filter(t => t.status === 'pending').length,
            in_progress: this.tasks.filter(t => t.status === 'in_progress').length,
            completed: this.tasks.filter(t => t.status === 'completed').length,
            overdue: this.tasks.filter(t => t.isOverdue()).length,
            byPriority: {
                high: this.tasks.filter(t => t.priority === 'high').length,
                medium: this.tasks.filter(t => t.priority === 'medium').length,
                low: this.tasks.filter(t => t.priority === 'low').length
            },
            byCategory: {}
        };
        
        // 按分类统计
        this.tasks.forEach(task => {
            if (!stats.byCategory[task.category]) {
                stats.byCategory[task.category] = 0;
            }
            stats.byCategory[task.category]++;
        });
        
        return stats;
    }
}

// 导出模块
module.exports = {
    TaskSync,
    Task,
    CONFIG
};

// 命令行接口
if (require.main === module) {
    const sync = new TaskSync();
    
    // 获取命令行参数
    const args = process.argv.slice(2);
    const command = args[0];
    
    async function main() {
        try {
            switch (command) {
                case 'sync':
                    console.log('开始双向同步...');
                    const result = await sync.sync();
                    console.log('同步完成');
                    break;
                    
                case 'sync-to-feishu':
                    console.log('同步任务到飞书...');
                    const toFeishuResult = await sync.syncTasksToFeishu();
                    console.log('同步完成');
                    break;
                    
                case 'sync-from-feishu':
                    console.log('从飞书同步任务...');
                    const fromFeishuResult = await sync.syncTasksFromFeishu();
                    console.log('同步完成');
                    break;
                    
                case 'add':
                    if (!args[1]) {
                        console.log('请提供任务标题');
                        process.exit(1);
                    }
                    const newTask = sync.addTask({
                        title: args[1],
                        description: args[2] || '',
                        priority: args[3] || 'medium'
                    });
                    console.log('任务创建成功:');
                    console.log('ID:', newTask.id);
                    console.log('标题:', newTask.title);
                    break;
                    
                case 'list':
                    const tasks = sync.getTasks();
                    console.log('任务列表:');
                    tasks.forEach((task, index) => {
                        console.log(`${index + 1}. ${task.title}`);
                        console.log(`   状态: ${task.status}`);
                        console.log(`   优先级: ${task.priority}`);
                        console.log(`   截止日期: ${task.dueDate || '未设置'}`);
                        console.log(`   创建时间: ${new Date(task.created_at).toLocaleString()}`);
                        console.log('');
                    });
                    break;
                    
                case 'stats':
                    const stats = sync.getTaskStats();
                    console.log('任务统计:');
                    console.log(`总任务数: ${stats.total}`);
                    console.log(`待处理: ${stats.pending}`);
                    console.log(`进行中: ${stats.in_progress}`);
                    console.log(`已完成: ${stats.completed}`);
                    console.log(`已逾期: ${stats.overdue}`);
                    console.log('按优先级:');
                    console.log(`  高: ${stats.byPriority.high}`);
                    console.log(`  中: ${stats.byPriority.medium}`);
                    console.log(`  低: ${stats.byPriority.low}`);
                    break;
                    
                default:
                    console.log('使用方法:');
                    console.log('  node task-sync.js sync              # 双向同步');
                    console.log('  node task-sync.js sync-to-feishu   # 同步到飞书');
                    console.log('  node task-sync.js sync-from-feishu # 从飞书同步');
                    console.log('  node task-sync.js add <title> [desc] [priority]  # 添加任务');
                    console.log('  node task-sync.js list             # 列出任务');
                    console.log('  node task-sync.js stats            # 统计信息');
                    break;
            }
        } catch (error) {
            console.error('错误:', error.message);
            process.exit(1);
        }
    }
    
    main();
}