from flask import Flask, request, jsonify
from datetime import datetime
from dateutil import parser as dateutil_parser
from flask_migrate import Migrate
from openai import OpenAI
from models import db, Tasks
import json

app = Flask(__name__)

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///tasks.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

Migrate(app, db)

@app.route('/tasks', methods=['GET'])
def get_tasks():
    tasks = Tasks.query.all()
    print([task.to_dict() for task in tasks])
    return jsonify([task.to_dict() for task in tasks])

@app.route('/tasks', methods=['POST'])
def add_task():
    data = request.json
    new_task = Tasks(title=data['title'])
    db.session.add(new_task)
    db.session.commit()
    return jsonify(new_task.to_dict()), 201

@app.route('/tasks/<int:id>', methods=['PATCH'])
def update_task(id):
    task = Tasks.query.filter(Tasks.id == id).first()
    if not task:
        return jsonify({"error": "Task not found"}), 404
    
    data = request.json
    if 'title' in data:
        task.title = data['title']
        print(task.title)
    if 'start_time' in data:
        try:
            task.start_time = dateutil_parser.isoparse(data['start_time']) if data['start_time'] else None
            print(task.start_time)
        except ValueError:
            return jsonify({"error": "Invalid start_time format"}), 400
    if 'end_time' in data:
        try:
            task.end_time = dateutil_parser.isoparse(data['end_time']) if data['end_time'] else None
            print(task.end_time)
        except ValueError:
            return jsonify({"error": "Invalid end_time format"}), 400
    if 'completed' in data:
        task.completed = data['completed']
        print(task.completed)
    
    db.session.commit()
    return jsonify(task.to_dict())

@app.route('/tasks/<int:id>', methods=['DELETE'])
def delete_task(id):
    task = Tasks.query.get(id)
    if not task:
        return jsonify({"error": "Task not found"}), 404
    
    db.session.delete(task)
    db.session.commit()
    return '', 204


# @app.route('/generate_schedule', methods=['POST'])
# def generate_schedule():
#     data = request.get_json()
#     task_titles = [task['title'] for task in data]
    
#     if not task_titles:
#         return jsonify({"error": "No titles provided"}), 400

#     # Create a new thread for the assistant
#     thread = client.beta.threads.create()

#     message = client.beta.threads.messages.create(
#         thread_id=thread.id,
#         role="user",
#         content= f'take in this JSON data {task_titles} and populate it with a start_time, and end_time, and create a completed column and set it to false'
#     )
    
#     run = client.beta.threads.runs.create_and_poll(
#         thread_id=thread.id,
#         assistant_id=assistant.id,
#         instructions="Generate a one-hour duration for each task. The task's start_time and end_time should always be set to the current date, RIGHT ON THE HOUR in ISO format.(example: 2024-07-29T14:00:00Z-04:00). They must all be placed in different time slots between 7AM and 7PM. Only show me the JSON data, no other text. Remove this as well ```json```."
#     )

#     if run.status == 'completed': 
#         messages = client.beta.threads.messages.list(
#             thread_id=thread.id
#         )
#         value = messages.data[0].content[0].text.value

#         try:
#             schedule = json.loads(value)
            
#             # Remove the existing tasks with matching titles that don't have start_time and end_time
#             for task_title in task_titles:
#                 task = Tasks.query.filter_by(title=task_title).first()
#                 if task and (task.start_time is None and task.end_time is None):
#                     db.session.delete(task)
#             db.session.commit()
            
#             # Add the new tasks with the generated schedule
#             for task_data in schedule:
#                 existing_task = Tasks.query.filter_by(title=task_data['task']).first()
#                 if existing_task:
#                     # Only update the completed status if start_time and end_time exist
#                     if existing_task.start_time and existing_task.end_time:
#                         existing_task.completed = task_data['completed']
#                 else:
#                     new_task = Tasks(
#                         title=task_data['task'],
#                         start_time=datetime.fromisoformat(task_data['start_time'].replace("Z", "+00:00")),
#                         end_time=datetime.fromisoformat(task_data['end_time'].replace("Z", "+00:00")),
#                         completed=task_data['completed']
#                     )
#                     db.session.add(new_task)
                
#             db.session.commit()

#             return jsonify({"message": "Schedule generated and tasks added successfully"}), 200

#         except TypeError as e:
#             return jsonify({"error": f"Failed to parse or add tasks: {str(e)}"}), 500

#     else:
#         return jsonify({"error": f"AI run status: {run.status}"}), 500

if __name__ == '__main__':
    app.run(debug=True)