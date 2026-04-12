const { ApiError } = require('./errorHandler');

/**
 * Creates a validation middleware that checks req.body against a schema.
 * Schema format: { fieldName: { required: bool, type: string } }
 */
function validate(schema) {
  return (req, res, next) => {
    const errors = [];

    for (const [field, rules] of Object.entries(schema)) {
      const value = req.body[field];

      if (rules.required && (value === undefined || value === null || value === '')) {
        errors.push(`'${field}' is required`);
        continue;
      }

      if (value !== undefined && value !== null && rules.type) {
        const actualType = typeof value;
        if (rules.type === 'number' && actualType !== 'number') {
          errors.push(`'${field}' must be a number`);
        } else if (rules.type === 'string' && actualType !== 'string') {
          errors.push(`'${field}' must be a string`);
        } else if (rules.type === 'boolean' && actualType !== 'boolean') {
          errors.push(`'${field}' must be a boolean`);
        }
      }
    }

    if (errors.length > 0) {
      return next(ApiError.badRequest(`Validation failed: ${errors.join(', ')}`));
    }

    next();
  };
}

module.exports = validate;
