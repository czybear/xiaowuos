#!/usr/bin/env node

// 本地任务管理器 - 不依赖飞书API
const fs = require('fs');
const path = require('path');

// 配置
const CONFIG = {
    // 本地任务文件路径
    localTasksPath: '/home/john/.openclaw/workspace/memory/tasks.json',
    // 任务统计文件路径
    taskStatsPath: '/home/john/.openclaw/workspace/memory/task-stats.json',
    // 每页显示任务数
    pageSize: 10,
    // 支持的优先级
    priorities: ['low', 'medium', 'high'],
    // 支持的状态
    statuses: ['pending', 'in_progress', 'completed'],
    // 支持的分类
    categories: ['general', 'work', 'personal', 'study', 'health', 'other']
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
        this.completed_at = data.completed_at || null;
        this.estimated_hours = data.estimated_hours || null;
        this.actual_hours = data.actual_hours || null;
    }

    generateId() {
        return 'task_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    isOverdue() {
        return this.dueDate && new Date(this.dueDate) < new Date() && this.status !== 'completed';
    }

    isDueToday() {
        if (!this.dueDate) return false;
        const today = new Date();
        const dueDate = new Date(this.dueDate);
        return today.toDateString() === dueDate.toDateString();
    }

    isDueTomorrow() {
        if (!this.dueDate) return false;
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const dueDate = new Date(this.dueDate);
        return tomorrow.toDateString() === dueDate.toDateString();
    }

    getDaysUntilDue() {
        if (!this.dueDate) return null;
        const now = new Date();
        const dueDate = new Date(this.dueDate);
        const diffTime = dueDate - now;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
    }

    markAsCompleted() {
        this.status = 'completed';
        this.completed_at = new Date().toISOString();
        this.updated_at = new Date().toISOString();
    }

    markAsInProgress() {
        this.status = 'in_progress';
        this.updated_at = new Date().toISOString();
    }

    markAsPending() {
        this.status = 'pending';
        this.updated_at = new Date().toISOString();
    }

    toObject() {
        return {
            id: this.id,
            title: this.title,
            description: this.description,
            status: this.status,
            priority: this.priority,
            dueDate: this.dueDate,
            created_at: this.created_at,
            updated_at: this.updated_at,
            tags: this.tags,
            category: this.category,
            completed_at: this.completed_at,
            estimated_hours: this.estimated_hours,
            actual_hours: this.actual_hours
        };
    }
}

