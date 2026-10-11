import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

import { query, pool } from './db.js';
import { auth, signToken } from './auth.js';

import {
  ReservationQueue,
  HistoryStack,
  BookBST,
  mergeSort,
  genreFrequency
} from './dsa.js';

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ------------------------------------------------------
// HELPERS
// ------------------------------------------------------

function normalizeEmail(value) {
  return String(value ?? '').trim().toLowerCase();
}

function sendServerError(res, error, label) {
  console.error(`${label}:`, error);

  return res.status(500).json({
    message: 'Something went wrong. Please try again.'
  });
}

function readPositiveId(value) {
  const id = Number(value);

  return Number.isSafeInteger(id) && id > 0 ? id : null;
}

function isAdmin(user) {
  return String(user?.role ?? '').toLowerCase() === 'admin';
}

function isCommunityBookOwner(book, user) {
  return (
    book.is_community_recommendation === true &&
    Number(book.submitted_by) === Number(user?.id)
  );
}

function validateBook(body = {}) {
  const title = String(body.title ?? '').trim();
  const author = String(body.author ?? '').trim();
  const genre = String(body.genre ?? '').trim();
  const description = String(body.description ?? '');
  const coverUrl = String(body.cover_url ?? '').trim();

  if (!title) return 'Book title is required.';
  if (!author) return 'Author is required.';
  if (!genre) return 'Genre is required.';

  if (title.length > 255 || author.length > 255) {
    return 'Title and author must be 255 characters or fewer.';
  }

  if (genre.length > 100) {
    return 'Genre must be 100 characters or fewer.';
  }

  if (description.length > 4000) {
    return 'Description must be 4000 characters or fewer.';
  }

  if (coverUrl.length > 2048) {
    return 'Cover image URL is too long.';
  }

  if (coverUrl) {
    try {
      const url = new URL(coverUrl);

      if (!['http:', 'https:'].includes(url.protocol)) {
        return 'Cover image URL must use HTTP or HTTPS.';
      }
    } catch {
      return 'Enter a valid cover image URL.';
    }
  }

  const rating = Number(body.rating ?? 0);
  const year = Number(body.published_year ?? 2024);
  const copies = Number(body.available_copies ?? 1);

  if (!Number.isFinite(rating) || rating < 0 || rating > 5) {
    return 'Rating must be a number between 0 and 5.';
  }

  if (!Number.isInteger(year) || year < 0 || year > 3000) {
    return 'Invalid publication year.';
  }

  if (!Number.isInteger(copies) || copies < 0) {
    return 'Available copies must be a non-negative integer.';
  }

  return null;
}

function bookValues(body, userId, isCommunityRecommendation) {
  return [
    String(body.title).trim(),
    String(body.author).trim(),
    String(body.genre).trim(),
    String(body.description ?? ''),
    Number(body.published_year ?? 2024),
    Number(body.rating ?? 0),
    Number(body.available_copies ?? 1),
    String(body.cover_url ?? '').trim(),
    userId,
    isCommunityRecommendation
  ];
}

function bookUpdateValues(body, id) {
  return [
    String(body.title).trim(),
    String(body.author).trim(),
    String(body.genre).trim(),
    String(body.description ?? ''),
    Number(body.published_year ?? 2024),
    Number(body.rating ?? 0),
    Number(body.available_copies ?? 1),
    String(body.cover_url ?? '').trim(),
    id
  ];
}

// Load the current role from PostgreSQL instead of trusting a
// potentially outdated role claim in the JWT.
async function loadUserRole(req, res, next) {
  try {
    const result = await query(
      'SELECT id, role FROM users WHERE id = $1',
      [req.user.id]
    );

    if (!result.rowCount) {
      return res.status(401).json({
        message: 'Your account no longer exists. Please sign in again.'
      });
    }

    req.user.role = String(result.rows[0].role ?? 'user').toLowerCase();

    return next();
  } catch (error) {
    return sendServerError(res, error, 'LOAD USER ROLE ERROR');
  }
}

