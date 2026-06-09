class ToDoApp {
    constructor() {
        this.tasks = [];
        this.currentFilter = 'all';
        this.editingTaskId = null;
        this.confirmAction = null;
        this.init();
    }

    init() {
        this.loadTasks();
        this.setupEventListeners();
        this.render();
    }

    setupEventListeners() {
        // Add task
        document.getElementById('addBtn').addEventListener('click', () => this.addTask());
        document.getElementById('todoInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addTask();
        });

        // Filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                e.target.closest('.filter-btn').classList.add('active');
                this.currentFilter = e.target.closest('.filter-btn').dataset.filter;
                this.render();
            });
        });

        // Action buttons
        document.getElementById('clearCompletedBtn').addEventListener('click', () => this.showConfirmModal(
            'Are you sure you want to clear all completed tasks?',
            () => this.clearCompleted()
        ));

        document.getElementById('clearAllBtn').addEventListener('click', () => this.showConfirmModal(
            'Are you sure you want to delete all tasks? This cannot be undone.',
            () => this.clearAll()
        ));

        // Modal buttons
        document.getElementById('cancelBtn').addEventListener('click', () => this.hideConfirmModal());
        document.getElementById('confirmBtn').addEventListener('click', () => {
            if (this.confirmAction) this.confirmAction();
            this.hideConfirmModal();
        });

        document.getElementById('editCancelBtn').addEventListener('click', () => this.hideEditModal());
        document.getElementById('editConfirmBtn').addEventListener('click', () => this.saveEdit());
        document.getElementById('editInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.saveEdit();
        });

        // Close modals on escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.hideConfirmModal();
                this.hideEditModal();
            }
        });
    }

    addTask() {
        const input = document.getElementById('todoInput');
        const text = input.value.trim();

        if (!text) {
            this.showToast('Please enter a task', 'warning');
            input.focus();
            return;
        }

        if (text.length > 200) {
            this.showToast('Task must be less than 200 characters', 'warning');
            return;
        }

        const task = {
            id: Date.now(),
            text: text,
            completed: false,
            createdAt: new Date().toISOString()
        };

        this.tasks.unshift(task);
        this.saveTasks();
        this.render();
        input.value = '';
        input.focus();
        this.showToast('Task added successfully', 'success');
    }

    deleteTask(id) {
        this.showConfirmModal(
            'Are you sure you want to delete this task?',
            () => {
                this.tasks = this.tasks.filter(task => task.id !== id);
                this.saveTasks();
                this.render();
                this.showToast('Task deleted', 'success');
            }
        );
    }

    toggleTask(id) {
        const task = this.tasks.find(t => t.id === id);
        if (task) {
            task.completed = !task.completed;
            this.saveTasks();
            this.render();
        }
    }

    editTask(id) {
        const task = this.tasks.find(t => t.id === id);
        if (task) {
            this.editingTaskId = id;
            document.getElementById('editInput').value = task.text;
            this.showEditModal();
            document.getElementById('editInput').focus();
            document.getElementById('editInput').select();
        }
    }

    saveEdit() {
        const input = document.getElementById('editInput');
        const newText = input.value.trim();

        if (!newText) {
            this.showToast('Task cannot be empty', 'warning');
            return;
        }

        if (newText.length > 200) {
            this.showToast('Task must be less than 200 characters', 'warning');
            return;
        }

        const task = this.tasks.find(t => t.id === this.editingTaskId);
        if (task) {
            task.text = newText;
            this.saveTasks();
            this.render();
            this.hideEditModal();
            this.showToast('Task updated successfully', 'success');
        }
    }

    clearCompleted() {
        const before = this.tasks.length;
        this.tasks = this.tasks.filter(task => !task.completed);
        const cleared = before - this.tasks.length;
        if (cleared > 0) {
            this.saveTasks();
            this.render();
            this.showToast(`${cleared} completed task${cleared !== 1 ? 's' : ''} cleared`, 'success');
        }
    }

    clearAll() {
        this.tasks = [];
        this.saveTasks();
        this.render();
        this.showToast('All tasks cleared', 'success');
    }

    getFilteredTasks() {
        if (this.currentFilter === 'active') {
            return this.tasks.filter(task => !task.completed);
        } else if (this.currentFilter === 'completed') {
            return this.tasks.filter(task => task.completed);
        }
        return this.tasks;
    }

    updateStats() {
        const total = this.tasks.length;
        const completed = this.tasks.filter(t => t.completed).length;
        const active = total - completed;

        document.getElementById('totalTasks').textContent = total;
        document.getElementById('activeTasks').textContent = active;
        document.getElementById('completedTasks').textContent = completed;
    }

    render() {
        const tasksList = document.getElementById('tasksList');
        const emptyState = document.getElementById('emptyState');
        const filteredTasks = this.getFilteredTasks();

        if (filteredTasks.length === 0) {
            tasksList.innerHTML = '';
            emptyState.classList.remove('hidden');
        } else {
            emptyState.classList.add('hidden');
            tasksList.innerHTML = filteredTasks.map(task => `
                <li class="task-item ${task.completed ? 'completed' : ''}" data-id="${task.id}">
                    <input
                        type="checkbox"
                        class="task-checkbox"
                        ${task.completed ? 'checked' : ''}
                        onchange="app.toggleTask(${task.id})"
                    />
                    <span class="task-text">${this.escapeHtml(task.text)}</span>
                    <div class="task-actions">
                        <button class="task-btn edit-btn" onclick="app.editTask(${task.id})" title="Edit task">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="task-btn delete-btn" onclick="app.deleteTask(${task.id})" title="Delete task">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </li>
            `).join('');
        }

        this.updateStats();
    }

    showConfirmModal(message, action) {
        document.getElementById('modalMessage').textContent = message;
        this.confirmAction = action;
        document.getElementById('confirmModal').classList.add('active');
    }

    hideConfirmModal() {
        document.getElementById('confirmModal').classList.remove('active');
        this.confirmAction = null;
    }

    showEditModal() {
        document.getElementById('editModal').classList.add('active');
    }

    hideEditModal() {
        document.getElementById('editModal').classList.remove('active');
        this.editingTaskId = null;
    }

    showToast(message, type = 'success') {
        const toast = document.getElementById('toast');
        toast.textContent = message;
        toast.className = `toast show ${type}`;
        
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    saveTasks() {
        try {
            localStorage.setItem('todoTasks', JSON.stringify(this.tasks));
        } catch (error) {
            console.error('Error saving tasks to localStorage:', error);
            this.showToast('Failed to save tasks', 'error');
        }
    }

    loadTasks() {
        try {
            const saved = localStorage.getItem('todoTasks');
            this.tasks = saved ? JSON.parse(saved) : [];
        } catch (error) {
            console.error('Error loading tasks from localStorage:', error);
            this.tasks = [];
            this.showToast('Failed to load tasks', 'error');
        }
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize app when DOM is ready
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new ToDoApp();
});
