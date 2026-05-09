def divide(a, b):
    """
    Divides a by b with validation.

    Args:
        a: The dividend (numerator)
        b: The divisor (denominator)

    Returns:
        The result of a / b

    Raises:
        TypeError: If inputs are not numbers
        ValueError: If b is zero
    """
    if not isinstance(a, (int, float)) or isinstance(a, bool):
        raise TypeError(f"First argument must be a number, got {type(a).__name__}")

    if not isinstance(b, (int, float)) or isinstance(b, bool):
        raise TypeError(f"Second argument must be a number, got {type(b).__name__}")

    if b == 0:
        raise ValueError("Cannot divide by zero")

    return a / b
