def sum_even_numbers(numbers):
    return sum(n for n in numbers if n % 2 == 0)


if __name__ == "__main__":
    print(sum_even_numbers([1, 2, 3, 4, 5, 6]))
    print(sum_even_numbers([7, 9, 11]))
    print(sum_even_numbers([-2, -1, 0, 1, 2]))
    print(sum_even_numbers([]))
