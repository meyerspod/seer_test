import pytest
from datetime import date
from task_manager import Task, TaskManager


@pytest.fixture
def manager():
    m = TaskManager()
    m.add_task(Task("Buy groceries", priority="low", due_date=date(2026, 6, 1)))
    m.add_task(Task("Fix bug #42", priority="high", due_date=date(2026, 5, 25)))
    m.add_task(Task("Write tests", priority="medium"))
    m.add_task(Task("Deploy release", priority="high", due_date=date(2026, 5, 24)))
    return m


def test_add_and_complete(manager):
    assert manager.complete_task("Write tests") is True
    assert manager.complete_task("Nonexistent") is False


def test_invalid_priority():
    with pytest.raises(ValueError):
        Task("Bad task", priority="urgent")


def test_filter_by_priority(manager):
    high = manager.filter_by_priority("high")
    assert len(high) == 2
    assert all(t.priority == "high" for t in high)

    low = manager.filter_by_priority("low")
    assert len(low) == 1
    assert low[0].title == "Buy groceries"

    medium = manager.filter_by_priority("medium")
    assert len(medium) == 1


def test_sort_by_due_date(manager):
    sorted_tasks = manager.sort_by_due_date()
    dated = [t for t in sorted_tasks if t.due_date is not None]
    undated = [t for t in sorted_tasks if t.due_date is None]

    assert dated[0].due_date <= dated[1].due_date <= dated[2].due_date
    assert all(t in undated for t in manager.tasks if t.due_date is None)


def test_pending_tasks(manager):
    manager.complete_task("Fix bug #42")
    pending = manager.pending_tasks()
    assert all(not t.done for t in pending)
    assert len(pending) == 3


def test_summary(manager):
    manager.complete_task("Deploy release")
    s = manager.summary()
    assert s["total"] == 4
    assert s["done"] == 1
    assert s["pending"] == 3
    assert s["high"] == 2
    assert s["medium"] == 1
    assert s["low"] == 1
