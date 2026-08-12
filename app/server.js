const express = require("express");
const { Pool } = require("pg");

const app = express();

app.use(express.json());

const pool = new Pool({
    host: process.env.DB_HOST || "localhost",
    port: Number(process.env.DB_PORT || 15432),
    database: process.env.DB_NAME || "todos",
    user: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD || "postgres"
});

async function initializeDatabase() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS todos (
            id SERIAL PRIMARY KEY,
            title TEXT NOT NULL,
            completed BOOLEAN NOT NULL DEFAULT FALSE
        )
    `);

    console.log("Database initialized");
}

app.get("/health", (req, res) => {
    res.json({
        status: "ok"
    });
});

app.get("/todos", async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT * FROM todos ORDER BY id"
        );

        res.json(result.rows);
    } catch (error) {
        console.error(error);

        res.status(500).json({
            error: "Database error"
        });
    }
});

app.post("/todos", async (req, res) => {
    try {
        const { title } = req.body;

        if (!title) {
            return res.status(400).json({
                error: "title is required"
            });
        }

        const result = await pool.query(
            "INSERT INTO todos (title) VALUES ($1) RETURNING *",
            [title]
        );

        res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        res.status(500).json({
            error: "Database error"
        });
    }
});

app.put("/todos/:id", async (req, res) => {
    try {
        const { completed } = req.body;

        const result = await pool.query(
            `
            UPDATE todos
            SET completed = $1
            WHERE id = $2
            RETURNING *
            `,
            [completed, req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: "Todo not found"
            });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error(error);

        res.status(500).json({
            error: "Database error"
        });
    }
});

app.delete("/todos/:id", async (req, res) => {
    try {
        const result = await pool.query(
            "DELETE FROM todos WHERE id = $1 RETURNING *",
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: "Todo not found"
            });
        }

        res.status(204).send();
    } catch (error) {
        console.error(error);

        res.status(500).json({
            error: "Database error"
        });
    }
});

const PORT = process.env.PORT || 3000;

async function start() {
    try {
        await initializeDatabase();

        app.listen(PORT, () => {
            console.log(`Todo API listening on port ${PORT}`);
        });
    } catch (error) {
        console.error("Failed to start application:", error);

        process.exit(1);
    }
}

start();