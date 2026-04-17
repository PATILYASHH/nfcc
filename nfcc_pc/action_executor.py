"""Thin dispatcher over the `actions` package.

Kept for compatibility with the old import path:
    `from action_executor import execute_action`

Returns `(success, message, data)`. The previous
(success, message) tuple still works via unpacking in older
callers — data is extra on the end.
"""

import logging
from typing import Any, Dict, Tuple

from actions import ACTION_MAP, available_actions

logger = logging.getLogger("nfcc")

__all__ = ["execute_action", "available_actions"]


def execute_action(action: str, params: dict) -> Tuple[bool, str, Dict[str, Any]]:
    handler = ACTION_MAP.get(action)
    if handler is None:
        return False, f"Unknown action: {action}", {}
    try:
        result = handler(params or {})
    except Exception as e:
        logger.exception("Action '%s' crashed", action)
        return False, f"{type(e).__name__}: {e}", {}

    # Accept both (ok, msg) and (ok, msg, data) from legacy handlers.
    if len(result) == 2:
        success, message = result
        return bool(success), str(message), {}
    success, message, data = result
    return bool(success), str(message), data or {}
