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


OPERATIONS = {
    "+": add,
    "-": subtract,
    "*": multiply,
    "/": divide,
}


def calculate(a, op, b):
    if op not in OPERATIONS:
        raise ValueError(f"Unknown operator: {op}. Use one of {list(OPERATIONS)}")
    return OPERATIONS[op](a, b)


def main():
    if len(sys.argv) == 4:
        a, op, b = float(sys.argv[1]), sys.argv[2], float(sys.argv[3])
        print(calculate(a, op, b))
        return

    print("Calculator — type expressions like: 2 + 3")
    print("Operators: + - * /")
    print("Type 'quit' to exit.\n")

    while True:
        try:
            line = input("> ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if line.lower() in ("quit", "exit", "q"):
            break
        parts = line.split()
        if len(parts) != 3:
            print("Usage: <number> <operator> <number>")
            continue
        try:
            result = calculate(float(parts[0]), parts[1], float(parts[2]))
            print(result)
        except ValueError as e:
            print(f"Error: {e}")


if __name__ == "__main__":
    main()
