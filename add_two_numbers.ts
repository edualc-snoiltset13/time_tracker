// Simple utility module demonstrating addition of two numbers.

export function addTwoNumbers(a: number, b: number): number {
  // Returns the sum of a and b. Works with integers and floats.
  return a + b;
}

// Integer example.
console.log(`3 + 5 = ${addTwoNumbers(3, 5)}`);

// Float example.
console.log(`10.5 + 4.2 = ${addTwoNumbers(10.5, 4.2)}`);

// Negative number example.
console.log(`-1 + 7 = ${addTwoNumbers(-1, 7)}`);
