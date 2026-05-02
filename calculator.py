"""A safe-expression calculator.

Run interactively:
    python calculator.py

Or evaluate a single expression:
    python calculator.py "2 + 2 * sqrt(16)"

Supported:
    + - * / // % **          arithmetic
    ( )                       grouping
    unary + and -             sign
    sqrt, sin, cos, tan,
    asin, acos, atan, log,
    log2, log10, exp, abs,
    floor, ceil, round, fact  functions
    pi, e, tau                constants
    ans                       previous result (REPL only)
"""

from __future__ import annotations

import ast
import math
import operator as op
import sys
from typing import Callable

_BIN_OPS: dict[type, Callable[[float, float], float]] = {
    ast.Add: op.add,
    ast.Sub: op.sub,
    ast.Mult: op.mul,
    ast.Div: op.truediv,
    ast.FloorDiv: op.floordiv,
    ast.Mod: op.mod,
    ast.Pow: op.pow,
}

_UNARY_OPS: dict[type, Callable[[float], float]] = {
    ast.UAdd: op.pos,
    ast.USub: op.neg,
}

_FUNCS: dict[str, Callable] = {
    "sqrt": math.sqrt,
    "sin": math.sin,
    "cos": math.cos,
    "tan": math.tan,
    "asin": math.asin,
    "acos": math.acos,
    "atan": math.atan,
    "log": math.log,
    "log2": math.log2,
    "log10": math.log10,
    "exp": math.exp,
    "abs": abs,
    "floor": math.floor,
    "ceil": math.ceil,
    "round": round,
    "fact": math.factorial,
}

_CONSTS: dict[str, float] = {
    "pi": math.pi,
    "e": math.e,
    "tau": math.tau,
}


class CalcError(Exception):
    """Raised on any user-facing calculator error."""


def evaluate(expression: str, *, ans: float | None = None) -> float:
    """Evaluate a math expression and return the numeric result."""
    expression = expression.strip()
    if not expression:
        raise CalcError("Empty expression.")
    try:
        tree = ast.parse(expression, mode="eval")
    except SyntaxError as exc:
        raise CalcError(f"Syntax error: {exc.msg}") from exc

    names = dict(_CONSTS)
    if ans is not None:
        names["ans"] = ans
    return _eval(tree.body, names)


def _eval(node: ast.AST, names: dict[str, float]) -> float:
    if isinstance(node, ast.Constant):
        if isinstance(node.value, (int, float)):
            return node.value
        raise CalcError(f"Unsupported literal: {node.value!r}")

    if isinstance(node, ast.Name):
        if node.id in names:
            return names[node.id]
        raise CalcError(f"Unknown name: {node.id}")

    if isinstance(node, ast.BinOp):
        fn = _BIN_OPS.get(type(node.op))
        if fn is None:
            raise CalcError(f"Unsupported operator: {type(node.op).__name__}")
        left = _eval(node.left, names)
        right = _eval(node.right, names)
        try:
            return fn(left, right)
        except ZeroDivisionError as exc:
            raise CalcError("Division by zero.") from exc

    if isinstance(node, ast.UnaryOp):
        fn = _UNARY_OPS.get(type(node.op))
        if fn is None:
            raise CalcError(f"Unsupported unary operator: {type(node.op).__name__}")
        return fn(_eval(node.operand, names))

    if isinstance(node, ast.Call):
        if not isinstance(node.func, ast.Name):
            raise CalcError("Only direct function calls are allowed.")
        fname = node.func.id
        if fname not in _FUNCS:
            raise CalcError(f"Unknown function: {fname}")
        if node.keywords:
            raise CalcError(f"{fname}() does not accept keyword arguments.")
        args = [_eval(a, names) for a in node.args]
        try:
            return _FUNCS[fname](*args)
        except (ValueError, TypeError, OverflowError) as exc:
            raise CalcError(f"{fname}: {exc}") from exc

    raise CalcError(f"Unsupported expression element: {type(node).__name__}")


def _format(value: float) -> str:
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value)


def _repl() -> int:
    print("Calculator. Type 'quit' or Ctrl-D to exit. 'ans' refers to the last result.")
    ans: float | None = None
    while True:
        try:
            line = input("> ")
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        line = line.strip()
        if not line:
            continue
        if line.lower() in {"quit", "exit"}:
            return 0
        try:
            ans = evaluate(line, ans=ans)
            print(_format(ans))
        except CalcError as exc:
            print(f"Error: {exc}")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) > 1:
        expr = " ".join(argv[1:])
        try:
            print(_format(evaluate(expr)))
            return 0
        except CalcError as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return 1
    return _repl()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
