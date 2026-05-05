def sum_even_numbers(numbers):
    """
    Returns the sum of only the even numbers from a list.

    Args:
        numbers: A list of integers

    Returns:
        The sum of all even numbers in the list

    Raises:
        TypeError: If input is not a list or contains non-integer values
        ValueError: If the list is empty
    """
    if not isinstance(numbers, list):
        raise TypeError("Input must be a list")

    if not numbers:
        raise ValueError("List cannot be empty")

    for num in numbers:
        if not isinstance(num, int) or isinstance(num, bool):
            raise TypeError(f"All values must be integers, got {type(num).__name__}")

    return sum(num for num in numbers if num % 2 == 0)
