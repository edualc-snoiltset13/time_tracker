def sum_even_numbers(numbers):
    """
    Returns the sum of only the even numbers from a list.

    Args:
        numbers: A list of integers

    Returns:
        The sum of all even numbers in the list
    """
    return sum(num for num in numbers if num % 2 == 0)
