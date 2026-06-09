# ============================================================================
# Unit Tests for Flask Application
# ============================================================================

import pytest
import json
from app import app, db, User, Task

@pytest.fixture
def client():
    """Create a test client"""
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    
    with app.app_context():
        db.create_all()
        yield app.test_client()
        db.session.remove()
        db.drop_all()

class TestHealthCheck:
    """Health check endpoint tests"""
    
    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get('/health')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'ok'

class TestUsers:
    """User endpoint tests"""
    
    def test_create_user(self, client):
        """Test creating a user"""
        response = client.post('/api/v1/users', 
            json={
                'email': 'test@example.com',
                'username': 'testuser'
            }
        )
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['email'] == 'test@example.com'

    def test_get_users(self, client):
        """Test fetching users"""
        # Create a user first
        client.post('/api/v1/users', 
            json={
                'email': 'test@example.com',
                'username': 'testuser'
            }
        )
        
        response = client.get('/api/v1/users')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data['data']) == 1

class TestTasks:
    """Task endpoint tests"""
    
    def test_create_task(self, client):
        """Test creating a task"""
        # Create user first
        user_response = client.post('/api/v1/users',
            json={
                'email': 'test@example.com',
                'username': 'testuser'
            }
        )
        user_id = json.loads(user_response.data)['id']
        
        # Create task
        response = client.post('/api/v1/tasks',
            json={
                'title': 'Test Task',
                'description': 'A test task',
                'user_id': user_id
            }
        )
        assert response.status_code == 201
        data = json.loads(response.data)
        assert data['title'] == 'Test Task'

    def test_get_tasks(self, client):
        """Test fetching tasks"""
        response = client.get('/api/v1/tasks')
        assert response.status_code == 200

if __name__ == '__main__':
    pytest.main([__file__, '-v'])
