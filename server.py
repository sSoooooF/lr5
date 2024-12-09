from flask import Flask, request, jsonify
from flask_cors import CORS
from uuid import uuid4
import jwt
import datetime
from functools import wraps

app = Flask(__name__)
app.config['SECRET_KEY'] = '1111'

CORS(app)

tasks = {}

def token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'message': 'Token is missing'}), 403
        try:
            jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired'}), 403
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Token is invalid'}), 403
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['POST'])
def login():
    auth = request.get_json()
    if auth.get('username') == 'user' and auth.get('password') == 'password':
        token = jwt.encode({
            'user': 'user',
            'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)
        }, app.config['SECRET_KEY'], algorithm="HS256")
        return jsonify({'token': token})
    return jsonify({'message': 'Bad credentials'}), 401

@app.route('/tasks', methods=['POST'])
@token_required
def create_task():
    data = request.get_json()
    task_id = str(uuid4())
    task = {
        'id': task_id,
        'title': data['title'],
        'description': data.get('description', ''),
        'done': False,
        'comments': []
    }
    tasks[task_id] = task
    return jsonify(task), 201

@app.route('/tasks', methods=['GET'])
@token_required
def get_tasks():
    filter_done = request.args.get('done', type=bool)
    sort_by = request.args.get('sort_by', default='title')

    filtered_tasks = list(tasks.values())
    if filter_done is not None:
        filtered_tasks = [task for task in filtered_tasks if task['done'] == filter_done]

    filtered_tasks.sort(key=lambda x: x.get(sort_by, ''))
    return jsonify(filtered_tasks)

@app.route('/tasks/export', methods=['GET'])
@token_required
def export_tasks():
    export_format = request.args.get('format', 'json')
    if export_format == 'json':
        return jsonify(list(tasks.values()))
    elif export_format == 'csv':
        output = "id,title,description,done\n"
        for task in tasks.values():
            output += f"{task['id']},{task['title']},{task['description']},{task['done']}\n"
        response = app.response_class(
            response=output,
            mimetype='text/csv',
            status=200
        )
        response.headers['Content-Disposition'] = 'attachment; filename=tasks.csv'
        return response
    return jsonify({'message': 'Unsupported format'}), 400

@app.route('/tasks/<task_id>/comments', methods=['POST'])
@token_required
def add_comment(task_id):
    task = tasks.get(task_id)
    if not task:
        return jsonify({'message': 'Task not found'}), 404
    comment = request.get_json().get('comment')
    if not comment: 
        return jsonify({'message': 'Comment cannot be empty'}), 400  
    task['comments'].append(comment)
    return jsonify(task), 201

@app.route('/tasks/<task_id>/comments', methods=['GET'])
@token_required
def get_comments(task_id):
    task = tasks.get(task_id)
    if task:
        return jsonify(task.get('comments', []))
    return jsonify({'message': 'Task not found'}), 404

@app.route('/tasks/<task_id>', methods=['GET'])
@token_required
def get_task(task_id):
    task = tasks.get(task_id)
    if task:
        return jsonify(task)
    return jsonify({'message': 'Task not found'}), 404

@app.route('/tasks/<task_id>', methods=['PUT'])
@token_required
def update_task(task_id):
    task = tasks.get(task_id)
    if task:
        data = request.get_json()
        task['title'] = data.get('title', task['title'])
        task['description'] = data.get('description', task['description'])
        task['done'] = data.get('done', task['done'])
        return jsonify(task)
    return jsonify({'message': 'Task not found'}), 404

@app.route('/tasks/<task_id>', methods=['DELETE'])
@token_required
def delete_task(task_id):
    if task_id in tasks:
        del tasks[task_id]
        return jsonify({'message': 'Task deleted'})
    return jsonify({'message': 'Task not found'}), 404

if __name__ == '__main__':
    app.run(debug=True)
