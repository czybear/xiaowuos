#!/usr/bin/env node

// 任务管理界面模块
const { TaskSync, Task, CONFIG } = require('./task-sync');

class TaskManager {
    constructor() {
        this.sync = new TaskSync();
        this.currentPage = 1;
        this.pageSize = 10;
        this.currentFilter = {};
        this.currentSort = { sortBy: 'created_at', sortOrder: 'desc' };
    }

    // 显示主菜单
    showMainMenu() {
        console.clear();
        console.log('=== xiaowuOS 任务管理器 ===');
        console.log('');
        this.showStats();
        console.log('');
        console.log('1. 查看任务列表');
        console.log('2. 添加新任务');
        console.log('3. 编辑任务');
        console.log('4. 删除任务');
        console.log('5. 搜索任务');
        console.log('6. 同步任务');
        console.log('7. 查看同步日志');
        console.log('8. 设置');
        console.log('9. 退出');
        console.log('');
        console.log('请选择操作 (1-9):');
    }

    // 显示统计信息
    showStats() {
        const stats = this.sync.getTaskStats();
        console.log('📊 任务统计:');
        console.log(`   总任务: ${stats.total} | 待处理: ${stats.pending} | 进行中: ${stats.in_progress} | 已完成: ${stats.completed} | 已逾期: ${stats.overdue}`);
        
        if (stats.byPriority.high > 0) {
            console.log(`   🔴 高优先级: ${stats.byPriority.high}`);
        }
        if (stats.byPriority.medium > 0) {
            console.log(`   🟡 中优先级: ${stats.byPriority.medium}`);
        }
        if (stats.byPriority.low > 0) {
            console.log(`   🟢 低优先级: ${stats.byPriority.low}`);
        }
    }

    // 显示任务列表
    showTaskList() {
        console.clear();
        console.log('=== 任务列表 ===');
        console.log('');
        
        // 获取任务
        const tasks = this.sync.getTasks({
            ...this.currentFilter,
            sortBy: this.currentSort.sortBy,
            sortOrder: this.currentSort.sortOrder,
            page: this.currentPage,
            pageSize: this.pageSize
        });
        
        if (tasks.length === 0) {
            console.log('没有找到任务');
            return;
        }
        
        // 显示任务
        tasks.forEach((task, index) => {
            const globalIndex = (this.currentPage - 1) * this.pageSize + index + 1;
            const statusIcon = this.getStatusIcon(task);
            const priorityIcon = this.getPriorityIcon(task);
            const dueDateInfo = this.getDueDateInfo(task);
            
            console.log(`${globalIndex}. ${statusIcon} ${priorityIcon} ${task.title}`);
            if (task.description) {
                console.log(`   描述: ${task.description}`);
            }
            console.log(`   状态: ${task.status} | 优先级: ${task.priority} | 分类: ${task.category}`);
            if (dueDateInfo) {
                console.log(`   截止: ${dueDateInfo}`);
            }
            if (task.tags.length > 0) {
                console.log(`   标签: ${task.tags.join(', ')}`);
            }
            console.log(`   创建: ${new Date(task.created_at).toLocaleDateString()}`);
            if (task.feishuEventId) {
                console.log(`   飞书日程: ✅`);
            }
            console.log('');
        });
        
        // 显示分页信息
        const totalTasks = this.sync.getTasks(this.currentFilter).length;
        const totalPages = Math.ceil(totalTasks / this.pageSize);
        
        console.log(`第 ${this.currentPage} 页，共 ${totalPages} 页 (共 ${totalTasks} 个任务)`);
        console.log('');
        console.log('操作: [n]下一页 [p]上一页 [f]过滤 [s]排序 [q]返回主菜单');
        
        this.handleTaskListInput();
    }

    // 获取状态图标
    getStatusIcon(task) {
        switch (task.status) {
            case 'completed':
                return '✅';
            case 'in_progress':
                return '🔄';
            case 'pending':
                return '⏳';
            default:
                return '❓';
        }
    }