// 本地任务管理器类
class LocalTaskManager {
    constructor() {
        this.tasks = [];
        this.currentPage = 1;
        this.currentFilter = {};
        this.currentSort = { sortBy: 'created_at', sortOrder: 'desc' };
        this.loadTasks();
        this.loadStats();
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
            const tasksData = this.tasks.map(task => task.toObject());
            fs.writeFileSync(CONFIG.localTasksPath, JSON.stringify(tasksData, null, 2));
        } catch (error) {
            console.error('保存任务文件失败:', error.message);
        }
    }

    // 加载统计信息
    loadStats() {
        try {
            if (fs.existsSync(CONFIG.taskStatsPath)) {
                const data = fs.readFileSync(CONFIG.taskStatsPath, 'utf8');
                this.stats = JSON.parse(data);
            } else {
                this.stats = this.calculateStats();
                this.saveStats();
            }
        } catch (error) {
            console.error('加载统计文件失败:', error.message);
            this.stats = this.calculateStats();
        }
    }

    // 保存统计信息
    saveStats() {
        try {
            fs.writeFileSync(CONFIG.taskStatsPath, JSON.stringify(this.stats, null, 2));
        } catch (error) {
            console.error('保存统计文件失败:', error.message);
        }
    }

    // 计算统计信息
    calculateStats() {
        const stats = {
            total: this.tasks.length,
            pending: this.tasks.filter(t => t.status === 'pending').length,
            in_progress: this.tasks.filter(t => t.status === 'in_progress').length,
            completed: this.tasks.filter(t => t.status === 'completed').length,
            overdue: this.tasks.filter(t => t.isOverdue()).length,
            due_today: this.tasks.filter(t => t.isDueToday()).length,
            due_tomorrow: this.tasks.filter(t => t.isDueTomorrow()).length,
            byPriority: {
                high: this.tasks.filter(t => t.priority === 'high').length,
                medium: this.tasks.filter(t => t.priority === 'medium').length,
                low: this.tasks.filter(t => t.priority === 'low').length
            },
            byCategory: {},
            byStatus: {
                pending: this.tasks.filter(t => t.status === 'pending').length,
                in_progress: this.tasks.filter(t => t.status === 'in_progress').length,
                completed: this.tasks.filter(t => t.status === 'completed').length
            },
            completed_today: this.tasks.filter(t => {
                return t.status === 'completed' && 
                       t.completed_at && 
                       new Date(t.completed_at).toDateString() === new Date().toDateString();
            }).length,
            created_today: this.tasks.filter(t => {
                return new Date(t.created_at).toDateString() === new Date().toDateString();
            }).length
        };
        
        // 按分类统计
        this.tasks.forEach(task => {
            if (!stats.byCategory[task.category]) {
                stats.byCategory[task.category] = 0;
            }
            stats.byCategory[task.category]++;
        });
        
        // 计算完成率
        stats.completion_rate = this.tasks.length > 0 ? 
            Math.round((stats.completed / this.tasks.length) * 100) : 0;
        
        // 计算平均完成时间
        const completedTasks = this.tasks.filter(t => t.status === 'completed' && t.completed_at);
        if (completedTasks.length > 0) {
            const totalTime = completedTasks.reduce((sum, task) => {
                const created = new Date(task.created_at);
                const completed = new Date(task.completed_at);
                return sum + (completed - created);
            }, 0);
            stats.average_completion_time = Math.round(totalTime / completedTasks.length / (1000 * 60 * 60 * 24)); // 天
        }
        
        return stats;
    }

    // 添加任务
    addTask(taskData) {
        const task = new Task(taskData);
        this.tasks.push(task);
        this.saveTasks();
        this.stats = this.calculateStats();
        this.saveStats();
        return task;
    }

    // 更新任务
    updateTask(taskId, updates) {
        const task = this.tasks.find(t => t.id === taskId);
        if (!task) {
            throw new Error(`任务 ${taskId} 不存在`);
        }
        
        Object.assign(task, updates, { updated_at: new Date().toISOString() });
        
        // 如果状态更新为已完成，设置完成时间
        if (updates.status === 'completed' && task.status !== 'completed') {
            task.markAsCompleted();
        } else if (updates.status === 'in_progress' && task.status !== 'in_progress') {
            task.markAsInProgress();
        } else if (updates.status === 'pending' && task.status !== 'pending') {
            task.markAsPending();
        }
        
        this.saveTasks();
        this.stats = this.calculateStats();
        this.saveStats();
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
        this.stats = this.calculateStats();
        this.saveStats();
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
        
        // 按截止日期过滤
        if (options.dueBefore) {
            const beforeDate = new Date(options.dueBefore);
            filteredTasks = filteredTasks.filter(t => 
                t.dueDate && new Date(t.dueDate) <= beforeDate
            );
        }
        
        if (options.dueAfter) {
            const afterDate = new Date(options.dueAfter);
            filteredTasks = filteredTasks.filter(t => 
                t.dueDate && new Date(t.dueDate) >= afterDate
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
                } else if (options.sortBy === 'updated_at') {
                    return new Date(b.updated_at) - new Date(a.updated_at);
                } else if (options.sortBy === 'title') {
                    return a.title.localeCompare(b.title);
                }
            });
            
            // 反转排序
            if (options.sortOrder === 'asc') {
                filteredTasks.reverse();
            }
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
        return this.stats;
    }

    // 获取即将到期的任务
    getUpcomingTasks(days = 7) {
        const now = new Date();
        const futureDate = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
        
        return this.tasks.filter(task => {
            if (!task.dueDate) return false;
            const dueDate = new Date(task.dueDate);
            return dueDate >= now && dueDate <= futureDate && task.status !== 'completed';
        });
    }

    // 获取今天的任务
    getTodaysTasks() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        return this.tasks.filter(task => {
            if (!task.dueDate) return false;
            const dueDate = new Date(task.dueDate);
            return dueDate >= today && dueDate < tomorrow && task.status !== 'completed';
        });
    }

    // 获取逾期任务
    getOverdueTasks() {
        return this.tasks.filter(task => task.isOverdue());
    }

    // 导出任务
    exportTasks(format = 'json') {
        if (format === 'json') {
            return JSON.stringify(this.tasks.map(t => t.toObject()), null, 2);
        } else if (format === 'csv') {
            const headers = ['ID', 'Title', 'Description', 'Status', 'Priority', 'Category', 'Due Date', 'Created At', 'Updated At'];
            const rows = this.tasks.map(task => [
                task.id,
                task.title,
                task.description,
                task.status,
                task.priority,
                task.category,
                task.dueDate || '',
                task.created_at,
                task.updated_at
            ]);
            
            return [headers, ...rows].map(row => row.join(',')).join('\n');
        }
        
        throw new Error(`不支持的导出格式: ${format}`);
    }

    // 导入任务
    importTasks(data, format = 'json') {
        let tasksData;
        
        if (format === 'json') {
            tasksData = JSON.parse(data);
        } else if (format === 'csv') {
            const lines = data.split('\n');
            const headers = lines[0].split(',');
            tasksData = [];
            
            for (let i = 1; i < lines.length; i++) {
                const values = lines[i].split(',');
                if (values.length === headers.length) {
                    const taskData = {};
                    headers.forEach((header, index) => {
                        taskData[header.toLowerCase().replace(' ', '_')] = values[index];
                    });
                    tasksData.push(taskData);
                }
            }
        } else {
            throw new Error(`不支持的导入格式: ${format}`);
        }
        
        tasksData.forEach(taskData => {
            try {
                const task = new Task(taskData);
                this.tasks.push(task);
            } catch (error) {
                console.error(`导入任务失败: ${taskData.title || '未知任务'}`, error.message);
            }
        });
        
        this.saveTasks();
        this.stats = this.calculateStats();
        this.saveStats();
        
        return {
            total: tasksData.length,
            success: this.tasks.length - (this.tasks.length - tasksData.length),
            failed: tasksData.length - (this.tasks.length - (this.tasks.length - tasksData.length))
        };
    }
}

