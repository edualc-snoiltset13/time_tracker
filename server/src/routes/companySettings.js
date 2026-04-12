const express = require('express');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const settingsSchema = {
  company_name: { required: true, type: 'string' },
  company_address: { required: true, type: 'string' },
  logo_path: { required: false, type: 'string' },
  show_letterhead: { required: false, type: 'boolean' },
};

// GET /api/company-settings - Get company settings (singleton)
router.get('/', (req, res) => {
  const db = getDb();
  const settings = db.prepare('SELECT * FROM company_settings ORDER BY id LIMIT 1').get();
  if (!settings) {
    return res.json(null);
  }
  res.json(settings);
});

// PUT /api/company-settings - Create or update company settings
router.put('/', validate(settingsSchema), (req, res) => {
  const db = getDb();
  const { company_name, company_address, logo_path, show_letterhead } = req.body;
  const existing = db.prepare('SELECT * FROM company_settings ORDER BY id LIMIT 1').get();

  if (existing) {
    db.prepare(
      `UPDATE company_settings SET company_name = ?, company_address = ?, logo_path = ?, show_letterhead = ?
       WHERE id = ?`
    ).run(company_name, company_address, logo_path || null, show_letterhead !== false ? 1 : 0, existing.id);
  } else {
    db.prepare(
      `INSERT INTO company_settings (company_name, company_address, logo_path, show_letterhead)
       VALUES (?, ?, ?, ?)`
    ).run(company_name, company_address, logo_path || null, show_letterhead !== false ? 1 : 0);
  }

  const settings = db.prepare('SELECT * FROM company_settings ORDER BY id LIMIT 1').get();
  res.json(settings);
});

module.exports = router;