    // 获取优先级图标
    getPriorityIcon(task) {
        switch (task.priority) {
            case 'high':
                return '🔴';
            case 'medium':
                return '🟡';
            case 'low':
                return '🟢';
            default:
                return '⚪';
        }
    }

    // 获取截止日期信息
    getDueDateInfo(task) {
        if (!task.dueDate) return null;
        
        const dueDate = new Date(task.dueDate);
        const now = new Date();
        const daysUntilDue = Math.ceil((dueDate - now) / (1000 * 60 * 60 * 24));
        
        if (daysUntilDue < 0) {
            return `已逾期 ${Math.abs(daysUntilDue)} 天`;
        } else if (daysUntilDue === 0) {
            return '今天到期';
        } else if (daysUntilDay === 1) {
            return '明天到期';
        } else {
            return `${daysUntilDue} 天后到期`;
        }
    }

    // 处理任务列表输入
    handleTaskListInput() {
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer.toLowerCase()) {
                case 'n':
                    this.currentPage++;
                    this.showTaskList();
                    break;
                case 'p':
                    if (this.currentPage > 1) {
                        this.currentPage--;
                    }
                    this.showTaskList();
                    break;
                case 'f':
                    this.showFilterMenu();
                    break;
                case 's':
                    this.showSortMenu();
                    break;
                case 'q':
                    this.showMainMenu();
                    break;
                default:
                    // 检查是否是数字
                    const taskIndex = parseInt(answer);
                    if (!isNaN(taskIndex)) {
                        this.showTaskDetail(taskIndex);
                    } else {
                        this.showTaskList();
                    }
                    break;
            }
        });
    }

    // 显示任务详情
    showTaskDetail(taskIndex) {
        const allTasks = this.sync.getTasks(this.currentFilter);
        const taskIndexInFiltered = (this.currentPage - 1) * this.pageSize + taskIndex - 1;
        
        if (taskIndexInFiltered < 0 || taskIndexInFiltered >= allTasks.length) {
            console.log('无效的任务编号');
            this.showTaskList();
            return;
        }
        
        const task = allTasks[taskIndexInFiltered];
        
        console.clear();
        console.log('=== 任务详情 ===');
        console.log('');
        console.log(`标题: ${task.title}`);
        console.log(`ID: ${task.id}`);
        console.log(`状态: ${task.status}`);
        console.log(`优先级: ${task.priority}`);
        console.log(`分类: ${task.category}`);
        console.log('');
        
        if (task.description) {
            console.log('描述:');
            console.log(task.description);
            console.log('');
        }
        
        if (task.dueDate) {
            console.log(`截止日期: ${new Date(task.dueDate).toLocaleString()}`);
            console.log('');
        }
        
        if (task.tags.length > 0) {
            console.log(`标签: ${task.tags.join(', ')}`);
            console.log('');
        }
        
        console.log(`创建时间: ${new Date(task.created_at).toLocaleString()}`);
        console.log(`更新时间: ${new Date(task.updated_at).toLocaleString()}`);
        
        if (task.feishuEventId) {
            console.log(`飞书日程ID: ${task.feishuEventId}`);
            console.log(`日历ID: ${task.calendarId}`);
        }
        
        console.log('');
        console.log('操作:');
        console.log('1. 编辑任务');
        console.log('2. 更新状态');
        console.log('3. 删除任务');
        console.log('4. 返回列表');
        console.log('');
        console.log('请选择操作 (1-4):');
        
        this.handleTaskDetailInput(task);
    }

    // 处理任务详情输入
    handleTaskDetailInput(task) {
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.editTask(task);
                    break;
                case '2':
                    this.updateTaskStatus(task);
                    break;
                case '3':
                    this.deleteTask(task);
                    break;
                case '4':
                    this.showTaskList();
                    break;
                default:
                    this.showTaskDetail(task);
                    break;
            }
        });
    }

    // 显示添加任务菜单
    showAddTaskMenu() {
        console.clear();
        console.log('=== 添加新任务 ===');
        console.log('');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        const taskData = {};
        
        function askQuestion(question, key, defaultValue = '') {
            return new Promise((resolve) => {
                const prompt = defaultValue ? `${question} [${defaultValue}]: ` : `${question}: `;
                rl.question(prompt, (answer) => {
                    resolve(answer || defaultValue);
                });
            });
        }
        
        async function collectTaskData() {
            taskData.title = await askQuestion('任务标题');
            if (!taskData.title) {
                console.log('任务标题不能为空');
                return;
            }
            
            taskData.description = await askQuestion('任务描述');
            taskData.priority = await askQuestion('优先级 (high/medium/low)', 'priority', 'medium');
            taskData.category = await askQuestion('分类', 'category', 'general');
            
            const dueDateInput = await askQuestion('截止日期 (YYYY-MM-DD 或留空)');
            if (dueDateInput) {
                const dueDate = new Date(dueDateInput);
                if (!isNaN(dueDate.getTime())) {
                    taskData.dueDate = dueDate.toISOString();
                }
            }
            
            const tagsInput = await askQuestion('标签 (逗号分隔)');
            if (tagsInput) {
                taskData.tags = tagsInput.split(',').map(tag => tag.trim()).filter(tag => tag);
            }
            
            console.log('');
            console.log('任务信息:');
            console.log(`标题: ${taskData.title}`);
            console.log(`描述: ${taskData.description || '无'}`);
            console.log(`优先级: ${taskData.priority}`);
            console.log(`分类: ${taskData.category}`);
            console.log(`截止日期: ${taskData.dueDate ? new Date(taskData.dueDate).toLocaleDateString() : '无'}`);
            console.log(`标签: ${taskData.tags.length > 0 ? taskData.tags.join(', ') : '无'}`);
            console.log('');
            
            const confirm = await askQuestion('确认添加任务? (y/n)');
            if (confirm.toLowerCase() === 'y') {
                const newTask = this.sync.addTask(taskData);
                console.log('✅ 任务添加成功!');
                console.log(`任务ID: ${newTask.id}`);
            }
            
            rl.close();
            this.showMainMenu();
        }
        
        collectTaskData.call(this);
    }

    // 编辑任务
    editTask(task) {
        console.clear();
        console.log('=== 编辑任务 ===');
        console.log('');
        console.log(`当前任务: ${task.title}`);
        console.log('');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        const updates = {};
        
        function askQuestion(question, key, currentValue) {
            return new Promise((resolve) => {
                const prompt = currentValue ? `${question} [${currentValue}]: ` : `${question}: `;
                rl.question(prompt, (answer) => {
                    resolve(answer || currentValue);
                });
            });
        }
        
        async function collectUpdates() {
            updates.title = await askQuestion('新标题', 'title', task.title);
            updates.description = await askQuestion('新描述', 'description', task.description);
            updates.priority = await askQuestion('新优先级', 'priority', task.priority);
            updates.category = await askQuestion('新分类', 'category', task.category);
            
            const dueDateInput = await askQuestion('新截止日期 (YYYY-MM-DD 或留空)', 'dueDate', task.dueDate ? new Date(task.dueDate).toISOString().split('T')[0] : '');
            if (dueDateInput) {
                const dueDate = new Date(dueDateInput);
                if (!isNaN(dueDate.getTime())) {
                    updates.dueDate = dueDate.toISOString();
                } else {
                    delete updates.dueDate;
                }
            }
            
            const tagsInput = await askQuestion('新标签 (逗号分隔)', 'tags', task.tags.join(', '));
            if (tagsInput) {
                updates.tags = tagsInput.split(',').map(tag => tag.trim()).filter(tag => tag);
            }
            
            console.log('');
            console.log('更新后的任务信息:');
            console.log(`标题: ${updates.title}`);
            console.log(`描述: ${updates.description || '无'}`);
            console.log(`优先级: ${updates.priority}`);
            console.log(`分类: ${updates.category}`);
            console.log(`截止日期: ${updates.dueDate ? new Date(updates.dueDate).toLocaleDateString() : '无'}`);
            console.log(`标签: ${updates.tags.length > 0 ? updates.tags.join(', ') : '无'}`);
            console.log('');
            
            const confirm = await askQuestion('确认更新任务? (y/n)');
            if (confirm.toLowerCase() === 'y') {
                this.sync.updateTask(task.id, updates);
                console.log('✅ 任务更新成功!');
            }
            
            rl.close();
            this.showMainMenu();
        }
        
        collectUpdates.call(this);
    }

    // 更新任务状态
    updateTaskStatus(task) {
        console.clear();
        console.log('=== 更新任务状态 ===');
        console.log('');
        console.log(`当前任务: ${task.title}`);
        console.log(`当前状态: ${task.status}`);
        console.log('');
        console.log('可选状态:');
        console.log('1. pending (待处理)');
        console.log('2. in_progress (进行中)');
        console.log('3. completed (已完成)');
        console.log('');
        console.log('请选择新状态 (1-3):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择状态: ', (answer) => {
            rl.close();
            
            let newStatus;
            switch (answer) {
                case '1':
                    newStatus = 'pending';
                    break;
                case '2':
                    newStatus = 'in_progress';
                    break;
                case '3':
                    newStatus = 'completed';
                    break;
                default:
                    console.log('无效选择');
                    this.showTaskDetail(task);
                    return;
            }
            
            this.sync.updateTask(task.id, { status: newStatus });
            console.log('✅ 任务状态已更新!');
            this.showMainMenu();
        });
    }

    // 删除任务
    deleteTask(task) {
        console.clear();
        console.log('=== 删除任务 ===');
        console.log('');
        console.log(`确定要删除任务 "${task.title}" 吗?`);
        console.log('此操作不可撤销!');
        console.log('');
        console.log('请输入 "DELETE" 确认删除: ');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请输入 "DELETE": ', (answer) => {
            rl.close();
            
            if (answer === 'DELETE') {
                this.sync.deleteTask(task.id);
                console.log('✅ 任务已删除!');
            } else {
                console.log('取消删除');
            }
            
            this.showMainMenu();
        });
    }

    // 显示同步菜单
    showSyncMenu() {
        console.clear();
        console.log('=== 任务同步 ===');
        console.log('');
        console.log('1. 双向同步 (推荐)');
        console.log('2. 仅同步到飞书');
        console.log('3. 仅从飞书同步');
        console.log('4. 查看同步日志');
        console.log('5. 返回主菜单');
        console.log('');
        console.log('请选择操作 (1-5):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.performSync('both');
                    break;
                case '2':
                    this.performSync('to_feishu');
                    break;
                case '3':
                    this.performSync('from_feishu');
                    break;
                case '4':
                    this.showSyncLog();
                    break;
                case '5':
                    this.showMainMenu();
                    break;
                default:
                    this.showSyncMenu();
                    break;
            }
        });
    }

    // 执行同步
    async performSync(type) {
        console.clear();
        console.log('=== 执行同步 ===');
        console.log('');
        
        try {
            let result;
            switch (type) {
                case 'both':
                    console.log('开始双向同步...');
                    result = await this.sync.sync();
                    break;
                case 'to_feishu':
                    console.log('开始同步到飞书...');
                    result = await this.sync.syncTasksToFeishu();
                    break;
                case 'from_feishu':
                    console.log('开始从飞书同步...');
                    result = await this.sync.syncTasksFromFeishu();
                    break;
            }
            
            console.log('✅ 同步完成!');
            if (result) {
                console.log('同步结果:', result);
            }
            
            console.log('');
            console.log('按 Enter 键返回...');
            
            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            rl.question('', () => {
                rl.close();
                this.showMainMenu();
            });
            
        } catch (error) {
            console.error('❌ 同步失败:', error.message);
            console.log('');
            console.log('按 Enter 键返回...');
            
            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            rl.question('', () => {
                rl.close();
                this.showMainMenu();
            });
        }
    }

    // 显示同步日志
    showSyncLog() {
        console.clear();
        console.log('=== 同步日志 ===');
        console.log('');
        
        const syncLog = this.sync.syncLog;
        if (syncLog.length === 0) {
            console.log('没有同步日志');
            console.log('');
            console.log('按 Enter 键返回...');
            
            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            rl.question('', () => {
                rl.close();
                this.showSyncMenu();
            });
            return;
        }
        
        // 显示最近的20条日志
        const recentLogs = syncLog.slice(-20);
        recentLogs.forEach((log, index) => {
            const statusIcon = log.status === 'success' ? '✅' : '❌';
            console.log(`${index + 1}. [${statusIcon}] ${log.action} - ${log.message}`);
            console.log(`   时间: ${new Date(log.timestamp).toLocaleString()}`);
            console.log(`   任务ID: ${log.taskId}`);
            console.log('');
        });
        
        console.log(`显示最近 ${recentLogs.length} 条日志，共 ${syncLog.length} 条`);
        console.log('');
        console.log('按 Enter 键返回...');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('', () => {
            rl.close();
            this.showSyncMenu();
        });
    }

    // 显示搜索菜单
    showSearchMenu() {
        console.clear();
        console.log('=== 搜索任务 ===');
        console.log('');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请输入搜索关键词: ', (keyword) => {
            rl.close();
            
            if (keyword.trim()) {
                this.currentFilter.search = keyword.trim();
                this.currentPage = 1;
                this.showTaskList();
            } else {
                this.showMainMenu();
            }
        });
    }

    // 显示过滤菜单
    showFilterMenu() {
        console.clear();
        console.log('=== 过滤任务 ===');
        console.log('');
        console.log('1. 按状态过滤');
        console.log('2. 按优先级过滤');
        console.log('3. 按分类过滤');
        console.log('4. 清除所有过滤器');
        console.log('5. 返回');
        console.log('');
        console.log('请选择操作 (1-5):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.filterByStatus();
                    break;
                case '2':
                    this.filterByPriority();
                    break;
                case '3':
                    this.filterByCategory();
                    break;
                case '4':
                    this.currentFilter = {};
                    this.currentPage = 1;
                    this.showTaskList();
                    break;
                case '5':
                    this.showTaskList();
                    break;
                default:
                    this.showFilterMenu();
                    break;
            }
        });
    }

    // 按状态过滤
    filterByStatus() {
        console.clear();
        console.log('=== 按状态过滤 ===');
        console.log('');
        console.log('1. pending (待处理)');
        console.log('2. in_progress (进行中)');
        console.log('3. completed (已完成)');
        console.log('4. 返回');
        console.log('');
        console.log('请选择状态 (1-4):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择状态: ', (answer) => {
            rl.close();
            
            let status;
            switch (answer) {
                case '1':
                    status = 'pending';
                    break;
                case '2':
                    status = 'in_progress';
                    break;
                case '3':
                    status = 'completed';
                    break;
                case '4':
                    this.showFilterMenu();
                    return;
                default:
                    this.filterByStatus();
                    return;
            }
            
            this.currentFilter.status = status;
            this.currentPage = 1;
            this.showTaskList();
        });
    }

    // 按优先级过滤
    filterByPriority() {
        console.clear();
        console.log('=== 按优先级过滤 ===');
        console.log('');
        console.log('1. high (高)');
        console.log('2. medium (中)');
        console.log('3. low (低)');
        console.log('4. 返回');
        console.log('');
        console.log('请选择优先级 (1-4):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择优先级: ', (answer) => {
            rl.close();
            
            let priority;
            switch (answer) {
                case '1':
                    priority = 'high';
                    break;
                case '2':
                    priority = 'medium';
                    break;
                case '3':
                    priority = 'low';
                    break;
                case '4':
                    this.showFilterMenu();
                    return;
                default:
                    this.filterByPriority();
                    return;
            }
            
            this.currentFilter.priority = priority;
            this.currentPage = 1;
            this.showTaskList();
        });
    }

    // 按分类过滤
    filterByCategory() {
        const stats = this.sync.getTaskStats();
        const categories = Object.keys(stats.byCategory);
        
        console.clear();
        console.log('=== 按分类过滤 ===');
        console.log('');
        
        if (categories.length === 0) {
            console.log('没有可用的分类');
            console.log('');
            console.log('按 Enter 键返回...');
            
            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            rl.question('', () => {
                rl.close();
                this.showFilterMenu();
            });
            return;
        }
        
        categories.forEach((category, index) => {
            console.log(`${index + 1}. ${category} (${stats.byCategory[category]} 个任务)`);
        });
        
        console.log(`${categories.length + 1}. 返回`);
        console.log('');
        console.log('请选择分类 (1-', categories.length + 1, '):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择分类: ', (answer) => {
            rl.close();
            
            const choice = parseInt(answer);
            if (choice >= 1 && choice <= categories.length) {
                this.currentFilter.category = categories[choice - 1];
                this.currentPage = 1;
                this.showTaskList();
            } else if (choice === categories.length + 1) {
                this.showFilterMenu();
            } else {
                this.filterByCategory();
            }
        });
    }

    // 显示排序菜单
    showSortMenu() {
        console.clear();
        console.log('=== 排序任务 ===');
        console.log('');
        console.log('1. 按创建时间 (新到旧)');
        console.log('2. 按创建时间 (旧到新)');
        console.log('3. 按截止日期 (早到晚)');
        console.log('4. 按截止日期 (晚到早)');
        console.log('5. 按优先级 (高到低)');
        console.log('6. 按优先级 (低到高)');
        console.log('7. 返回');
        console.log('');
        console.log('请选择排序方式 (1-7):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择排序方式: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.currentSort = { sortBy: 'created_at', sortOrder: 'desc' };
                    break;
                case '2':
                    this.currentSort = { sortBy: 'created_at', sortOrder: 'asc' };
                    break;
                case '3':
                    this.currentSort = { sortBy: 'dueDate', sortOrder: 'asc' };
                    break;
                case '4':
                    this.currentSort = { sortBy: 'dueDate', sortOrder: 'desc' };
                    break;
                case '5':
                    this.currentSort = { sortBy: 'priority', sortOrder: 'desc' };
                    break;
                case '6':
                    this.currentSort = { sortBy: 'priority', sortOrder: 'asc' };
                    break;
                case '7':
                    this.showTaskList();
                    return;
                default:
                    this.showSortMenu();
                    return;
            }
            
            this.currentPage = 1;
            this.showTaskList();
        });
    }

    // 显示设置菜单
    showSettingsMenu() {
        console.clear();
        console.log('=== 设置 ===');
        console.log('');
        console.log('1. 每页显示任务数');
        console.log('2. 同步设置');
        console.log('3. 返回主菜单');
        console.log('');
        console.log('请选择操作 (1-3):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.changePageSize();
                    break;
                case '2':
                    this.showSyncSettings();
                    break;
                case '3':
                    this.showMainMenu();
                    break;
                default:
                    this.showSettingsMenu();
                    break;
            }
        });
    }

    // 改变每页显示任务数
    changePageSize() {
        console.clear();
        console.log('=== 每页显示任务数 ===');
        console.log('');
        console.log(`当前每页显示 ${this.pageSize} 个任务`);
        console.log('');
        console.log('请输入新的每页任务数 (5-50):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请输入每页任务数: ', (answer) => {
            rl.close();
            
            const newSize = parseInt(answer);
            if (newSize >= 5 && newSize <= 50) {
                this.pageSize = newSize;
                this.currentPage = 1;
                console.log(`✅ 已设置为每页 ${this.pageSize} 个任务`);
                console.log('');
                console.log('按 Enter 键返回...');
                
                const readline2 = require('readline');
                const rl2 = readline2.createInterface({
                    input: process.stdin,
                    output: process.stdout
                });
                
                rl2.question('', () => {
                    rl2.close();
                    this.showSettingsMenu();
                });
            } else {
                console.log('无效的每页任务数，请输入 5-50 之间的数字');
                this.changePageSize();
            }
        });
    }

    // 显示同步设置
    showSyncSettings() {
        console.clear();
        console.log('=== 同步设置 ===');
        console.log('');
        console.log('1. 是否同步已完成任务');
        console.log('2. 是否删除已完成的任务');
        console.log('3. 冲突解决策略');
        console.log('4. 返回');
        console.log('');
        console.log('请选择操作 (1-4):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.toggleSyncCompletedTasks();
                    break;
                case '2':
                    this.toggleDeleteCompletedTasks();
                    break;
                case '3':
                    this.changeConflictStrategy();
                    break;
                case '4':
                    this.showSettingsMenu();
                    break;
                default:
                    this.showSyncSettings();
                    break;
            }
        });
    }

    // 切换是否同步已完成任务
    toggleSyncCompletedTasks() {
        CONFIG.sync.syncCompletedTasks = !CONFIG.sync.syncCompletedTasks;
        console.log(`✅ 已${CONFIG.sync.syncCompletedTasks ? '开启' : '关闭'}同步已完成任务`);
        console.log('');
        console.log('按 Enter 键返回...');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('', () => {
            rl.close();
            this.showSyncSettings();
        });
    }

    // 切换是否删除已完成的任务
    toggleDeleteCompletedTasks() {
        CONFIG.sync.deleteCompletedTasks = !CONFIG.sync.deleteCompletedTasks;
        console.log(`✅ 已${CONFIG.sync.deleteCompletedTasks ? '开启' : '关闭'}删除已完成任务`);
        console.log('');
        console.log('按 Enter 键返回...');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('', () => {
            rl.close();
            this.showSyncSettings();
        });
    }

    // 改变冲突解决策略
    changeConflictStrategy() {
        console.clear();
        console.log('=== 冲突解决策略 ===');
        console.log('');
        console.log('当前策略:', CONFIG.sync.conflictStrategy);
        console.log('');
        console.log('可选策略:');
        console.log('1. local - 优先使用本地数据');
        console.log('2. remote - 优先使用远程数据');
        console.log('3. merge - 合并数据');
        console.log('');
        console.log('请选择策略 (1-3):');
        
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择策略: ', (answer) => {
            rl.close();
            
            let strategy;
            switch (answer) {
                case '1':
                    strategy = 'local';
                    break;
                case '2':
                    strategy = 'remote';
                    break;
                case '3':
                    strategy = 'merge';
                    break;
                default:
                    this.changeConflictStrategy();
                    return;
            }
            
            CONFIG.sync.conflictStrategy = strategy;
            console.log(`✅ 已设置为 ${strategy} 策略`);
            console.log('');
            console.log('按 Enter 键返回...');
            
            const readline2 = require('readline');
            const rl2 = readline2.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            rl2.question('', () => {
                rl2.close();
                this.showSyncSettings();
            });
        });
    }

    // 处理主菜单输入
    handleMainMenuInput() {
        const readline = require('readline');
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        rl.question('请选择操作: ', (answer) => {
            rl.close();
            
            switch (answer) {
                case '1':
                    this.showTaskList();
                    break;
                case '2':
                    this.showAddTaskMenu();
                    break;
                case '3':
                    // 编辑任务 - 这里简化为显示任务列表让用户选择
                    this.showTaskList();
                    break;
                case '4':
                    // 删除任务 - 这里简化为显示任务列表让用户选择
                    this.showTaskList();
                    break;
                case '5':
                    this.showSearchMenu();
                    break;
                case '6':
                    this.showSyncMenu();
                    break;
                case '7':
                    this.showSyncLog();
                    break;
                case '8':
                    this.showSettingsMenu();
                    break;
                case '9':
                    console.log('再见!');
                    process.exit(0);
                    break;
                default:
                    this.showMainMenu();
                    break;
            }
        });
    }

    // 启动任务管理器
    start() {
        this.showMainMenu();
        this.handleMainMenuInput();
    }
}

// 导出模块
module.exports = TaskManager;

// 如果直接运行此文件，启动任务管理器
if (require.main === module) {
    const manager = new TaskManager();
    manager.start();
}