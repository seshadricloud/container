# ============================================================================
# Python Flask Application with PostgreSQL Integration
# ============================================================================

from flask import Flask, jsonify, request, render_template
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from sqlalchemy.exc import SQLAlchemyError
import logging
import os
from datetime import datetime
from config import Config

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Initialize database
db = SQLAlchemy(app)
migrate = Migrate(app, db)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ============================================================================
# Database Models
# ============================================================================

class User(db.Model):
    """User model for the application"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'username': self.username,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

class Task(db.Model):
    """Task model for the application"""
    __tablename__ = 'tasks'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(20), nullable=False, default='pending')
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = db.relationship('User', backref=db.backref('tasks', lazy='dynamic'))
    
    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'status': self.status,
            'user_id': self.user_id,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }

# ============================================================================
# Health Check Endpoints
# ============================================================================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint for load balancer"""
    try:
        # Check database connectivity
        db.session.execute('SELECT 1')
        return jsonify({
            'status': 'ok',
            'version': os.getenv('APP_VERSION', '1.0.0')
        }), 200
    except SQLAlchemyError as e:
        logger.error(f"Database health check failed: {str(e)}")
        return jsonify({
            'status': 'unhealthy',
            'error': 'Database connection failed'
        }), 500

@app.route('/ready', methods=['GET'])
def readiness_check():
    """Readiness check endpoint for Kubernetes"""
    try:
        db.session.execute('SELECT 1')
        return jsonify({'status': 'ready'}), 200
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return jsonify({'status': 'not-ready'}), 503

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus metrics endpoint"""
    return f"""# HELP app_requests_total Total application requests
# TYPE app_requests_total counter
app_requests_total{{method="GET"}} 1
""", 200, {'Content-Type': 'text/plain'}

# ============================================================================
# API Endpoints - Users
# ============================================================================

@app.route('/api/v1/users', methods=['GET'])
def get_users():
    """Get all users"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        pagination = User.query.paginate(page=page, per_page=per_page)
        
        return jsonify({
            'data': [user.to_dict() for user in pagination.items],
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': pagination.total,
                'pages': pagination.pages
            }
        }), 200
    except Exception as e:
        logger.error(f"Error fetching users: {str(e)}")
        return jsonify({'error': 'Failed to fetch users'}), 500

@app.route('/api/v1/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get a specific user"""
    try:
        user = User.query.get_or_404(user_id)
        return jsonify(user.to_dict()), 200
    except Exception as e:
        logger.error(f"Error fetching user {user_id}: {str(e)}")
        return jsonify({'error': 'User not found'}), 404

@app.route('/api/v1/users', methods=['POST'])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        
        if not data or not data.get('email') or not data.get('username'):
            return jsonify({'error': 'Missing required fields'}), 400
        
        user = User(email=data['email'], username=data['username'])
        db.session.add(user)
        db.session.commit()
        
        logger.info(f"User created: {user.email}")
        return jsonify(user.to_dict()), 201
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error creating user: {str(e)}")
        return jsonify({'error': 'Failed to create user'}), 500

# ============================================================================
# API Endpoints - Tasks
# ============================================================================

@app.route('/api/v1/tasks', methods=['GET'])
def get_tasks():
    """Get all tasks"""
    try:
        status = request.args.get('status', None)
        user_id = request.args.get('user_id', None)
        
        query = Task.query
        if status:
            query = query.filter_by(status=status)
        if user_id:
            query = query.filter_by(user_id=user_id)
        
        tasks = query.all()
        return jsonify([task.to_dict() for task in tasks]), 200
    except Exception as e:
        logger.error(f"Error fetching tasks: {str(e)}")
        return jsonify({'error': 'Failed to fetch tasks'}), 500

@app.route('/api/v1/tasks', methods=['POST'])
def create_task():
    """Create a new task"""
    try:
        data = request.get_json()
        
        if not data or not data.get('title') or not data.get('user_id'):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify user exists
        user = User.query.get(data['user_id'])
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        task = Task(
            title=data['title'],
            description=data.get('description', ''),
            status=data.get('status', 'pending'),
            user_id=data['user_id']
        )
        db.session.add(task)
        db.session.commit()
        
        logger.info(f"Task created: {task.id}")
        return jsonify(task.to_dict()), 201
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error creating task: {str(e)}")
        return jsonify({'error': 'Failed to create task'}), 500

@app.route('/api/v1/tasks/<int:task_id>', methods=['PATCH'])
def update_task(task_id):
    """Update a task"""
    try:
        task = Task.query.get_or_404(task_id)
        data = request.get_json()
        
        if 'title' in data:
            task.title = data['title']
        if 'description' in data:
            task.description = data['description']
        if 'status' in data:
            task.status = data['status']
        
        db.session.commit()
        logger.info(f"Task updated: {task_id}")
        return jsonify(task.to_dict()), 200
    except SQLAlchemyError as e:
        db.session.rollback()
        logger.error(f"Database error updating task: {str(e)}")
        return jsonify({'error': 'Failed to update task'}), 500

# ============================================================================
# Error Handlers
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Resource not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