// 导出模块
module.exports = {
    LocalTaskManager,
    Task,
    CONFIG
};

// 命令行接口
if (require.main === module) {
    const manager = new LocalTaskManager();
    
    // 获取命令行参数
    const args = process.argv.slice(2);
    const command = args[0];
    
    async function main() {
        try {
            switch (command) {
                case 'add':
                    if (!args[1]) {
                        console.log('请提供任务标题');
                        process.exit(1);
                    }
                    const newTask = manager.addTask({
                        title: args[1],
                        description: args[2] || '',
                        priority: args[3] || 'medium',
                        category: args[4] || 'general'
                    });
                    console.log('✅ 任务创建成功:');
                    console.log('ID:', newTask.id);
                    console.log('标题:', newTask.title);
                    console.log('优先级:', newTask.priority);
                    console.log('分类:', newTask.category);
                    break;
                    
                case 'list':
                    const tasks = manager.getTasks({
                        sortBy: 'created_at',
                        sortOrder: 'desc',
                        page: args[1] || 1,
                        pageSize: CONFIG.pageSize
                    });
                    
                    console.log('=== 任务列表 ===');
                    console.log('');
                    
                    if (tasks.length === 0) {
                        console.log('没有找到任务');
                        break;
                    }
                    
                    tasks.forEach((task, index) => {
                        const statusIcon = task.status === 'completed' ? '✅' : 
                                          task.status === 'in_progress' ? '🔄' : '⏳';
                        const priorityIcon = task.priority === 'high' ? '🔴' : 
                                          task.priority === 'medium' ? '🟡' : '🟢';
                        const dueInfo = task.dueDate ? 
                            ` (截止: ${new Date(task.dueDate).toLocaleDateString()})` : '';
                        
                        console.log(`${index + 1}. ${statusIcon} ${priorityIcon} ${task.title}${dueInfo}`);
                        if (task.description) {
                            console.log(`   描述: ${task.description}`);
                        }
                        console.log(`   状态: ${task.status} | 优先级: ${task.priority} | 分类: ${task.category}`);
                        if (task.tags.length > 0) {
                            console.log(`   标签: ${task.tags.join(', ')}`);
                        }
                        console.log(`   创建: ${new Date(task.created_at).toLocaleDateString()}`);
                        console.log('');
                    });
                    
                    const totalTasks = manager.getTasks().length;
                    const totalPages = Math.ceil(totalTasks / CONFIG.pageSize);
                    console.log(`第 ${args[1] || 1} 页，共 ${totalPages} 页 (共 ${totalTasks} 个任务)`);
                    break;
                    
                case 'update':
                    if (!args[1] || !args[2]) {
                        console.log('请提供任务ID和更新字段');
                        process.exit(1);
                    }
                    
                    const taskId = args[1];
                    const updates = {};
                    
                    // 解析更新字段
                    for (let i = 2; i < args.length; i += 2) {
                        const field = args[i];
                        const value = args[i + 1];
                        
                        switch (field) {
                            case 'title':
                                updates.title = value;
                                break;
                            case 'description':
                                updates.description = value;
                                break;
                            case 'priority':
                                updates.priority = value;
                                break;
                            case 'category':
                                updates.category = value;
                                break;
                            case 'status':
                                updates.status = value;
                                break;
                            case 'dueDate':
                                updates.dueDate = value;
                                break;
                            case 'tags':
                                updates.tags = value.split(',');
                                break;
                            default:
                                console.log(`未知字段: ${field}`);
                                break;
                        }
                    }
                    
                    const updatedTask = manager.updateTask(taskId, updates);
                    console.log('✅ 任务更新成功:');
                    console.log('ID:', updatedTask.id);
                    console.log('标题:', updatedTask.title);
                    console.log('状态:', updatedTask.status);
                    break;
                    
                case 'delete':
                    if (!args[1]) {
                        console.log('请提供任务ID');
                        process.exit(1);
                    }
                    
                    const deletedTask = manager.deleteTask(args[1]);
                    console.log('✅ 任务删除成功:');
                    console.log('ID:', deletedTask.id);
                    console.log('标题:', deletedTask.title);
                    break;
                    
                case 'stats':
                    const stats = manager.getTaskStats();
                    console.log('=== 任务统计 ===');
                    console.log('');
                    console.log(`总任务数: ${stats.total}`);
                    console.log(`待处理: ${stats.pending}`);
                    console.log(`进行中: ${stats.in_progress}`);
                    console.log(`已完成: ${stats.completed}`);
                    console.log(`已逾期: ${stats.overdue}`);
                    console.log(`今天到期: ${stats.due_today}`);
                    console.log(`明天到期: ${stats.due_tomorrow}`);
                    console.log(`今日完成: ${stats.completed_today}`);
                    console.log(`今日创建: ${stats.created_today}`);
                    console.log(`完成率: ${stats.completion_rate}%`);
                    if (stats.average_completion_time) {
                        console.log(`平均完成时间: ${stats.average_completion_time} 天`);
                    }
                    console.log('');
                    console.log('按优先级:');
                    console.log(`  高: ${stats.byPriority.high}`);
                    console.log(`  中: ${stats.byPriority.medium}`);
                    console.log(`  低: ${stats.byPriority.low}`);
                    console.log('');
                    console.log('按分类:');
                    Object.entries(stats.byCategory).forEach(([category, count]) => {
                        console.log(`  ${category}: ${count}`);
                    });
                    break;
                    
                case 'upcoming':
                    const days = parseInt(args[1]) || 7;
                    const upcomingTasks = manager.getUpcomingTasks(days);
                    console.log(`=== 未来 ${days} 天到期的任务 ===`);
                    console.log('');
                    
                    if (upcomingTasks.length === 0) {
                        console.log('没有即将到期的任务');
                        break;
                    }
                    
                    upcomingTasks.forEach((task, index) => {
                        const daysUntil = task.getDaysUntilDue();
                        console.log(`${index + 1}. ${task.title}`);
                        console.log(`   截止日期: ${new Date(task.dueDate).toLocaleDateString()}`);
                        console.log(`   剩余天数: ${daysUntil} 天`);
                        console.log(`   优先级: ${task.priority}`);
                        console.log(`   状态: ${task.status}`);
                        console.log('');
                    });
                    break;
                    
                case 'today':
                    const todaysTasks = manager.getTodaysTasks();
                    console.log('=== 今日任务 ===');
                    console.log('');
                    
                    if (todaysTasks.length === 0) {
                        console.log('今天没有任务');
                        break;
                    }
                    
                    todaysTasks.forEach((task, index) => {
                        console.log(`${index + 1}. ${task.title}`);
                        console.log(`   截止日期: ${new Date(task.dueDate).toLocaleDateString()}`);
                        console.log(`   优先级: ${task.priority}`);
                        console.log(`   状态: ${task.status}`);
                        console.log('');
                    });
                    break;
                    
                case 'overdue':
                    const overdueTasks = manager.getOverdueTasks();
                    console.log('=== 逾期任务 ===');
                    console.log('');
                    
                    if (overdueTasks.length === 0) {
                        console.log('没有逾期任务');
                        break;
                    }
                    
                    overdueTasks.forEach((task, index) => {
                        const overdueDays = Math.abs(task.getDaysUntilDue());
                        console.log(`${index + 1}. ${task.title}`);
                        console.log(`   截止日期: ${new Date(task.dueDate).toLocaleDateString()}`);
                        console.log(`   逾期天数: ${overdueDays} 天`);
                        console.log(`   优先级: ${task.priority}`);
                        console.log(`   状态: ${task.status}`);
                        console.log('');
                    });
                    break;
                    
                case 'export':
                    const format = args[1] || 'json';
                    const exportedData = manager.exportTasks(format);
                    const outputPath = args[2] || `tasks.${format}`;
                    
                    fs.writeFileSync(outputPath, exportedData);
                    console.log(`✅ 任务已导出到: ${outputPath}`);
                    console.log(`导出格式: ${format}`);
                    console.log(`任务数量: ${manager.tasks.length}`);
                    break;
                    
                case 'import':
                    if (!args[1] || !args[2]) {
                        console.log('请提供文件路径和格式');
                        process.exit(1);
                    }
                    
                    const importPath = args[1];
                    const importFormat = args[2];
                    
                    if (!fs.existsSync(importPath)) {
                        console.log(`文件不存在: ${importPath}`);
                        process.exit(1);
                    }
                    
                    const importData = fs.readFileSync(importPath, 'utf8');
                    const result = manager.importTasks(importData, importFormat);
                    
                    console.log('✅ 任务导入完成:');
                    console.log(`总导入: ${result.total}`);
                    console.log(`成功: ${result.success}`);
                    console.log(`失败: ${result.failed}`);
                    break;
                    
                case 'help':
                default:
                    console.log('使用方法:');
                    console.log('');
                    console.log('任务管理:');
                    console.log('  node local-task-manager.js add <title> [desc] [priority] [category]  # 添加任务');
                    console.log('  node local-task-manager.js list [page]                               # 列出任务');
                    console.log('  node local-task-manager.js update <id> <field> <value> ...            # 更新任务');
                    console.log('  node local-task-manager.js delete <id>                              # 删除任务');
                    console.log('');
                    console.log('统计和查询:');
                    console.log('  node local-task-manager.js stats                                    # 统计信息');
                    console.log('  node local-task-manager.js upcoming [days]                          # 即将到期的任务');
                    console.log('  node local-task-manager.js today                                     # 今日任务');
                    console.log('  node local-task-manager.js overdue                                   # 逾期任务');
                    console.log('');
                    console.log('数据管理:');
                    console.log('  node local-task-manager.js export [format] [output]                 # 导出任务');
                    console.log('  node local-task-manager.js import <file> <format>                    # 导入任务');
                    console.log('');
                    console.log('优先级: low, medium, high');
                    console.log('分类: general, work, personal, study, health, other');
                    console.log('状态: pending, in_progress, completed');
                    console.log('格式: json, csv');
                    break;
            }
        } catch (error) {
            console.error('错误:', error.message);
            process.exit(1);
        }
    }
    
    main();
}