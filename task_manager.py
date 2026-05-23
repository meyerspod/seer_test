"""Simple task manager with priority and due-date support."""

from dataclasses import dataclass, field
from datetime import date
from typing import List, Optional


VALID_PRIORITIES = {"low", "medium", "high"}


@dataclass
class Task:
    title: str
    priority: str = "medium"
    due_date: Optional[date] = None
    done: bool = False

    def __post_init__(self):
        if self.priority not in VALID_PRIORITIES:
            raise ValueError(f"priority must be one of {VALID_PRIORITIES}")


@dataclass
class TaskManager:
    tasks: List[Task] = field(default_factory=list)

    def add_task(self, task: Task) -> None:
        self.tasks.append(task)

    def complete_task(self, title: str) -> bool:
        for task in self.tasks:
            if task.title == title:
                task.done = True
                return True
        return False

    def filter_by_priority(self, priority: str) -> List[Task]:
        if priority not in VALID_PRIORITIES:
            raise ValueError(f"priority must be one of {VALID_PRIORITIES}")
        return [t for t in self.tasks if t.priority == priority]

    def sort_by_due_date(self) -> List[Task]:
        # TODO: implement sort_by_due_date — return tasks sorted ascending by due_date,
        # with tasks that have no due_date placed at the end
        return sorted(self.tasks, key=lambda t: (t.due_date is None, t.due_date))

    def pending_tasks(self) -> List[Task]:
        # TODO: implement pending_tasks — return tasks that are not yet done
        return [t for t in self.tasks if not t.done]

    def summary(self) -> dict:
        # TODO: implement summary — return a dict with keys 'total', 'done', 'pending',
        # and counts for each priority level: 'low', 'medium', 'high'
        done_count = sum(1 for t in self.tasks if t.done)
        return {
            "total": len(self.tasks),
            "done": done_count,
            "pending": len(self.tasks) - done_count,
            **{p: sum(1 for t in self.tasks if t.priority == p) for p in VALID_PRIORITIES},
        }
