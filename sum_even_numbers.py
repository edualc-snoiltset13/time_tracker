def sum_even_numbers(numbers):
    if not isinstance(numbers, list):
        raise TypeError(f"expected a list, got {type(numbers).__name__}")
    for i, n in enumerate(numbers):
        if not isinstance(n, int) or isinstance(n, bool):
            raise TypeError(
                f"expected int at index {i}, got {type(n).__name__}: {n!r}"
            )
    return sum(n for n in numbers if n % 2 == 0)


if __name__ == "__main__":
    print(sum_even_numbers([1, 2, 3, 4, 5, 6]))
    print(sum_even_numbers([7, 9, 11]))
    print(sum_even_numbers([-2, -1, 0, 1, 2]))
    print(sum_even_numbers([]))

    for bad in [[1, 2, "3"], [1, 2.5, 3], [1, True, 3], "not a list"]:
        try:
            sum_even_numbers(bad)
        except TypeError as e:
            print(f"TypeError for {bad!r}: {e}")
