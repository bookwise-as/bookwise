import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import pg from 'pg';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

async function resetAdmin() {
  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  const name = process.env.ADMIN_NAME || 'BookWise Administrator';

  if (!email || !password) {
    throw new Error('ADMIN_EMAIL or ADMIN_PASSWORD is missing from .env');
  }

  const passwordHash = await bcrypt.hash(password, 12);

  const result = await pool.query(
    `UPDATE users
     SET name=$1,
         password_hash=$2,
         role='admin'
     WHERE lower(email)=lower($3)
     RETURNING id,name,email,role`,
    [name, passwordHash, email]
  );

  if (!result.rowCount) {
    const created = await pool.query(
      `INSERT INTO users(name,email,password_hash,role)
       VALUES($1,$2,$3,'admin')
       RETURNING id,name,email,role`,
      [name, email, passwordHash]
    );

    console.log('ADMIN RESET/CREATED');
    console.log(created.rows[0]);
  } else {
    console.log('ADMIN PASSWORD RESET');
    console.log(result.rows[0]);
  }

  await pool.end();
}

resetAdmin().catch(async (error) => {
  console.error(error.message);
  await pool.end();
  process.exit(1);
});