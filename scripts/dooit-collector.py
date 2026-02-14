import json
from datetime import datetime, date
from dooit.api import Todo, manager

manager.connect()

def format_datetime(datetime_obj):
    return datetime_obj.strftime("%d/%m/%Y") if datetime_obj is not None else ""

today_str = format_datetime(date.today())

todays = []
no_due_todos = []

todos = Todo.all()
for todo in todos:
    formatted_due_date = format_datetime(todo.due)
    due_str = formatted_due_date if getattr(todo, "due", None) else None
    if due_str == today_str or (todo.due is not None and todo.due <= datetime.today()):
        if (todo.due is not None and todo.due < datetime.today()) and todo.pending:
            todays.append(todo)
        elif due_str == today_str:
            todays.append(todo)
    elif getattr(todo, "due", None) is None:
        if todo.pending:
            no_due_todos.append(todo)

def created_dt(t):
    """Best-effort: return a datetime for sorting (older first)."""
    v = getattr(t, "due", None)
    if v:
        return v  # oft schon datetime
    # Fallback: sehr weit in die Zukunft => landet am Ende (nicht 'ältest')
    return datetime.max

# 5 älteste ohne due
no_due_oldest_5 = sorted(no_due_todos, key=created_dt)[:5]

all_todos = todays + no_due_oldest_5
all_todos = [[t.description, t.pending, t.due.strftime("%d/%m/%Y") if getattr(t, "due", None) else None] for t in all_todos]

payload = {
    "todoCount": str(len(all_todos)),
    "class": "dooit",
    "todos": all_todos
}

print(json.dumps(payload, ensure_ascii=False))
