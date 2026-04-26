# Simple utility module demonstrating addition of two numbers.

def add_two_numbers(a, b):
    # Returns the sum of a and b. Works with ints and floats.
    return a + b


if __name__ == "__main__":
    # Integer example.
    result = add_two_numbers(3, 5)
    print(f"3 + 5 = {result}")

    # Float example.
    result = add_two_numbers(10.5, 4.2)
    print(f"10.5 + 4.2 = {result}")

    # Negative number example.
    result = add_two_numbers(-1, 7)
    print(f"-1 + 7 = {result}")