// Every administrator-only route must use this middleware.
async function adminOnly(req, res, next) {
  return loadUserRole(req, res, () => {
    if (!isAdmin(req.user)) {
      return res.status(403).json({
        message: 'Administrator access is required.'
      });
    }

    return next();
  });
}

// ------------------------------------------------------
// HEALTH CHECK
// ------------------------------------------------------

app.get('/api/health', (_req, res) => {
  return res.json({
    ok: true,
    service: 'book-recommendation-api'
  });
});

// ------------------------------------------------------
// AUTHENTICATION
// ------------------------------------------------------

app.post('/api/auth/signup', async (req, res) => {
  try {
    const name = String(req.body?.name ?? '').trim();
    const email = normalizeEmail(req.body?.email);
    const password = req.body?.password;

    if (
      !name ||
      !EMAIL_PATTERN.test(email) ||
      typeof password !== 'string' ||
      password.length < 6
    ) {
      return res.status(400).json({
        message:
          'Name, valid email and password of at least 6 characters are required.'
      });
    }

    if (name.length > 100) {
      return res.status(400).json({
        message: 'Name must be 100 characters or fewer.'
      });
    }

    const existing = await query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existing.rowCount) {
      return res.status(409).json({
        message: 'Email is already registered.'
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const result = await query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, 'user')
       RETURNING id, name, email, role, created_at`,
      [name, email, passwordHash]
    );

    const user = result.rows[0];

    return res.status(201).json({
      token: signToken(user),
      user
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        message: 'Email is already registered.'
      });
    }

    return sendServerError(res, error, 'SIGNUP ERROR');
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = req.body?.password;

    if (!email || typeof password !== 'string') {
      return res.status(400).json({
        message: 'Email and password are required.'
      });
    }

    const result = await query(
      'SELECT id, name, email, password_hash, role FROM users WHERE email = $1',
      [email]
    );

    if (
      !result.rowCount ||
      !(await bcrypt.compare(password, result.rows[0].password_hash))
    ) {
      return res.status(401).json({
        message: 'Incorrect email or password.'
      });
    }

    const row = result.rows[0];

    const user = {
      id: row.id,
      name: row.name,
      email: row.email,
      role: String(row.role ?? 'user').toLowerCase()
    };

    return res.json({
      token: signToken(user),
      user
    });
  } catch (error) {
    return sendServerError(res, error, 'LOGIN ERROR');
  }
});

// ------------------------------------------------------
// BOOK CATALOG
// ------------------------------------------------------

app.get('/api/books', auth, async (req, res) => {
  try {
    const search = String(req.query.q ?? '').trim();
    const sort = String(req.query.sort ?? 'title');

    const result = await query(
      `SELECT
         b.*,
         EXISTS (
           SELECT 1
           FROM favorites f
           WHERE f.book_id = b.id AND f.user_id = $1
         ) AS is_favorite,
         EXISTS (
           SELECT 1
           FROM borrow_history bh
           WHERE bh.book_id = b.id
             AND bh.user_id = $1
           GROUP BY bh.book_id
           HAVING
             COUNT(*) FILTER (WHERE bh.action = 'borrowed')
             >
             COUNT(*) FILTER (WHERE bh.action = 'returned')
         ) AS is_borrowed
       FROM books b
       WHERE (
         $2 = ''
         OR LOWER(b.title) LIKE LOWER('%' || $2 || '%')
         OR LOWER(b.author) LIKE LOWER('%' || $2 || '%')
         OR LOWER(b.genre) LIKE LOWER('%' || $2 || '%')
       )`,
      [req.user.id, search]
    );

    const bst = new BookBST();
    result.rows.forEach(book => bst.insert(book));

    let books = result.rows;

    if (search) {
      const titleMatches = bst.searchPrefix(search);

      books = [
        ...new Map(
          [...titleMatches, ...result.rows].map(book => [book.id, book])
        ).values()
      ];
    }

    if (sort === 'rating') {
      books = mergeSort(
        books,
        (a, b) => Number(b.rating) - Number(a.rating)
      );
    } else if (sort === 'year') {
      books = mergeSort(
        books,
        (a, b) =>
          Number(b.published_year) - Number(a.published_year)
      );
    } else {
      books = mergeSort(
        books,
        (a, b) => a.title.localeCompare(b.title)
      );
    }

    return res.json({
      books,
      algorithm: search
        ? 'BST title search and database filtering'
        : 'Merge Sort / database retrieval'
    });
  } catch (error) {
    return sendServerError(res, error, 'GET BOOKS ERROR');
  }
});

// Administrators add library books.
// Readers may submit community recommendations.
app.post('/api/books', auth, loadUserRole, async (req, res) => {
  try {
    const body = req.body ?? {};
    const community = body.community_recommendation === true;

    if (!community && !isAdmin(req.user)) {
      return res.status(403).json({
        message:
          'Only administrators can add books directly to the library. Readers may submit community recommendations.'
      });
    }

    const validationError = validateBook(body);

    if (validationError) {
      return res.status(400).json({
        message: validationError
      });
    }

    const result = await query(
      `INSERT INTO books (
         title, author, genre, description, published_year,
         rating, available_copies, cover_url, submitted_by,
         is_community_recommendation
       )
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING *`,
      bookValues(body, req.user.id, community)
    );

    return res.status(201).json({
      message: community
        ? 'Book recommendation submitted successfully.'
        : 'Book added successfully.',
      book: result.rows[0]
    });
  } catch (error) {
    return sendServerError(res, error, 'ADD BOOK ERROR');
  }
});

app.get('/api/books/:id', auth, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);

    if (!id) {
      return res.status(400).json({ message: 'Invalid book ID.' });
    }

    const result = await query(
      `SELECT
         b.*,
         EXISTS (
           SELECT 1 FROM favorites f
           WHERE f.book_id = b.id AND f.user_id = $1
         ) AS is_favorite,
         EXISTS (
           SELECT 1 FROM borrow_history bh
           WHERE bh.book_id = b.id AND bh.user_id = $1
           GROUP BY bh.book_id
           HAVING
             COUNT(*) FILTER (WHERE bh.action = 'borrowed')
             >
             COUNT(*) FILTER (WHERE bh.action = 'returned')
         ) AS is_borrowed
       FROM books b
       WHERE b.id = $2`,
      [req.user.id, id]
    );

    if (!result.rowCount) {
      return res.status(404).json({ message: 'Book not found.' });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    return sendServerError(res, error, 'GET BOOK ERROR');
  }
});

// Administrators may edit any book. Readers may edit their own
// community recommendations only.
app.put('/api/books/:id', auth, loadUserRole, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);

    if (!id) {
      return res.status(400).json({ message: 'Invalid book ID.' });
    }

    const existing = await query(
      `SELECT id, submitted_by, is_community_recommendation
       FROM books
       WHERE id = $1`,
      [id]
    );

    if (!existing.rowCount) {
      return res.status(404).json({ message: 'Book not found.' });
    }

    if (
      !isAdmin(req.user) &&
      !isCommunityBookOwner(existing.rows[0], req.user)
    ) {
      return res.status(403).json({
        message: 'You are not authorized to edit this book.'
      });
    }

    const validationError = validateBook(req.body);

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const result = await query(
      `UPDATE books
       SET title = $1,
           author = $2,
           genre = $3,
           description = $4,
           published_year = $5,
           rating = $6,
           available_copies = $7,
           cover_url = $8
       WHERE id = $9
       RETURNING *`,
      bookUpdateValues(req.body, id)
    );

    return res.json({
      message: 'Book updated successfully.',
      book: result.rows[0]
    });
  } catch (error) {
    return sendServerError(res, error, 'EDIT BOOK ERROR');
  }
});

app.delete('/api/books/:id', auth, loadUserRole, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);

    if (!id) {
      return res.status(400).json({ message: 'Invalid book ID.' });
    }

    const existing = await query(
      `SELECT id, submitted_by, is_community_recommendation
       FROM books
       WHERE id = $1`,
      [id]
    );

    if (!existing.rowCount) {
      return res.status(404).json({ message: 'Book not found.' });
    }

    if (
      !isAdmin(req.user) &&
      !isCommunityBookOwner(existing.rows[0], req.user)
    ) {
      return res.status(403).json({
        message: 'You are not authorized to delete this book.'
      });
    }

    await query('DELETE FROM books WHERE id = $1', [id]);

    return res.json({ message: 'Book deleted successfully.' });
  } catch (error) {
    return sendServerError(res, error, 'DELETE BOOK ERROR');
  }
});

// ------------------------------------------------------
// MY RECOMMENDATIONS
// ------------------------------------------------------

app.get('/api/my-recommendations', auth, async (req, res) => {
  try {
    const result = await query(
      `SELECT *
       FROM books
       WHERE submitted_by = $1
         AND is_community_recommendation = TRUE
       ORDER BY created_at DESC`,
      [req.user.id]
    );

    return res.json({ books: result.rows });
  } catch (error) {
    return sendServerError(res, error, 'MY RECOMMENDATIONS ERROR');
  }
});

// ------------------------------------------------------
// FAVORITES
// ------------------------------------------------------

app.post('/api/books/:id/favorite', auth, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);

    if (!id) {
      return res.status(400).json({ message: 'Invalid book ID.' });
    }

    const book = await query('SELECT id FROM books WHERE id = $1', [id]);

    if (!book.rowCount) {
      return res.status(404).json({ message: 'Book not found.' });
    }

    const existing = await query(
      'SELECT 1 FROM favorites WHERE user_id = $1 AND book_id = $2',
      [req.user.id, id]
    );

    if (existing.rowCount) {
      await query(
        'DELETE FROM favorites WHERE user_id = $1 AND book_id = $2',
        [req.user.id, id]
      );

      return res.json({ favorite: false });
    }

    await query(
      'INSERT INTO favorites (user_id, book_id) VALUES ($1, $2)',
      [req.user.id, id]
    );

    return res.json({ favorite: true });
  } catch (error) {
    return sendServerError(res, error, 'FAVORITE ERROR');
  }
});

// ------------------------------------------------------
// BORROW A BOOK
// ------------------------------------------------------

app.post('/api/books/:id/borrow', auth, async (req, res) => {
  const id = readPositiveId(req.params.id);

  if (!id) {
    return res.status(400).json({ message: 'Invalid book ID.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const result = await client.query(
      'SELECT * FROM books WHERE id = $1 FOR UPDATE',
      [id]
    );

    const book = result.rows[0];

    if (!book) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Book not found.' });
    }

    if (Number(book.available_copies) <= 0) {
      await client.query('ROLLBACK');

      return res.status(400).json({
        message: 'No copies available. Reserve the book instead.'
      });
    }

    await client.query(
      'UPDATE books SET available_copies = available_copies - 1 WHERE id = $1',
      [id]
    );

    await client.query(
      `INSERT INTO borrow_history (user_id, book_id, action)
       VALUES ($1, $2, 'borrowed')`,
      [req.user.id, id]
    );

    await client.query('COMMIT');

    return res.json({ message: 'Book borrowed successfully.' });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    return sendServerError(res, error, 'BORROW BOOK ERROR');
  } finally {
    client.release();
  }
});

// ------------------------------------------------------
// RETURN A BOOK
// ------------------------------------------------------

app.post('/api/books/:id/return', auth, async (req, res) => {
  const id = readPositiveId(req.params.id);

  if (!id) {
    return res.status(400).json({ message: 'Invalid book ID.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const book = await client.query(
      'SELECT id FROM books WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (!book.rowCount) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Book not found.' });
    }

    const history = await client.query(
      `SELECT
         COUNT(*) FILTER (WHERE action = 'borrowed')::int AS borrowed_count,
         COUNT(*) FILTER (WHERE action = 'returned')::int AS returned_count
       FROM borrow_history
       WHERE user_id = $1 AND book_id = $2`,
      [req.user.id, id]
    );

    const borrowedCount = history.rows[0].borrowed_count;
    const returnedCount = history.rows[0].returned_count;

    if (borrowedCount <= returnedCount) {
      await client.query('ROLLBACK');

      return res.status(400).json({
        message: 'You do not currently have this book borrowed.'
      });
    }

    await client.query(
      'UPDATE books SET available_copies = available_copies + 1 WHERE id = $1',
      [id]
    );

    await client.query(
      `INSERT INTO borrow_history (user_id, book_id, action)
       VALUES ($1, $2, 'returned')`,
      [req.user.id, id]
    );

    await client.query('COMMIT');

    return res.json({ message: 'Book returned successfully.' });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    return sendServerError(res, error, 'RETURN BOOK ERROR');
  } finally {
    client.release();
  }
});

// ------------------------------------------------------
// RESERVE A BOOK
// ------------------------------------------------------

app.post('/api/books/:id/reserve', auth, async (req, res) => {
  const id = readPositiveId(req.params.id);

  if (!id) {
    return res.status(400).json({ message: 'Invalid book ID.' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const book = await client.query(
      'SELECT id FROM books WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (!book.rowCount) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Book not found.' });
    }

    const duplicate = await client.query(
      `SELECT 1
       FROM reservations
       WHERE user_id = $1
         AND book_id = $2
         AND status = 'waiting'`,
      [req.user.id, id]
    );

    if (duplicate.rowCount) {
      await client.query('ROLLBACK');

      return res.status(409).json({
        message: 'You already have a reservation for this book.'
      });
    }

    const count = await client.query(
      `SELECT COUNT(*)::int AS count
       FROM reservations
       WHERE book_id = $1 AND status = 'waiting'`,
      [id]
    );

    const queue = new ReservationQueue(
      Array.from(
        { length: count.rows[0].count },
        (_, index) => index + 1
      )
    );

    queue.enqueue(req.user.id);

    const position = queue.length;

    await client.query(
      `INSERT INTO reservations (user_id, book_id, status, queue_position)
       VALUES ($1, $2, 'waiting', $3)`,
      [req.user.id, id, position]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      message: 'Added to reservation queue.',
      queue_position: position
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    return sendServerError(res, error, 'RESERVATION ERROR');
  } finally {
    client.release();
  }
});

// ------------------------------------------------------
// ADMIN DASHBOARD OVERVIEW
// ------------------------------------------------------

app.get('/api/admin/overview', auth, adminOnly, async (_req, res) => {
  try {
    const [
      userResult,
      bookResult,
      borrowedResult,
      reservationResult,
      returnedResult,
      copiesResult
    ] = await Promise.all([
      query('SELECT COUNT(*)::int AS count FROM users'),
      query('SELECT COUNT(*)::int AS count FROM books'),

      query(`
        SELECT COALESCE(SUM(active_count), 0)::int AS count
        FROM (
          SELECT
            user_id,
            book_id,
            COUNT(*) FILTER (WHERE action = 'borrowed')
              - COUNT(*) FILTER (WHERE action = 'returned') AS active_count
          FROM borrow_history
          GROUP BY user_id, book_id
        ) active
        WHERE active_count > 0
      `),

      query(`
        SELECT COUNT(*)::int AS count
        FROM reservations
        WHERE status = 'waiting'
      `),

      query(`
        SELECT COUNT(*)::int AS count
        FROM borrow_history
        WHERE action = 'returned'
      `),

      query(`
        SELECT COALESCE(SUM(available_copies), 0)::int AS count
        FROM books
      `)
    ]);

    return res.json({
      users: userResult.rows[0].count,
      books: bookResult.rows[0].count,
      borrowed: borrowedResult.rows[0].count,
      reservations: reservationResult.rows[0].count,
      returned: returnedResult.rows[0].count,
      availableCopies: copiesResult.rows[0].count
    });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN OVERVIEW ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: VIEW USERS
// ------------------------------------------------------

app.get('/api/admin/users', auth, adminOnly, async (_req, res) => {
  try {
    const result = await query(`
      SELECT id, name, email, role, created_at
      FROM users
      ORDER BY created_at DESC
    `);

    return res.json({ users: result.rows });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN USERS ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: CHANGE USER ROLE
// ------------------------------------------------------

app.put('/api/admin/users/:id/role', auth, adminOnly, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);
    const role = String(req.body?.role ?? '').trim().toLowerCase();

    if (!id) {
      return res.status(400).json({ message: 'Invalid user ID.' });
    }

    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({
        message: 'Role must be user or admin.'
      });
    }

    if (id === Number(req.user.id)) {
      return res.status(400).json({
        message: 'You cannot change your own role.'
      });
    }

    const target = await query(
      'SELECT id, role FROM users WHERE id = $1',
      [id]
    );

    if (!target.rowCount) {
      return res.status(404).json({ message: 'User not found.' });
    }

    // Do not let the last administrator lose admin access.
    if (
      role === 'user' &&
      String(target.rows[0].role).toLowerCase() === 'admin'
    ) {
      const count = await query(
        `SELECT COUNT(*)::int AS count
         FROM users
         WHERE LOWER(COALESCE(role, 'user')) = 'admin'`
      );

      if (count.rows[0].count <= 1) {
        return res.status(400).json({
          message: 'The last administrator cannot be demoted.'
        });
      }
    }

    const result = await query(
      `UPDATE users
       SET role = $1
       WHERE id = $2
       RETURNING id, name, email, role, created_at`,
      [role, id]
    );

    return res.json({
      message: 'User role updated successfully.',
      user: result.rows[0]
    });
  } catch (error) {
    return sendServerError(res, error, 'CHANGE USER ROLE ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: DELETE USER
// ------------------------------------------------------

app.delete('/api/admin/users/:id', auth, adminOnly, async (req, res) => {
  const userId = readPositiveId(req.params.id);

  if (!userId) {
    return res.status(400).json({ message: 'Invalid user ID.' });
  }

  if (userId === Number(req.user.id)) {
    return res.status(400).json({
      message: 'You cannot delete your own active account.'
    });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const target = await client.query(
      `SELECT id, role
       FROM users
       WHERE id = $1
       FOR UPDATE`,
      [userId]
    );

    if (!target.rowCount) {
      await client.query('ROLLBACK');

      return res.status(404).json({ message: 'User not found.' });
    }

    if (String(target.rows[0].role ?? 'user').toLowerCase() === 'admin') {
      await client.query('ROLLBACK');

      return res.status(403).json({
        message: 'Administrator accounts are protected from deletion.'
      });
    }

    // Return book copies which this user has not yet returned.
    const activeLoans = await client.query(
      `SELECT
         book_id,
         (
           COUNT(*) FILTER (WHERE action = 'borrowed')
           - COUNT(*) FILTER (WHERE action = 'returned')
         )::int AS active_count
       FROM borrow_history
       WHERE user_id = $1
       GROUP BY book_id
       HAVING
         COUNT(*) FILTER (WHERE action = 'borrowed')
         >
         COUNT(*) FILTER (WHERE action = 'returned')`,
      [userId]
    );

    for (const loan of activeLoans.rows) {
      await client.query(
        `UPDATE books
         SET available_copies = available_copies + $1
         WHERE id = $2`,
        [Number(loan.active_count), loan.book_id]
      );
    }

    // The existing schema cascades deletion into this user's
    // favorites, reservations and borrowing-history records.
    // Books they submitted remain in the library because
    // books.submitted_by uses ON DELETE SET NULL.
    await client.query(
      'DELETE FROM users WHERE id = $1',
      [userId]
    );

    await client.query('COMMIT');

    return res.json({
      message: 'User account deleted successfully.'
    });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => {});
    return sendServerError(res, error, 'ADMIN DELETE USER ERROR');
  } finally {
    client.release();
  }
});

// ------------------------------------------------------
// ADMIN: VIEW ALL BOOKS AND SUBMITTERS
// ------------------------------------------------------

app.get('/api/admin/books', auth, adminOnly, async (_req, res) => {
  try {
    const result = await query(`
      SELECT
        b.*,
        u.name AS submitted_by_name,
        u.email AS submitted_by_email
      FROM books b
      LEFT JOIN users u ON u.id = b.submitted_by
      ORDER BY b.created_at DESC
    `);

    return res.json({ books: result.rows });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN BOOKS ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: EDIT ANY BOOK
// ------------------------------------------------------

app.put('/api/admin/books/:id', auth, adminOnly, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);

    if (!id) {
      return res.status(400).json({ message: 'Invalid book ID.' });
    }

    const validationError = validateBook(req.body);

    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const result = await query(
      `UPDATE books
       SET title = $1,
           author = $2,
           genre = $3,
           description = $4,
           published_year = $5,
           rating = $6,
           available_copies = $7,
           cover_url = $8
       WHERE id = $9
       RETURNING *`,
      bookUpdateValues(req.body, id)
    );

    if (!result.rowCount) {
      return res.status(404).json({ message: 'Book not found.' });
    }

    return res.json({
      message: 'Book updated successfully.',
      book: result.rows[0]
    });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN EDIT BOOK ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: DELETE ANY BOOK
// ------------------------------------------------------

app.delete('/api/admin/books/:id', auth, adminOnly, async (req, res) => {
  try {
    const id = readPositiveId(req.params.id);

    if (!id) {
      return res.status(400).json({ message: 'Invalid book ID.' });
    }

    const result = await query(
      'DELETE FROM books WHERE id = $1 RETURNING id',
      [id]
    );

    if (!result.rowCount) {
      return res.status(404).json({ message: 'Book not found.' });
    }

    return res.json({ message: 'Book deleted successfully.' });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN DELETE BOOK ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: VIEW RESERVATIONS
// ------------------------------------------------------

app.get('/api/admin/reservations', auth, adminOnly, async (_req, res) => {
  try {
    const result = await query(`
      SELECT
        r.id,
        r.status,
        r.queue_position,
        r.created_at,
        u.id AS user_id,
        u.name AS user_name,
        u.email AS user_email,
        b.id AS book_id,
        b.title,
        b.author
      FROM reservations r
      JOIN users u ON u.id = r.user_id
      JOIN books b ON b.id = r.book_id
      ORDER BY
        CASE WHEN r.status = 'waiting' THEN 0 ELSE 1 END,
        r.queue_position ASC,
        r.created_at ASC
    `);

    return res.json({ reservations: result.rows });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN RESERVATIONS ERROR');
  }
});

// ------------------------------------------------------
// ADMIN: VIEW ALL BORROWING AND RETURN HISTORY
// ------------------------------------------------------

app.get('/api/admin/history', auth, adminOnly, async (_req, res) => {
  try {
    const result = await query(`
      SELECT
        h.id,
        h.action,
        h.created_at,
        u.id AS user_id,
        u.name AS user_name,
        u.email AS user_email,
        b.id AS book_id,
        b.title,
        b.author
      FROM borrow_history h
      JOIN users u ON u.id = h.user_id
      JOIN books b ON b.id = h.book_id
      ORDER BY h.created_at DESC
    `);

    return res.json({ history: result.rows });
  } catch (error) {
    return sendServerError(res, error, 'ADMIN HISTORY ERROR');
  }
});

// ------------------------------------------------------
// USER'S OWN BORROWING HISTORY
// ------------------------------------------------------

app.get('/api/history', auth, async (req, res) => {
  try {
    const result = await query(
      `SELECT h.*, b.title, b.author
       FROM borrow_history h
       JOIN books b ON b.id = h.book_id
       WHERE h.user_id = $1
       ORDER BY h.created_at DESC`,
      [req.user.id]
    );

    const stack = new HistoryStack(result.rows);

    return res.json({
      history: stack.values(),
      dataStructure: 'Stack (LIFO)'
    });
  } catch (error) {
    return sendServerError(res, error, 'USER HISTORY ERROR');
  }
});

// ------------------------------------------------------
// PERSONALIZED RECOMMENDATIONS
// ------------------------------------------------------

app.get('/api/recommendations', auth, async (req, res) => {
  try {
    const [booksResult, favoritesResult, historyResult] =
      await Promise.all([
        query('SELECT * FROM books'),

        query(
          `SELECT b.*
           FROM favorites f
           JOIN books b ON b.id = f.book_id
           WHERE f.user_id = $1`,
          [req.user.id]
        ),

        query(
          `SELECT b.*
           FROM borrow_history h
           JOIN books b ON b.id = h.book_id
           WHERE h.user_id = $1`,
          [req.user.id]
        )
      ]);

    const preferences = [
      ...favoritesResult.rows,
      ...historyResult.rows
    ];

    const genreCounts = genreFrequency(preferences);

    const recommendations = booksResult.rows
      .filter(book => !preferences.some(item => item.id === book.id))
      .map(book => ({
        ...book,
        recommendation_score:
          (genreCounts.get(book.genre) || 0) * 10 +
          Number(book.rating) * 2
      }));

    return res.json({
      recommendations: mergeSort(
        recommendations,
        (a, b) =>
          b.recommendation_score - a.recommendation_score
      ).slice(0, 15)
    });
  } catch (error) {
    return sendServerError(res, error, 'RECOMMENDATIONS ERROR');
  }
});

// ------------------------------------------------------
// USER PROFILE
// ------------------------------------------------------

app.get('/api/profile', auth, async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, email, role, created_at, profile_photo
       FROM users
       WHERE id = $1`,
      [req.user.id]
    );

    if (!result.rowCount) {
      return res.status(404).json({
        message: 'User profile not found.'
      });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    return sendServerError(res, error, 'PROFILE ERROR');
  }
});

// ------------------------------------------------------
// SAVE PROFILE PHOTO
// ------------------------------------------------------

app.put('/api/profile/photo', auth, async (req, res) => {
  try {
    const photo = req.body?.profile_photo;
    const prefix = 'data:image/jpeg;base64,';

    if (typeof photo !== 'string' || !photo.startsWith(prefix)) {
      return res.status(400).json({
        message: 'Please upload a valid JPEG profile photo.'
      });
    }

    if (photo.length > 500000) {
      return res.status(413).json({
        message: 'Photo is too large. Please choose a smaller image.'
      });
    }

    const encoded = photo.slice(prefix.length);

    if (
      !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(encoded)
    ) {
      return res.status(400).json({
        message: 'The photo data is invalid.'
      });
    }

    const image = Buffer.from(encoded, 'base64');

    if (
      image.length === 0 ||
      image.length > 350 * 1024 ||
      image[0] !== 0xff ||
      image[1] !== 0xd8
    ) {
      return res.status(400).json({
        message: 'Please upload a valid JPEG image under 350 KB.'
      });
    }

    const result = await query(
      `UPDATE users
       SET profile_photo = $1
       WHERE id = $2
       RETURNING profile_photo`,
      [photo, req.user.id]
    );

    if (!result.rowCount) {
      return res.status(404).json({
        message: 'User profile not found.'
      });
    }

    return res.json({
      message: 'Profile photo saved successfully.',
      profile_photo: result.rows[0].profile_photo
    });
  } catch (error) {
    return sendServerError(res, error, 'SAVE PROFILE PHOTO ERROR');
  }
});

// ------------------------------------------------------
// REMOVE PROFILE PHOTO
// ------------------------------------------------------

app.delete('/api/profile/photo', auth, async (req, res) => {
  try {
    const result = await query(
      `UPDATE users
       SET profile_photo = NULL
       WHERE id = $1
       RETURNING id`,
      [req.user.id]
    );

    if (!result.rowCount) {
      return res.status(404).json({
        message: 'User profile not found.'
      });
    }

    return res.json({
      message: 'Profile photo removed successfully.'
    });
  } catch (error) {
    return sendServerError(res, error, 'REMOVE PROFILE PHOTO ERROR');
  }
});

// ------------------------------------------------------
// ERROR HANDLING
// ------------------------------------------------------

app.use((error, _req, res, _next) => {
  if (error.type === 'entity.too.large') {
    return res.status(413).json({
      message: 'Request body is too large.'
    });
  }

  console.error('UNHANDLED API ERROR:', error);

  return res.status(500).json({
    message: 'Internal server error.'
  });
});

// ------------------------------------------------------
// START SERVER
// ------------------------------------------------------

const port = Number(process.env.PORT) || 5000;

app.listen(port, '0.0.0.0', () => {
  console.log(`API running on port ${port}`);
});