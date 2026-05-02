import sys


def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    return a * b


def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b


def modulo(a, b):
    if b == 0:
        raise ValueError("Cannot modulo by zero")
    return a % b


def power(a, b):
    return a ** b


OPERATIONS = {
    "+": add,
    "-": subtract,
    "*": multiply,
    "/": divide,
    "%": modulo,
    "**": power,
}


def calculate(a, op, b):
    if op not in OPERATIONS:
        raise ValueError(f"Unknown operator: {op}. Supported: {', '.join(OPERATIONS)}")
    return OPERATIONS[op](a, b)


def main():
    print("Python Calculator")
    print(f"Supported operators: {', '.join(OPERATIONS)}")
    print("Type 'quit' to exit.\n")

    while True:
        try:
            expr = input(">>> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not expr or expr.lower() in ("quit", "exit", "q"):
            break

        parts = expr.split()
        if len(parts) != 3:
            print("Usage: <number> <operator> <number>  (e.g. 5 + 3)")
            continue

        try:
            a = float(parts[0])
            op = parts[1]
            b = float(parts[2])
            result = calculate(a, op, b)
            if result == int(result):
                result = int(result)
            print(f"= {result}")
        except ValueError as e:
            print(f"Error: {e}")


if __name__ == "__main__":
    main()
